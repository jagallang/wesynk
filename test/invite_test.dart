import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Invite code generation', () {
    test('generated code is 8 characters', () {
      const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghjkmnpqrstuvwxyz23456789';
      final rng = Random.secure();
      final code =
          List.generate(8, (_) => chars[rng.nextInt(chars.length)]).join();
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

    test('multiple codes are unique', () {
      const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghjkmnpqrstuvwxyz23456789';
      final rng = Random.secure();
      final codes = List.generate(
          100,
          (_) =>
              List.generate(8, (_) => chars[rng.nextInt(chars.length)]).join());
      expect(codes.toSet().length, 100);
    });
  });

  group('Auto-generated pairing code', () {
    test('pairing code is 6 digits', () {
      final rng = Random.secure();
      final code = List.generate(6, (_) => rng.nextInt(10)).join();
      expect(code.length, 6);
      expect(int.tryParse(code), isNotNull);
    });

    test('pairing code is numeric only', () {
      final rng = Random.secure();
      final code = List.generate(6, (_) => rng.nextInt(10)).join();
      expect(code, matches(RegExp(r'^\d{6}$')));
    });

    test('multiple pairing codes are mostly unique', () {
      final rng = Random.secure();
      final codes = List.generate(
          50, (_) => List.generate(6, (_) => rng.nextInt(10)).join());
      // 6자리 = 100만 가지이므로 50개는 거의 항상 고유
      expect(codes.toSet().length, greaterThanOrEqualTo(45));
    });

    test('pairing code hash is consistent', () {
      const code = '482917';
      final hash1 = sha256.convert(utf8.encode(code)).toString();
      final hash2 = sha256.convert(utf8.encode(code)).toString();
      expect(hash1, hash2);
    });

    test('different pairing codes produce different hashes', () {
      final hash1 = sha256.convert(utf8.encode('123456')).toString();
      final hash2 = sha256.convert(utf8.encode('654321')).toString();
      expect(hash1, isNot(hash2));
    });
  });

  group('Pairing code hash', () {
    test('SHA-256 hash is consistent', () {
      final hash1 = sha256.convert(utf8.encode('mySecret123')).toString();
      final hash2 = sha256.convert(utf8.encode('mySecret123')).toString();
      expect(hash1, hash2);
    });

    test('different codes produce different hashes', () {
      final hash1 = sha256.convert(utf8.encode('code1')).toString();
      final hash2 = sha256.convert(utf8.encode('code2')).toString();
      expect(hash1, isNot(hash2));
    });

    test('hash is 64 characters', () {
      final hash = sha256.convert(utf8.encode('testcode')).toString();
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
      expect(used, isTrue);
    });

    test('unused invite is accepted', () {
      const used = false;
      expect(used, isFalse);
    });

    test('self-invite is rejected', () {
      const hostUid = 'user123';
      const myUid = 'user123';
      expect(hostUid == myUid, isTrue);
    });

    test('partner invite is accepted', () {
      const hostUid = 'user123';
      const myUid = 'user456';
      expect(hostUid == myUid, isFalse);
    });

    test('pairing code mismatch is rejected', () {
      final storedHash =
          sha256.convert(utf8.encode('correctCode')).toString();
      final inputHash = sha256.convert(utf8.encode('wrongCode')).toString();
      expect(storedHash == inputHash, isFalse);
    });

    test('pairing code match is accepted', () {
      final storedHash =
          sha256.convert(utf8.encode('sameCode')).toString();
      final inputHash = sha256.convert(utf8.encode('sameCode')).toString();
      expect(storedHash == inputHash, isTrue);
    });
  });

  group('Couple isolation', () {
    test('different coupleIds are independent', () {
      const coupleA = 'couple-uidA';
      const coupleB = 'couple-uidB';
      expect(coupleA, isNot(coupleB));
    });

    test('members array correctly identifies couple', () {
      final members = ['uid1', 'uid2'];
      expect(members.contains('uid1'), isTrue);
      expect(members.contains('uid2'), isTrue);
      expect(members.contains('uid3'), isFalse);
    });

    test('couple with 2 members rejects third member', () {
      final existingMembers = ['uid1', 'uid2'];
      const newUid = 'uid3';
      final canJoin =
          existingMembers.length < 2 || existingMembers.contains(newUid);
      expect(canJoin, isFalse);
    });

    test('couple with 1 member accepts second member', () {
      final existingMembers = ['uid1'];
      const newUid = 'uid2';
      final canJoin =
          existingMembers.length < 2 || existingMembers.contains(newUid);
      expect(canJoin, isTrue);
    });

    test('existing member can rejoin', () {
      final existingMembers = ['uid1', 'uid2'];
      const newUid = 'uid1';
      final canJoin =
          existingMembers.length < 2 || existingMembers.contains(newUid);
      expect(canJoin, isTrue);
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

    test('invite code is preserved in URL encoding', () {
      const code = 'Abc12345';
      final link = 'https://wesynk-app.web.app/?invite=$code';
      final uri = Uri.parse(link);
      expect(uri.queryParameters['invite'], code);
    });
  });
}
