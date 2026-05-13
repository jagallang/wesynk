import 'package:flutter/material.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/services/firestore_service.dart';

/// 일정 수정 폼
void showEventEdit(
    BuildContext context, FirestoreService service, String coupleId,
    String itemId, Map<String, dynamic> payload) {
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
                  coupleId: coupleId, itemId: itemId, payload: payload);
              Navigator.pop(ctx);
            },
            child: Text(S.change),
          ),
        ],
      ),
    ),
  );
}

/// 일기 수정 폼
void showNoteEdit(
    BuildContext context, FirestoreService service, String coupleId,
    String itemId, Map<String, dynamic> payload) {
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
                  coupleId: coupleId, itemId: itemId, payload: payload);
              Navigator.pop(ctx);
            },
            child: Text(S.change),
          ),
        ],
      ),
    ),
  );
}

/// 데이트 기록 수정 폼
void showDateEdit(
    BuildContext context, FirestoreService service, String coupleId,
    String itemId, Map<String, dynamic> payload) {
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
                      itemId: itemId,
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
