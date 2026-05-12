import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/services/photo_service.dart';
import '../../../../shared/models/item_model.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../providers/home_providers.dart';
import '../providers/photo_providers.dart';
import 'item_card.dart';

class DayTabContent extends ConsumerWidget {
  final ItemType type;
  const DayTabContent({super.key, required this.type});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateKey = ref.watch(selectedDateKeyProvider);
    final itemsAsync = ref.watch(
      itemsForDateAndTypeProvider((dateKey: dateKey, type: type)),
    );

    // 사진 탭이면 Firebase Storage 사진 표시
    if (type == ItemType.photo) {
      return _PhotoTabContent(dateKey: dateKey);
    }

    return itemsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('${S.error}: $e')),
      data: (items) {
        if (items.isEmpty) return EmptyState(type: type);
        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (_, i) => ItemCard(item: items[i]),
        );
      },
    );
  }
}

class _PhotoTabContent extends ConsumerWidget {
  final String dateKey;
  const _PhotoTabContent({required this.dateKey});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final photosAsync = ref.watch(photosByDateProvider(dateKey));
    final photoService = ref.read(photoServiceProvider);

    return photosAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('${S.error}: $e')),
      data: (photos) {
        if (photos.isEmpty) return const EmptyState(type: ItemType.photo);

        return GridView.builder(
          padding: const EdgeInsets.all(8),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 4,
            mainAxisSpacing: 4,
          ),
          itemCount: photos.length,
          itemBuilder: (context, i) {
            final photo = photos[i];
            return GestureDetector(
              onTap: () => _showDetail(context, photoService, photo),
              child: _StorageThumb(
                  photo: photo, photoService: photoService),
            );
          },
        );
      },
    );
  }

  void _showDetail(
      BuildContext context, PhotoService service, PhotoItem photo) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FutureBuilder<String>(
              future: service.originalUrl(photo),
              builder: (context, snap) {
                if (!snap.hasData) {
                  return const SizedBox(
                      height: 300,
                      child: Center(child: CircularProgressIndicator()));
                }
                return CachedNetworkImage(
                  imageUrl: snap.data!,
                  fit: BoxFit.contain,
                  placeholder: (_, __) => const SizedBox(
                      height: 300,
                      child: Center(child: CircularProgressIndicator())),
                  errorWidget: (_, __, ___) => const SizedBox(
                      height: 200, child: Icon(Icons.broken_image)),
                );
              },
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(photo.date,
                  style:
                      const TextStyle(fontSize: 12, color: Colors.grey)),
            ),
          ],
        ),
      ),
    );
  }
}

class _StorageThumb extends StatelessWidget {
  final PhotoItem photo;
  final PhotoService photoService;

  const _StorageThumb({required this.photo, required this.photoService});

  @override
  Widget build(BuildContext context) {
    if (photo.uploading) {
      return Container(
        color: Colors.grey.shade200,
        child: const Center(
            child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2))),
      );
    }

    return FutureBuilder<String>(
      future: photoService.thumbnailUrl(photo, size: 400),
      builder: (context, snap) {
        if (!snap.hasData) {
          return Container(color: Colors.grey.shade200);
        }
        return CachedNetworkImage(
          imageUrl: snap.data!,
          fit: BoxFit.cover,
          placeholder: (_, __) => Container(color: Colors.grey.shade200),
          errorWidget: (_, __, ___) => Container(
              color: Colors.grey.shade200,
              child: const Icon(Icons.broken_image)),
        );
      },
    );
  }
}
