import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:exif/exif.dart';
import 'package:file_selector/file_selector.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

// ─── PhotoItem 모델 ───

class PhotoItem {
  final String id;
  final String storagePath;
  final String mimeType;
  final int? width, height;
  final DateTime? takenAt;
  final String? caption;
  final DateTime uploadedAt;
  final int byteSize;
  final DateTime? deletedAt;
  final bool uploading;
  final String date;

  PhotoItem({
    required this.id,
    required this.storagePath,
    required this.mimeType,
    this.width,
    this.height,
    this.takenAt,
    this.caption,
    required this.uploadedAt,
    required this.byteSize,
    this.deletedAt,
    this.uploading = false,
    required this.date,
  });

  factory PhotoItem.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    final p = (d['payload'] as Map<String, dynamic>?) ?? {};
    return PhotoItem(
      id: doc.id,
      storagePath: p['storagePath'] as String? ?? '',
      mimeType: p['mimeType'] as String? ?? 'image/jpeg',
      width: p['width'] as int?,
      height: p['height'] as int?,
      takenAt: (p['takenAt'] as Timestamp?)?.toDate(),
      caption: p['caption'] as String?,
      uploadedAt: (p['uploadedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      byteSize: p['byteSize'] as int? ?? 0,
      deletedAt: (d['deletedAt'] as Timestamp?)?.toDate(),
      uploading: p['uploading'] as bool? ?? false,
      date: d['date'] as String? ?? '',
    );
  }

  String thumbnailPath(int size) {
    final segments = storagePath.split('/');
    final filename = segments.last;
    final dotIdx = filename.lastIndexOf('.');
    final name = dotIdx > 0 ? filename.substring(0, dotIdx) : filename;
    final ext = dotIdx > 0 ? filename.substring(dotIdx) : '';
    segments[segments.length - 2] = 'thumb_$size';
    segments[segments.length - 1] = '${name}_${size}x$size$ext';
    return segments.join('/');
  }
}

// ─── PhotoItem 확장 (날짜별 그룹화용) ───

extension PhotoItemDisplay on PhotoItem {
  /// 그룹화·정렬 기준 날짜: takenAt(EXIF) > uploadedAt
  DateTime get displayDate => takenAt ?? uploadedAt;

  /// "YYYY-MM-DD" 키 (그룹 키로 사용)
  DateTime get displayDateKey {
    final d = displayDate;
    return DateTime(d.year, d.month, d.day);
  }
}

// ─── EXIF 메타데이터 추출 ───

/// 사진 바이트에서 EXIF 메타데이터 추출.
/// 추출 실패 시 빈 Map 반환 (앱 죽지 않음).
Future<Map<String, dynamic>> extractPhotoMetadata(Uint8List bytes) async {
  final result = <String, dynamic>{};

  try {
    final tags = await readExifFromBytes(bytes);
    if (tags.isEmpty) return result;

    // 이미지 크기
    final widthTag = tags['EXIF ExifImageWidth']
        ?? tags['Image ImageWidth']
        ?? tags['EXIF PixelXDimension'];
    final heightTag = tags['EXIF ExifImageLength']
        ?? tags['Image ImageLength']
        ?? tags['EXIF PixelYDimension'];

    final widthValue = widthTag?.values.toList();
    final heightValue = heightTag?.values.toList();

    if (widthValue != null && widthValue.isNotEmpty) {
      final w = widthValue.first;
      if (w is int && w > 0) result['width'] = w;
    }
    if (heightValue != null && heightValue.isNotEmpty) {
      final h = heightValue.first;
      if (h is int && h > 0) result['height'] = h;
    }

    // 촬영일 (DateTimeOriginal 우선)
    final dateTag = tags['EXIF DateTimeOriginal']
        ?? tags['Image DateTime']
        ?? tags['EXIF DateTimeDigitized'];

    if (dateTag != null) {
      final parsed = _parseExifDateTime(dateTag.printable);
      if (parsed != null) result['takenAt'] = parsed;
    }
  } catch (e) {
    debugPrint('[PhotoService] EXIF extraction failed: $e');
  }

  return result;
}

/// EXIF 날짜 문자열 파싱 ("YYYY:MM:DD HH:MM:SS")
DateTime? _parseExifDateTime(String exifString) {
  try {
    if (exifString.length < 19) return null;
    // "2026:05:11 14:30:45" → "2026-05-11 14:30:45"
    final normalized = exifString
        .replaceFirst(':', '-')
        .replaceFirst(':', '-');
    return DateTime.tryParse(normalized);
  } catch (_) {
    return null;
  }
}

// ─── PhotoService ───

class PhotoService {
  final String coupleId;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  String get _myUid => FirebaseAuth.instance.currentUser?.uid ?? 'me';

  PhotoService(this.coupleId);

  CollectionReference<Map<String, dynamic>> get _itemsCol =>
      _db.collection('couples').doc(coupleId).collection('items');

  // ─── 조회 ───

  Stream<List<PhotoItem>> recentPhotos({int limit = 500}) {
    return _itemsCol
        .where('type', isEqualTo: 'photo')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) {
      return snap.docs
          .map(PhotoItem.fromDoc)
          .where((p) => p.deletedAt == null)
          .toList();
    });
  }

  Stream<List<PhotoItem>> photosForDate(String dateKey) {
    return _itemsCol
        .where('date', isEqualTo: dateKey)
        .snapshots()
        .map((snap) => snap.docs
            .map(PhotoItem.fromDoc)
            .where((p) => p.deletedAt == null && p.storagePath.isNotEmpty)
            .toList());
  }

  // ─── 업로드 ───

  Future<List<PhotoItem>> pickAndUpload({
    void Function(int done, int total)? onProgress,
  }) async {
    const imageTypeGroup = XTypeGroup(
      label: 'images',
      extensions: ['jpg', 'jpeg', 'png', 'webp', 'heic'],
      mimeTypes: ['image/jpeg', 'image/png', 'image/webp', 'image/heic'],
    );

    final files = await openFiles(acceptedTypeGroups: [imageTypeGroup]);
    if (files.isEmpty) return [];

    final results = <PhotoItem>[];
    for (int i = 0; i < files.length; i++) {
      final file = files[i];
      try {
        final bytes = await file.readAsBytes();
        if (bytes.isEmpty) continue;
        final item = await _uploadOne(bytes, file.name);
        results.add(item);
        onProgress?.call(i + 1, files.length);
      } catch (e) {
        debugPrint('[PhotoService] upload failed: $e');
      }
    }
    return results;
  }

  Future<PhotoItem> _uploadOne(Uint8List bytes, String fileName) async {
    final now = DateTime.now();
    final dateKey =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final photoId = const Uuid().v4();

    // 확장자 추출
    final dotIdx = fileName.lastIndexOf('.');
    String ext = 'jpg';
    if (dotIdx > 0) {
      final candidate = fileName.substring(dotIdx + 1).toLowerCase();
      if (RegExp(r'^[a-z0-9]{2,5}$').hasMatch(candidate)) {
        ext = candidate;
      }
    }

    final storagePath = 'couples/$coupleId/photos/original/$photoId.$ext';

    // 1. Firestore 사전 문서
    final docRef = _itemsCol.doc(photoId);
    await docRef.set({
      'type': 'photo',
      'date': dateKey,
      'createdAt': Timestamp.fromDate(now),
      'createdBy': _myUid,
      'deletedAt': null,
      'payload': {
        'uploading': true,
        'uploadedAt': Timestamp.fromDate(now),
        'mimeType': _mimeForExt(ext),
        'byteSize': bytes.length,
      },
    });

    // 2. Storage 업로드 + EXIF 추출 병렬
    final storageRef = _storage.ref(storagePath);
    final uploadFuture = storageRef.putData(
      bytes,
      SettableMetadata(
        contentType: _mimeForExt(ext),
        customMetadata: {
          'uploadedBy': _myUid,
          'coupleId': coupleId,
          'photoId': photoId,
        },
      ),
    );
    final metadataFuture = extractPhotoMetadata(bytes);
    final task = await uploadFuture;
    final metadata = await metadataFuture;

    debugPrint('[PhotoService] EXIF metadata: '
        'w=${metadata['width']}, h=${metadata['height']}, '
        'taken=${metadata['takenAt']}');

    // 3. Firestore 업데이트 — 메타데이터 합치기
    final updateData = <String, dynamic>{
      'payload.uploading': false,
      'payload.storagePath': storagePath,
      'payload.byteSize': task.totalBytes,
    };
    if (metadata['width'] != null) {
      updateData['payload.width'] = metadata['width'];
    }
    if (metadata['height'] != null) {
      updateData['payload.height'] = metadata['height'];
    }
    if (metadata['takenAt'] != null) {
      updateData['payload.takenAt'] =
          Timestamp.fromDate(metadata['takenAt'] as DateTime);
    }
    await docRef.update(updateData);

    debugPrint('[PhotoService] uploaded: $storagePath (${task.totalBytes} bytes)');

    return PhotoItem(
      id: photoId,
      storagePath: storagePath,
      mimeType: _mimeForExt(ext),
      width: metadata['width'] as int?,
      height: metadata['height'] as int?,
      takenAt: metadata['takenAt'] as DateTime?,
      uploadedAt: now,
      byteSize: task.totalBytes,
      date: dateKey,
    );
  }

  String _mimeForExt(String ext) => switch (ext) {
        'jpg' || 'jpeg' => 'image/jpeg',
        'png' => 'image/png',
        'heic' => 'image/heic',
        'webp' => 'image/webp',
        _ => 'image/jpeg',
      };

  // ─── URL ───

  Future<String> thumbnailUrl(PhotoItem photo, {int size = 400}) async {
    try {
      return await _storage.ref(photo.thumbnailPath(size)).getDownloadURL();
    } catch (_) {
      return await _storage.ref(photo.storagePath).getDownloadURL();
    }
  }

  Future<String> originalUrl(PhotoItem photo) async {
    return await _storage.ref(photo.storagePath).getDownloadURL();
  }

  // ─── 삭제 ───

  Future<void> moveToTrash(String photoId) async {
    await _itemsCol.doc(photoId).update({
      'deletedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  Future<void> restoreFromTrash(String photoId) async {
    await _itemsCol.doc(photoId).update({'deletedAt': null});
  }

  Future<void> permanentlyDelete(String photoId) async {
    final doc = await _itemsCol.doc(photoId).get();
    if (doc.data() == null) return;
    final photo = PhotoItem.fromDoc(doc);
    if (photo.storagePath.isNotEmpty) {
      await Future.wait([
        _storage.ref(photo.storagePath).delete().catchError((_) {}),
        _storage.ref(photo.thumbnailPath(400)).delete().catchError((_) {}),
        _storage.ref(photo.thumbnailPath(800)).delete().catchError((_) {}),
      ]);
    }
    await _itemsCol.doc(photoId).delete();
  }
}
