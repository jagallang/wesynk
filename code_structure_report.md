# WeSync 코드 구조 문서 (v2.7.1)

> 최종 갱신: 2026-05-13 리팩토링 후 스냅샷

---

## 1. 프로젝트 개요

| 항목 | 값 |
|------|-----|
| 앱 이름 | WeSync — 커플 공유 캘린더·일기·앨범·채팅 |
| 버전 | 2.7.1+1 (pubspec.yaml) |
| Flutter | 3.29.2 (Dart 3.7.2) |
| Firebase 프로젝트 | wesynk-app (ID: 242440576982) |
| 배포 URL | https://wesynk-app.web.app |
| 상태 관리 | Riverpod 2.6.1 |
| 총 파일 수 | 30개 Dart 파일 (lib/) + 9개 (wesync_chat 패키지) |
| 총 코드 | ~5,175 LOC (lib/) |

---

## 2. 디렉토리 트리

```
wesynk/
├── lib/
│   ├── main.dart                          (22줄) 앱 진입점
│   ├── app.dart                          (106줄) 루트 위젯 + AuthGate
│   ├── firebase_options.dart              (74줄) [자동생성]
│   │
│   ├── core/
│   │   ├── constants/
│   │   │   ├── app_colors.dart            (33줄) 색상 팔레트
│   │   │   └── app_strings.dart          (221줄) 한/영 문자열 + AppLanguage
│   │   ├── services/
│   │   │   ├── firestore_service.dart    (365줄) Firestore CRUD + 페어링
│   │   │   ├── photo_service.dart        (373줄) 사진 업로드/삭제 + PhotoItem 모델
│   │   │   ├── google_calendar_service.dart (116줄) Google Calendar API
│   │   │   └── preferences_service.dart  (112줄) SharedPreferences + SecureStorage
│   │   └── theme/
│   │       └── app_theme.dart             (74줄) Material 3 테마 팩토리
│   │
│   ├── features/
│   │   ├── auth/
│   │   │   └── presentation/
│   │   │       ├── pages/login_page.dart   (82줄) Google Sign-In UI
│   │   │       └── providers/auth_provider.dart (63줄) Firebase Auth + OAuth
│   │   │
│   │   ├── home/
│   │   │   └── presentation/
│   │   │       ├── pages/home_page.dart   (318줄) 메인 화면 + 4탭 네비게이션
│   │   │       ├── providers/
│   │   │       │   ├── home_providers.dart (242줄) 앱 커스터마이즈 + 데이터 프로바이더
│   │   │       │   └── photo_providers.dart (22줄) 사진 스트림
│   │   │       └── widgets/
│   │   │           ├── monthly_calendar.dart (158줄) 캘린더 위젯
│   │   │           ├── day_tab_content.dart  (179줄) 탭별 콘텐츠
│   │   │           ├── item_card.dart       (201줄) 아이템 카드 + 액션
│   │   │           ├── item_form_sheets.dart (232줄) 일정/일기/데이트 추가 폼
│   │   │           └── item_edit_sheets.dart (190줄) 일정/일기/데이트 수정 폼
│   │   │
│   │   ├── album/
│   │   │   └── presentation/pages/
│   │   │       └── album_page.dart        (441줄) 앨범 그리드 + 영상 재생
│   │   │
│   │   ├── settings/
│   │   │   └── presentation/
│   │   │       ├── pages/settings_page.dart (583줄) 설정 메인 + 커스터마이즈
│   │   │       └── widgets/
│   │   │           ├── partner_card.dart   (278줄) 페어링 카드 + 매칭 상태
│   │   │           └── security_card.dart  (119줄) PIN/보안 설정
│   │   │
│   │   └── security/
│   │       └── presentation/
│   │           ├── pages/pin_screen.dart   (223줄) PIN 입력 UI
│   │           └── providers/security_provider.dart (102줄) 보안 설정 + 영구저장
│   │
│   └── shared/
│       ├── models/
│       │   └── item_model.dart            (78줄) Item + ItemType enum
│       └── widgets/
│           ├── empty_state.dart            (30줄) 빈 상태 위젯
│           ├── photo_thumbnail.dart        (85줄) 사진 썸네일 (공유)
│           └── photo_detail_dialog.dart    (53줄) 사진 상세 다이얼로그 (공유)
│
├── packages/
│   └── wesync_chat/                       로컬 채팅 패키지
│       └── lib/
│           ├── wesync_chat.dart           배럴 export
│           ├── models/
│           │   ├── message.dart           Message 모델
│           │   ├── chat_settings.dart     채팅 설정
│           │   └── chat_strings.dart      채팅 문자열
│           ├── screens/
│           │   ├── chat_screen.dart       채팅 화면
│           │   └── chat_settings_screen.dart 채팅 설정 화면
│           ├── services/
│           │   └── chat_service.dart      Firestore 채팅 서비스
│           └── widgets/
│               ├── message_bubble.dart    메시지 버블
│               └── message_input.dart     메시지 입력
│
├── functions/
│   └── index.js                          Cloud Function (썸네일 생성)
│
├── firestore.rules                       Firestore 보안 규칙
├── storage.rules                         Storage 보안 규칙
├── firebase.json                         Firebase 호스팅 설정
├── firestore.indexes.json                Firestore 인덱스
└── pubspec.yaml                          패키지 의존성
```

---

## 3. 앱 진입 흐름

```
main.dart
  ├── Firebase.initializeApp()
  ├── PreferencesService().init()          ← 설정 영구저장 초기화
  ├── initializeDateFormatting()
  └── ProviderScope(child: WesynkApp)
        │
        └── WesynkApp (app.dart)
              ├── 언어/테마 설정 적용
              └── _AuthGate
                    ├── PIN 잠금 활성 → PinScreen(unlock)
                    ├── 미인증 → LoginPage
                    └── 인증 완료 → _initCoupleData() → HomePage
                          │
                          ├── pairing 문서에서 coupleId 조회
                          ├── 매칭됨 → coupleIdProvider 설정
                          └── 미매칭 → 임시 couple-{uid} 생성
```

---

## 4. 네비게이션 구조

```
HomePage (IndexedStack + BottomNavigationBar)
  ├── [0] _CalendarView
  │         ├── MonthlyCalendar (table_calendar)
  │         └── TabBarView (4탭)
  │               ├── event → DayTabContent → ItemCard
  │               ├── date  → DayTabContent → ItemCard
  │               ├── note  → DayTabContent → ItemCard
  │               └── photo → DayTabContent → PhotoThumbnail
  │
  ├── [1] ChatScreen (wesync_chat 패키지)
  │
  ├── [2] AlbumPage
  │         └── _GroupedPhotoGrid → PhotoThumbnail
  │
  └── [3] SettingsPage
            ├── 프로필 카드
            ├── PartnerCard (페어링)
            ├── 언어 선택 (ko/en)
            ├── 앱 커스터마이즈 (이름/아이콘/테마/배경)
            ├── Google Calendar 토글
            ├── 일정 색상 설정
            ├── SecurityCard (PIN/자동잠금)
            └── 로그아웃
```

---

## 5. 상태 관리 (Riverpod Providers)

### 5.1 인증 / 사용자

| Provider | 타입 | 위치 | 설명 |
|----------|------|------|------|
| `authStateProvider` | `StreamProvider<User?>` | auth_provider.dart | Firebase Auth 상태 |
| `currentUserProvider` | `Provider<User?>` | auth_provider.dart | 현재 유저 |
| `googleAuthHeadersProvider` | `StateProvider<Map?>` | auth_provider.dart | Google OAuth 헤더 |
| `authServiceProvider` | `Provider<AuthService>` | auth_provider.dart | 인증 서비스 |

### 5.2 커플 / 데이터

| Provider | 타입 | 위치 | 설명 |
|----------|------|------|------|
| `coupleIdProvider` | `StateProvider<String>` | home_providers.dart | 현재 coupleId (캐시 초기화) |
| `firestoreServiceProvider` | `Provider<FirestoreService>` | home_providers.dart | DB 서비스 |
| `selectedDateProvider` | `StateProvider<DateTime>` | home_providers.dart | 선택된 날짜 |
| `selectedDateKeyProvider` | `Provider<String>` | home_providers.dart | "YYYY-MM-DD" 키 |
| `itemsForDateAndTypeProvider` | `StreamProvider.family` | home_providers.dart | 날짜+타입별 아이템 스트림 |
| `eventCountByDateProvider` | `StreamProvider.family` | home_providers.dart | 월간 이벤트 수 |

### 5.3 사진

| Provider | 타입 | 위치 | 설명 |
|----------|------|------|------|
| `photoServiceProvider` | `Provider<PhotoService>` | photo_providers.dart | 사진 서비스 (coupleId 연동) |
| `allPhotosProvider` | `StreamProvider<List<PhotoItem>>` | photo_providers.dart | 전체 사진 스트림 |
| `photosByDateProvider` | `StreamProvider.family` | photo_providers.dart | 날짜별 사진 |

### 5.4 앱 커스터마이즈 (영구 저장)

| Provider | 타입 | 위치 | 설명 |
|----------|------|------|------|
| `appCustomizationProvider` | `StateNotifierProvider` | home_providers.dart | 이름/테마/아이콘/배경 |
| `myEventColorProvider` | `StateNotifierProvider` | home_providers.dart | 내 일정 색상 |
| `partnerEventColorProvider` | `StateNotifierProvider` | home_providers.dart | 파트너 일정 색상 |
| `googleEventColorProvider` | `StateNotifierProvider` | home_providers.dart | Google 일정 색상 |
| `appLanguageProvider` | `StateProvider<AppLanguage>` | app_strings.dart | 언어 (ko/en) |
| `googleCalendarEnabledProvider` | `StateProvider<bool>` | home_providers.dart | Google Calendar 연동 |

### 5.5 보안 (영구 저장)

| Provider | 타입 | 위치 | 설명 |
|----------|------|------|------|
| `securityProvider` | `StateNotifierProvider` | security_provider.dart | PIN/잠금 설정 |
| `isUnlockedProvider` | `StateProvider<bool>` | security_provider.dart | 잠금 해제 여부 |
| `lastActivityProvider` | `StateProvider<DateTime>` | security_provider.dart | 마지막 활동 시간 |

### 5.6 Google Calendar

| Provider | 타입 | 위치 | 설명 |
|----------|------|------|------|
| `googleCalendarServiceProvider` | `Provider<GoogleCalendarService?>` | home_providers.dart | 조건부 서비스 |
| `googleEventsForDateProvider` | `FutureProvider.family` | home_providers.dart | 날짜별 Google 일정 |
| `googleEventCountsProvider` | `FutureProvider.family` | home_providers.dart | 월간 Google 일정 수 |

---

## 6. 서비스 레이어

### 6.1 FirestoreService (365줄)

**위치**: `lib/core/services/firestore_service.dart`

| 메서드 | 설명 |
|--------|------|
| `toDateKey(DateTime)` | 날짜 → "YYYY-MM-DD" 키 변환 (정적) |
| `lookupCoupleId()` | pairing 문서에서 매칭된 coupleId 조회 |
| `coupleIdStream()` | coupleId 실시간 스트림 |
| `itemsStream(coupleId, dateKey, type)` | 아이템 실시간 스트림 (클라이언트 type 필터) |
| `eventCountsStream(coupleId, firstDay, lastDay)` | 월간 이벤트 수 (서버 date 범위 필터) |
| `addItem(coupleId, item)` | 아이템 추가 |
| `toggleChecked(coupleId, itemId, checked)` | 체크 토글 |
| `updateItem(coupleId, itemId, payload)` | payload 수정 |
| `deleteItem(coupleId, itemId)` | soft delete (deletedAt 설정) |
| `ensureCoupleExists(coupleId)` | couples 문서 초기화 |
| `seedSampleData(coupleId)` | 샘플 데이터 생성 |
| `registerForPairing(...)` | 이메일 페어링 등록 + 매칭 |
| `checkAndUpdateMatch(myEmail)` | 상대방 매칭 감지 → 내 문서 업데이트 |
| `pairingStatusStream(myEmail)` | 페어링 상태 실시간 스트림 |
| `disconnectPairing(myEmail)` | 페어링 해제 (본인 문서만) |

**Firestore 경로**:
```
couples/{coupleId}                    커플 문서 (members 배열)
couples/{coupleId}/items/{itemId}     아이템 (일정/일기/데이트/사진)
couples/{coupleId}/messages/{msgId}   채팅 메시지
pairing/{email}                       페어링 상태
```

### 6.2 PhotoService (373줄)

**위치**: `lib/core/services/photo_service.dart`

**PhotoItem 모델** 포함 (같은 파일):
```dart
class PhotoItem {
  id, storagePath, mimeType, width?, height?,
  takenAt?, caption?, uploadedAt, byteSize,
  deletedAt?, uploading, date, duration?, thumbnailReady
}
```

| 메서드 | 설명 |
|--------|------|
| `pickAndUpload(onProgress?)` | 파일 선택 → 멀티 업로드 |
| `recentPhotos(limit)` | 최근 사진 스트림 (500개) |
| `photosForDate(dateKey)` | 날짜별 사진 스트림 |
| `thumbnailUrl(photo, size)` | 썸네일 URL (fallback: 원본) |
| `originalUrl(photo)` | 원본 URL |
| `moveToTrash(photoId)` | 휴지통 (soft delete) |
| `restoreFromTrash(photoId)` | 복원 |
| `permanentlyDelete(photoId)` | 영구 삭제 (Storage + Firestore) |

**Storage 경로**:
```
couples/{coupleId}/photos/original/{uuid}.{ext}
couples/{coupleId}/photos/thumb_400/{uuid}_400x400.{ext}
couples/{coupleId}/photos/thumb_800/{uuid}_800x800.{ext}
```

### 6.3 PreferencesService (112줄)

**위치**: `lib/core/services/preferences_service.dart`

싱글톤. `SharedPreferences` + `FlutterSecureStorage` 래퍼.

| 카테고리 | 키 | 타입 | 저장소 |
|----------|-----|------|--------|
| 언어 | `app_language` | String | SharedPrefs |
| 앱 이름 | `app_name` | String | SharedPrefs |
| 테마 색상 | `theme_color` | int (ARGB) | SharedPrefs |
| 앱 아이콘 | `app_icon` | int (codePoint) | SharedPrefs |
| 배경 색상 | `bg_color` | int (ARGB) | SharedPrefs |
| 내 일정 색상 | `my_event_color` | int | SharedPrefs |
| 파트너 색상 | `partner_event_color` | int | SharedPrefs |
| Google 색상 | `google_event_color` | int | SharedPrefs |
| Google Cal | `google_cal_enabled` | bool | SharedPrefs |
| PIN 활성 | `pin_enabled` | bool | SharedPrefs |
| 탭 잠금 | `lock_on_tab_switch` | bool | SharedPrefs |
| 자동잠금 | `auto_lock_duration` | String (enum name) | SharedPrefs |
| PIN 코드 | `user_pin` | String | **SecureStorage** |
| coupleId | `couple_id` | String | SharedPrefs |

### 6.4 GoogleCalendarService (116줄)

**위치**: `lib/core/services/google_calendar_service.dart`

Google Calendar API (읽기 전용). OAuth 헤더 기반.

---

## 7. 데이터 모델

### 7.1 Item (Firestore: couples/{id}/items)

```dart
class Item {
  String id;             // Firestore 문서 ID
  ItemType type;         // event | note | photo | date
  String date;           // "YYYY-MM-DD"
  String createdBy;      // Firebase Auth uid
  DateTime createdAt;
  Map<String, dynamic> payload;  // 타입별 데이터
  bool checked;          // 완료 체크
  DateTime? deletedAt;   // soft delete
}
```

**Payload 구조 (타입별)**:
```
event: { title, location, startAt (ISO8601), allDay }
note:  { body, mood (이모지) }
date:  { title, place: {name}, rating (1-5), review }
photo: { storagePath, mimeType, byteSize, uploading, uploadedAt, width?, height?, takenAt? }
```

### 7.2 PhotoItem (photo_service.dart 내장)

```dart
class PhotoItem {
  String id, storagePath, mimeType, date;
  int? width, height, duration;
  DateTime? takenAt, deletedAt;
  DateTime uploadedAt;
  int byteSize;
  bool uploading, thumbnailReady;
  String? caption;
}
```

### 7.3 Message (wesync_chat 패키지)

```dart
class Message {
  String id, senderId, body;
  DateTime sentAt;
  DateTime? editedAt, hideAfter;
  Map<String, DateTime> readBy;           // 읽음 확인
  Map<String, List<String>> reactions;    // 이모지 리액션
  String? imageUrl;                       // 사진 메시지
}
```

### 7.4 AppCustomization

```dart
class AppCustomization {
  String appName;          // 기본: "WeSync", 최대 12자
  Color themeColor;        // 8개 프리셋 중 선택
  IconData appIcon;        // 8개 프리셋 중 선택
  Color backgroundColor;  // 8개 프리셋 중 선택
}
```

### 7.5 SecuritySettings

```dart
class SecuritySettings {
  bool pinEnabled;
  String? pin;              // 4자리, SecureStorage 저장
  bool lockOnTabSwitch;     // 탭 전환 시 PIN 요구
  AutoLockDuration autoLockDuration;  // off|30s|1m|3m|5m|10m
}
```

---

## 8. Firestore 보안 규칙

**파일**: `firestore.rules`

```
헬퍼:
  isAuth()           → request.auth != null
  isMember(coupleId) → 이메일이 couples/{coupleId}.members 배열에 포함

couples/{coupleId}:
  read:   isMember
  create: isAuth + 본인 이메일이 members에 포함
  update: isMember
  delete: 불가

couples/{coupleId}/items/{itemId}:
  read/update/delete: isMember
  create: isMember + createdBy == auth.uid

couples/{coupleId}/messages/{messageId}:
  read/update/delete: isMember
  create: isMember + senderId == auth.uid

pairing/{email}:
  read:   isAuth (매칭 확인용)
  create/update/delete: isAuth + email == auth.token.email (본인 문서만)
```

---

## 9. Cloud Function

**파일**: `functions/index.js`

**함수**: `generateThumbnail`
- **트리거**: Cloud Storage finalized (photos/original/ 경로)
- **이미지**: sharp로 400x400, 800x800 JPEG 썸네일 생성
- **영상**: ffmpeg로 첫 프레임 추출 + ffprobe로 메타데이터 (duration, width, height)
- **Firestore 업데이트**: `payload.thumbnailReady: true`, `width`, `height`, `duration`
- **설정**: 1GiB 메모리, 300초 타임아웃, asia-northeast3 리전

---

## 10. 의존성 (pubspec.yaml)

### 핵심
| 패키지 | 용도 |
|--------|------|
| `flutter_riverpod: ^2.4.9` | 상태 관리 |
| `firebase_core: ^3.8.0` | Firebase 초기화 |
| `firebase_auth: ^5.3.3` | 인증 |
| `cloud_firestore: ^5.5.0` | 데이터베이스 |
| `firebase_storage: ^12.3.0` | 파일 저장소 |
| `google_sign_in: ^6.2.2` | Google OAuth |
| `shared_preferences: ^2.3.4` | 설정 영구 저장 |
| `flutter_secure_storage: ^9.2.4` | PIN 암호화 저장 |

### UI
| 패키지 | 용도 |
|--------|------|
| `table_calendar: ^3.1.2` | 캘린더 위젯 |
| `google_fonts: ^6.2.1` | Noto Sans KR |
| `cached_network_image: ^3.3.1` | 이미지 캐싱 |
| `intl: ^0.19.0` | 날짜 포맷/로컬라이제이션 |

### 기타
| 패키지 | 용도 |
|--------|------|
| `uuid: ^4.2.1` | 고유 ID 생성 |
| `file_selector: ^1.0.4` | 파일 선택기 |
| `exif: ^3.3.0` | EXIF 메타데이터 추출 |
| `googleapis: ^15.0.0` | Google Calendar API |
| `web: ^1.1.1` | 웹 네이티브 영상 재생 |
| `wesync_chat` (로컬) | 채팅 패키지 |

---

## 11. 파일 간 의존 관계

```
main.dart
  → app.dart
      → home_page.dart → day_tab_content.dart → item_card.dart
      │                                        → item_edit_sheets.dart
      │                 → item_form_sheets.dart
      │                 → monthly_calendar.dart
      │
      → album_page.dart → photo_thumbnail.dart (shared)
      │                  → photo_detail_dialog.dart (shared)
      │
      → settings_page.dart → partner_card.dart
      │                     → security_card.dart
      │
      → login_page.dart
      → pin_screen.dart

Providers 의존:
  auth_provider.dart          (독립)
  security_provider.dart      → preferences_service.dart
  home_providers.dart         → firestore_service.dart
                              → google_calendar_service.dart
                              → preferences_service.dart
                              → auth_provider.dart
  photo_providers.dart        → photo_service.dart
                              → home_providers.dart (coupleIdProvider)
```

---

## 12. 페어링 흐름 (양방향 이메일 매칭)

```
사용자 A                              사용자 B
   │                                     │
   ├─ 내 이메일 + B 이메일 + 코드 입력      │
   ├─ registerForPairing()               │
   │   ├─ pairing/{A이메일} 문서 생성       │
   │   ├─ pairing/{B이메일} 조회           │
   │   └─ B 미등록 → null 반환            │
   │                                     │
   │                    내 이메일 + A 이메일 + 코드 입력 ─┤
   │                    registerForPairing() ─┤
   │                      ├─ pairing/{B이메일} 문서 생성
   │                      ├─ pairing/{A이메일} 조회 → 발견!
   │                      ├─ 이메일 + 코드 매칭 확인
   │                      ├─ pairing/{B이메일}.matched = true
   │                      ├─ couples/{coupleId} 생성
   │                      └─ coupleId 반환
   │                                     │
   ├─ pairingStatusStream 감지            │
   ├─ checkAndUpdateMatch()              │
   │   └─ B가 matched → 내 문서도 업데이트   │
   └─ coupleId 획득                       │
```

**보안 규칙**: 각 사용자는 자기 이메일 문서만 쓰기 가능.

---

## 13. 설정 영구 저장 구조

```
앱 시작
  └─ PreferencesService().init()     ← SharedPreferences 로드

Provider 초기화 시:
  ├─ SecurityNotifier._loadFromPrefs()  ← PIN은 SecureStorage에서 비동기 로드
  ├─ AppCustomizationNotifier._load()   ← 테마/아이콘/배경 로드
  ├─ _ColorNotifier(initial)            ← 일정 색상 로드
  ├─ appLanguageProvider                ← 언어 로드
  ├─ coupleIdProvider                   ← 캐시된 coupleId
  └─ googleCalendarEnabledProvider      ← Google Cal 상태

설정 변경 시:
  └─ Notifier.update() / setState()
       └─ PreferencesService.setXxx()   ← 즉시 저장
```

---

## 14. 빌드 & 배포

```bash
# 분석
flutter analyze

# 웹 빌드
flutter build web --release

# Firebase 배포
firebase deploy --only hosting

# Firestore 규칙만 배포
firebase deploy --only firestore:rules

# 전체 배포
firebase deploy
```

---

## 15. 프리셋 상수

### 테마 색상 (8개)
코랄핑크 `#E8757D` | 라벤더 `#9B8EC4` | 스카이블루 `#6AABDB` | 민트 `#5BBFAD`
피치 `#F4A683` | 로즈골드 `#B76E79` | 인디고 `#5C6BC0` | 슬레이트 `#607D8B`

### 앱 아이콘 (8개)
하트 | 반려동물 | 공원 | 커피 | 별 | 다이아 | 스파 | 여행

### 배경 색상 (8개)
웜크림 `#FFFBF8` | 쿨화이트 `#F8FAFC` | 라벤더 `#F5F0FF` | 민트 `#F0FFF4`
핑크 `#FFF0F5` | 스카이 `#F0F4FF` | 그레이 `#F5F5F5` | 다크 `#1E1E2E`

### 일정 색상 (6개)
빨간색 `#E53935` | 파란색 `#1E88E5` | 보라색 `#8E24AA`
초록색 `#43A047` | 주황색 `#FB8C00` | 핑크색 `#D81B60`

### 감정 이모지 (8개)
😊 😍 😢 😡 🥺 🎬 📝 🌸

---

## 16. git으로 복원하기

```bash
# 변경 사항 확인
git diff --stat

# 리팩토링 전 상태로 복원
git checkout -- .

# 특정 커밋으로 복원
git log --oneline -10
git checkout <commit-hash> -- .
```
