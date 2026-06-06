import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

/// Firestore에 보안 설정 저장 (users/{uid}/security — 개인 문서)
Future<void> saveSecurityToFirestore(WidgetRef ref) async {
  final security = ref.read(securityProvider);
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return;
  await FirebaseFirestore.instance.collection('users').doc(uid).set({
    'security': {
      'pinEnabled': security.pinEnabled,
      'pinHash': security.pin,
      'lockOnTabSwitch': security.lockOnTabSwitch,
      'lockOnResume': security.lockOnResume,
      'autoLockDuration': security.autoLockDuration.name,
    },
  }, SetOptions(merge: true));
}

/// Firestore에서 보안 설정 로드 (users/{uid}/security)
Future<SecuritySettings> loadSecurityFromFirestore() async {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return const SecuritySettings();
  final doc =
      await FirebaseFirestore.instance.collection('users').doc(uid).get();
  final s = (doc.data()?['security'] as Map<String, dynamic>?) ?? {};
  return SecuritySettings(
    pinEnabled: s['pinEnabled'] as bool? ?? true,
    pin: s['pinHash'] as String?,
    lockOnTabSwitch: s['lockOnTabSwitch'] as bool? ?? false,
    lockOnResume: s['lockOnResume'] as bool? ?? true,
    autoLockDuration: AutoLockDuration.values.firstWhere(
      (d) => d.name == (s['autoLockDuration'] as String?),
      orElse: () => AutoLockDuration.min1,
    ),
  );
}
