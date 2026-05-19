import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wesynk/features/home/presentation/providers/home_providers.dart';

void main() {
  group('AppIconPreset', () {
    test('appIconPresets contains 16 presets (4 shapes x 4 colors)', () {
      expect(appIconPresets.length, 16);
    });

    test('all preset IDs are unique', () {
      final ids = appIconPresets.map((p) => p.id).toSet();
      expect(ids.length, 16);
    });

    test('preset ID format is shape_color', () {
      for (final preset in appIconPresets) {
        expect(preset.id, matches(RegExp(r'^[a-z]+_[a-z]+$')));
      }
    });

    test('contains all 4 shapes', () {
      final shapes = appIconPresets.map((p) => p.id.split('_').first).toSet();
      expect(shapes, containsAll(['calendar', 'diary', 'wesync', 'todo']));
      expect(shapes.length, 4);
    });

    test('contains all 4 colors', () {
      final colors = appIconPresets.map((p) => p.id.split('_').last).toSet();
      expect(colors, containsAll(['coral', 'lavender', 'blue', 'mint']));
      expect(colors.length, 4);
    });

    test('each shape has all 4 color variants', () {
      for (final shape in ['calendar', 'diary', 'wesync', 'todo']) {
        final variants =
            appIconPresets.where((p) => p.id.startsWith('${shape}_'));
        expect(variants.length, 4, reason: '$shape should have 4 color variants');
      }
    });

    test('each preset has a non-null icon and color', () {
      for (final preset in appIconPresets) {
        expect(preset.icon, isNotNull);
        expect(preset.color, isNotNull);
        expect(preset.shapeName, isNotEmpty);
        expect(preset.colorName, isNotEmpty);
      }
    });

    test('wesync presets use sync_alt icon', () {
      final wesyncPresets =
          appIconPresets.where((p) => p.id.startsWith('wesync_'));
      for (final p in wesyncPresets) {
        expect(p.icon, Icons.sync_alt);
      }
    });

    test('calendar presets use calendar_month icon', () {
      final calPresets =
          appIconPresets.where((p) => p.id.startsWith('calendar_'));
      for (final p in calPresets) {
        expect(p.icon, Icons.calendar_month);
      }
    });

    test('todo presets use check_box icon', () {
      final todoPresets =
          appIconPresets.where((p) => p.id.startsWith('todo_'));
      for (final p in todoPresets) {
        expect(p.icon, Icons.check_box);
      }
    });

    test('diary presets use menu_book icon', () {
      final diaryPresets =
          appIconPresets.where((p) => p.id.startsWith('diary_'));
      for (final p in diaryPresets) {
        expect(p.icon, Icons.menu_book);
      }
    });
  });

  group('AppCustomization', () {
    test('default values', () {
      const c = AppCustomization();
      expect(c.appName, 'WeSync');
      expect(c.themeColor, const Color(0xFFE8757D));
      expect(c.appIcon, Icons.favorite);
      expect(c.backgroundColor, const Color(0xFFFFFBF8));
    });

    test('copyWith changes only specified fields', () {
      const c = AppCustomization();
      final c2 = c.copyWith(appName: 'OurApp');
      expect(c2.appName, 'OurApp');
      expect(c2.themeColor, c.themeColor);
      expect(c2.appIcon, c.appIcon);
      expect(c2.backgroundColor, c.backgroundColor);
    });

    test('copyWith changes themeColor', () {
      const c = AppCustomization();
      final c2 = c.copyWith(themeColor: Colors.blue);
      expect(c2.themeColor, Colors.blue);
      expect(c2.appName, 'WeSync');
    });

    test('copyWith changes appIcon', () {
      const c = AppCustomization();
      final c2 = c.copyWith(appIcon: Icons.star);
      expect(c2.appIcon, Icons.star);
    });

    test('copyWith changes backgroundColor', () {
      const c = AppCustomization();
      final c2 = c.copyWith(backgroundColor: Colors.black);
      expect(c2.backgroundColor, Colors.black);
    });

    test('copyWith changes all fields at once', () {
      const c = AppCustomization();
      final c2 = c.copyWith(
        appName: 'Test',
        themeColor: Colors.red,
        appIcon: Icons.home,
        backgroundColor: Colors.grey,
      );
      expect(c2.appName, 'Test');
      expect(c2.themeColor, Colors.red);
      expect(c2.appIcon, Icons.home);
      expect(c2.backgroundColor, Colors.grey);
    });
  });

  group('presetColors', () {
    test('contains 8 color presets', () {
      expect(presetColors.length, 8);
    });

    test('all colors have names', () {
      for (final c in presetColors) {
        expect(c.name, isNotEmpty);
      }
    });

    test('first color is coral pink', () {
      expect(presetColors.first.name, '코랄핑크');
      expect(presetColors.first.color, const Color(0xFFE8757D));
    });
  });

  group('presetIcons', () {
    test('contains 8 icon presets', () {
      expect(presetIcons.length, 8);
    });

    test('first icon is heart', () {
      expect(presetIcons.first.name, '하트');
      expect(presetIcons.first.icon, Icons.favorite);
    });
  });

  group('presetBackgrounds', () {
    test('contains 8 background presets', () {
      expect(presetBackgrounds.length, 8);
    });

    test('includes dark theme', () {
      final dark = presetBackgrounds.where((b) => b.name == '다크');
      expect(dark.length, 1);
      expect(dark.first.color, const Color(0xFF1E1E2E));
    });
  });
}
