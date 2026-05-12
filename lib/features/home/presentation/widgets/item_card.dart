import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/services/firestore_service.dart';
import '../../../../shared/models/item_model.dart';
import '../providers/home_providers.dart';

class ItemCard extends ConsumerWidget {
  final Item item;
  const ItemCard({super.key, required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final service = ref.read(firestoreServiceProvider);
    final coupleId = FirestoreService.defaultCoupleId;
    final payload = item.payload;
    final theme = Theme.of(context);

    final eventColor = item.createdBy == 'me'
        ? ref.watch(myEventColorProvider)
        : ref.watch(partnerEventColorProvider);

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onLongPress: () => _showActions(context, ref),
        child: Row(
          children: [
            // 색상 인디케이터
            Container(
              width: 4,
              height: 40,
              margin: const EdgeInsets.only(left: 4),
              decoration: BoxDecoration(
                color: eventColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // 체크박스
            Checkbox(
              value: item.checked,
              onChanged: (v) {
                service.toggleChecked(
                  coupleId: coupleId,
                  itemId: item.id,
                  checked: v ?? false,
                );
              },
            ),

            // 컨텐츠
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: _buildContent(payload, theme),
              ),
            ),

            // 더보기 버튼
            IconButton(
              icon: const Icon(Icons.more_vert, size: 20),
              onPressed: () => _showActions(context, ref),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(Map<String, dynamic> payload, ThemeData theme) {
    final titleStyle = item.checked
        ? TextStyle(
            decoration: TextDecoration.lineThrough,
            color: Colors.grey,
          )
        : null;
    final subtitleStyle = item.checked
        ? const TextStyle(color: Colors.grey, fontSize: 12)
        : const TextStyle(fontSize: 12);

    return switch (item.type) {
      ItemType.event => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(payload['title']?.toString() ?? '', style: titleStyle),
            if ((payload['location']?.toString() ?? '').isNotEmpty)
              Text(payload['location'].toString(), style: subtitleStyle),
          ],
        ),
      ItemType.note => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(payload['mood']?.toString() ?? '📝',
                    style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    (payload['body']?.toString() ?? '').split('\n').first,
                    style: titleStyle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            if ((payload['body']?.toString() ?? '').contains('\n'))
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  payload['body']?.toString() ?? '',
                  style: titleStyle?.copyWith(fontSize: 13) ??
                      const TextStyle(fontSize: 13),
                  maxLines: 5,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
        ),
      ItemType.photo => Text(
          payload['caption']?.toString() ?? '',
          style: titleStyle,
        ),
      ItemType.date => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(payload['title']?.toString() ?? '', style: titleStyle),
            Text(
              '${(payload['place'] as Map?)?['name'] ?? ''} '
              '${'★' * ((payload['rating'] as int?) ?? 0)}',
              style: subtitleStyle,
            ),
          ],
        ),
    };
  }

  void _showActions(BuildContext context, WidgetRef ref) {
    final service = ref.read(firestoreServiceProvider);
    final coupleId = FirestoreService.defaultCoupleId;

    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 수정
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: Text(S.isKo ? '수정' : 'Edit'),
              onTap: () {
                Navigator.pop(context);
                _showEditForm(context, ref);
              },
            ),
            // 체크 토글
            ListTile(
              leading: Icon(item.checked
                  ? Icons.check_box
                  : Icons.check_box_outline_blank),
              title: Text(item.checked
                  ? (S.isKo ? '완료 해제' : 'Uncheck')
                  : (S.isKo ? '완료 체크' : 'Check')),
              onTap: () {
                service.toggleChecked(
                  coupleId: coupleId,
                  itemId: item.id,
                  checked: !item.checked,
                );
                Navigator.pop(context);
              },
            ),
            const Divider(height: 1),
            // 삭제
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: Text(S.delete,
                  style: const TextStyle(color: Colors.red)),
              onTap: () {
                service.deleteItem(coupleId: coupleId, itemId: item.id);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showEditForm(BuildContext context, WidgetRef ref) {
    final service = ref.read(firestoreServiceProvider);
    final coupleId = FirestoreService.defaultCoupleId;
    final payload = Map<String, dynamic>.from(item.payload);

    switch (item.type) {
      case ItemType.event:
        _showEventEdit(context, service, coupleId, payload);
      case ItemType.note:
        _showNoteEdit(context, service, coupleId, payload);
      case ItemType.date:
        _showDateEdit(context, service, coupleId, payload);
      case ItemType.photo:
        break;
    }
  }

  void _showEventEdit(BuildContext context, FirestoreService service,
      String coupleId, Map<String, dynamic> payload) {
    final titleCtrl =
        TextEditingController(text: payload['title']?.toString() ?? '');
    final locationCtrl =
        TextEditingController(text: payload['location']?.toString() ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
            24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(S.isKo ? '수정' : 'Edit',
                style: Theme.of(ctx).textTheme.titleMedium),
            const SizedBox(height: 16),
            TextField(
              controller: titleCtrl,
              decoration: InputDecoration(
                  labelText: S.fieldTitle,
                  border: const OutlineInputBorder()),
              autofocus: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: locationCtrl,
              decoration: InputDecoration(
                  labelText: S.fieldLocation,
                  border: const OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () {
                if (titleCtrl.text.trim().isEmpty) return;
                payload['title'] = titleCtrl.text.trim();
                payload['location'] = locationCtrl.text.trim();
                service.updateItem(
                    coupleId: coupleId, itemId: item.id, payload: payload);
                Navigator.pop(ctx);
              },
              child: Text(S.change),
            ),
          ],
        ),
      ),
    );
  }

  void _showNoteEdit(BuildContext context, FirestoreService service,
      String coupleId, Map<String, dynamic> payload) {
    final bodyCtrl =
        TextEditingController(text: payload['body']?.toString() ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
            24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(S.isKo ? '수정' : 'Edit',
                style: Theme.of(ctx).textTheme.titleMedium),
            const SizedBox(height: 16),
            TextField(
              controller: bodyCtrl,
              decoration: InputDecoration(
                  hintText: S.noteHint,
                  border: const OutlineInputBorder()),
              maxLines: null,
              minLines: 6,
              keyboardType: TextInputType.multiline,
              autofocus: true,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () {
                if (bodyCtrl.text.trim().isEmpty) return;
                payload['body'] = bodyCtrl.text.trim();
                service.updateItem(
                    coupleId: coupleId, itemId: item.id, payload: payload);
                Navigator.pop(ctx);
              },
              child: Text(S.change),
            ),
          ],
        ),
      ),
    );
  }

  void _showDateEdit(BuildContext context, FirestoreService service,
      String coupleId, Map<String, dynamic> payload) {
    final titleCtrl =
        TextEditingController(text: payload['title']?.toString() ?? '');
    final placeCtrl = TextEditingController(
        text: (payload['place'] as Map?)?['name']?.toString() ?? '');
    final reviewCtrl =
        TextEditingController(text: payload['review']?.toString() ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          int rating = (payload['rating'] as int?) ?? 3;
          return Padding(
            padding: EdgeInsets.fromLTRB(
                24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(S.isKo ? '수정' : 'Edit',
                    style: Theme.of(ctx).textTheme.titleMedium),
                const SizedBox(height: 16),
                TextField(
                  controller: titleCtrl,
                  decoration: InputDecoration(
                      labelText: S.fieldTitle,
                      border: const OutlineInputBorder()),
                  autofocus: true,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: placeCtrl,
                  decoration: InputDecoration(
                      labelText: S.fieldPlace,
                      border: const OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text(S.fieldRating),
                    ...List.generate(5, (i) => IconButton(
                      icon: Icon(
                          i < rating ? Icons.star : Icons.star_border,
                          color: Colors.amber),
                      onPressed: () =>
                          setSheetState(() => rating = i + 1),
                    )),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: reviewCtrl,
                  decoration: InputDecoration(
                      hintText: S.fieldReview,
                      border: const OutlineInputBorder()),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () {
                    if (titleCtrl.text.trim().isEmpty) return;
                    payload['title'] = titleCtrl.text.trim();
                    payload['place'] = {'name': placeCtrl.text.trim()};
                    payload['rating'] = rating;
                    payload['review'] = reviewCtrl.text.trim();
                    service.updateItem(
                        coupleId: coupleId,
                        itemId: item.id,
                        payload: payload);
                    Navigator.pop(ctx);
                  },
                  child: Text(S.change),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
