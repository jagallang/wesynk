import 'package:flutter_test/flutter_test.dart';
import 'package:wesynk/features/security/presentation/providers/security_provider.dart';

void main() {
  group('SecuritySettings', () {
    test('default values', () {
      const s = SecuritySettings();
      expect(s.pinEnabled, isTrue);
      expect(s.pin, isNull);
      expect(s.lockOnTabSwitch, isFalse);
      expect(s.lockOnResume, isTrue);
      expect(s.autoLockDuration, AutoLockDuration.min1);
    });

    test('copyWith changes pinEnabled', () {
      const s = SecuritySettings();
      final s2 = s.copyWith(pinEnabled: false);
      expect(s2.pinEnabled, isFalse);
      expect(s2.lockOnResume, isTrue); // unchanged
    });

    test('copyWith changes lockOnResume', () {
      const s = SecuritySettings();
      final s2 = s.copyWith(lockOnResume: false);
      expect(s2.lockOnResume, isFalse);
      expect(s2.pinEnabled, isTrue); // unchanged
    });

    test('copyWith changes lockOnTabSwitch', () {
      const s = SecuritySettings();
      final s2 = s.copyWith(lockOnTabSwitch: true);
      expect(s2.lockOnTabSwitch, isTrue);
    });

    test('copyWith changes autoLockDuration', () {
      const s = SecuritySettings();
      final s2 = s.copyWith(autoLockDuration: AutoLockDuration.min5);
      expect(s2.autoLockDuration, AutoLockDuration.min5);
      expect(s2.autoLockDuration.seconds, 300);
    });

    test('copyWith changes pin', () {
      const s = SecuritySettings();
      final s2 = s.copyWith(pin: 'hashed_pin_value');
      expect(s2.pin, 'hashed_pin_value');
    });

    test('copyWith preserves all unchanged fields', () {
      final s = const SecuritySettings().copyWith(
        pinEnabled: false,
      );
      expect(s.pin, isNull);
      expect(s.lockOnTabSwitch, isFalse);
      expect(s.lockOnResume, isTrue);
      expect(s.autoLockDuration, AutoLockDuration.min1);
    });

    test('disabled security settings', () {
      const disabled = SecuritySettings(pinEnabled: false);
      expect(disabled.pinEnabled, isFalse);
      expect(disabled.pin, isNull);
      expect(disabled.lockOnResume, isTrue); // lockOnResume default is true
    });
  });

  group('AutoLockDuration', () {
    test('off has 0 seconds', () {
      expect(AutoLockDuration.off.seconds, 0);
      expect(AutoLockDuration.off.labelKo, '끄기');
      expect(AutoLockDuration.off.labelEn, 'Off');
    });

    test('sec30 has 30 seconds', () {
      expect(AutoLockDuration.sec30.seconds, 30);
    });

    test('min1 has 60 seconds', () {
      expect(AutoLockDuration.min1.seconds, 60);
      expect(AutoLockDuration.min1.labelKo, '1분');
    });

    test('min3 has 180 seconds', () {
      expect(AutoLockDuration.min3.seconds, 180);
    });

    test('min5 has 300 seconds', () {
      expect(AutoLockDuration.min5.seconds, 300);
    });

    test('min10 has 600 seconds', () {
      expect(AutoLockDuration.min10.seconds, 600);
      expect(AutoLockDuration.min10.labelEn, '10m');
    });

    test('has 6 values', () {
      expect(AutoLockDuration.values.length, 6);
    });
  });

  group('hashPin', () {
    test('produces consistent hash', () {
      final hash1 = hashPin('1234');
      final hash2 = hashPin('1234');
      expect(hash1, hash2);
    });

    test('different pins produce different hashes', () {
      final hash1 = hashPin('1234');
      final hash2 = hashPin('5678');
      expect(hash1, isNot(hash2));
    });

    test('hash is 64 characters (SHA-256)', () {
      final hash = hashPin('0000');
      expect(hash.length, 64);
    });

    test('hash does not contain original pin', () {
      final hash = hashPin('1234');
      expect(hash.contains('1234'), isFalse);
    });
  });
}
