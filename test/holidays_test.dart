import 'package:flutter_test/flutter_test.dart';
import 'package:wesynk/core/constants/holidays.dart';

void main() {
  group('Holidays', () {
    group('Korean holidays', () {
      test('returns fixed holiday (New Year)', () {
        final result = Holidays.getHoliday(DateTime(2026, 1, 1), isKo: true);
        expect(result, '신정');
      });

      test('returns fixed holiday (Christmas)', () {
        final result = Holidays.getHoliday(DateTime(2026, 12, 25), isKo: true);
        expect(result, '크리스마스');
      });

      test('returns variable holiday (Chuseok 2026)', () {
        final result = Holidays.getHoliday(DateTime(2026, 9, 25), isKo: true);
        expect(result, '추석');
      });

      test('returns variable holiday (Seollal 2026)', () {
        final result = Holidays.getHoliday(DateTime(2026, 2, 17), isKo: true);
        expect(result, '설날');
      });

      test('returns null for non-holiday', () {
        final result = Holidays.getHoliday(DateTime(2026, 4, 15), isKo: true);
        expect(result, isNull);
      });

      test('isHoliday returns true for holiday', () {
        expect(Holidays.isHoliday(DateTime(2026, 3, 1), isKo: true), isTrue);
      });

      test('isHoliday returns false for non-holiday', () {
        expect(Holidays.isHoliday(DateTime(2026, 4, 15), isKo: true), isFalse);
      });
    });

    group('US holidays', () {
      test('returns fixed holiday (Independence Day)', () {
        final result = Holidays.getHoliday(DateTime(2026, 7, 4), isKo: false);
        expect(result, 'Independence Day');
      });

      test('returns variable holiday (Thanksgiving 2026)', () {
        final result = Holidays.getHoliday(DateTime(2026, 11, 26), isKo: false);
        expect(result, 'Thanksgiving');
      });

      test('returns null for non-holiday', () {
        final result = Holidays.getHoliday(DateTime(2026, 4, 15), isKo: false);
        expect(result, isNull);
      });
    });

    group('variable overrides fixed', () {
      test('Children Day 2025 is also Buddha birthday - variable wins', () {
        // 2025-05-05: 부처님오신날 (variable) overrides 어린이날 (fixed)
        final result = Holidays.getHoliday(DateTime(2025, 5, 5), isKo: true);
        expect(result, '부처님오신날');
      });
    });
  });
}
