import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AutoLockDuration {
  off(0, '끄기', 'Off'),
  sec30(30, '30초', '30s'),
  min1(60, '1분', '1m'),
  min3(180, '3분', '3m'),
  min5(300, '5분', '5m'),
  min10(600, '10분', '10m');

  final int seconds;
  final String labelKo;
  final String labelEn;
  const AutoLockDuration(this.seconds, this.labelKo, this.labelEn);
}

class SecuritySettings {
  final bool pinEnabled;
  final String? pin;

  /// 탭 전환 시 PIN 요구 (강화 모드)
  final bool lockOnTabSwitch;

  /// 자동 잠금 시간 (비활동 시)
  final AutoLockDuration autoLockDuration;

  const SecuritySettings({
    this.pinEnabled = true,
    this.pin,
    this.lockOnTabSwitch = false,
    this.autoLockDuration = AutoLockDuration.off,
  });

  SecuritySettings copyWith({
    bool? pinEnabled,
    String? pin,
    bool? lockOnTabSwitch,
    AutoLockDuration? autoLockDuration,
  }) {
    return SecuritySettings(
      pinEnabled: pinEnabled ?? this.pinEnabled,
      pin: pin ?? this.pin,
      lockOnTabSwitch: lockOnTabSwitch ?? this.lockOnTabSwitch,
      autoLockDuration: autoLockDuration ?? this.autoLockDuration,
    );
  }
}

final securityProvider = StateProvider<SecuritySettings>(
  (ref) => const SecuritySettings(),
);

/// 앱 잠금 해제 여부
final isUnlockedProvider = StateProvider<bool>((ref) => false);

/// 마지막 활동 시간 (자동 잠금용)
final lastActivityProvider = StateProvider<DateTime>((ref) => DateTime.now());

/// SharedPreferences에 보안 설정 저장
Future<void> saveSecurityToLocal(SecuritySettings s) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool('pinEnabled', s.pinEnabled);
  if (s.pin != null) {
    await prefs.setString('pin', s.pin!);
  } else {
    await prefs.remove('pin');
  }
  await prefs.setBool('lockOnTabSwitch', s.lockOnTabSwitch);
  await prefs.setString('autoLockDuration', s.autoLockDuration.name);
}

/// SharedPreferences에서 보안 설정 로드
Future<SecuritySettings> loadSecurityFromLocal() async {
  final prefs = await SharedPreferences.getInstance();
  final pinEnabled = prefs.getBool('pinEnabled') ?? true;
  final pin = prefs.getString('pin');
  final lockOnTabSwitch = prefs.getBool('lockOnTabSwitch') ?? false;
  final autoLockName = prefs.getString('autoLockDuration');
  final autoLockDuration = AutoLockDuration.values.firstWhere(
    (d) => d.name == autoLockName,
    orElse: () => AutoLockDuration.off,
  );
  return SecuritySettings(
    pinEnabled: pinEnabled,
    pin: pin,
    lockOnTabSwitch: lockOnTabSwitch,
    autoLockDuration: autoLockDuration,
  );
}

/// SharedPreferences에서 보안 설정 삭제
Future<void> clearSecurityFromLocal() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove('pinEnabled');
  await prefs.remove('pin');
  await prefs.remove('lockOnTabSwitch');
  await prefs.remove('autoLockDuration');
}
