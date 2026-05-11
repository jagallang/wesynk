import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/services/drive_service.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../home/presentation/providers/drive_providers.dart';

class AlbumPage extends ConsumerWidget {
  const AlbumPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final photosAsync = ref.watch(drivePhotosProvider);

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: Row(
              children: [
                Text(S.albumTitle,
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () => ref.invalidate(drivePhotosProvider),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: photosAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline,
                        size: 48, color: Colors.grey),
                    const SizedBox(height: 12),
                    Text('${S.error}: $e',
                        style: const TextStyle(color: Colors.grey)),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: () =>
                          ref.invalidate(drivePhotosProvider),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              ),
              data: (photos) {
                if (photos.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.photo_library_outlined,
                            size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        Text(S.albumEmpty,
                            style: const TextStyle(
                                color: Colors.grey, fontSize: 16)),
                      ],
                    ),
                  );
                }

                return _PhotoGrid(photos: photos, ref: ref);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _PhotoGrid extends StatelessWidget {
  final List<DrivePhoto> photos;
  final WidgetRef ref;

  const _PhotoGrid({required this.photos, required this.ref});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(4),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
      ),
      itemCount: photos.length,
      itemBuilder: (context, i) {
        final photo = photos[i];
        return GestureDetector(
          onTap: () => _showPhotoDetail(context, photo),
          child: _PhotoThumbnail(photo: photo, ref: ref),
        );
      },
    );
  }

  void _showPhotoDetail(BuildContext context, DrivePhoto photo) {
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
                  errorBuilder: (_, e, __) =>
                      const SizedBox(height: 200, child: Icon(Icons.broken_image)),
                );
              },
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Text(photo.name,
                      style: const TextStyle(fontWeight: FontWeight.w500)),
                  Text(photo.date,
                      style: const TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PhotoThumbnail extends StatelessWidget {
  final DrivePhoto photo;
  final WidgetRef ref;

  const _PhotoThumbnail({required this.photo, required this.ref});

  @override
  Widget build(BuildContext context) {
    if (photo.thumbnailLink != null) {
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
              child: const Icon(Icons.broken_image),
            ),
          );
        },
      );
    }
    return Container(
      color: Colors.grey.shade200,
      child: const Icon(Icons.photo),
    );
  }
}
