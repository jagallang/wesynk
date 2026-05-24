const { onObjectFinalized } = require("firebase-functions/v2/storage");
const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { initializeApp } = require("firebase-admin/app");
const { getStorage } = require("firebase-admin/storage");
const { getFirestore } = require("firebase-admin/firestore");
const { getMessaging } = require("firebase-admin/messaging");
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
  // rotate()로 EXIF orientation 적용 후 메타데이터 추출
  const rotatedBuffer = await sharp(inputPath).rotate().toBuffer();
  const meta = await sharp(rotatedBuffer).metadata();
  const result = { width: meta.width, height: meta.height, thumbnailReady: true };

  for (const size of THUMB_SIZES) {
    const thumbName = `${baseName}_${size}x${size}.jpg`;
    const thumbPath = `${parentDir}/thumb_${size}/${thumbName}`;
    const tempThumb = path.join(os.tmpdir(), thumbName);

    await sharp(inputPath)
      .rotate() // EXIF orientation 자동 적용
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

// ─── 푸시 알림 ───

/**
 * 상대방의 FCM 토큰 목록 가져오기
 */
async function getPartnerTokens(coupleId, senderUid) {
  const db = getFirestore();
  const coupleDoc = await db.collection("couples").doc(coupleId).get();
  if (!coupleDoc.exists) return { tokens: [], partnerUid: null };

  const members = coupleDoc.data().members || [];
  const partnerUid = members.find((uid) => uid !== senderUid);
  if (!partnerUid) return { tokens: [], partnerUid: null };

  const tokenSnap = await db
    .collection("users")
    .doc(partnerUid)
    .collection("tokens")
    .get();

  const tokens = tokenSnap.docs.map((d) => d.data().token).filter(Boolean);
  return { tokens, partnerUid };
}

/**
 * 알림 설정 확인 (couples/{coupleId} 문서의 settings 필드)
 */
async function isNotifEnabled(coupleId, type) {
  const db = getFirestore();
  const coupleDoc = await db.collection("couples").doc(coupleId).get();
  if (!coupleDoc.exists) return true;
  const settings = coupleDoc.data().settings || {};
  const key = `notif_${type}`;
  return settings[key] !== false; // 기본값 true
}

/**
 * FCM 메시지 전송 (만료 토큰 자동 정리)
 */
async function sendFcm(tokens, notification, data, partnerUid) {
  if (tokens.length === 0) return;

  const messaging = getMessaging();
  const results = await Promise.allSettled(
    tokens.map((token) =>
      messaging.send({
        token,
        notification,
        data,
        webpush: {
          notification: {
            icon: "/icons/Icon-192.png",
          },
        },
      })
    )
  );

  // 만료/무효 토큰 자동 삭제
  const db = getFirestore();
  const invalidCodes = [
    "messaging/registration-token-not-registered",
    "messaging/invalid-registration-token",
    "messaging/mismatched-credential",
  ];

  for (let i = 0; i < results.length; i++) {
    const r = results[i];
    if (r.status === "rejected") {
      const code = r.reason?.code || "";
      console.warn(`[FCM] Failed: ${tokens[i].substring(0, 20)}... (${code})`);
      if (partnerUid && invalidCodes.includes(code)) {
        const tokenHash = tokens[i].hashCode;
        const tokenSnap = await db
          .collection("users")
          .doc(partnerUid)
          .collection("tokens")
          .where("token", "==", tokens[i])
          .get();
        for (const doc of tokenSnap.docs) {
          await doc.ref.delete();
          console.log(`[FCM] Deleted invalid token: ${doc.id}`);
        }
      }
    }
  }
}

/**
 * 채팅 메시지 알림
 */
exports.onNewMessage = onDocumentCreated(
  {
    document: "couples/{coupleId}/messages/{messageId}",
    region: "asia-northeast3",
  },
  async (event) => {
    const data = event.data?.data();
    if (!data) return;

    const coupleId = event.params.coupleId;
    const senderUid = data.senderId;

    if (!(await isNotifEnabled(coupleId, "chat"))) return;

    const { tokens, partnerUid } = await getPartnerTokens(coupleId, senderUid);
    const body = data.imageUrl
      ? "📷 사진을 보냈습니다"
      : data.body || "새 메시지";

    await sendFcm(
      tokens,
      { title: "WeSync", body },
      { type: "chat", coupleId },
      partnerUid
    );
    console.log(`[FCM] chat notification sent to ${tokens.length} devices`);
  }
);

/**
 * 캘린더 일정 알림
 */
exports.onNewItem = onDocumentCreated(
  {
    document: "couples/{coupleId}/items/{itemId}",
    region: "asia-northeast3",
  },
  async (event) => {
    const data = event.data?.data();
    if (!data) return;

    const coupleId = event.params.coupleId;
    const senderUid = data.createdBy;
    const type = data.type; // event, note, date, photo

    // 사진은 별도 트리거 없이 items로 통합
    if (type === "photo") {
      if (!(await isNotifEnabled(coupleId, "album"))) return;
      const { tokens, partnerUid } = await getPartnerTokens(coupleId, senderUid);
      await sendFcm(
        tokens,
        { title: "WeSync", body: "📷 새 사진이 추가되었습니다" },
        { type: "album", coupleId },
        partnerUid
      );
      console.log(`[FCM] album notification sent to ${tokens.length} devices`);
      return;
    }

    if (!(await isNotifEnabled(coupleId, "calendar"))) return;

    const payload = data.payload || {};
    const title = payload.title || payload.body || "";
    const labels = {
      event: "📅 새 일정",
      note: "📝 새 메모",
      date: "💑 데이트 기록",
    };

    const { tokens, partnerUid } = await getPartnerTokens(coupleId, senderUid);
    await sendFcm(
      tokens,
      { title: "WeSync", body: `${labels[type] || "📋 새 항목"}: ${title}` },
      { type: "calendar", coupleId },
      partnerUid
    );
    console.log(`[FCM] calendar notification sent to ${tokens.length} devices`);
  }
);
