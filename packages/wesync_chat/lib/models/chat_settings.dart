class ChatSettings {
  /// 기본 휘발 모드 ON/OFF (켜면 모든 메시지가 기본 휘발)
  final bool defaultEphemeral;

  /// 기본 휘발 수명
  final Duration defaultLifetime;

  /// 읽음 표시 보이기
  final bool showReadReceipts;

  /// 입력 중 표시 (향후)
  final bool showTypingIndicator;

  /// 메시지 글자 크기 (small / medium / large)
  final MessageFontSize fontSize;

  /// 알림 표시
  final bool notificationsEnabled;

  /// 채팅 배경 (인덱스)
  final int backgroundIndex;

  const ChatSettings({
    this.defaultEphemeral = false,
    this.defaultLifetime = const Duration(hours: 1),
    this.showReadReceipts = true,
    this.showTypingIndicator = true,
    this.fontSize = MessageFontSize.medium,
    this.notificationsEnabled = true,
    this.backgroundIndex = 0,
  });

  ChatSettings copyWith({
    bool? defaultEphemeral,
    Duration? defaultLifetime,
    bool? showReadReceipts,
    bool? showTypingIndicator,
    MessageFontSize? fontSize,
    bool? notificationsEnabled,
    int? backgroundIndex,
  }) {
    return ChatSettings(
      defaultEphemeral: defaultEphemeral ?? this.defaultEphemeral,
      defaultLifetime: defaultLifetime ?? this.defaultLifetime,
      showReadReceipts: showReadReceipts ?? this.showReadReceipts,
      showTypingIndicator: showTypingIndicator ?? this.showTypingIndicator,
      fontSize: fontSize ?? this.fontSize,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      backgroundIndex: backgroundIndex ?? this.backgroundIndex,
    );
  }
}

enum MessageFontSize {
  small(12, '작게'),
  medium(14, '보통'),
  large(17, '크게');

  final double size;
  final String label;
  const MessageFontSize(this.size, this.label);
}

/// 휘발 수명 프리셋
const ephemeralPresets = <(String, Duration)>[
  ('1분', Duration(minutes: 1)),
  ('10분', Duration(minutes: 10)),
  ('30분', Duration(minutes: 30)),
  ('1시간', Duration(hours: 1)),
  ('6시간', Duration(hours: 6)),
  ('1일', Duration(days: 1)),
  ('7일', Duration(days: 7)),
  ('30일', Duration(days: 30)),
];

String formatLifetime(Duration d) {
  if (d.inDays > 0) return '${d.inDays}일';
  if (d.inHours > 0) return '${d.inHours}시간';
  if (d.inMinutes > 0) return '${d.inMinutes}분';
  return '${d.inSeconds}초';
}
