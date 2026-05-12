import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
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

  /// 썸네일 경로 (extension 자동 생성 경로와 매칭)
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

// ─── PhotoService ───

class PhotoService {
  final String coupleId;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();

  String get _myUid =>
      FirebaseAuth.instance.currentUser?.uid ?? 'me';

  PhotoService(this.coupleId);

  CollectionReference<Map<String, dynamic>> get _itemsCol =>
      _db.collection('couples').doc(coupleId).collection('items');

  // ─── 조회 ───

  /// 전체 사진 (앨범용) — 단순 쿼리 + 클라이언트 정렬
  Stream<List<PhotoItem>> recentPhotos({int limit = 100}) {
    return _itemsCol
        .where('type', isEqualTo: 'photo')
        .snapshots()
        .map((snap) {
      final items = snap.docs
          .map(PhotoItem.fromDoc)
          .where((p) => p.deletedAt == null)
          .toList()
        ..sort((a, b) => b.uploadedAt.compareTo(a.uploadedAt));
      return items.take(limit).toList();
    });
  }

  /// 특정 날짜의 사진 (캘린더 사진탭용)
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

  /// 갤러리 picker → 다중 선택 → 업로드
  Future<List<PhotoItem>> pickAndUpload({
    void Function(int done, int total)? onProgress,
  }) async {
    final picked = await _picker.pickMultiImage(
      maxWidth: 4096,
      maxHeight: 4096,
      imageQuality: 90,
    );
    if (picked.isEmpty) return [];

    final results = <PhotoItem>[];
    for (int i = 0; i < picked.length; i++) {
      try {
        final item = await _uploadOne(picked[i]);
        results.add(item);
        onProgress?.call(i + 1, picked.length);
      } catch (e) {
        debugPrint('[PhotoService] upload failed: $e');
      }
    }
    return results;
  }

  Future<PhotoItem> _uploadOne(XFile xfile) async {
    final now = DateTime.now();
    final dateKey =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final photoId = const Uuid().v4();
    // 웹: xfile.path가 blob URL이라 확장자 추출 불가 → 무조건 jpg
    const ext = 'jpg';
    final storagePath =
        'couples/$coupleId/photos/original/$photoId.$ext';

    // 바이트 읽기 (웹 호환)
    final bytes = await xfile.readAsBytes();

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

    // 2. Storage 업로드 (putData — 웹/모바일 모두 호환)
    final ref = _storage.ref(storagePath);
    final task = await ref.putData(
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

    // 3. Firestore 업데이트
    await docRef.update({
      'payload.uploading': false,
      'payload.storagePath': storagePath,
      'payload.byteSize': task.totalBytes,
    });

    debugPrint('[PhotoService] uploaded: $storagePath (${task.totalBytes} bytes)');

    return PhotoItem(
      id: photoId,
      storagePath: storagePath,
      mimeType: _mimeForExt(ext),
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

  /// 썸네일 URL (그리드: 400, 상세: 800)
  Future<String> thumbnailUrl(PhotoItem photo, {int size = 400}) async {
    try {
      return await _storage.ref(photo.thumbnailPath(size)).getDownloadURL();
    } catch (_) {
      // 썸네일 아직 생성 안 됨 → 원본 fallback
      return await _storage.ref(photo.storagePath).getDownloadURL();
    }
  }

  /// 원본 URL
  Future<String> originalUrl(PhotoItem photo) async {
    return await _storage.ref(photo.storagePath).getDownloadURL();
  }

  // ─── 삭제 ───

  /// 휴지통 (soft delete)
  Future<void> moveToTrash(String photoId) async {
    await _itemsCol.doc(photoId).update({
      'deletedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  /// 복원
  Future<void> restoreFromTrash(String photoId) async {
    await _itemsCol.doc(photoId).update({
      'deletedAt': null,
    });
  }

  /// 영구 삭제
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
