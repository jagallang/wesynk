// ignore_for_file: avoid_print
import 'dart:io';
import 'package:image/image.dart' as img;

/// Resizes 16 icons to all required iOS & Android sizes.
/// Also sets wesync_coral as the default app icon.
void main() {
  final srcDir = Directory('assets/app_icons');

  // iOS sizes needed for alternate icons
  final iosSizes = [60, 120, 180]; // 60@1x is not used, but 120(@2x) and 180(@3x) are main

  // Android mipmap sizes
  final androidSizes = <String, int>{
    'mipmap-mdpi': 48,
    'mipmap-hdpi': 72,
    'mipmap-xhdpi': 96,
    'mipmap-xxhdpi': 144,
    'mipmap-xxxhdpi': 192,
  };

  // iOS full icon set sizes
  final iosIconSizes = [
    (name: 'Icon-App-20x20@1x', size: 20),
    (name: 'Icon-App-20x20@2x', size: 40),
    (name: 'Icon-App-20x20@3x', size: 60),
    (name: 'Icon-App-29x29@1x', size: 29),
    (name: 'Icon-App-29x29@2x', size: 58),
    (name: 'Icon-App-29x29@3x', size: 87),
    (name: 'Icon-App-40x40@1x', size: 40),
    (name: 'Icon-App-40x40@2x', size: 80),
    (name: 'Icon-App-40x40@3x', size: 120),
    (name: 'Icon-App-60x60@2x', size: 120),
    (name: 'Icon-App-60x60@3x', size: 180),
    (name: 'Icon-App-76x76@1x', size: 76),
    (name: 'Icon-App-76x76@2x', size: 152),
    (name: 'Icon-App-83.5x83.5@2x', size: 167),
    (name: 'Icon-App-1024x1024@1x', size: 1024),
  ];

  final icons = srcDir.listSync().whereType<File>().where((f) => f.path.endsWith('.png')).toList();

  for (final iconFile in icons) {
    final basename = iconFile.uri.pathSegments.last.replaceAll('.png', '');
    final src = img.decodePng(iconFile.readAsBytesSync())!;

    // --- iOS alternate icon assets ---
    final iosAltDir = Directory('ios/Runner/Assets.xcassets/$basename.appiconset');
    if (!iosAltDir.existsSync()) iosAltDir.createSync(recursive: true);

    // Generate Contents.json for alternate icon
    final contentsEntries = <String>[];
    for (final entry in iosIconSizes) {
      final resized = img.copyResize(src, width: entry.size, height: entry.size, interpolation: img.Interpolation.average);
      final outFile = File('${iosAltDir.path}/${entry.name}.png');
      outFile.writeAsBytesSync(img.encodePng(resized));

      // Parse scale from name
      final scaleMatch = RegExp(r'@(\d+)x').firstMatch(entry.name);
      final scale = scaleMatch != null ? scaleMatch.group(1)! : '1';

      contentsEntries.add('''    {
      "filename" : "${entry.name}.png",
      "idiom" : "universal",
      "platform" : "ios",
      "size" : "${_sizeStr(entry.name)}",
      "scale" : "${scale}x"
    }''');
    }

    final contentsJson = '''{
  "images" : [
${contentsEntries.join(',\n')}
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}''';
    File('${iosAltDir.path}/Contents.json').writeAsStringSync(contentsJson);

    // --- Android mipmap ---
    for (final entry in androidSizes.entries) {
      final dir = Directory('android/app/src/main/res/${entry.key}');
      if (!dir.existsSync()) dir.createSync(recursive: true);
      final resized = img.copyResize(src, width: entry.value, height: entry.value, interpolation: img.Interpolation.average);
      File('${dir.path}/$basename.png').writeAsBytesSync(img.encodePng(resized));
    }

    print('Processed: $basename');
  }

  // --- Set wesync_coral as the default icon ---
  print('\nSetting wesync_coral as default icon...');
  _setDefaultIcon('wesync_coral', iosIconSizes, androidSizes);

  print('\nDone!');
}

String _sizeStr(String name) {
  final match = RegExp(r'Icon-App-(.+)@').firstMatch(name);
  if (match != null) return '${match.group(1)!}';
  return '1024x1024';
}

void _setDefaultIcon(String iconName, List<({String name, int size})> iosIconSizes, Map<String, int> androidSizes) {
  final src = img.decodePng(File('assets/app_icons/$iconName.png').readAsBytesSync())!;

  // iOS default icon
  final iosDir = Directory('ios/Runner/Assets.xcassets/AppIcon.appiconset');
  for (final entry in iosIconSizes) {
    final resized = img.copyResize(src, width: entry.size, height: entry.size, interpolation: img.Interpolation.average);
    File('${iosDir.path}/${entry.name}.png').writeAsBytesSync(img.encodePng(resized));
  }
  print('  iOS default icon updated');

  // Android default icon
  for (final entry in androidSizes.entries) {
    final dir = Directory('android/app/src/main/res/${entry.key}');
    final resized = img.copyResize(src, width: entry.value, height: entry.value, interpolation: img.Interpolation.average);
    File('${dir.path}/ic_launcher.png').writeAsBytesSync(img.encodePng(resized));
  }
  print('  Android default icon updated');
}
