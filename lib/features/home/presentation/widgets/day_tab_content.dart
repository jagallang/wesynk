import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/services/drive_service.dart';
import '../../../../shared/models/item_model.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/drive_providers.dart';
import '../providers/home_providers.dart';
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

    // 사진 탭이면 Drive 사진도 함께 표시
    if (type == ItemType.photo) {
      return _PhotoTabContent(dateKey: dateKey, itemsAsync: itemsAsync);
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
  final AsyncValue<List<Item>> itemsAsync;

  const _PhotoTabContent({required this.dateKey, required this.itemsAsync});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final drivePhotos = ref.watch(drivePhotosByDateProvider(dateKey));

    final firestoreItems = itemsAsync.valueOrNull ?? [];
    final hasPhotos = drivePhotos.isNotEmpty || firestoreItems.isNotEmpty;

    if (!hasPhotos) return const EmptyState(type: ItemType.photo);

    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
      ),
      itemCount: drivePhotos.length,
      itemBuilder: (context, i) {
        final photo = drivePhotos[i];
        return GestureDetector(
          onTap: () => _showDetail(context, ref, photo),
          child: _DriveThumb(photo: photo, ref: ref),
        );
      },
    );
  }

  void _showDetail(BuildContext context, WidgetRef ref, DrivePhoto photo) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FutureBuilder<Map<String, String>?>(
              future: ref.read(authServiceProvider).getAuthHeaders(),
              builder: (context, snap) {
                if (!snap.hasData || snap.data == null) {
                  return const SizedBox(
                      height: 300,
                      child: Center(child: CircularProgressIndicator()));
                }
                return Image.network(
                  photo.thumbnailUrl(size: 800),
                  headers: snap.data!,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const SizedBox(
                      height: 200, child: Icon(Icons.broken_image)),
                );
              },
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(photo.name,
                  style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ),
          ],
        ),
      ),
    );
  }
}

class _DriveThumb extends StatelessWidget {
  final DrivePhoto photo;
  final WidgetRef ref;

  const _DriveThumb({required this.photo, required this.ref});

  @override
  Widget build(BuildContext context) {
    if (photo.thumbnailLink == null) {
      return Container(
          color: Colors.grey.shade200, child: const Icon(Icons.photo));
    }
    return FutureBuilder<Map<String, String>?>(
      future: ref.read(authServiceProvider).getAuthHeaders(),
      builder: (context, snap) {
        if (!snap.hasData || snap.data == null) {
          return Container(color: Colors.grey.shade200);
        }
        return Image.network(
          photo.thumbnailUrl(size: 300),
          headers: snap.data!,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
              color: Colors.grey.shade200,
              child: const Icon(Icons.broken_image)),
        );
      },
    );
  }
}
