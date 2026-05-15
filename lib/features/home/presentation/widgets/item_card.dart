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

    // 일기(note)는 일기장 스타일 카드
    if (item.type == ItemType.note) {
      return _buildNoteCard(context, ref, payload, theme, eventColor);
    }

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

  Widget _buildNoteCard(BuildContext context, WidgetRef ref,
      Map<String, dynamic> payload, ThemeData theme, Color eventColor) {
    final body = payload['body']?.toString() ?? '';
    final mood = payload['mood']?.toString() ?? '📝';
    final tag = payload['tag']?.toString() ?? '';
    final tagName = payload['tagName']?.toString() ?? '';
    final title = payload['title']?.toString() ?? '';

    // 기존 일기 (tag/title 없는) 하위 호환: 본문 첫 줄을 제목으로
    final displayTitle = title.isNotEmpty
        ? title
        : body.split('\n').first;
    final tagLabel = tag.isNotEmpty ? '$tag $tagName' : '';

    return Card(
      child: StatefulBuilder(
        builder: (context, setCardState) {
          // _expanded 상태를 클로저로 관리
          return _NoteExpandableCard(
            item: item,
            displayTitle: displayTitle,
            tagLabel: tagLabel,
            mood: mood,
            body: body,
            eventColor: eventColor,
            theme: theme,
            onLongPress: () => _showActions(context, ref),
            onEdit: () => _showEditForm(context, ref),
            onDelete: () {
              final service = ref.read(firestoreServiceProvider);
              final coupleId = FirestoreService.defaultCoupleId;
              service.deleteItem(coupleId: coupleId, itemId: item.id);
            },
          );
        },
      ),
    );
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

  static const _noteTags = [
    ('📚', '독서', 'Reading'),
    ('🎵', '음악', 'Music'),
    ('💡', '관심사', 'Interests'),
    ('🎬', '영화', 'Movies'),
    ('✈️', '여행', 'Travel'),
    ('💭', '일상', 'Daily'),
  ];

  void _showNoteEdit(BuildContext context, FirestoreService service,
      String coupleId, Map<String, dynamic> payload) {
    final titleCtrl =
        TextEditingController(text: payload['title']?.toString() ?? '');
    final bodyCtrl =
        TextEditingController(text: payload['body']?.toString() ?? '');
    final currentTag = payload['tag']?.toString() ?? '';
    int selectedTag = _noteTags.indexWhere((t) => t.$1 == currentTag);
    if (selectedTag < 0) selectedTag = 5;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(
              24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(S.isKo ? '수정' : 'Edit',
                  style: Theme.of(ctx).textTheme.titleMedium),
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: List.generate(_noteTags.length, (i) {
                  final (emoji, ko, en) = _noteTags[i];
                  return ChoiceChip(
                    label: Text('$emoji ${S.isKo ? ko : en}',
                        style: const TextStyle(fontSize: 13)),
                    selected: i == selectedTag,
                    onSelected: (_) =>
                        setSheetState(() => selectedTag = i),
                  );
                }),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: titleCtrl,
                decoration: InputDecoration(
                    labelText: S.isKo ? '제목' : 'Title',
                    border: const OutlineInputBorder()),
                autofocus: true,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: bodyCtrl,
                decoration: InputDecoration(
                    hintText: S.noteHint,
                    border: const OutlineInputBorder()),
                maxLines: null,
                minLines: 4,
                keyboardType: TextInputType.multiline,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () {
                  if (titleCtrl.text.trim().isEmpty) return;
                  final (tagEmoji, tagKo, tagEn) = _noteTags[selectedTag];
                  payload['title'] = titleCtrl.text.trim();
                  payload['body'] = bodyCtrl.text.trim();
                  payload['tag'] = tagEmoji;
                  payload['tagName'] = S.isKo ? tagKo : tagEn;
                  service.updateItem(
                      coupleId: coupleId, itemId: item.id, payload: payload);
                  Navigator.pop(ctx);
                },
                child: Text(S.change),
              ),
            ],
          ),
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

/// 일기 카드 — 탭하면 펼침/접힘
class _NoteExpandableCard extends StatefulWidget {
  final Item item;
  final String displayTitle;
  final String tagLabel;
  final String mood;
  final String body;
  final Color eventColor;
  final ThemeData theme;
  final VoidCallback onLongPress;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _NoteExpandableCard({
    required this.item,
    required this.displayTitle,
    required this.tagLabel,
    required this.mood,
    required this.body,
    required this.eventColor,
    required this.theme,
    required this.onLongPress,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<_NoteExpandableCard> createState() => _NoteExpandableCardState();
}

class _NoteExpandableCardState extends State<_NoteExpandableCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => setState(() => _expanded = !_expanded),
      onLongPress: widget.onLongPress,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 헤더: 태그 + 제목 + 감정 + 날짜
            Row(
              children: [
                if (widget.tagLabel.isNotEmpty) ...[
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: widget.theme.colorScheme.primary
                          .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(widget.tagLabel,
                        style: TextStyle(
                            fontSize: 12,
                            color: widget.theme.colorScheme.primary)),
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Text(
                    widget.displayTitle,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 15),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(widget.mood, style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 6),
                Icon(
                  _expanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  size: 20,
                  color: Colors.grey.shade400,
                ),
              ],
            ),

            // 날짜 + 작성자 색상
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: widget.eventColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(widget.item.date,
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey.shade500)),
                ],
              ),
            ),

            // 펼침: 본문 + 수정/삭제 버튼
            if (_expanded) ...[
              if (widget.body.isNotEmpty) ...[
                const Divider(height: 20),
                Text(
                  widget.body,
                  style:
                      widget.theme.textTheme.bodyMedium?.copyWith(height: 1.6),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: widget.onEdit,
                    icon: const Icon(Icons.edit_outlined, size: 16),
                    label: Text(S.isKo ? '수정' : 'Edit',
                        style: const TextStyle(fontSize: 13)),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: widget.onDelete,
                    icon: const Icon(Icons.delete_outline,
                        size: 16, color: Colors.red),
                    label: Text(S.isKo ? '삭제' : 'Delete',
                        style:
                            const TextStyle(fontSize: 13, color: Colors.red)),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
