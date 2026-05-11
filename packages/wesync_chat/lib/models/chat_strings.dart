/// wesync_chat 패키지 내부 문자열 다국어 지원
class CS {
  CS._();

  static bool isKo = true;

  static String get chatTitle => isKo ? '우리' : 'Us';
  static String get chatEmpty => isKo ? '아직 대화가 없어요' : 'No messages yet';
  static String get chatFirst => isKo ? '첫 메시지를 보내보세요' : 'Send the first message';
  static String get chatInput => isKo ? '메시지 입력...' : 'Type a message...';
  static String get chatRead => isKo ? '읽음' : 'Read';
  static String get copy => isKo ? '복사' : 'Copy';
  static String get copied => isKo ? '복사됨' : 'Copied';
  static String get delete => isKo ? '삭제' : 'Delete';
  static String get ephemeral => isKo ? '휘발 메시지' : 'Ephemeral';
  static String get messageMode => isKo ? '메시지 보관 방식' : 'Message Mode';
  static String get permanent => isKo ? '영구 저장' : 'Keep forever';
  static String get permanentDesc => isKo ? '메시지가 삭제 전까지 보관됩니다' : 'Kept until deleted';
  static String get ephemeralSection => isKo ? '휘발 메시지 (자동 사라짐)' : 'Ephemeral (auto-delete)';
  static String ephemeralHint(String t) => isKo ? '$t 후 사라질 메시지' : 'Disappears after $t';
  static String ephemeralTooltip(String t) => isKo ? '$t 휘발 (탭하면 해제)' : '$t ephemeral (tap to disable)';
  static String get pickLifetime => isKo ? '얼마 후 사라질까요?' : 'When should it disappear?';

  // 채팅 설정
  static String get settings => isKo ? '채팅 설정' : 'Chat Settings';
  static String get defaultEphemeral => isKo ? '기본 휘발 모드' : 'Default Ephemeral';
  static String defaultEphemeralOn(String t) => isKo ? '모든 메시지가 $t 후 사라짐' : 'All messages disappear after $t';
  static String get defaultEphemeralOff => isKo ? '수동으로 휘발 토글 시에만 적용' : 'Only when manually toggled';
  static String get defaultLifetime => isKo ? '기본 휘발 시간' : 'Default Lifetime';
  static String get showRead => isKo ? '읽음 표시' : 'Read Receipts';
  static String get showReadDesc => isKo ? '상대가 읽었는지 표시' : 'Show when partner has read';
  static String get fontSize => isKo ? '글자 크기' : 'Font Size';
  static String get background => isKo ? '채팅 배경' : 'Chat Background';
  static String get notification => isKo ? '채팅 알림' : 'Chat Notifications';
  static String get notificationDesc => isKo ? '새 메시지 알림 받기' : 'Get notified for new messages';
  static String get manage => isKo ? '대화 관리' : 'Manage';
  static String get cleanExpired => isKo ? '만료된 메시지 정리' : 'Clean Expired Messages';
  static String get cleanExpiredDesc => isKo ? '숨김 처리된 휘발 메시지 목록 정리' : 'Remove hidden ephemeral messages';
  static String get export => isKo ? '대화 내보내기' : 'Export Chat';
  static String get exportDesc => isKo ? '텍스트 파일로 저장' : 'Save as text file';
  static String get cleaned => isKo ? '만료 메시지 정리됨' : 'Expired messages cleaned';
  static String get exportSoon => isKo ? '대화 내보내기 - Phase 2에서 구현 예정' : 'Export - coming soon';
  static String get display => isKo ? '표시' : 'Display';

  // 시간
  static String daysAfter(int n) => isKo ? '$n일 후' : 'in ${n}d';
  static String hoursAfter(int n) => isKo ? '$n시간 후' : 'in ${n}h';
  static String minutesAfter(int n) => isKo ? '$n분 후' : 'in ${n}m';
  static String secondsAfter(int n) => isKo ? '$n초 후' : 'in ${n}s';

  static List<String> get lifetimeLabels => isKo
      ? ['1분', '10분', '30분', '1시간', '6시간', '1일', '7일', '30일']
      : ['1m', '10m', '30m', '1h', '6h', '1d', '7d', '30d'];

  static List<String> get fontSizeLabels => isKo
      ? ['작게', '보통', '크게']
      : ['Small', 'Medium', 'Large'];
}
