import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wesynk/shared/models/item_model.dart';

void main() {
  group('Item model', () {
    test('toMap produces correct structure for event', () {
      final item = Item(
        id: 'test-id',
        type: ItemType.event,
        date: '2026-05-17',
        createdBy: 'uid123',
        createdAt: DateTime(2026, 5, 17, 10, 30),
        payload: {'title': 'Meeting', 'location': 'Office'},
      );

      final map = item.toMap();

      expect(map['type'], 'event');
      expect(map['date'], '2026-05-17');
      expect(map['createdBy'], 'uid123');
      expect(map['payload']['title'], 'Meeting');
      expect(map['payload']['location'], 'Office');
      expect(map['deletedAt'], isNull);
      expect(map['createdAt'], isA<Timestamp>());
    });

    test('toMap produces correct structure for note', () {
      final item = Item(
        id: 'note-1',
        type: ItemType.note,
        date: '2026-05-17',
        createdBy: 'uid456',
        createdAt: DateTime(2026, 5, 17),
        payload: {'body': 'Hello world', 'mood': '😊'},
      );

      final map = item.toMap();

      expect(map['type'], 'note');
      expect(map['payload']['body'], 'Hello world');
      expect(map['payload']['mood'], '😊');
    });

    test('tabOrder has 4 types in correct order', () {
      expect(tabOrder.length, 4);
      expect(tabOrder[0], ItemType.event);
      expect(tabOrder[1], ItemType.date);
      expect(tabOrder[2], ItemType.note);
      expect(tabOrder[3], ItemType.photo);
    });

    test('Item defaults checked to false', () {
      final item = Item(
        id: '1',
        type: ItemType.event,
        date: '2026-01-01',
        createdBy: 'me',
        createdAt: DateTime.now(),
        payload: {},
      );
      expect(item.checked, isFalse);
      expect(item.deletedAt, isNull);
    });
  });
}
