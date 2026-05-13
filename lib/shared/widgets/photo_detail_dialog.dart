import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../core/services/photo_service.dart';

/// 사진 상세 다이얼로그 (앨범 + 캘린더 사진탭 공용)
void showPhotoDetailDialog(
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
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              return CachedNetworkImage(
                imageUrl: snap.data!,
                fit: BoxFit.contain,
                placeholder: (_, __) => const SizedBox(
                  height: 300,
                  child: Center(child: CircularProgressIndicator()),
                ),
                errorWidget: (_, __, ___) => const SizedBox(
                  height: 200,
                  child: Icon(Icons.broken_image),
                ),
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
            child: Text(
              photo.date,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ),
        ],
      ),
    ),
  );
}
