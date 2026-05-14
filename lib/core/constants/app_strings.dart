import 'package:flutter_riverpod/flutter_riverpod.dart';

enum AppLanguage {
  ko('한국어'),
  en('English');

  final String label;
  const AppLanguage(this.label);
}

final appLanguageProvider = StateProvider<AppLanguage>((ref) => AppLanguage.ko);

class S {
  S._();

  static AppLanguage _lang = AppLanguage.ko;

  static void setLanguage(AppLanguage lang) => _lang = lang;
  static bool get isKo => _lang == AppLanguage.ko;

  // ─── 공통 ───
  static String get appName => isKo ? 'WeSync' : 'WeSync';
  static String get error => isKo ? '오류' : 'Error';
  static String get cancel => isKo ? '취소' : 'Cancel';
  static String get confirm => isKo ? '확인' : 'OK';
  static String get add => isKo ? '추가' : 'Add';
  static String get change => isKo ? '변경' : 'Change';
  static String get delete => isKo ? '삭제' : 'Delete';
  static String get copy => isKo ? '복사' : 'Copy';
  static String get copied => isKo ? '복사됨' : 'Copied';

  // ─── 탭 ───
  static String get tabTravel => isKo ? '일정' : 'Schedule';
  static String get tabFood => isKo ? '마실' : 'Outing';
  static String get tabNote => isKo ? '일기' : 'Diary';
  static String get tabPhoto => isKo ? '사진' : 'Photos';

  // ─── 하단 네비게이션 ───
  static String get navCalendar => isKo ? '캘린더' : 'Calendar';
  static String get navChat => isKo ? '채팅' : 'Chat';
  static String get navAlbum => isKo ? '앨범' : 'Album';
  static String get navSettings => isKo ? '설정' : 'Settings';

  // ─── 캘린더 ───
  static String get calendarMonth => isKo ? '월간' : 'Month';
  static String get calendarWeek => isKo ? '주간' : 'Week';
  static String noItemForDay(String type) =>
      isKo ? '이 날 $type 없음' : 'No $type for this day';
  static String get addWithButton => isKo ? '아래 + 버튼으로 추가' : 'Tap + to add';

  // ─── 아이템 추가 ───
  static String addTitle(String type) =>
      isKo ? '$type 추가' : 'Add $type';
  static String get fieldTitle => isKo ? '제목' : 'Title';
  static String get fieldLocation => isKo ? '장소 (선택)' : 'Location (optional)';
  static String get fieldPlace => isKo ? '장소' : 'Place';
  static String get fieldRating => isKo ? '평점: ' : 'Rating: ';
  static String get fieldReview => isKo ? '후기 (선택)' : 'Review (optional)';
  static String get noteHint => isKo ? '오늘의 이야기...' : "Today's story...";
  static String get noteAdd => isKo ? '메모 추가' : 'Add Note';
  static String get dateRecord => isKo ? '데이트 기록' : 'Date Record';
  static String get photoPlaceholder =>
      isKo ? '사진 업로드 - Phase 3에서 구현 예정' : 'Photo upload - coming soon';

  // ─── 로그인 ───
  static String get loginSubtitle =>
      isKo ? '둘만의 공유 캘린더 + 채팅' : 'Shared calendar + chat for two';
  static String get loginWithGoogle =>
      isKo ? 'Google로 시작하기' : 'Sign in with Google';
  static String get loginLoading => isKo ? '로그인 중...' : 'Signing in...';
  static String loginFailed(String e) =>
      isKo ? '로그인 실패: $e' : 'Sign in failed: $e';

  // ─── 설정 ───
  static String get settingsTitle => isKo ? '설정' : 'Settings';
  static String get myProfile => isKo ? '내 프로필' : 'My Profile';
  static String get profilePlaceholder =>
      isKo ? '로그인 후 표시됩니다' : 'Shown after sign in';
  static String get partner => isKo ? '파트너' : 'Partner';
  static String get partnerPlaceholder =>
      isKo ? '파트너 이메일을 등록하세요' : 'Register partner email';
  static String get pairingDesc =>
      isKo ? '서로의 이메일을 입력하면 자동으로 매칭됩니다. 두 사람 모두 상대방의 이메일을 입력해야 연결됩니다.'
          : 'Enter each other\'s email to auto-match. Both must enter each other\'s email.';
  static String get myEmail => isKo ? '내 이메일' : 'My Email';
  static String get partnerEmail => isKo ? '파트너 이메일' : 'Partner Email';
  static String get partnerEmailHint => isKo ? 'partner@gmail.com' : 'partner@gmail.com';
  static String get requestPairing => isKo ? '페어링 요청' : 'Request Pairing';
  static String get pairingPending =>
      isKo ? '파트너의 수락을 기다리는 중...' : 'Waiting for partner to accept...';
  static String get acceptPairing => isKo ? '페어링 수락' : 'Accept Pairing';
  static String get rejectPairing => isKo ? '거부' : 'Reject';
  static String get pairingSuccess => isKo ? '페어링 성공!' : 'Paired successfully!';
  static String get pairingFailed => isKo ? '페어링 실패' : 'Pairing failed';
  static String get invalidEmail => isKo ? '올바른 이메일을 입력하세요' : 'Enter a valid email';
  static String get partnerConnected => isKo ? '파트너 연결됨' : 'Partner connected';
  static String get disconnect => isKo ? '연결 해제' : 'Disconnect';
  static String get pairingRequest =>
      isKo ? '페어링 요청이 있습니다' : 'You have a pairing request';
  static String get customize => isKo ? '앱 꾸미기' : 'Customize';
  static String get appNameSetting => isKo ? '앱 이름' : 'App Name';
  static String get appIcon => isKo ? '앱 아이콘' : 'App Icon';
  static String get themeColor => isKo ? '테마 색상' : 'Theme Color';
  static String get bgColor => isKo ? '배경 색상' : 'Background';
  static String get security => isKo ? '보안' : 'Security';
  static String get appLock => isKo ? '앱 잠금 (비밀번호)' : 'App Lock (PIN)';
  static String get appLockOn =>
      isKo ? '앱 시작 시 4자리 비밀번호 입력' : '4-digit PIN on app launch';
  static String get appLockOff => isKo ? '꺼짐' : 'Off';
  static String get changePin => isKo ? '비밀번호 변경' : 'Change PIN';
  static String get lockOnTabSwitch =>
      isKo ? '탭 전환 시 잠금' : 'Lock on Tab Switch';
  static String get lockOnTabSwitchDesc =>
      isKo ? '캘린더/채팅/앨범/설정 이동 시 비밀번호 입력' : 'Require PIN when switching tabs';
  static String get autoLock => isKo ? '자동 잠금' : 'Auto Lock';
  static String get autoLockDesc =>
      isKo ? '비활동 시 자동으로 잠금' : 'Lock after inactivity';
  static String get appInfo => isKo ? '앱 정보' : 'App Info';
  static String get logout => isKo ? '로그아웃' : 'Sign Out';
  static String get changeAppName => isKo ? '앱 이름 변경' : 'Change App Name';
  static String get newAppName => isKo ? '새 앱 이름' : 'New app name';
  static String get language => isKo ? '언어' : 'Language';

  // ─── PIN ───
  static String get pinEnter => isKo ? '비밀번호를 입력하세요' : 'Enter your PIN';
  static String get pinNew => isKo ? '새 비밀번호 입력' : 'Enter new PIN';
  static String get pinConfirm => isKo ? '비밀번호 확인' : 'Confirm PIN';
  static String get pinCurrent => isKo ? '현재 비밀번호 입력' : 'Enter current PIN';
  static String get pinWrong => isKo ? '비밀번호가 틀렸습니다' : 'Wrong PIN';
  static String get pinMismatch =>
      isKo ? '비밀번호가 일치하지 않습니다. 다시 입력하세요' : "PINs don't match. Try again";

  // ─── 앨범 ───
  static String get albumTitle => isKo ? '앨범' : 'Album';
  static String get albumEmpty => isKo ? '사진이 없습니다' : 'No photos yet';

  // ─── 채팅 ───
  static String get chatTitle => isKo ? '우리' : 'Us';
  static String get chatEmpty => isKo ? '아직 대화가 없어요' : 'No messages yet';
  static String get chatFirst =>
      isKo ? '첫 메시지를 보내보세요' : 'Send the first message';
  static String get chatInput => isKo ? '메시지 입력...' : 'Type a message...';
  static String get chatRead => isKo ? '읽음' : 'Read';
  static String get chatEphemeral => isKo ? '휘발 메시지' : 'Ephemeral';
  static String get chatMessageMode => isKo ? '메시지 보관 방식' : 'Message Mode';
  static String get chatPermanent => isKo ? '영구 저장' : 'Keep forever';
  static String get chatPermanentDesc =>
      isKo ? '메시지가 삭제 전까지 보관됩니다' : 'Message is kept until deleted';
  static String get chatEphemeralSection =>
      isKo ? '휘발 메시지 (자동 사라짐)' : 'Ephemeral (auto-delete)';
  static String chatEphemeralHint(String time) =>
      isKo ? '$time 후 사라질 메시지' : 'Disappears after $time';
  static String chatEphemeralTooltip(String time) =>
      isKo ? '$time 휘발 (탭하면 해제)' : '$time ephemeral (tap to disable)';
  static String get chatPickLifetime =>
      isKo ? '얼마 후 사라질까요?' : 'When should it disappear?';

  // ─── 채팅 설정 ───
  static String get chatSettings => isKo ? '채팅 설정' : 'Chat Settings';
  static String get chatDefaultEphemeral => isKo ? '기본 휘발 모드' : 'Default Ephemeral';
  static String chatDefaultEphemeralOn(String time) =>
      isKo ? '모든 메시지가 $time 후 사라짐' : 'All messages disappear after $time';
  static String get chatDefaultEphemeralOff =>
      isKo ? '수동으로 휘발 토글 시에만 적용' : 'Only when manually toggled';
  static String get chatDefaultLifetime => isKo ? '기본 휘발 시간' : 'Default Lifetime';
  static String get chatShowRead => isKo ? '읽음 표시' : 'Read Receipts';
  static String get chatShowReadDesc =>
      isKo ? '상대가 읽었는지 표시' : 'Show when partner has read';
  static String get chatFontSize => isKo ? '글자 크기' : 'Font Size';
  static String get chatBackground => isKo ? '채팅 배경' : 'Chat Background';
  static String get chatNotification => isKo ? '채팅 알림' : 'Chat Notifications';
  static String get chatNotificationDesc =>
      isKo ? '새 메시지 알림 받기' : 'Get notified for new messages';
  static String get chatManage => isKo ? '대화 관리' : 'Manage';
  static String get chatCleanExpired =>
      isKo ? '만료된 메시지 정리' : 'Clean Expired Messages';
  static String get chatCleanExpiredDesc =>
      isKo ? '숨김 처리된 휘발 메시지 목록 정리' : 'Remove hidden ephemeral messages';
  static String get chatExport => isKo ? '대화 내보내기' : 'Export Chat';
  static String get chatExportDesc =>
      isKo ? '텍스트 파일로 저장' : 'Save as text file';
  static String get chatCleaned => isKo ? '만료 메시지 정리됨' : 'Expired messages cleaned';
  static String get chatExportSoon =>
      isKo ? '대화 내보내기 - Phase 2에서 구현 예정' : 'Export - coming soon';
  static String get display => isKo ? '표시' : 'Display';
  static String get notification => isKo ? '알림' : 'Notification';

  // ─── 휘발 시간 ───
  static String daysAfter(int n) => isKo ? '$n일 후' : 'in ${n}d';
  static String hoursAfter(int n) => isKo ? '$n시간 후' : 'in ${n}h';
  static String minutesAfter(int n) => isKo ? '$n분 후' : 'in ${n}m';
  static String secondsAfter(int n) => isKo ? '$n초 후' : 'in ${n}s';

  // ─── 프리셋 이름 ───
  static List<String> get colorNames => isKo
      ? ['코랄핑크', '라벤더', '스카이블루', '민트', '피치', '로즈골드', '인디고', '슬레이트']
      : ['Coral', 'Lavender', 'Sky Blue', 'Mint', 'Peach', 'Rose Gold', 'Indigo', 'Slate'];

  static List<String> get iconNames => isKo
      ? ['하트', '반려동물', '공원', '커피', '별', '다이아', '스파', '여행']
      : ['Heart', 'Pets', 'Park', 'Coffee', 'Star', 'Diamond', 'Spa', 'Travel'];

  static List<String> get bgNames => isKo
      ? ['웜크림', '쿨화이트', '라벤더', '민트', '핑크', '스카이', '그레이', '다크']
      : ['Warm', 'Cool', 'Lavender', 'Mint', 'Pink', 'Sky', 'Grey', 'Dark'];

  static List<String> get fontSizeLabels => isKo
      ? ['작게', '보통', '크게']
      : ['Small', 'Medium', 'Large'];

  static List<String> get lifetimeLabels => isKo
      ? ['1분', '10분', '30분', '1시간', '6시간', '1일', '7일', '30일']
      : ['1m', '10m', '30m', '1h', '6h', '1d', '7d', '30d'];
}
