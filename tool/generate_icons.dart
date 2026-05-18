// ignore_for_file: avoid_print
import 'dart:io';
import 'package:image/image.dart' as img;

/// Generates 16 app icons (4 shapes x 4 colors) as 1024x1024 PNG files.
/// Run: dart pub add image --dev && dart run tool/generate_icons.dart
void main() {
  final colors = <String, int>{
    'coral': 0xFFE8757D,
    'lavender': 0xFF9B8EC4,
    'blue': 0xFF6AABDB,
    'mint': 0xFF5BBFAD,
  };

  final shapes = ['calendar', 'diary', 'wesync', 'todo'];
  const size = 1024;

  final outDir = Directory('assets/app_icons');
  if (!outDir.existsSync()) outDir.createSync(recursive: true);

  for (final shape in shapes) {
    for (final entry in colors.entries) {
      final name = '${shape}_${entry.key}';
      final image = _renderIcon(size, entry.value, shape);
      final bytes = img.encodePng(image);
      final file = File('${outDir.path}/$name.png');
      file.writeAsBytesSync(bytes);
      print('Generated: $name.png (${bytes.length} bytes)');
    }
  }

  print('\nDone! 16 icons generated in ${outDir.path}/');
}

img.Image _renderIcon(int size, int argbColor, String shape) {
  final image = img.Image(width: size, height: size);
  final s = size.toDouble();

  // Convert ARGB to image package color
  final r = (argbColor >> 16) & 0xFF;
  final g = (argbColor >> 8) & 0xFF;
  final b = argbColor & 0xFF;
  final bgColor = img.ColorRgba8(r, g, b, 255);
  final white = img.ColorRgba8(255, 255, 255, 255);
  final semiWhite = img.ColorRgba8(255, 255, 255, 150);

  // Fill with rounded rect background
  _fillRoundedRect(image, 0, 0, size, size, (s * 0.22).toInt(), bgColor);

  // Draw shape
  switch (shape) {
    case 'calendar':
      _drawCalendar(image, size, white, semiWhite);
      break;
    case 'diary':
      _drawDiary(image, size, white, semiWhite);
      break;
    case 'wesync':
      _drawWeSync(image, size, white);
      break;
    case 'todo':
      _drawTodo(image, size, white);
      break;
  }

  return image;
}

void _fillRoundedRect(img.Image image, int x, int y, int w, int h, int radius, img.Color color) {
  for (int py = y; py < y + h; py++) {
    for (int px = x; px < x + w; px++) {
      if (_isInRoundedRect(px - x, py - y, w, h, radius)) {
        image.setPixel(px, py, color);
      }
    }
  }
}

bool _isInRoundedRect(int px, int py, int w, int h, int r) {
  // Check corners
  if (px < r && py < r) {
    return (px - r) * (px - r) + (py - r) * (py - r) <= r * r;
  }
  if (px >= w - r && py < r) {
    return (px - (w - r)) * (px - (w - r)) + (py - r) * (py - r) <= r * r;
  }
  if (px < r && py >= h - r) {
    return (px - r) * (px - r) + (py - (h - r)) * (py - (h - r)) <= r * r;
  }
  if (px >= w - r && py >= h - r) {
    return (px - (w - r)) * (px - (w - r)) + (py - (h - r)) * (py - (h - r)) <= r * r;
  }
  return px >= 0 && px < w && py >= 0 && py < h;
}

void _drawThickLine(img.Image image, double x1, double y1, double x2, double y2, double thickness, img.Color color) {
  final halfT = thickness / 2;
  final dx = x2 - x1;
  final dy = y2 - y1;
  final len = _sqrt(dx * dx + dy * dy);
  if (len == 0) return;

  final nx = -dy / len;
  final ny = dx / len;

  final minX = ([x1 - halfT * nx.abs(), x2 - halfT * nx.abs()].reduce((a, b) => a < b ? a : b)).floor().clamp(0, image.width - 1);
  final maxX = ([x1 + halfT * nx.abs(), x2 + halfT * nx.abs()].reduce((a, b) => a > b ? a : b)).ceil().clamp(0, image.width - 1);
  final minY = ([y1 - halfT * ny.abs(), y2 - halfT * ny.abs()].reduce((a, b) => a < b ? a : b)).floor().clamp(0, image.height - 1);
  final maxY = ([y1 + halfT * ny.abs(), y2 + halfT * ny.abs()].reduce((a, b) => a > b ? a : b)).ceil().clamp(0, image.height - 1);

  for (int py = minY; py <= maxY; py++) {
    for (int px = minX; px <= maxX; px++) {
      final t = ((px - x1) * dx + (py - y1) * dy) / (len * len);
      if (t < -0.01 || t > 1.01) continue;
      final tc = t.clamp(0.0, 1.0);
      final closestX = x1 + tc * dx;
      final closestY = y1 + tc * dy;
      final dist = _sqrt((px - closestX) * (px - closestX) + (py - closestY) * (py - closestY));
      if (dist <= halfT) {
        image.setPixel(px, py, color);
      }
    }
  }
}

void _drawFilledCircle(img.Image image, double cx, double cy, double radius, img.Color color) {
  final r2 = radius * radius;
  for (int py = (cy - radius).floor(); py <= (cy + radius).ceil(); py++) {
    for (int px = (cx - radius).floor(); px <= (cx + radius).ceil(); px++) {
      if (px < 0 || px >= image.width || py < 0 || py >= image.height) continue;
      if ((px - cx) * (px - cx) + (py - cy) * (py - cy) <= r2) {
        image.setPixel(px, py, color);
      }
    }
  }
}

void _drawFilledRoundedRect(img.Image image, double x, double y, double w, double h, double r, img.Color color) {
  _fillRoundedRect(image, x.toInt(), y.toInt(), w.toInt(), h.toInt(), r.toInt(), color);
}

double _sqrt(double v) {
  if (v <= 0) return 0;
  double x = v;
  for (int i = 0; i < 20; i++) {
    x = (x + v / x) / 2;
  }
  return x;
}

void _drawCalendar(img.Image image, int size, img.Color white, img.Color semiWhite) {
  final s = size.toDouble();
  final m = s * 0.25;
  final w = s - 2 * m;
  final h = w;
  final top = m + s * 0.05;
  final thick = s * 0.04;
  final r = s * 0.06;

  // Calendar body outline
  _drawThickLine(image, m + r, top, m + w - r, top, thick, white);
  _drawThickLine(image, m + r, top + h, m + w - r, top + h, thick, white);
  _drawThickLine(image, m, top + r, m, top + h - r, thick, white);
  _drawThickLine(image, m + w, top + r, m + w, top + h - r, thick, white);
  // Corners
  _drawFilledCircle(image, m + r, top + r, r, white);
  _drawFilledCircle(image, m + w - r, top + r, r, white);
  _drawFilledCircle(image, m + r, top + h - r, r, white);
  _drawFilledCircle(image, m + w - r, top + h - r, r, white);
  // Inner fill (bg color to make outline)
  final bgR = (image.getPixel(size ~/ 2, 10));
  _fillRoundedRect(image, (m + thick).toInt(), (top + thick).toInt(),
      (w - 2 * thick).toInt(), (h - 2 * thick).toInt(), (r - thick).toInt().clamp(0, 999), bgR);

  // Header bar
  final headerH = h * 0.28;
  _fillRoundedRect(image, m.toInt(), top.toInt(), w.toInt(), headerH.toInt(), r.toInt(), white);

  // Calendar hooks
  for (final x in [m + w * 0.3, m + w * 0.7]) {
    _drawThickLine(image, x, top - s * 0.04, x, top + s * 0.06, thick * 0.8, white);
    // Round caps
    _drawFilledCircle(image, x, top - s * 0.04, thick * 0.4, white);
    _drawFilledCircle(image, x, top + s * 0.06, thick * 0.4, white);
  }

  // Grid dots (3x3)
  final dotR = s * 0.028;
  final gridTop = top + headerH + (h - headerH) * 0.22;
  final gridH = (h - headerH) * 0.6;
  final gridL = m + w * 0.2;
  final gridW = w * 0.6;
  for (int row = 0; row < 3; row++) {
    for (int col = 0; col < 3; col++) {
      final cx = gridL + gridW * col / 2;
      final cy = gridTop + gridH * row / 2;
      _drawFilledCircle(image, cx, cy, dotR, white);
    }
  }
}

void _drawDiary(img.Image image, int size, img.Color white, img.Color semiWhite) {
  final s = size.toDouble();
  final m = s * 0.24;
  final w = s - 2 * m;
  final h = w * 1.2;
  final top = (s - h) / 2;
  final thick = s * 0.04;
  final r = s * 0.05;

  // Book body (filled white outline)
  _drawFilledRoundedRect(image, m, top, w, h, r, white);
  final bgR = image.getPixel(size ~/ 2, 10);
  _drawFilledRoundedRect(image, m + thick, top + thick, w - 2 * thick, h - 2 * thick, (r - thick).clamp(0, 999), bgR);

  // Spine
  _drawThickLine(image, m + w * 0.2, top, m + w * 0.2, top + h, thick, white);

  // Lines
  final lineStart = m + w * 0.32;
  final lineEnd = m + w - w * 0.1;
  for (int i = 0; i < 4; i++) {
    final y = top + h * 0.25 + i * h * 0.15;
    _drawThickLine(image, lineStart, y, lineEnd, y, thick * 0.4, semiWhite);
  }

  // Bookmark triangle
  final bx = m + w * 0.72;
  final by = top;
  final bw = s * 0.08;
  final bh = s * 0.12;
  // Simple filled triangle bookmark
  for (int py = by.toInt(); py < (by + bh).toInt(); py++) {
    final progress = (py - by) / bh;
    double leftX, rightX;
    if (progress < 0.7) {
      leftX = bx - bw / 2;
      rightX = bx + bw / 2;
    } else {
      final t = (progress - 0.7) / 0.3;
      leftX = bx - bw / 2 + t * bw / 2;
      rightX = bx + bw / 2 - t * bw / 2;
    }
    for (int px = leftX.toInt(); px <= rightX.toInt(); px++) {
      if (px >= 0 && px < image.width && py >= 0 && py < image.height) {
        image.setPixel(px, py, white);
      }
    }
  }
}

void _drawWeSync(img.Image image, int size, img.Color white) {
  final s = size.toDouble();
  final thick = s * 0.07;
  final m = s * 0.22;
  final top = s * 0.28;
  final bot = s * 0.72;
  final w = s - 2 * m;
  final mid = (top + bot) / 2 + s * 0.06;

  // "W" shape
  _drawThickLine(image, m, top, m + w * 0.25, bot, thick, white);
  _drawThickLine(image, m + w * 0.25, bot, m + w * 0.5, mid, thick, white);
  _drawThickLine(image, m + w * 0.5, mid, m + w * 0.75, bot, thick, white);
  _drawThickLine(image, m + w * 0.75, bot, m + w, top, thick, white);

  // Round caps at endpoints
  final capR = thick / 2;
  _drawFilledCircle(image, m, top, capR, white);
  _drawFilledCircle(image, m + w * 0.25, bot, capR, white);
  _drawFilledCircle(image, m + w * 0.5, mid, capR, white);
  _drawFilledCircle(image, m + w * 0.75, bot, capR, white);
  _drawFilledCircle(image, m + w, top, capR, white);
}

void _drawTodo(img.Image image, int size, img.Color white) {
  final s = size.toDouble();
  final m = s * 0.25;
  final w = s - 2 * m;
  final h = w;
  final top = (s - h) / 2;
  final thick = s * 0.04;
  final r = s * 0.06;

  // Checkbox outline
  _drawFilledRoundedRect(image, m, top, w, h, r, white);
  final bgR = image.getPixel(size ~/ 2, 10);
  _drawFilledRoundedRect(image, m + thick, top + thick, w - 2 * thick, h - 2 * thick, (r - thick).clamp(0, 999), bgR);

  // Checkmark
  final checkThick = s * 0.065;
  _drawThickLine(image, m + w * 0.22, top + h * 0.5, m + w * 0.42, top + h * 0.7, checkThick, white);
  _drawThickLine(image, m + w * 0.42, top + h * 0.7, m + w * 0.78, top + h * 0.3, checkThick, white);

  // Round caps
  final capR = checkThick / 2;
  _drawFilledCircle(image, m + w * 0.22, top + h * 0.5, capR, white);
  _drawFilledCircle(image, m + w * 0.42, top + h * 0.7, capR, white);
  _drawFilledCircle(image, m + w * 0.78, top + h * 0.3, capR, white);
}
