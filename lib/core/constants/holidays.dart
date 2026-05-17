// 한국 + 미국 공휴일 데이터 (2024~2027)

class Holidays {
  Holidays._();

  /// 한국 고정 공휴일
  static const _koFixed = {
    '01-01': '신정',
    '03-01': '삼일절',
    '05-05': '어린이날',
    '06-06': '현충일',
    '08-15': '광복절',
    '10-03': '개천절',
    '10-09': '한글날',
    '12-25': '크리스마스',
  };

  /// 한국 변동 공휴일 (설날, 추석, 부처님오신날, 대체공휴일 등)
  static const _koVariable = {
    // 2024
    '2024-02-09': '설날 연휴',
    '2024-02-10': '설날',
    '2024-02-11': '설날 연휴',
    '2024-02-12': '대체공휴일',
    '2024-05-15': '부처님오신날',
    '2024-09-16': '추석 연휴',
    '2024-09-17': '추석',
    '2024-09-18': '추석 연휴',
    // 2025
    '2025-01-28': '설날 연휴',
    '2025-01-29': '설날',
    '2025-01-30': '설날 연휴',
    '2025-05-05': '부처님오신날',
    '2025-10-05': '추석 연휴',
    '2025-10-06': '추석',
    '2025-10-07': '추석 연휴',
    '2025-10-08': '대체공휴일',
    // 2026
    '2026-02-16': '설날 연휴',
    '2026-02-17': '설날',
    '2026-02-18': '설날 연휴',
    '2026-05-24': '부처님오신날',
    '2026-09-24': '추석 연휴',
    '2026-09-25': '추석',
    '2026-09-26': '추석 연휴',
    // 2027
    '2027-02-06': '설날 연휴',
    '2027-02-07': '설날',
    '2027-02-08': '설날 연휴',
    '2027-02-09': '대체공휴일',
    '2027-05-13': '부처님오신날',
    '2027-09-14': '추석 연휴',
    '2027-09-15': '추석',
    '2027-09-16': '추석 연휴',
  };

  /// 미국 고정 공휴일
  static const _usFixed = {
    '01-01': "New Year's Day",
    '06-19': 'Juneteenth',
    '07-04': 'Independence Day',
    '11-11': "Veterans Day",
    '12-25': 'Christmas Day',
  };

  /// 미국 변동 공휴일 (MLK Day, Presidents Day, Memorial Day, Labor Day, Thanksgiving 등)
  static const _usVariable = {
    // 2024
    '2024-01-15': 'MLK Day',
    '2024-02-19': "Presidents' Day",
    '2024-05-27': 'Memorial Day',
    '2024-09-02': 'Labor Day',
    '2024-10-14': 'Columbus Day',
    '2024-11-28': 'Thanksgiving',
    // 2025
    '2025-01-20': 'MLK Day',
    '2025-02-17': "Presidents' Day",
    '2025-05-26': 'Memorial Day',
    '2025-09-01': 'Labor Day',
    '2025-10-13': 'Columbus Day',
    '2025-11-27': 'Thanksgiving',
    // 2026
    '2026-01-19': 'MLK Day',
    '2026-02-16': "Presidents' Day",
    '2026-05-25': 'Memorial Day',
    '2026-09-07': 'Labor Day',
    '2026-10-12': 'Columbus Day',
    '2026-11-26': 'Thanksgiving',
    // 2027
    '2027-01-18': 'MLK Day',
    '2027-02-15': "Presidents' Day",
    '2027-05-31': 'Memorial Day',
    '2027-09-06': 'Labor Day',
    '2027-10-11': 'Columbus Day',
    '2027-11-25': 'Thanksgiving',
  };

  /// 특정 날짜의 공휴일 이름 반환 (없으면 null)
  static String? getHoliday(DateTime date, {required bool isKo}) {
    final fixed = isKo ? _koFixed : _usFixed;
    final variable = isKo ? _koVariable : _usVariable;

    final mmdd =
        '${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    final yyyymmdd =
        '${date.year}-$mmdd';

    // 변동 공휴일 우선 (고정보다 구체적)
    if (variable.containsKey(yyyymmdd)) return variable[yyyymmdd];
    if (fixed.containsKey(mmdd)) return fixed[mmdd];
    return null;
  }

  /// 특정 날짜가 공휴일인지 여부
  static bool isHoliday(DateTime date, {required bool isKo}) {
    return getHoliday(date, isKo: isKo) != null;
  }
}
