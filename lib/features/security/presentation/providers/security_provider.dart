import 'package:flutter_riverpod/flutter_riverpod.dart';

class SecuritySettings {
  final bool pinEnabled;
  final String? pin; // 4자리

  const SecuritySettings({
    this.pinEnabled = false,
    this.pin,
  });

  SecuritySettings copyWith({
    bool? pinEnabled,
    String? pin,
  }) {
    return SecuritySettings(
      pinEnabled: pinEnabled ?? this.pinEnabled,
      pin: pin ?? this.pin,
    );
  }
}

final securityProvider = StateProvider<SecuritySettings>(
  (ref) => const SecuritySettings(),
);

/// 앱 잠금 해제 여부 (앱 시작 시 false, PIN 입력 후 true)
final isUnlockedProvider = StateProvider<bool>((ref) => false);
