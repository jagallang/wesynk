import 'dart:typed_data';
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
              error: (e, _) => _ErrorView(error: '$e', ref: ref),
              data: (photos) {
                if (photos.isEmpty) {
                  return _EmptyOrConnect(ref: ref);
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

/// 사진이 없을 때: 토큰 없으면 연결 버튼, 있으면 빈 상태
class _EmptyOrConnect extends StatelessWidget {
  final WidgetRef ref;
  const _EmptyOrConnect({required this.ref});

  @override
  Widget build(BuildContext context) {
    final hasToken = ref.read(authServiceProvider).accessToken != null;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            hasToken ? Icons.photo_library_outlined : Icons.cloud_outlined,
            size: 64,
            color: hasToken ? Colors.grey : Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text(
            hasToken
                ? S.albumEmpty
                : (S.isKo ? 'Google Drive 연결 필요' : 'Connect Google Drive'),
            style: const TextStyle(fontSize: 16),
          ),
          if (!hasToken) ...[
            const SizedBox(height: 8),
            Text(
              S.isKo
                  ? '사진을 보려면 Drive 접근 권한이 필요합니다'
                  : 'Drive access is needed to view photos',
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ],
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () async {
              if (!hasToken) {
                await ref.read(authServiceProvider).signInWithGoogle();
              }
              ref.invalidate(drivePhotosProvider);
            },
            icon: Icon(hasToken ? Icons.refresh : Icons.login),
            label: Text(hasToken
                ? (S.isKo ? '새로고침' : 'Refresh')
                : (S.isKo ? 'Drive 연결하기' : 'Connect Drive')),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String error;
  final WidgetRef ref;
  const _ErrorView({required this.error, required this.ref});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.grey),
          const SizedBox(height: 12),
          Text('${S.error}: $error',
              style: const TextStyle(color: Colors.grey),
              textAlign: TextAlign.center),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () => ref.invalidate(drivePhotosProvider),
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
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
          onTap: () => _showDetail(context, photo),
          child: _Thumb(photo: photo, ref: ref),
        );
      },
    );
  }

  void _showDetail(BuildContext context, DrivePhoto photo) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FutureBuilder<Uint8List?>(
              future: () async {
                final headers =
                    await ref.read(authServiceProvider).getAuthHeaders();
                if (headers == null) return null;
                return DrivePhoto.downloadImage(photo.id, headers);
              }(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const SizedBox(
                      height: 300,
                      child: Center(child: CircularProgressIndicator()));
                }
                if (snap.data == null) {
                  return const SizedBox(
                      height: 200, child: Icon(Icons.broken_image));
                }
                return Image.memory(snap.data!, fit: BoxFit.contain);
              },
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Text(photo.name,
                      style: const TextStyle(fontWeight: FontWeight.w500)),
                  Text(photo.date,
                      style:
                          const TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  final DrivePhoto photo;
  final WidgetRef ref;
  const _Thumb({required this.photo, required this.ref});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List?>(
      future: _loadImage(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return Container(
            color: Colors.grey.shade200,
            child: const Center(
                child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2))),
          );
        }
        if (snap.data == null) {
          return Container(
              color: Colors.grey.shade200,
              child: const Icon(Icons.broken_image));
        }
        return Image.memory(snap.data!, fit: BoxFit.cover);
      },
    );
  }

  Future<Uint8List?> _loadImage() async {
    final headers = await ref.read(authServiceProvider).getAuthHeaders();
    if (headers == null) return null;
    return DrivePhoto.downloadImage(photo.id, headers);
  }
}
