import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/drive_service.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

final driveServiceProvider = Provider<DriveService>((ref) => DriveService());

/// Drive 사진 전체 목록 (앨범용)
final drivePhotosProvider = FutureProvider<List<DrivePhoto>>((ref) async {
  final authService = ref.read(authServiceProvider);
  final headers = await authService.getAuthHeaders();
  debugPrint('[DriveProvider] headers=${headers != null}');
  if (headers == null) return [];

  final service = ref.read(driveServiceProvider);
  final photos = await service.listPhotosRecursive(
    authHeaders: headers,
    folderId: DriveService.defaultFolderId,
  );
  debugPrint('[DriveProvider] loaded ${photos.length} photos');
  return photos;
});

/// 특정 날짜의 Drive 사진
final drivePhotosByDateProvider =
    Provider.family<List<DrivePhoto>, String>((ref, dateKey) {
  final photosAsync = ref.watch(drivePhotosProvider);
  final photos = photosAsync.valueOrNull ?? [];
  return photos.where((p) => p.date == dateKey).toList();
});
