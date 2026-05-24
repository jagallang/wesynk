import 'package:flutter_test/flutter_test.dart';
import 'package:wesynk/shared/models/item_model.dart';

void main() {
  group('Item model createdBy', () {
    test('Item has createdBy field', () {
      final item = Item(
        id: 'test1',
        type: ItemType.event,
        date: '2026-05-25',
        createdBy: 'user123',
        createdAt: DateTime(2026, 5, 25),
        payload: {'title': 'Test Event'},
      );
      expect(item.createdBy, 'user123');
    });

    test('isMine check with matching uid', () {
      final item = Item(
        id: 'test2',
        type: ItemType.note,
        date: '2026-05-25',
        createdBy: 'myUid',
        createdAt: DateTime(2026, 5, 25),
        payload: {'body': 'Test note'},
      );
      final myUid = 'myUid';
      final isMine = item.createdBy == myUid;
      expect(isMine, isTrue);
    });

    test('isMine check with different uid', () {
      final item = Item(
        id: 'test3',
        type: ItemType.event,
        date: '2026-05-25',
        createdBy: 'partnerUid',
        createdAt: DateTime(2026, 5, 25),
        payload: {'title': 'Partner Event'},
      );
      final myUid = 'myUid';
      final isMine = item.createdBy == myUid;
      expect(isMine, isFalse);
    });

    test('legacy me value', () {
      final item = Item(
        id: 'test4',
        type: ItemType.date,
        date: '2026-05-25',
        createdBy: 'me',
        createdAt: DateTime(2026, 5, 25),
        payload: {'title': 'Legacy item'},
      );
      final myUid = 'actualUid';
      final isMine = item.createdBy == myUid || item.createdBy == 'me';
      expect(isMine, isTrue);
    });
  });

  group('Item types', () {
    test('ItemType.event', () {
      expect(ItemType.event.name, 'event');
    });

    test('ItemType.note', () {
      expect(ItemType.note.name, 'note');
    });

    test('ItemType.date', () {
      expect(ItemType.date.name, 'date');
    });

    test('ItemType.photo', () {
      expect(ItemType.photo.name, 'photo');
    });

    test('tabOrder has 4 types', () {
      expect(tabOrder.length, 4);
    });
  });
}
