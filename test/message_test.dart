import 'package:flutter_test/flutter_test.dart';
import 'package:wesync_chat/wesync_chat.dart';

void main() {
  group('Message', () {
    test('isVisible returns true when hideAfter is null', () {
      final msg = Message(
        id: '1',
        senderId: 'user1',
        body: 'hello',
        sentAt: DateTime.now(),
      );
      expect(msg.isVisible(), isTrue);
    });

    test('isVisible returns true when hideAfter is in the future', () {
      final msg = Message(
        id: '2',
        senderId: 'user1',
        body: 'hello',
        sentAt: DateTime.now(),
        hideAfter: DateTime.now().add(const Duration(hours: 1)),
      );
      expect(msg.isVisible(), isTrue);
    });

    test('isVisible returns false when hideAfter is in the past', () {
      final msg = Message(
        id: '3',
        senderId: 'user1',
        body: 'hello',
        sentAt: DateTime.now().subtract(const Duration(hours: 2)),
        hideAfter: DateTime.now().subtract(const Duration(hours: 1)),
      );
      expect(msg.isVisible(), isFalse);
    });

    test('isEphemeral returns false when hideAfter is null', () {
      final msg = Message(
        id: '4',
        senderId: 'user1',
        body: 'hello',
        sentAt: DateTime.now(),
      );
      expect(msg.isEphemeral, isFalse);
    });

    test('isEphemeral returns true when hideAfter - sentAt > 5s', () {
      final sentAt = DateTime(2026, 1, 1, 12, 0, 0);
      final msg = Message(
        id: '5',
        senderId: 'user1',
        body: 'hello',
        sentAt: sentAt,
        hideAfter: sentAt.add(const Duration(minutes: 10)),
      );
      expect(msg.isEphemeral, isTrue);
    });

    test('isEphemeral returns false when hideAfter - sentAt <= 5s', () {
      final sentAt = DateTime(2026, 1, 1, 12, 0, 0);
      final msg = Message(
        id: '6',
        senderId: 'user1',
        body: 'hello',
        sentAt: sentAt,
        hideAfter: sentAt.add(const Duration(seconds: 3)),
      );
      expect(msg.isEphemeral, isFalse);
    });

    test('remainingLifetime returns null for non-ephemeral', () {
      final msg = Message(
        id: '7',
        senderId: 'user1',
        body: 'hello',
        sentAt: DateTime.now(),
      );
      expect(msg.remainingLifetime(), isNull);
    });

    test('remainingLifetime returns positive duration for active ephemeral', () {
      final msg = Message(
        id: '8',
        senderId: 'user1',
        body: 'hello',
        sentAt: DateTime.now(),
        hideAfter: DateTime.now().add(const Duration(minutes: 5)),
      );
      final remaining = msg.remainingLifetime();
      expect(remaining, isNotNull);
      expect(remaining!.inSeconds, greaterThan(0));
    });

    test('remainingLifetime returns zero for expired ephemeral', () {
      final sentAt = DateTime.now().subtract(const Duration(hours: 2));
      final msg = Message(
        id: '9',
        senderId: 'user1',
        body: 'hello',
        sentAt: sentAt,
        hideAfter: sentAt.add(const Duration(minutes: 10)),
      );
      final remaining = msg.remainingLifetime();
      expect(remaining, Duration.zero);
    });

    test('hasImage returns true when imageUrl is set', () {
      final msg = Message(
        id: '10',
        senderId: 'user1',
        body: '',
        sentAt: DateTime.now(),
        imageUrl: 'https://example.com/photo.jpg',
      );
      expect(msg.hasImage, isTrue);
    });

    test('hasImage returns false when imageUrl is null', () {
      final msg = Message(
        id: '11',
        senderId: 'user1',
        body: 'text only',
        sentAt: DateTime.now(),
      );
      expect(msg.hasImage, isFalse);
    });

    test('toMap includes imageUrl when set', () {
      final msg = Message(
        id: '12',
        senderId: 'user1',
        body: 'photo',
        sentAt: DateTime(2026, 1, 1),
        imageUrl: 'https://example.com/img.jpg',
      );
      final map = msg.toMap();
      expect(map['imageUrl'], 'https://example.com/img.jpg');
    });

    test('toMap excludes imageUrl when null', () {
      final msg = Message(
        id: '13',
        senderId: 'user1',
        body: 'text',
        sentAt: DateTime(2026, 1, 1),
      );
      final map = msg.toMap();
      expect(map.containsKey('imageUrl'), isFalse);
    });
  });
}
