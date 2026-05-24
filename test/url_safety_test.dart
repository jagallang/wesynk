import 'package:flutter_test/flutter_test.dart';

void main() {
  group('URL safety validation', () {
    final urlRegex = RegExp(
      r'https?://[^\s<>\"\)]+',
      caseSensitive: false,
    );

    test('matches http URLs', () {
      final matches = urlRegex.allMatches('visit http://example.com today');
      expect(matches.length, 1);
      expect(matches.first.group(0), 'http://example.com');
    });

    test('matches https URLs', () {
      final matches = urlRegex.allMatches('go to https://google.com/search');
      expect(matches.length, 1);
      expect(matches.first.group(0), 'https://google.com/search');
    });

    test('does NOT match javascript: protocol', () {
      final matches =
          urlRegex.allMatches('click javascript:alert(1)');
      expect(matches.length, 0);
    });

    test('does NOT match data: protocol', () {
      final matches = urlRegex.allMatches('data:text/html,<h1>hi</h1>');
      expect(matches.length, 0);
    });

    test('does NOT match ftp: protocol', () {
      final matches = urlRegex.allMatches('ftp://files.example.com');
      expect(matches.length, 0);
    });

    test('matches multiple URLs in text', () {
      final text =
          'check https://a.com and http://b.com for details';
      final matches = urlRegex.allMatches(text);
      expect(matches.length, 2);
    });

    test('does not match plain text without URL', () {
      final matches = urlRegex.allMatches('hello world no links here');
      expect(matches.length, 0);
    });

    test('URI scheme validation for safe URLs', () {
      final safeUrl = Uri.tryParse('https://example.com');
      expect(safeUrl, isNotNull);
      expect(safeUrl!.scheme == 'http' || safeUrl.scheme == 'https', isTrue);
    });

    test('URI scheme validation rejects javascript', () {
      final badUrl = Uri.tryParse('javascript:alert(1)');
      expect(badUrl, isNotNull);
      final isSafe =
          badUrl!.scheme == 'http' || badUrl.scheme == 'https';
      expect(isSafe, isFalse);
    });

    test('URI scheme validation rejects empty scheme', () {
      final noScheme = Uri.tryParse('not-a-url');
      expect(noScheme, isNotNull);
      final isSafe =
          noScheme!.scheme == 'http' || noScheme.scheme == 'https';
      expect(isSafe, isFalse);
    });
  });
}
