import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/preferences_service.dart';

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

  static AutoLockDuration fromName(String name) {
    return AutoLockDuration.values.firstWhere(
      (e) => e.name == name,
      orElse: () => AutoLockDuration.off,
    );
  }
}

class SecuritySettings {
  final bool pinEnabled;
  final String? pin;

  /// 탭 전환 시 PIN 요구 (강화 모드)
  final bool lockOnTabSwitch;

  /// 자동 잠금 시간 (비활동 시)
  final AutoLockDuration autoLockDuration;

  const SecuritySettings({
    this.pinEnabled = false,
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

/// 보안 설정 (영구 저장 연동)
class SecurityNotifier extends StateNotifier<SecuritySettings> {
  SecurityNotifier() : super(const SecuritySettings()) {
    _loadFromPrefs();
  }

  Future<void> _loadFromPrefs() async {
    final prefs = PreferencesService();
    final pin = await prefs.getPin();
    state = SecuritySettings(
      pinEnabled: prefs.pinEnabled,
      pin: pin,
      lockOnTabSwitch: prefs.lockOnTabSwitch,
      autoLockDuration: AutoLockDuration.fromName(prefs.autoLockDuration),
    );
  }

  Future<void> update(SecuritySettings settings) async {
    state = settings;
    final prefs = PreferencesService();
    await prefs.setPinEnabled(settings.pinEnabled);
    await prefs.setLockOnTabSwitch(settings.lockOnTabSwitch);
    await prefs.setAutoLockDuration(settings.autoLockDuration.name);
    await prefs.setPin(settings.pin);
  }

  Future<void> reset() async {
    state = const SecuritySettings();
    final prefs = PreferencesService();
    await prefs.setPinEnabled(false);
    await prefs.setLockOnTabSwitch(false);
    await prefs.setAutoLockDuration('off');
    await prefs.setPin(null);
  }
}

final securityProvider =
    StateNotifierProvider<SecurityNotifier, SecuritySettings>(
  (ref) => SecurityNotifier(),
);

/// 앱 잠금 해제 여부
final isUnlockedProvider = StateProvider<bool>((ref) => false);

/// 마지막 활동 시간 (자동 잠금용)
final lastActivityProvider = StateProvider<DateTime>((ref) => DateTime.now());
