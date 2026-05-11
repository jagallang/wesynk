import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class DrivePhoto {
  final String id;
  final String name;
  final String mimeType;
  final String? thumbnailLink;
  final DateTime? createdTime;
  final String date; // "YYYY-MM-DD" 파일명에서 추출

  DrivePhoto({
    required this.id,
    required this.name,
    required this.mimeType,
    this.thumbnailLink,
    this.createdTime,
    required this.date,
  });

  /// Drive 원본 이미지 URL (OAuth 헤더 필요)
  String get imageUrl =>
      'https://www.googleapis.com/drive/v3/files/$id?alt=media';

  /// 썸네일 URL (크기 조절 가능)
  String thumbnailUrl({int size = 400}) {
    if (thumbnailLink != null) {
      return thumbnailLink!.replaceAll('=s220', '=s$size');
    }
    return imageUrl;
  }

  /// 이미지 바이트 다운로드 (OAuth 인증)
  static Future<Uint8List?> downloadImage(
      String fileId, Map<String, String> authHeaders,
      {bool thumbnail = true, int size = 400}) async {
    String url;
    if (thumbnail) {
      url = 'https://www.googleapis.com/drive/v3/files/$fileId?alt=media';
    } else {
      url = 'https://www.googleapis.com/drive/v3/files/$fileId?alt=media';
    }
    try {
      final response = await http.get(Uri.parse(url), headers: authHeaders);
      if (response.statusCode == 200) return response.bodyBytes;
      debugPrint('[DrivePhoto] download error: ${response.statusCode}');
    } catch (e) {
      debugPrint('[DrivePhoto] download error: $e');
    }
    return null;
  }
}

class DriveService {
  static const defaultFolderId = '1BabG4hSPUNfmszgQ4eK6WGAt3T0GXk3K';

  /// 폴더 내 이미지 파일 목록 가져오기
  Future<List<DrivePhoto>> listPhotos({
    required Map<String, String> authHeaders,
    required String folderId,
    String? pageToken,
    int pageSize = 100,
  }) async {
    final query = "'$folderId' in parents and mimeType contains 'image/' and trashed = false";
    var url =
        'https://www.googleapis.com/drive/v3/files'
        '?q=${Uri.encodeComponent(query)}'
        '&fields=nextPageToken,files(id,name,mimeType,thumbnailLink,createdTime)'
        '&orderBy=createdTime desc'
        '&pageSize=$pageSize';
    if (pageToken != null) url += '&pageToken=$pageToken';

    final response = await http.get(Uri.parse(url), headers: authHeaders);

    if (response.statusCode != 200) {
      debugPrint('[DriveService] Error ${response.statusCode}: ${response.body}');
      return [];
    }

    final data = json.decode(response.body);
    final files = (data['files'] as List?) ?? [];

    return files.map<DrivePhoto>((f) {
      final name = f['name'] as String? ?? '';
      final createdTime = f['createdTime'] != null
          ? DateTime.tryParse(f['createdTime'] as String)
          : null;

      return DrivePhoto(
        id: f['id'] as String,
        name: name,
        mimeType: f['mimeType'] as String? ?? '',
        thumbnailLink: f['thumbnailLink'] as String?,
        createdTime: createdTime,
        date: _extractDate(name, createdTime),
      );
    }).toList();
  }

  /// 하위 폴더도 재귀 탐색
  Future<List<DrivePhoto>> listPhotosRecursive({
    required Map<String, String> authHeaders,
    required String folderId,
  }) async {
    final photos = <DrivePhoto>[];

    // 현재 폴더 사진
    photos.addAll(await listPhotos(
        authHeaders: authHeaders, folderId: folderId));

    // 하위 폴더 탐색
    final subFolders = await _listSubFolders(
        authHeaders: authHeaders, folderId: folderId);
    for (final sf in subFolders) {
      photos.addAll(await listPhotosRecursive(
          authHeaders: authHeaders, folderId: sf));
    }

    debugPrint('[DriveService] total ${photos.length} photos from $folderId');
    return photos;
  }

  Future<List<String>> _listSubFolders({
    required Map<String, String> authHeaders,
    required String folderId,
  }) async {
    final query =
        "'$folderId' in parents and mimeType = 'application/vnd.google-apps.folder' and trashed = false";
    final url =
        'https://www.googleapis.com/drive/v3/files'
        '?q=${Uri.encodeComponent(query)}'
        '&fields=files(id)';

    final response = await http.get(Uri.parse(url), headers: authHeaders);
    if (response.statusCode != 200) return [];

    final data = json.decode(response.body);
    final files = (data['files'] as List?) ?? [];
    return files.map<String>((f) => f['id'] as String).toList();
  }

  /// 파일명에서 날짜 추출. 실패 시 createdTime 사용.
  /// 지원 패턴: 2026-05-11, 20260511, IMG_20260511
  static String _extractDate(String fileName, DateTime? createdTime) {
    // 패턴 1: YYYY-MM-DD
    final r1 = RegExp(r'(\d{4})-(\d{2})-(\d{2})');
    final m1 = r1.firstMatch(fileName);
    if (m1 != null) return '${m1.group(1)}-${m1.group(2)}-${m1.group(3)}';

    // 패턴 2: YYYYMMDD
    final r2 = RegExp(r'(\d{4})(\d{2})(\d{2})');
    final m2 = r2.firstMatch(fileName);
    if (m2 != null) {
      final y = int.tryParse(m2.group(1)!) ?? 0;
      final mo = int.tryParse(m2.group(2)!) ?? 0;
      final d = int.tryParse(m2.group(3)!) ?? 0;
      if (y >= 2000 && y <= 2099 && mo >= 1 && mo <= 12 && d >= 1 && d <= 31) {
        return '${m2.group(1)}-${m2.group(2)}-${m2.group(3)}';
      }
    }

    // fallback: createdTime
    if (createdTime != null) {
      return '${createdTime.year}-${createdTime.month.toString().padLeft(2, '0')}-${createdTime.day.toString().padLeft(2, '0')}';
    }

    // 최후 fallback: 오늘
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }
}
