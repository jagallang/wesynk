const { onObjectFinalized } = require("firebase-functions/v2/storage");
const { initializeApp } = require("firebase-admin/app");
const { getStorage } = require("firebase-admin/storage");
const { getFirestore } = require("firebase-admin/firestore");
const sharp = require("sharp");
const ffmpeg = require("fluent-ffmpeg");
const ffmpegPath = require("@ffmpeg-installer/ffmpeg").path;
const path = require("path");
const os = require("os");
const fs = require("fs");

ffmpeg.setFfmpegPath(ffmpegPath);
initializeApp();

const THUMB_SIZES = [400, 800];
const MAX_VIDEO_SIZE = 100 * 1024 * 1024; // 100MB

/**
 * Storage에 파일 업로드 시 자동 썸네일 생성
 * - 사진: sharp로 리사이즈
 * - 영상: ffmpeg로 첫 프레임 추출 + 리사이즈
 */
exports.generateThumbnail = onObjectFinalized(
  {
    memory: "1GiB",
    timeoutSeconds: 300,
    region: "asia-northeast3",
  },
  async (event) => {
    const object = event.data;
    const filePath = object.name;
    const contentType = object.contentType || "";
    const fileSize = parseInt(object.size || "0", 10);

    // original/ 경로의 파일만 처리
    if (!filePath || !filePath.includes("/photos/original/")) {
      console.log(`[Thumb] Skipping: not in original/ path: ${filePath}`);
      return null;
    }

    // 이미 썸네일이면 무시 (무한 루프 방지)
    if (filePath.includes("/thumb_")) {
      console.log(`[Thumb] Skipping: already a thumbnail: ${filePath}`);
      return null;
    }

    const isImage = contentType.startsWith("image/");
    const isVideo = contentType.startsWith("video/");

    if (!isImage && !isVideo) {
      console.log(`[Thumb] Skipping: unsupported type: ${contentType}`);
      return null;
    }

    // 영상 크기 제한
    if (isVideo && fileSize > MAX_VIDEO_SIZE) {
      console.log(`[Thumb] Skipping: video too large: ${fileSize} bytes`);
      return null;
    }

    console.log(`[Thumb] Processing: ${filePath} (${contentType}, ${fileSize} bytes)`);

    const bucket = getStorage().bucket(object.bucket);
    const fileName = path.basename(filePath);
    const fileDir = path.dirname(filePath); // couples/{id}/photos/original
    const parentDir = path.dirname(fileDir); // couples/{id}/photos
    const dotIdx = fileName.lastIndexOf(".");
    const baseName = dotIdx > 0 ? fileName.substring(0, dotIdx) : fileName;

    // 임시 파일 다운로드
    const tempOriginal = path.join(os.tmpdir(), fileName);
    await bucket.file(filePath).download({ destination: tempOriginal });
    console.log(`[Thumb] Downloaded to: ${tempOriginal}`);

    // coupleId와 photoId 추출
    // 경로: couples/{coupleId}/photos/original/{photoId}.{ext}
    const pathParts = filePath.split("/");
    const coupleId = pathParts[1];
    const photoId = baseName;

    let metadata = {};

    try {
      if (isImage) {
        metadata = await processImage(tempOriginal, baseName, parentDir, bucket);
      } else {
        metadata = await processVideo(tempOriginal, baseName, parentDir, bucket);
      }

      // Firestore 업데이트
      await updateFirestore(coupleId, photoId, metadata);
      console.log(`[Thumb] Done: ${filePath}`);
    } catch (err) {
      console.error(`[Thumb] Error processing ${filePath}:`, err);
    } finally {
      // 임시 파일 정리
      cleanupTemp(tempOriginal);
    }

    return null;
  }
);

/**
 * 이미지 썸네일 생성
 */
async function processImage(inputPath, baseName, parentDir, bucket) {
  const image = sharp(inputPath);
  const meta = await image.metadata();
  const result = { width: meta.width, height: meta.height, thumbnailReady: true };

  for (const size of THUMB_SIZES) {
    const thumbName = `${baseName}_${size}x${size}.jpg`;
    const thumbPath = `${parentDir}/thumb_${size}/${thumbName}`;
    const tempThumb = path.join(os.tmpdir(), thumbName);

    await sharp(inputPath)
      .resize(size, size, { fit: "cover" })
      .jpeg({ quality: 80 })
      .toFile(tempThumb);

    await bucket.upload(tempThumb, {
      destination: thumbPath,
      metadata: { contentType: "image/jpeg" },
    });

    cleanupTemp(tempThumb);
    console.log(`[Thumb] Created: ${thumbPath}`);
  }

  return result;
}

/**
 * 영상 썸네일 생성 (첫 프레임 추출 + 리사이즈)
 */
async function processVideo(inputPath, baseName, parentDir, bucket) {
  // 1. 첫 프레임 추출
  const frameFile = `${baseName}_frame.jpg`;
  const framePath = path.join(os.tmpdir(), frameFile);

  await new Promise((resolve, reject) => {
    ffmpeg(inputPath)
      .screenshots({
        count: 1,
        folder: os.tmpdir(),
        filename: frameFile,
        timemarks: ["00:00:01"],
      })
      .on("end", resolve)
      .on("error", reject);
  });

  // 2. 영상 메타데이터 추출
  const videoMeta = await new Promise((resolve, reject) => {
    ffmpeg.ffprobe(inputPath, (err, data) => {
      if (err) return reject(err);
      resolve(data);
    });
  });

  const videoStream = (videoMeta.streams || []).find(
    (s) => s.codec_type === "video"
  );
  const duration = videoMeta.format ? Math.round(videoMeta.format.duration || 0) : 0;
  const width = videoStream ? videoStream.width : null;
  const height = videoStream ? videoStream.height : null;

  const result = {
    width,
    height,
    duration,
    thumbnailReady: true,
  };

  // 3. 프레임을 리사이즈해서 썸네일 생성
  for (const size of THUMB_SIZES) {
    const thumbName = `${baseName}_${size}x${size}.jpg`;
    const thumbPath = `${parentDir}/thumb_${size}/${thumbName}`;
    const tempThumb = path.join(os.tmpdir(), thumbName);

    await sharp(framePath)
      .resize(size, size, { fit: "cover" })
      .jpeg({ quality: 80 })
      .toFile(tempThumb);

    await bucket.upload(tempThumb, {
      destination: thumbPath,
      metadata: { contentType: "image/jpeg" },
    });

    cleanupTemp(tempThumb);
    console.log(`[Thumb] Created: ${thumbPath}`);
  }

  cleanupTemp(framePath);
  return result;
}

/**
 * Firestore photo 문서 업데이트
 */
async function updateFirestore(coupleId, photoId, metadata) {
  const db = getFirestore();
  const docRef = db
    .collection("couples")
    .doc(coupleId)
    .collection("items")
    .doc(photoId);

  const updateData = { "payload.thumbnailReady": true };

  if (metadata.width != null) updateData["payload.width"] = metadata.width;
  if (metadata.height != null) updateData["payload.height"] = metadata.height;
  if (metadata.duration != null) updateData["payload.duration"] = metadata.duration;

  await docRef.update(updateData);
  console.log(`[Thumb] Firestore updated: couples/${coupleId}/items/${photoId}`);
}

/**
 * 임시 파일 정리
 */
function cleanupTemp(filePath) {
  try {
    if (fs.existsSync(filePath)) fs.unlinkSync(filePath);
  } catch (_) {}
}
