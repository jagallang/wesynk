import 'package:flutter_test/flutter_test.dart';
import 'package:wesync_chat/wesync_chat.dart';

void main() {
  group('ChatSettings', () {
    test('default values', () {
      const s = ChatSettings();
      expect(s.showReadReceipts, isTrue);
      expect(s.defaultEphemeral, isFalse);
      expect(s.fontSize, MessageFontSize.medium);
      expect(s.notificationsEnabled, isTrue);
      expect(s.backgroundIndex, 0);
      expect(s.defaultLifetime, const Duration(hours: 1));
    });

    test('copyWith changes showReadReceipts', () {
      const s = ChatSettings();
      final s2 = s.copyWith(showReadReceipts: false);
      expect(s2.showReadReceipts, isFalse);
      expect(s2.defaultEphemeral, isFalse);
    });

    test('copyWith changes defaultEphemeral', () {
      const s = ChatSettings();
      final s2 = s.copyWith(defaultEphemeral: true);
      expect(s2.defaultEphemeral, isTrue);
    });

    test('copyWith changes fontSize', () {
      const s = ChatSettings();
      final s2 = s.copyWith(fontSize: MessageFontSize.large);
      expect(s2.fontSize, MessageFontSize.large);
      expect(s2.fontSize.size, 17);
    });

    test('copyWith changes notificationsEnabled', () {
      const s = ChatSettings();
      final s2 = s.copyWith(notificationsEnabled: false);
      expect(s2.notificationsEnabled, isFalse);
    });

    test('copyWith preserves unchanged fields', () {
      final s = const ChatSettings().copyWith(fontSize: MessageFontSize.small);
      expect(s.showReadReceipts, isTrue);
      expect(s.defaultEphemeral, isFalse);
      expect(s.notificationsEnabled, isTrue);
      expect(s.fontSize.size, 12);
    });
  });

  group('MessageFontSize', () {
    test('small has size 12', () {
      expect(MessageFontSize.small.size, 12);
      expect(MessageFontSize.small.label, '작게');
    });

    test('medium has size 14', () {
      expect(MessageFontSize.medium.size, 14);
      expect(MessageFontSize.medium.label, '보통');
    });

    test('large has size 17', () {
      expect(MessageFontSize.large.size, 17);
      expect(MessageFontSize.large.label, '크게');
    });
  });

  group('ephemeralPresets', () {
    test('has 8 presets', () {
      expect(ephemeralPresets.length, 8);
    });

    test('first is 1 minute', () {
      expect(ephemeralPresets.first.$1, '1분');
      expect(ephemeralPresets.first.$2, const Duration(minutes: 1));
    });

    test('last is 30 days', () {
      expect(ephemeralPresets.last.$1, '30일');
      expect(ephemeralPresets.last.$2, const Duration(days: 30));
    });
  });

  group('formatLifetime', () {
    test('formats days', () {
      expect(formatLifetime(const Duration(days: 3)), '3일');
    });

    test('formats hours', () {
      expect(formatLifetime(const Duration(hours: 6)), '6시간');
    });

    test('formats minutes', () {
      expect(formatLifetime(const Duration(minutes: 30)), '30분');
    });

    test('formats seconds', () {
      expect(formatLifetime(const Duration(seconds: 45)), '45초');
    });
  });
}
