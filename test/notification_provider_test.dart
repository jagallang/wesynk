import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wesynk/features/home/presentation/providers/home_providers.dart';

void main() {
  group('Notification Providers defaults', () {
    test('notifChatProvider defaults to true', () {
      final container = ProviderContainer();
      expect(container.read(notifChatProvider), isTrue);
      container.dispose();
    });

    test('notifCalendarProvider defaults to true', () {
      final container = ProviderContainer();
      expect(container.read(notifCalendarProvider), isTrue);
      container.dispose();
    });

    test('notifAlbumProvider defaults to true', () {
      final container = ProviderContainer();
      expect(container.read(notifAlbumProvider), isTrue);
      container.dispose();
    });

    test('notification providers can be toggled', () {
      final container = ProviderContainer();
      container.read(notifChatProvider.notifier).state = false;
      expect(container.read(notifChatProvider), isFalse);

      container.read(notifCalendarProvider.notifier).state = false;
      expect(container.read(notifCalendarProvider), isFalse);

      container.read(notifAlbumProvider.notifier).state = false;
      expect(container.read(notifAlbumProvider), isFalse);
      container.dispose();
    });
  });

  group('chatTitleProvider', () {
    test('defaults to null', () {
      final container = ProviderContainer();
      expect(container.read(chatTitleProvider), isNull);
      container.dispose();
    });

    test('can be set to custom title', () {
      final container = ProviderContainer();
      container.read(chatTitleProvider.notifier).state = '우리 둘';
      expect(container.read(chatTitleProvider), '우리 둘');
      container.dispose();
    });
  });

  group('selectedAppIconProvider', () {
    test('defaults to null', () {
      final container = ProviderContainer();
      expect(container.read(selectedAppIconProvider), isNull);
      container.dispose();
    });

    test('can be set to icon id', () {
      final container = ProviderContainer();
      container.read(selectedAppIconProvider.notifier).state = 'calendar_coral';
      expect(container.read(selectedAppIconProvider), 'calendar_coral');
      container.dispose();
    });
  });
}
