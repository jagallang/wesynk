import 'package:flutter_test/flutter_test.dart';
import 'package:wesync_chat/wesync_chat.dart';

void main() {
  group('ReplyTo', () {
    test('toMap produces correct structure', () {
      const reply = ReplyTo(
        id: 'msg123',
        body: 'hello world',
        senderId: 'user1',
      );
      final map = reply.toMap();
      expect(map['id'], 'msg123');
      expect(map['body'], 'hello world');
      expect(map['senderId'], 'user1');
      expect(map.containsKey('imageUrl'), isFalse);
    });

    test('toMap includes imageUrl when set', () {
      const reply = ReplyTo(
        id: 'msg456',
        body: '',
        senderId: 'user2',
        imageUrl: 'https://example.com/img.jpg',
      );
      final map = reply.toMap();
      expect(map['imageUrl'], 'https://example.com/img.jpg');
    });

    test('fromMap restores all fields', () {
      final reply = ReplyTo.fromMap({
        'id': 'msg789',
        'body': 'quoted text',
        'senderId': 'user3',
        'imageUrl': 'https://example.com/photo.png',
      });
      expect(reply.id, 'msg789');
      expect(reply.body, 'quoted text');
      expect(reply.senderId, 'user3');
      expect(reply.imageUrl, 'https://example.com/photo.png');
    });

    test('fromMap handles missing fields gracefully', () {
      final reply = ReplyTo.fromMap({});
      expect(reply.id, '');
      expect(reply.body, '');
      expect(reply.senderId, '');
      expect(reply.imageUrl, isNull);
    });

    test('roundtrip toMap → fromMap', () {
      const original = ReplyTo(
        id: 'abc',
        body: 'test body',
        senderId: 'sender1',
        imageUrl: 'https://img.com/a.jpg',
      );
      final restored = ReplyTo.fromMap(original.toMap());
      expect(restored.id, original.id);
      expect(restored.body, original.body);
      expect(restored.senderId, original.senderId);
      expect(restored.imageUrl, original.imageUrl);
    });
  });

  group('Message with replyTo', () {
    test('toMap includes replyTo when set', () {
      final msg = Message(
        id: '1',
        senderId: 'user1',
        body: 'reply message',
        sentAt: DateTime(2026, 1, 1),
        replyTo: const ReplyTo(
          id: 'orig1',
          body: 'original message',
          senderId: 'user2',
        ),
      );
      final map = msg.toMap();
      expect(map.containsKey('replyTo'), isTrue);
      expect(map['replyTo']['id'], 'orig1');
      expect(map['replyTo']['body'], 'original message');
      expect(map['replyTo']['senderId'], 'user2');
    });

    test('toMap excludes replyTo when null', () {
      final msg = Message(
        id: '2',
        senderId: 'user1',
        body: 'no reply',
        sentAt: DateTime(2026, 1, 1),
      );
      final map = msg.toMap();
      expect(map.containsKey('replyTo'), isFalse);
    });

    test('copyWith preserves replyTo', () {
      final msg = Message(
        id: '3',
        senderId: 'user1',
        body: 'test',
        sentAt: DateTime(2026, 1, 1),
        replyTo: const ReplyTo(
          id: 'r1',
          body: 'quoted',
          senderId: 'user2',
        ),
      );
      final copied = msg.copyWith(readBy: {'user2': DateTime(2026, 1, 2)});
      expect(copied.replyTo, isNotNull);
      expect(copied.replyTo!.id, 'r1');
      expect(copied.readBy.containsKey('user2'), isTrue);
    });

    test('replyTo with image shows photo label', () {
      const reply = ReplyTo(
        id: 'img1',
        body: '',
        senderId: 'user1',
        imageUrl: 'https://example.com/photo.jpg',
      );
      expect(reply.imageUrl, isNotNull);
      expect(reply.body, isEmpty);
    });
  });
}
