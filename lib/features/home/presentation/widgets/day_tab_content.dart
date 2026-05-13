import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/services/google_calendar_service.dart';
import '../../../../shared/models/item_model.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/photo_detail_dialog.dart';
import '../../../../shared/widgets/photo_thumbnail.dart';
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

class _GoogleEventCard extends ConsumerWidget {
  final CalendarEvent event;
  const _GoogleEventCard({required this.event});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final googleColor = ref.watch(googleEventColorProvider);
    final timeText = event.isAllDay
        ? (S.isKo ? '종일' : 'All day')
        : '${DateFormat('HH:mm').format(event.startTime)}'
            ' - ${DateFormat('HH:mm').format(event.endTime)}';

    return Card(
      color: googleColor.withValues(alpha: 0.08),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Icon(Icons.event_outlined,
                size: 20, color: googleColor),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(event.title,
                      style: Theme.of(context).textTheme.bodyMedium
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
                color: googleColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text('Google',
                  style: TextStyle(
                      fontSize: 10, color: googleColor)),
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
              onTap: () =>
                  showPhotoDetailDialog(context, photoService, photo),
              child: PhotoThumbnail(
                  photo: photo, photoService: photoService),
            );
          },
        );
      },
    );
  }
}
