import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/services/photo_service.dart';
import '../../../home/presentation/providers/photo_providers.dart';

class AlbumPage extends ConsumerWidget {
  const AlbumPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final photosAsync = ref.watch(allPhotosProvider);
    final photoService = ref.read(photoServiceProvider);

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
                // 업로드 버튼
                IconButton(
                  icon: const Icon(Icons.add_photo_alternate_outlined),
                  onPressed: () => _uploadPhotos(context, ref),
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
                child: Text('${S.error}: $e',
                    style: const TextStyle(color: Colors.grey)),
              ),
              data: (photos) {
                if (photos.isEmpty) {
                  return _EmptyAlbum(onUpload: () => _uploadPhotos(context, ref));
                }
                return _PhotoGrid(
                  photos: photos,
                  photoService: photoService,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _uploadPhotos(BuildContext context, WidgetRef ref) async {
    try {
      final service = ref.read(photoServiceProvider);
      debugPrint('[Album] starting pickAndUpload...');
      final results = await service.pickAndUpload(
        onProgress: (done, total) {
          debugPrint('[Album] uploading $done/$total');
        },
      );
      debugPrint('[Album] upload done: ${results.length} photos');
      if (results.isNotEmpty && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(S.isKo
                ? '${results.length}장 업로드 완료'
                : '${results.length} photos uploaded'),
          ),
        );
      }
    } catch (e) {
      debugPrint('[Album] upload error: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload error: $e')),
        );
      }
    }
  }
}

class _EmptyAlbum extends StatelessWidget {
  final VoidCallback onUpload;
  const _EmptyAlbum({required this.onUpload});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.photo_library_outlined,
              size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(S.albumEmpty,
              style: const TextStyle(color: Colors.grey, fontSize: 16)),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onUpload,
            icon: const Icon(Icons.add_photo_alternate),
            label: Text(S.isKo ? '사진 추가' : 'Add Photos'),
          ),
        ],
      ),
    );
  }
}

class _PhotoGrid extends StatelessWidget {
  final List<PhotoItem> photos;
  final PhotoService photoService;

  const _PhotoGrid({required this.photos, required this.photoService});

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
          onTap: () => _showDetail(context, photo),
          onLongPress: () => _showActions(context, photo),
          child: _PhotoThumb(photo: photo, photoService: photoService),
        );
      },
    );
  }

  void _showDetail(BuildContext context, PhotoItem photo) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FutureBuilder<String>(
              future: photoService.originalUrl(photo),
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
            if (photo.caption != null)
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text(photo.caption!),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Text(photo.date,
                  style:
                      const TextStyle(color: Colors.grey, fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }

  void _showActions(BuildContext context, PhotoItem photo) {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading:
                  const Icon(Icons.delete_outline, color: Colors.red),
              title: Text(S.delete,
                  style: const TextStyle(color: Colors.red)),
              onTap: () {
                photoService.moveToTrash(photo.id);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _PhotoThumb extends StatelessWidget {
  final PhotoItem photo;
  final PhotoService photoService;

  const _PhotoThumb({required this.photo, required this.photoService});

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
