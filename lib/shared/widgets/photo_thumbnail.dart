import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../core/services/photo_service.dart';

/// 사진/영상 썸네일 위젯 (앨범 + 캘린더 사진탭 공용)
class PhotoThumbnail extends StatefulWidget {
  final PhotoItem photo;
  final PhotoService photoService;
  final int size;

  const PhotoThumbnail({
    super.key,
    required this.photo,
    required this.photoService,
    this.size = 400,
  });

  @override
  State<PhotoThumbnail> createState() => _PhotoThumbnailState();
}

class _PhotoThumbnailState extends State<PhotoThumbnail> {
  late Future<String> _urlFuture;

  @override
  void initState() {
    super.initState();
    _urlFuture =
        widget.photoService.thumbnailUrl(widget.photo, size: widget.size);
  }

  @override
  void didUpdateWidget(PhotoThumbnail old) {
    super.didUpdateWidget(old);
    if (old.photo.id != widget.photo.id) {
      _urlFuture =
          widget.photoService.thumbnailUrl(widget.photo, size: widget.size);
    }
  }

  @override
  Widget build(BuildContext context) {
    // 업로드 중
    if (widget.photo.uploading) {
      return Container(
        color: Colors.grey.shade200,
        child: const Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    // 영상인데 썸네일 미생성
    if (widget.photo.isVideo && !widget.photo.thumbnailReady) {
      return Container(
        color: Colors.grey.shade800,
        child: const Center(
          child: Icon(Icons.videocam, size: 32, color: Colors.white54),
        ),
      );
    }

    return FutureBuilder<String>(
      future: _urlFuture,
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
            child: const Icon(Icons.broken_image),
          ),
        );
      },
    );
  }
}
