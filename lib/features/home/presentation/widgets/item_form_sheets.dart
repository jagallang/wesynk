import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../shared/models/item_model.dart';

const moodEmojis = ['😊', '😍', '😢', '😡', '🥺', '🎬', '📝', '🌸'];

/// 일정 추가 폼
void showEventForm(BuildContext context, String dateKey, void Function(Item) onAdd) {
  final titleCtrl = TextEditingController();
  final locationCtrl = TextEditingController();

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
          Text(S.addTitle(S.tabTravel),
              style: Theme.of(ctx).textTheme.titleMedium),
          const SizedBox(height: 16),
          TextField(
            controller: titleCtrl,
            decoration: InputDecoration(
              labelText: S.fieldTitle,
              border: const OutlineInputBorder(),
            ),
            autofocus: true,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: locationCtrl,
            decoration: InputDecoration(
              labelText: S.fieldLocation,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () {
              if (titleCtrl.text.trim().isEmpty) return;
              onAdd(Item(
                id: const Uuid().v4(),
                type: ItemType.event,
                date: dateKey,
                createdBy: FirebaseAuth.instance.currentUser?.uid ?? '',
                createdAt: DateTime.now(),
                payload: {
                  'title': titleCtrl.text.trim(),
                  'location': locationCtrl.text.trim(),
                  'startAt': DateTime.now().toIso8601String(),
                  'allDay': false,
                },
              ));
              Navigator.pop(ctx);
            },
            child: Text(S.add),
          ),
        ],
      ),
    ),
  );
}

/// 일기 추가 폼
void showNoteForm(BuildContext context, String dateKey, void Function(Item) onAdd) {
  final bodyCtrl = TextEditingController();
  String selectedMood = '😊';

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
            Text(S.noteAdd, style: Theme.of(ctx).textTheme.titleMedium),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: moodEmojis
                  .map((m) => GestureDetector(
                        onTap: () => setSheetState(() => selectedMood = m),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: selectedMood == m
                                ? AppColors.primaryLight
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child:
                              Text(m, style: const TextStyle(fontSize: 24)),
                        ),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: bodyCtrl,
              decoration: InputDecoration(
                hintText: S.noteHint,
                border: const OutlineInputBorder(),
              ),
              maxLines: null,
              minLines: 6,
              keyboardType: TextInputType.multiline,
              autofocus: true,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () {
                if (bodyCtrl.text.trim().isEmpty) return;
                onAdd(Item(
                  id: const Uuid().v4(),
                  type: ItemType.note,
                  date: dateKey,
                  createdBy: FirebaseAuth.instance.currentUser?.uid ?? '',
                  createdAt: DateTime.now(),
                  payload: {
                    'body': bodyCtrl.text.trim(),
                    'mood': selectedMood,
                  },
                ));
                Navigator.pop(ctx);
              },
              child: Text(S.add),
            ),
          ],
        ),
      ),
    ),
  );
}

/// 데이트 기록 추가 폼
void showDateForm(BuildContext context, String dateKey, void Function(Item) onAdd) {
  final titleCtrl = TextEditingController();
  final placeCtrl = TextEditingController();
  final reviewCtrl = TextEditingController();
  int rating = 3;

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
            Text(S.dateRecord, style: Theme.of(ctx).textTheme.titleMedium),
            const SizedBox(height: 16),
            TextField(
              controller: titleCtrl,
              decoration: InputDecoration(
                labelText: S.fieldTitle,
                border: const OutlineInputBorder(),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: placeCtrl,
              decoration: InputDecoration(
                labelText: S.fieldPlace,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text(S.fieldRating),
                ...List.generate(5, (i) {
                  return IconButton(
                    icon: Icon(
                      i < rating ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                    ),
                    onPressed: () => setSheetState(() => rating = i + 1),
                  );
                }),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reviewCtrl,
              decoration: InputDecoration(
                hintText: S.fieldReview,
                border: const OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () {
                if (titleCtrl.text.trim().isEmpty) return;
                onAdd(Item(
                  id: const Uuid().v4(),
                  type: ItemType.date,
                  date: dateKey,
                  createdBy: FirebaseAuth.instance.currentUser?.uid ?? '',
                  createdAt: DateTime.now(),
                  payload: {
                    'title': titleCtrl.text.trim(),
                    'place': {'name': placeCtrl.text.trim()},
                    'rating': rating,
                    'review': reviewCtrl.text.trim(),
                  },
                ));
                Navigator.pop(ctx);
              },
              child: Text(S.add),
            ),
          ],
        ),
      ),
    ),
  );
}
