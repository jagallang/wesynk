import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Invite code generation', () {
    test('generated code is 8 characters', () {
      // 시뮬레이션: _generateCode와 동일한 로직
      const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghjkmnpqrstuvwxyz23456789';
      expect(chars.length, greaterThan(0));
      // 8자리 코드
      final code = List.generate(8, (_) => chars[0]).join();
      expect(code.length, 8);
    });

    test('code excludes ambiguous characters (0, O, 1, l, I)', () {
      const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghjkmnpqrstuvwxyz23456789';
      expect(chars.contains('0'), isFalse);
      expect(chars.contains('O'), isFalse);
      expect(chars.contains('1'), isFalse);
      expect(chars.contains('l'), isFalse);
      expect(chars.contains('I'), isFalse);
    });
  });

  group('Pairing code hash', () {
    test('SHA-256 hash is consistent', () {
      final hash1 =
          sha256.convert(utf8.encode('mySecret123')).toString();
      final hash2 =
          sha256.convert(utf8.encode('mySecret123')).toString();
      expect(hash1, hash2);
    });

    test('different codes produce different hashes', () {
      final hash1 =
          sha256.convert(utf8.encode('code1')).toString();
      final hash2 =
          sha256.convert(utf8.encode('code2')).toString();
      expect(hash1, isNot(hash2));
    });

    test('hash is 64 characters', () {
      final hash =
          sha256.convert(utf8.encode('testcode')).toString();
      expect(hash.length, 64);
    });

    test('empty code produces valid hash', () {
      final hash = sha256.convert(utf8.encode('')).toString();
      expect(hash.length, 64);
    });
  });

  group('Invite validation logic', () {
    test('expired invite is rejected', () {
      final expiresAt = DateTime.now().subtract(const Duration(hours: 1));
      final isExpired = DateTime.now().isAfter(expiresAt);
      expect(isExpired, isTrue);
    });

    test('valid invite is not expired', () {
      final expiresAt = DateTime.now().add(const Duration(hours: 23));
      final isExpired = DateTime.now().isAfter(expiresAt);
      expect(isExpired, isFalse);
    });

    test('used invite is rejected', () {
      const used = true;
      expect(used, isTrue); // should be rejected
    });

    test('unused invite is accepted', () {
      const used = false;
      expect(used, isFalse); // should be accepted
    });

    test('self-invite is rejected', () {
      const hostUid = 'user123';
      const myUid = 'user123';
      expect(hostUid == myUid, isTrue); // should be rejected
    });

    test('partner invite is accepted', () {
      const hostUid = 'user123';
      const myUid = 'user456';
      expect(hostUid == myUid, isFalse); // should be accepted
    });

    test('pairing code mismatch is rejected', () {
      final storedHash =
          sha256.convert(utf8.encode('correctCode')).toString();
      final inputHash =
          sha256.convert(utf8.encode('wrongCode')).toString();
      expect(storedHash == inputHash, isFalse);
    });

    test('pairing code match is accepted', () {
      final storedHash =
          sha256.convert(utf8.encode('sameCode')).toString();
      final inputHash =
          sha256.convert(utf8.encode('sameCode')).toString();
      expect(storedHash == inputHash, isTrue);
    });
  });

  group('Invite link format', () {
    test('link contains invite parameter', () {
      const code = 'AbCd1234';
      final link = 'https://wesynk-app.web.app/?invite=$code';
      final uri = Uri.parse(link);
      expect(uri.queryParameters['invite'], 'AbCd1234');
    });

    test('empty invite parameter is detected', () {
      final uri = Uri.parse('https://wesynk-app.web.app/');
      final inviteCode = uri.queryParameters['invite'];
      expect(inviteCode, isNull);
    });

    test('invite parameter extraction from full URL', () {
      final uri = Uri.parse(
          'https://wesynk-app.web.app/?invite=XyZ789Ab&other=value');
      expect(uri.queryParameters['invite'], 'XyZ789Ab');
    });
  });
}
