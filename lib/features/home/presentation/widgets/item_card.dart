import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/services/firestore_service.dart';
import '../../../../shared/models/item_model.dart';
import '../providers/home_providers.dart';
import 'item_edit_sheets.dart';

class ItemCard extends ConsumerWidget {
  final Item item;
  const ItemCard({super.key, required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final service = ref.read(firestoreServiceProvider);
    final coupleId = ref.watch(coupleIdProvider);
    final payload = item.payload;
    final theme = Theme.of(context);

    final myUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final eventColor = item.createdBy == myUid
        ? ref.watch(myEventColorProvider)
        : ref.watch(partnerEventColorProvider);

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onLongPress: () => _showActions(context, ref),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 40,
              margin: const EdgeInsets.only(left: 4),
              decoration: BoxDecoration(
                color: eventColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
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
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: _buildContent(payload, theme),
              ),
            ),
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
    final coupleId = ref.read(coupleIdProvider);

    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: Text(S.isKo ? '수정' : 'Edit'),
              onTap: () {
                Navigator.pop(context);
                _showEditForm(context, service, coupleId);
              },
            ),
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

  void _showEditForm(
      BuildContext context, FirestoreService service, String coupleId) {
    final payload = Map<String, dynamic>.from(item.payload);

    switch (item.type) {
      case ItemType.event:
        showEventEdit(context, service, coupleId, item.id, payload);
      case ItemType.note:
        showNoteEdit(context, service, coupleId, item.id, payload);
      case ItemType.date:
        showDateEdit(context, service, coupleId, item.id, payload);
      case ItemType.photo:
        break;
    }
  }
}
