import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../home/presentation/providers/home_providers.dart';

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

  /// 앱 복귀 시 항상 잠금
  final bool lockOnResume;

  /// 자동 잠금 시간 (비활동 시)
  final AutoLockDuration autoLockDuration;

  const SecuritySettings({
    this.pinEnabled = true,
    this.pin,
    this.lockOnTabSwitch = false,
    this.lockOnResume = true,
    this.autoLockDuration = AutoLockDuration.min1,
  });

  SecuritySettings copyWith({
    bool? pinEnabled,
    String? pin,
    bool? lockOnTabSwitch,
    bool? lockOnResume,
    AutoLockDuration? autoLockDuration,
  }) {
    return SecuritySettings(
      pinEnabled: pinEnabled ?? this.pinEnabled,
      pin: pin ?? this.pin,
      lockOnTabSwitch: lockOnTabSwitch ?? this.lockOnTabSwitch,
      lockOnResume: lockOnResume ?? this.lockOnResume,
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

/// PIN을 SHA-256 해시로 변환
String hashPin(String pin) {
  final bytes = utf8.encode(pin);
  return sha256.convert(bytes).toString();
}

/// Firestore에 보안 설정 저장 (PIN은 이미 해시된 상태)
Future<void> saveSecurityToFirestore(WidgetRef ref) async {
  final security = ref.read(securityProvider);
  final coupleId = ref.read(coupleIdProvider);
  if (coupleId == 'uninitialized') return;
  final service = ref.read(firestoreServiceProvider);
  await service.saveSettings(coupleId: coupleId, settings: {
    'pinEnabled': security.pinEnabled,
    'pinHash': security.pin,
    'lockOnTabSwitch': security.lockOnTabSwitch,
    'lockOnResume': security.lockOnResume,
    'autoLockDuration': security.autoLockDuration.name,
  });
}
