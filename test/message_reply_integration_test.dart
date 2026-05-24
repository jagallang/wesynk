import 'package:flutter_test/flutter_test.dart';
import 'package:wesync_chat/wesync_chat.dart';

void main() {
  group('Message with ReplyTo integration', () {
    test('message toMap with replyTo includes all fields', () {
      final msg = Message(
        id: 'msg1',
        senderId: 'user1',
        body: 'reply text',
        sentAt: DateTime(2026, 5, 25),
        replyTo: const ReplyTo(
          id: 'orig1',
          body: 'original',
          senderId: 'user2',
        ),
      );
      final map = msg.toMap();
      expect(map['replyTo'], isNotNull);
      expect(map['replyTo']['id'], 'orig1');
      expect(map['senderId'], 'user1');
    });

    test('message without replyTo omits field', () {
      final msg = Message(
        id: 'msg2',
        senderId: 'user1',
        body: 'plain text',
        sentAt: DateTime(2026, 5, 25),
      );
      expect(msg.toMap().containsKey('replyTo'), isFalse);
    });

    test('replyTo with image shows imageUrl', () {
      const reply = ReplyTo(
        id: 'img1',
        body: '',
        senderId: 'user1',
        imageUrl: 'https://example.com/photo.jpg',
      );
      final map = reply.toMap();
      expect(map['imageUrl'], 'https://example.com/photo.jpg');
    });

    test('message copyWith preserves replyTo', () {
      final msg = Message(
        id: 'msg3',
        senderId: 'user1',
        body: 'test',
        sentAt: DateTime(2026, 5, 25),
        replyTo: const ReplyTo(id: 'r1', body: 'q', senderId: 'u2'),
      );
      final copied = msg.copyWith(readBy: {'u2': DateTime(2026, 5, 26)});
      expect(copied.replyTo?.id, 'r1');
      expect(copied.readBy.containsKey('u2'), isTrue);
    });

    test('message visibility with replyTo', () {
      final msg = Message(
        id: 'msg4',
        senderId: 'user1',
        body: 'visible reply',
        sentAt: DateTime.now(),
        replyTo: const ReplyTo(id: 'r2', body: 'quoted', senderId: 'u2'),
      );
      expect(msg.isVisible(), isTrue);
      expect(msg.replyTo, isNotNull);
    });

    test('ephemeral message with replyTo', () {
      final now = DateTime.now();
      final msg = Message(
        id: 'msg5',
        senderId: 'user1',
        body: 'ephemeral reply',
        sentAt: now,
        hideAfter: now.add(const Duration(minutes: 10)),
        replyTo: const ReplyTo(id: 'r3', body: 'q', senderId: 'u2'),
      );
      expect(msg.isEphemeral, isTrue);
      expect(msg.replyTo, isNotNull);
    });
  });

  group('ChatSettings notifications', () {
    test('default ChatSettings', () {
      const s = ChatSettings();
      expect(s.notificationsEnabled, isTrue);
      expect(s.showReadReceipts, isTrue);
    });

    test('copyWith notifications disabled', () {
      final s = const ChatSettings().copyWith(notificationsEnabled: false);
      expect(s.notificationsEnabled, isFalse);
      expect(s.showReadReceipts, isTrue);
    });
  });

  group('formatLifetime edge cases', () {
    test('zero duration', () {
      expect(formatLifetime(Duration.zero), '0초');
    });

    test('exactly 1 day', () {
      expect(formatLifetime(const Duration(days: 1)), '1일');
    });

    test('exactly 1 hour', () {
      expect(formatLifetime(const Duration(hours: 1)), '1시간');
    });

    test('25 hours shows days', () {
      expect(formatLifetime(const Duration(hours: 25)), '1일');
    });
  });
}
