import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wesynk/features/home/presentation/providers/home_providers.dart';

void main() {
  group('AppIconPreset filter consistency', () {
    test('all presets have valid id format', () {
      for (final preset in appIconPresets) {
        expect(preset.id, matches(RegExp(r'^[a-z]+_[a-z]+$')));
      }
    });

    test('presetColors count unchanged at 8', () {
      expect(presetColors.length, 8);
    });

    test('presetBackgrounds count unchanged at 8', () {
      expect(presetBackgrounds.length, 8);
    });
  });

  group('Notification providers', () {
    test('all notification providers default to true', () {
      final container = ProviderContainer();
      expect(container.read(notifChatProvider), isTrue);
      expect(container.read(notifCalendarProvider), isTrue);
      expect(container.read(notifAlbumProvider), isTrue);
      container.dispose();
    });
  });
}
