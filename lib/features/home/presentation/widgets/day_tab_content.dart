import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/services/google_calendar_service.dart';
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

    // 일정 탭이면 Google Calendar 이벤트도 합침
    if (type == ItemType.event) {
      return _EventTabWithGoogle(dateKey: dateKey, itemsAsync: itemsAsync);
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

// ─── 일정 탭 + Google Calendar 합산 ───

class _EventTabWithGoogle extends ConsumerWidget {
  final String dateKey;
  final AsyncValue<List<Item>> itemsAsync;

  const _EventTabWithGoogle({
    required this.dateKey,
    required this.itemsAsync,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final googleAsync = ref.watch(googleEventsForDateProvider(dateKey));
    final googleEvents = googleAsync.valueOrNull ?? [];

    return itemsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('${S.error}: $e')),
      data: (items) {
        final totalCount = items.length + googleEvents.length;
        if (totalCount == 0) return const EmptyState(type: ItemType.event);

        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: totalCount,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (_, i) {
            // WeSync 일정 먼저, Google 일정 뒤에
            if (i < items.length) {
              return ItemCard(item: items[i]);
            }
            return _GoogleEventCard(
                event: googleEvents[i - items.length]);
          },
        );
      },
    );
  }
}

class _GoogleEventCard extends StatelessWidget {
  final CalendarEvent event;
  const _GoogleEventCard({required this.event});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final timeText = event.isAllDay
        ? (S.isKo ? '종일' : 'All day')
        : '${DateFormat('HH:mm').format(event.startTime)}'
            ' - ${DateFormat('HH:mm').format(event.endTime)}';

    return Card(
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Icon(Icons.event_outlined,
                size: 20, color: Colors.blue.shade400),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(event.title,
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w500)),
                  Text(timeText,
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey.shade600)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.blue.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text('Google',
                  style: TextStyle(
                      fontSize: 10, color: Colors.blue.shade700)),
            ),
          ],
        ),
      ),
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

class _StorageThumb extends StatefulWidget {
  final PhotoItem photo;
  final PhotoService photoService;

  const _StorageThumb({required this.photo, required this.photoService});

  @override
  State<_StorageThumb> createState() => _StorageThumbState();
}

class _StorageThumbState extends State<_StorageThumb> {
  late Future<String> _urlFuture;

  @override
  void initState() {
    super.initState();
    _urlFuture = widget.photoService.thumbnailUrl(widget.photo, size: 400);
  }

  @override
  void didUpdateWidget(_StorageThumb old) {
    super.didUpdateWidget(old);
    if (old.photo.id != widget.photo.id) {
      _urlFuture = widget.photoService.thumbnailUrl(widget.photo, size: 400);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.photo.uploading) {
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
              child: const Icon(Icons.broken_image)),
        );
      },
    );
  }
}
