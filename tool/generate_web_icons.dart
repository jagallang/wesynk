// ignore_for_file: avoid_print
import 'dart:io';
import 'package:image/image.dart' as img;

/// Generates web icons (favicon + PWA) from calendar_coral.png
void main() {
  final src = img.decodePng(File('assets/app_icons/calendar_coral.png').readAsBytesSync())!;

  final sizes = {
    'web/favicon.png': 32,
    'web/icons/Icon-192.png': 192,
    'web/icons/Icon-512.png': 512,
    'web/icons/Icon-maskable-192.png': 192,
    'web/icons/Icon-maskable-512.png': 512,
  };

  for (final entry in sizes.entries) {
    final resized = img.copyResize(src, width: entry.value, height: entry.value, interpolation: img.Interpolation.average);
    File(entry.key).writeAsBytesSync(img.encodePng(resized));
    print('Generated: ${entry.key} (${entry.value}x${entry.value})');
  }

  print('\nDone!');
}
