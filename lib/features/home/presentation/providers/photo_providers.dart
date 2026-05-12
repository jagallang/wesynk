import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/photo_service.dart';
import 'home_providers.dart';

/// PhotoService provider
final photoServiceProvider = Provider<PhotoService>((ref) {
  final coupleId = ref.watch(coupleIdProvider);
  return PhotoService(coupleId);
});

/// 전체 사진 스트림 (앨범용) — createdAt 내림차순 정렬
final allPhotosProvider = StreamProvider<List<PhotoItem>>((ref) {
  final service = ref.watch(photoServiceProvider);
  return service.recentPhotos(limit: 500);
});

/// 특정 날짜의 사진 스트림 (캘린더 사진탭용)
final photosByDateProvider =
    StreamProvider.family<List<PhotoItem>, String>((ref, dateKey) {
  final service = ref.watch(photoServiceProvider);
  return service.photosForDate(dateKey);
});
