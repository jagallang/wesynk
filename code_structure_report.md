# WeSync 코드 구조 상세 보고서

작성일: 2026-05-12
Flutter: 3.29.2 (Dart 3.7.2)
앱 버전: v2.1.1 (pubspec.yaml에는 1.0.0+1로 기재, 실제 git tag 기준 v2.1.1)
Firebase 프로젝트: wesynk-app (242440576982)
배포: https://wesynk-app.web.app

---

## 1. 프로젝트 트리 (depth=3)

```
lib/                                           (22 파일, 3889줄)
├── main.dart                                  (29줄)
├── app.dart                                   (81줄)
├── firebase_options.dart                      (74줄, 자동 생성)
├── core/
│   ├── constants/
│   │   ├── app_colors.dart                    (33줄)
│   │   └── app_strings.dart                   (214줄)
│   ├── services/
│   │   ├── firestore_service.dart             (295줄) ← 핵심
│   │   └── photo_service.dart                 (266줄) ← 핵심
│   └── theme/
│       └── app_theme.dart                     (74줄)
├── features/
│   ├── album/presentation/pages/
│   │   └── album_page.dart                    (317줄) ← 핵심
│   ├── auth/presentation/
│   │   ├── pages/login_page.dart              (82줄)
│   │   └── providers/auth_provider.dart       (54줄)
│   ├── home/presentation/
│   │   ├── pages/home_page.dart               (471줄) ← 핵심
│   │   ├── providers/
│   │   │   ├── home_providers.dart            (119줄) ← 핵심
│   │   │   └── photo_providers.dart           (22줄) ← 핵심
│   │   └── widgets/
│   │       ├── day_tab_content.dart           (156줄)
│   │       ├── item_card.dart                 (357줄)
│   │       └── monthly_calendar.dart          (122줄)
│   ├── security/presentation/
│   │   ├── pages/pin_screen.dart              (223줄)
│   │   └── providers/security_provider.dart   (57줄)
│   └── settings/presentation/pages/
│       └── settings_page.dart                 (735줄)
└── shared/
    ├── models/
    │   └── item_model.dart                    (78줄)
    └── widgets/
        └── empty_state.dart                   (30줄)

packages/wesync_chat/                          (9 파일, 1253줄)
├── lib/
│   ├── wesync_chat.dart                       (8줄, barrel export)
│   ├── models/
│   │   ├── message.dart                       (91줄)
│   │   ├── chat_settings.dart                 (81줄)
│   │   └── chat_strings.dart                  (58줄)
│   ├── services/
│   │   └── chat_service.dart                  (139줄)
│   ├── screens/
│   │   ├── chat_screen.dart                   (242줄)
│   │   └── chat_settings_screen.dart          (324줄)
│   └── widgets/
│       ├── message_bubble.dart                (137줄)
│       └── message_input.dart                 (173줄)
└── pubspec.yaml
```

---

## 2. 패키지 의존성

### pubspec.yaml dependencies (정확한 버전)

```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_localizations:
    sdk: flutter
  cupertino_icons: ^1.0.8
  flutter_riverpod: ^2.4.9
  table_calendar: ^3.1.2
  intl: ^0.19.0
  uuid: ^4.2.1
  firebase_core: ^3.8.0
  firebase_auth: ^5.3.3
  cloud_firestore: ^5.5.0
  google_sign_in: ^6.2.2
  google_fonts: ^6.2.1
  firebase_storage: ^12.3.0
  file_selector: ^1.0.4
  cached_network_image: ^3.3.1
  wesync_chat:
    path: packages/wesync_chat
```

### dev_dependencies

```yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^5.0.0
```

### wesync_chat/pubspec.yaml dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter
  intl: ^0.19.0
  uuid: ^4.2.1
  cloud_firestore: ^5.5.0
```

---

## 3. 핵심 데이터 모델

### 3-1. Item

파일: `lib/shared/models/item_model.dart:5-78`

```dart
enum ItemType { event, note, photo, date }

extension ItemTypeExt on ItemType {
  String get label => switch (this) {
        ItemType.event => S.tabTravel,   // "일정"/"Schedule"
        ItemType.note => S.tabNote,      // "일기"/"Diary"
        ItemType.photo => S.tabPhoto,    // "사진"/"Photos"
        ItemType.date => S.tabFood,      // "맛집"/"Food"
      };

  IconData get icon => switch (this) {
        ItemType.event => Icons.event,
        ItemType.note => Icons.note_alt_outlined,
        ItemType.photo => Icons.photo_outlined,
        ItemType.date => Icons.favorite_outline,
      };
}

const tabOrder = [ItemType.event, ItemType.date, ItemType.note, ItemType.photo];

class Item {
  final String id;
  final ItemType type;
  final String date;           // "YYYY-MM-DD" 형식
  final String createdBy;      // "me" 또는 "partner" (하드코딩)
  final DateTime createdAt;
  final Map<String, dynamic> payload;  // type별 다른 구조 (아래 참고)
  final bool checked;          // default: false
  final DateTime? deletedAt;   // null이면 활성, non-null이면 소프트삭제

  const Item({
    required this.id,
    required this.type,
    required this.date,
    required this.createdBy,
    required this.createdAt,
    required this.payload,
    this.checked = false,
    this.deletedAt,
  });

  factory Item.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return Item(
      id: doc.id,
      type: ItemType.values.firstWhere(
        (t) => t.name == d['type'],
        orElse: () => ItemType.note,
      ),
      date: d['date'] as String? ?? '',
      createdBy: d['createdBy'] as String? ?? '',
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      payload: Map<String, dynamic>.from(d['payload'] as Map? ?? {}),
      checked: d['checked'] as bool? ?? false,
      deletedAt: (d['deletedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type.name,
      'date': date,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'payload': payload,
      'deletedAt': null,   // 주의: toMap()은 항상 deletedAt=null로 생성
    };
  }
}
```

**payload 구조 (type별):**
- **event**: `{ 'title': String, 'location': String, 'startAt': ISO8601 String, 'allDay': bool }`
- **note**: `{ 'body': String, 'mood': String (이모지) }`
- **photo**: `{ 'storagePath': String, 'mimeType': String, 'byteSize': int, 'uploading': bool, 'uploadedAt': Timestamp, 'width': int?, 'height': int?, 'takenAt': Timestamp? }`
- **date**: `{ 'title': String, 'place': { 'name': String }, 'rating': int(1~5), 'review': String }`

### 3-2. PhotoItem

파일: `lib/core/services/photo_service.dart:10-67`

```dart
class PhotoItem {
  final String id;
  final String storagePath;       // "couples/{coupleId}/photos/original/{id}.{ext}"
  final String mimeType;          // "image/jpeg" 등
  final int? width;               // 항상 null (EXIF 미구현)
  final int? height;              // 항상 null (EXIF 미구현)
  final DateTime? takenAt;        // 항상 null (EXIF 미구현)
  final String? caption;          // 현재 미사용 (업로드 시 설정 안 함)
  final DateTime uploadedAt;      // non-null
  final int byteSize;
  final DateTime? deletedAt;      // null=활성, non-null=휴지통
  final bool uploading;           // true=업로드 진행 중
  final String date;              // "YYYY-MM-DD"

  // 생성자: id, storagePath, mimeType, uploadedAt, byteSize, date는 required
  // 나머지는 optional named

  factory PhotoItem.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    final p = (d['payload'] as Map<String, dynamic>?) ?? {};
    return PhotoItem(
      id: doc.id,
      storagePath: p['storagePath'] as String? ?? '',
      mimeType: p['mimeType'] as String? ?? 'image/jpeg',
      width: p['width'] as int?,
      height: p['height'] as int?,
      takenAt: (p['takenAt'] as Timestamp?)?.toDate(),
      caption: p['caption'] as String?,
      uploadedAt: (p['uploadedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      byteSize: p['byteSize'] as int? ?? 0,
      deletedAt: (d['deletedAt'] as Timestamp?)?.toDate(),
      uploading: p['uploading'] as bool? ?? false,
      date: d['date'] as String? ?? '',
    );
  }

  String thumbnailPath(int size) {
    // "couples/X/photos/original/abc.jpg" → "couples/X/photos/thumb_400/abc_400x400.jpg"
    final segments = storagePath.split('/');
    segments[segments.length - 2] = 'thumb_$size';
    segments[segments.length - 1] = '${name}_${size}x$size$ext';
    return segments.join('/');
  }
}
```

**extension (날짜별 그룹화용):**

파일: `lib/core/services/photo_service.dart:69-80`

```dart
extension PhotoItemDisplay on PhotoItem {
  DateTime get displayDate => takenAt ?? uploadedAt;
  DateTime get displayDateKey {
    final d = displayDate;
    return DateTime(d.year, d.month, d.day);
  }
}
```

### 3-3. Message (wesync_chat 패키지)

파일: `packages/wesync_chat/lib/models/message.dart:3-91`

```dart
class Message {
  final String id;
  final String senderId;              // "me" 또는 "partner"
  final String body;
  final DateTime sentAt;
  final Map<String, DateTime> readBy; // { "uid": DateTime }
  final Map<String, List<String>> reactions; // { "❤️": ["uid1"] }
  final DateTime? hideAfter;          // null=영구, non-null=휘발
  final DateTime? editedAt;

  // fromDoc: Firestore Timestamp → DateTime 변환
  // toMap: DateTime → Timestamp 변환
  // copyWith: readBy, reactions, hideAfter, editedAt만 변경 가능
  // isVisible([DateTime? now]): hideAfter가 null이거나 미래면 true
  // isEphemeral: hideAfter - sentAt > 5초면 true
  // remainingLifetime([DateTime? now]): 남은 시간 Duration 반환
}
```

### 3-4. SecuritySettings

파일: `lib/features/security/presentation/providers/security_provider.dart:3-47`

```dart
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
  final bool pinEnabled;                     // default: false
  final String? pin;                         // 4자리 문자열, null이면 미설정
  final bool lockOnTabSwitch;                // default: false
  final AutoLockDuration autoLockDuration;   // default: off

  // copyWith 지원
}
```

### 3-5. AppCustomization

파일: `lib/features/home/presentation/providers/home_providers.dart:9-35`

```dart
class AppCustomization {
  final String appName;         // default: 'WeSync'
  final Color themeColor;       // default: Color(0xFFE8757D) 코랄핑크
  final IconData appIcon;       // default: Icons.favorite
  final Color backgroundColor;  // default: Color(0xFFFFFBF8) 웜크림

  // copyWith 지원
}
```

---

## 4. Riverpod Provider 카탈로그

### 메인 앱 Provider

| 이름 | 타입 | 위치 | 반환 | 의존 |
|---|---|---|---|---|
| `appCustomizationProvider` | `StateProvider<AppCustomization>` | `home_providers.dart:73` | `AppCustomization` | 없음 |
| `firestoreServiceProvider` | `Provider<FirestoreService>` | `home_providers.dart:79` | `FirestoreService` | 없음 |
| `coupleIdProvider` | `StateProvider<String>` | `home_providers.dart:84` | `String` | 없음 (초기값 `'default-couple'`) |
| `selectedDateProvider` | `StateProvider<DateTime>` | `home_providers.dart:89` | `DateTime` | 없음 (초기값 `DateTime.now()`) |
| `selectedDateKeyProvider` | `Provider<String>` | `home_providers.dart:92` | `String` (`"YYYY-MM-DD"`) | `selectedDateProvider` |
| `appLanguageProvider` | `StateProvider<AppLanguage>` | `app_strings.dart:11` | `AppLanguage` | 없음 (초기값 `ko`) |
| `itemsForDateAndTypeProvider` | `StreamProvider.family<List<Item>, ({String dateKey, ItemType type})>` | `home_providers.dart:98` | `List<Item>` | `firestoreServiceProvider` |
| `eventCountByDateProvider` | `StreamProvider.family<Map<String, int>, DateTime>` | `home_providers.dart:109` | `Map<String, int>` | `firestoreServiceProvider` |
| `photoServiceProvider` | `Provider<PhotoService>` | `photo_providers.dart:6` | `PhotoService` | `coupleIdProvider` |
| `allPhotosProvider` | `StreamProvider<List<PhotoItem>>` | `photo_providers.dart:12` | `List<PhotoItem>` | `photoServiceProvider` |
| `photosByDateProvider` | `StreamProvider.family<List<PhotoItem>, String>` | `photo_providers.dart:18` | `List<PhotoItem>` | `photoServiceProvider` |
| `authStateProvider` | `StreamProvider<User?>` | `auth_provider.dart:6` | `User?` | Firebase Auth 직접 |
| `currentUserProvider` | `Provider<User?>` | `auth_provider.dart:10` | `User?` | `authStateProvider` |
| `authServiceProvider` | `Provider<AuthService>` | `auth_provider.dart:54` | `AuthService` | 없음 |
| `securityProvider` | `StateProvider<SecuritySettings>` | `security_provider.dart:49` | `SecuritySettings` | 없음 |
| `isUnlockedProvider` | `StateProvider<bool>` | `security_provider.dart:54` | `bool` | 없음 (초기값 `false`) |
| `lastActivityProvider` | `StateProvider<DateTime>` | `security_provider.dart:57` | `DateTime` | 없음 |

### 핵심 Provider 코드 스니펫

**allPhotosProvider** (`photo_providers.dart:12-15`):
```dart
final allPhotosProvider = StreamProvider<List<PhotoItem>>((ref) {
  final service = ref.watch(photoServiceProvider);
  return service.recentPhotos(limit: 500);
});
```

**itemsForDateAndTypeProvider** (`home_providers.dart:98-106`):
```dart
final itemsForDateAndTypeProvider = StreamProvider.family<List<Item>,
    ({String dateKey, ItemType type})>((ref, params) {
  final service = ref.watch(firestoreServiceProvider);
  return service.itemsStream(
    coupleId: FirestoreService.defaultCoupleId,  // ← 하드코딩
    dateKey: params.dateKey,
    type: params.type,
  );
});
```

---

## 5. Firestore/Storage 실제 사용 패턴

### 5-1. Firestore 쿼리 목록

| # | 호출 위치 | 컬렉션 경로 | where | orderBy | limit | 인덱스 |
|---|---|---|---|---|---|---|
| 1 | `firestore_service.dart:21-34` `itemsStream()` | `couples/{coupleId}/items` | `date == dateKey` | 없음 (클라이언트 정렬) | 없음 | 불필요 |
| 2 | `firestore_service.dart:44-58` `eventCountsStream()` | `couples/{coupleId}/items` | `type == 'event'` | 없음 | 없음 | 불필요 |
| 3 | `photo_service.dart:98-110` `recentPhotos()` | `couples/{coupleId}/items` | `type == 'photo'` | `createdAt DESC` | 500 | **필요** (배포됨) |
| 4 | `photo_service.dart:112-119` `photosForDate()` | `couples/{coupleId}/items` | `date == dateKey` | 없음 | 없음 | 불필요 |
| 5 | `chat_service.dart:17-24` `recentMessagesStream()` | `couples/{coupleId}/messages` | 없음 | `sentAt DESC` | 50 | 불필요 |

**쿼리 1 주의사항**: `itemsStream()`은 `date`만 where 조건이고, `type` 필터와 `deletedAt == null` 필터는 클라이언트 측에서 수행. 모든 type의 문서를 가져온 뒤 `where((item) => item.type == type)`으로 필터링.

**배포된 복합 인덱스** (`firestore.indexes.json`):

```json
[
  { "fields": ["date ASC", "type ASC", "createdAt DESC"] },
  { "fields": ["type ASC", "date ASC"] },
  { "fields": ["type ASC", "createdAt DESC"] }   // ← 쿼리 3용
]
```

### 5-2. Firestore 쓰기 패턴

| # | 호출 위치 | 컬렉션 | 동작 |
|---|---|---|---|
| 1 | `firestore_service.dart:67` `addItem()` | `items` | `col.add(item.toMap())` — auto ID |
| 2 | `firestore_service.dart:77` `toggleChecked()` | `items` | `doc.update({'checked': v})` |
| 3 | `firestore_service.dart:86-89` `updateItem()` | `items` | `doc.update({'payload': p, 'updatedAt': now})` |
| 4 | `firestore_service.dart:97-99` `deleteItem()` | `items` | soft delete: `doc.update({'deletedAt': now})` |
| 5 | `photo_service.dart:171-184` `_uploadOne()` 1단계 | `items` | `doc(photoId).set({type:'photo', uploading:true, ...})` — 지정 ID |
| 6 | `photo_service.dart:200-205` `_uploadOne()` 3단계 | `items` | `doc.update({uploading:false, storagePath:..., byteSize:...})` |
| 7 | `photo_service.dart:243-245` `moveToTrash()` | `items` | `doc.update({'deletedAt': now})` |
| 8 | `photo_service.dart:264` `permanentlyDelete()` | `items` | `doc.delete()` (hard delete) |
| 9 | `firestore_service.dart:216` `registerForPairing()` | `pairing` | `doc(email).set({...})` |
| 10 | `firestore_service.dart:254-269` `_checkMutualMatch()` | `pairing` + `couples` | 양쪽 pairing doc update + couples doc set(merge) |
| 11 | `chat_service.dart:38` `send()` | `messages` | `col.add(msg.toMap())` |
| 12 | `chat_service.dart:44-46` `hide()` | `messages` | `doc.update({'hideAfter': now})` |
| 13 | `chat_service.dart:51-53` `markRead()` | `messages` | `doc.update({'readBy.$myUid': now})` |
| 14 | `chat_service.dart:58-76` `toggleReaction()` | `messages` | 트랜잭션으로 reactions 맵 토글 |

### 5-3. Storage 경로 패턴

**업로드 경로** (`photo_service.dart:168`):
```
couples/{coupleId}/photos/original/{uuid}.{ext}
```

**썸네일 경로** (`photo_service.dart:57-66` `thumbnailPath()`):
```
couples/{coupleId}/photos/thumb_{size}/{uuid}_{size}x{size}.{ext}
```
- 실제로 썸네일 파일이 존재하지 않음 (Resize Images extension 미설치)
- `thumbnailUrl()` (`photo_service.dart:229-234`)에서 썸네일 404 시 원본 URL fallback

**Storage 함수 위치:**
- 업로드: `photo_service.dart:187-198` `ref.putData(bytes, SettableMetadata(...))`
- 다운로드 URL: `photo_service.dart:229-238` `_storage.ref(path).getDownloadURL()`
- 삭제: `photo_service.dart:258-261` `_storage.ref(path).delete()`

---

## 6. 페이지별 구조

### 6-1. HomePage

파일: `lib/features/home/presentation/pages/home_page.dart:19-471`
타입: `ConsumerStatefulWidget` with `SingleTickerProviderStateMixin`, `WidgetsBindingObserver`

**State 필드:**
```dart
late final TabController _tabController;  // length: tabOrder.length (4)
int _navIndex = 0;                         // 하단 네비 인덱스
DateTime _lastActivity = DateTime.now();   // 자동 잠금용
```

**위젯 트리:**
```
Scaffold
├── body: IndexedStack(index: _navIndex)
│   ├── [0] _CalendarView (내부 위젯)
│   │   └── SafeArea → Column
│   │       ├── 앱 헤더 (아이콘 + 앱 이름 + 알림 버튼)
│   │       ├── MonthlyCalendar
│   │       ├── Divider
│   │       ├── 날짜 헤더 ("M월 d일 (E)")
│   │       ├── TabBar (4탭: event, date, note, photo)
│   │       └── Expanded → TabBarView
│   │           └── DayTabContent(type: tabOrder[i]) × 4
│   ├── [1] ChatScreen(coupleId: 'default-couple', myUid: 'me')
│   ├── [2] AlbumPage()
│   └── [3] SettingsPage()
├── floatingActionButton: (_navIndex == 0일 때만)
│   └── FAB.extended("일정 추가"/"맛집 추가" 등 — 현재 탭에 따라 변경)
└── bottomNavigationBar: NavigationBar (4 destinations)
```

**주요 메서드:**
- `_onTabSelected(int i)` (`:67`): 탭 전환 시 PIN 잠금 체크
- `_onAddPressed(ItemType type)` (`:131`): type에 따라 다른 BottomSheet 호출
- `_showPhotoPlaceholder(String dateKey)` (`:287`): `photoServiceProvider.pickAndUpload()` 호출
- `_checkAutoLock()` (`:56`): 앱 resume 시 자동 잠금 판단

### 6-2. AlbumPage

파일: `lib/features/album/presentation/pages/album_page.dart:9-317`
타입: `ConsumerWidget` (stateless)

**의존 Provider:** `allPhotosProvider`, `photoServiceProvider`

**위젯 트리:**
```
SafeArea → Column
├── 헤더 Row (앨범 제목 + 업로드 버튼)
└── Expanded
    └── photosAsync.when(...)
        ├── empty → _EmptyAlbum (아이콘 + 텍스트 + "사진 추가" 버튼)
        └── data → _GroupedPhotoGrid
            └── CustomScrollView
                └── [날짜별 반복]
                    ├── SliverToBoxAdapter (날짜 헤더: "오늘"/"어제"/"M월 d일")
                    └── SliverGrid (3열, spacing 2px)
                        └── _PhotoThumb (FutureBuilder → CachedNetworkImage)
```

**주요 메서드:**
- `_uploadPhotos(context, ref)` (`:62`): `service.pickAndUpload()` 호출, SnackBar로 결과 표시
- `_GroupedPhotoGrid._showDetail(context, photo)` (`:209`): `showDialog()` → `service.originalUrl()` → `CachedNetworkImage`
- `_GroupedPhotoGrid._showActions(context, photo)` (`:237`): `showModalBottomSheet()` → 삭제 `service.moveToTrash()`

### 6-3. SettingsPage

파일: `lib/features/settings/presentation/pages/settings_page.dart:10-735`
타입: `ConsumerWidget`

**구조 요약 (ListView 안):**
1. 프로필 카드 (Firebase user 정보)
2. `_PartnerCard` (StatefulWidget, `:492-646`) — 이메일 양방향 매칭
3. 언어 선택 (RadioListTile × 2)
4. 앱 꾸미기 ExpansionTile (이름, 아이콘 8종, 테마색 8종, 배경색 8종)
5. `_SecurityCard` (ConsumerWidget, `:378-490`) — PIN 관련 설정
6. 기타 (앱 정보 v1.3.0, 로그아웃)

**`_PartnerCard` State 필드:**
```dart
final _myEmailCtrl = TextEditingController();
final _partnerEmailCtrl = TextEditingController();
bool _loading = false;
bool _registered = false;
```

### 6-4. 기타 페이지 (요약)

**LoginPage** (`auth/pages/login_page.dart:6-82`): StatefulWidget, `_loading` 필드 1개, Google 로그인 버튼

**PinScreen** (`security/pages/pin_screen.dart:8-223`): StatefulWidget, mode(unlock/setup/confirm/change), 4자리 키패드 UI

---

## 7. 미구현·기술 부채 상세

### 7-1. 사진 EXIF 추출 미구현

- **위치**: `photo_service.dart:152` `_uploadOne(Uint8List bytes, String fileName)` 함수
- **현재 상태**: bytes를 받아 바로 Storage에 업로드. EXIF 파싱 코드 없음. PhotoItem.width, height, takenAt에 해당하는 payload 필드를 Firestore에 저장하지 않음 (`photo_service.dart:178-183` 참고: payload에 `width`, `height`, `takenAt` 미포함)
- **영향**:
  - `PhotoItem.takenAt` 항상 null → `displayDate` extension이 항상 `uploadedAt` 반환
  - 앨범 날짜별 그룹화가 업로드 시점 기준으로만 작동
  - 일괄 업로드한 사진들이 같은 날짜 그룹에 묶임 (촬영일 무시)

### 7-2. 썸네일 자동 생성 미설치

- **사실 확인**: `firebase.json`에 extensions 섹션 없음. `photo_service.dart:57-66`의 `thumbnailPath()` 메서드가 `thumb_400` 경로를 생성하지만, 해당 경로에 실제 파일 없음 (Firebase Resize Images extension 미설치)
- **현재 동작**: `thumbnailUrl()` (`photo_service.dart:229-234`)이 썸네일 URL 요청 → 404 → catch에서 원본 URL fallback
- **영향**:
  - 앨범 그리드에서 원본 이미지를 로드 (사진당 평균 1~2MB)
  - 그리드 한 화면 12장 × 2MB = 24MB 다운로드
  - Storage 무료 한도(1GB/일) 빠르게 소진 가능
  - 콘솔에 `thumb_400` 404 에러 반복 출력

### 7-3. Auth 바이패스 ON

- **위치**: `app.dart:53` `static const _bypassAuth = true;`
- **현재 동작**: `_AuthGate.build()` (`:64`)에서 `if (_bypassAuth) return const HomePage();`로 로그인 화면 우회
- **영향**:
  - `FirebaseAuth.instance.currentUser`가 null → `_myUid` getter (`photo_service.dart:89`)가 항상 `'me'` 반환
  - SettingsPage의 프로필 카드에 null 표시
  - Firestore 문서의 `createdBy` 필드가 항상 `'me'`

### 7-4. Firestore/Storage Rules 전체 개방

- **Firestore**: `firestore.rules:6-8` → `allow read, write: if true;`
- **Storage**: `storage.rules:6-8` → `allow read, write: if true;`
- **영향**: 인증 없이 누구나 모든 데이터 읽기/쓰기/삭제 가능

### 7-5. 보안 설정 비영속

- **위치**: `security_provider.dart:49` `StateProvider<SecuritySettings>` — Riverpod StateProvider (인메모리)
- **현재 상태**: PIN, 잠금 설정이 앱 새로고침/재시작 시 초기화됨. SharedPreferences/Hive 등 영속 저장소 미사용
- **영향**: 웹에서 새로고침하면 PIN 잠금 해제됨, 설정 초기화

### 7-6. 앱 커스터마이즈 비영속

- **위치**: `home_providers.dart:73` `StateProvider<AppCustomization>` — 인메모리
- **현재 상태**: 앱 이름, 테마색, 아이콘, 배경색 설정이 새로고침 시 초기화
- **영향**: 사용자가 변경한 커스터마이즈가 유지되지 않음

### 7-7. 앱 버전 하드코딩 불일치

- **위치**: `settings_page.dart:305` `trailing: const Text('v1.3.0')`
- **상태**: pubspec.yaml에는 `version: 1.0.0+1`, git tag는 v2.1.1. 세 곳 모두 다른 값

### 7-8. 채팅 내보내기 미구현

- **위치**: `app_strings.dart:183` `chatExportSoon` → "Phase 2에서 구현 예정"
- **상태**: 문자열만 정의됨, 실제 export 로직 없음

---

## 8. 인증·페어링 흐름

### 앱 시작 → 인증 흐름

```
1. main.dart:12  WidgetsFlutterBinding.ensureInitialized()
2. main.dart:13  Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)
3. main.dart:15  FirebaseAuth.instance.currentUser → null (바이패스 모드)
4. main.dart:18-19  initializeDateFormatting('ko_KR'), initializeDateFormatting('en_US')
5. main.dart:21-22  GoogleFonts 초기화
6. main.dart:24-26  FirestoreService.ensureCoupleExists('default-couple')
                     FirestoreService.seedSampleData('default-couple')
7. main.dart:28  runApp(ProviderScope(child: WesynkApp()))
8. app.dart:28   MaterialApp(home: _AuthGate())
9. app.dart:57   _AuthGate.build():
                   - securityProvider.pinEnabled == false → 스킵
                   - _bypassAuth == true → return HomePage()
                   (LoginPage 도달 불가)
```

### 페어링 흐름 (SettingsPage 내)

```
1. settings_page.dart:556-582  사용자가 내 이메일 + 파트너 이메일 입력
2. settings_page.dart:623-644  _register() 호출:
   → firestoreServiceProvider.registerForPairing(myEmail, partnerEmail, coupleId)
3. firestore_service.dart:216-222  pairing/{myEmail} 문서 생성:
   { myEmail, partnerEmail, coupleId, createdAt }
4. firestore_service.dart:226  _checkMutualMatch() 호출
5. firestore_service.dart:232  pairing/{partnerEmail} 문서 조회
   → 존재하지 않으면 null 반환 (대기 상태)
   → 존재하고 theirPartner == myEmail이면:
6. firestore_service.dart:254-268  양쪽 pairing 문서에 matched=true 기록
                                    couples/{matchedCoupleId} 문서 생성/업데이트
7. settings_page.dart:637  coupleIdProvider.state = matchedId
8. settings_page.dart:606-615  _PairingStatusView StreamBuilder가 실시간 감시
   → matched == true 시 onMatched 콜백 → coupleIdProvider 업데이트
```

---

## 9. 잠금·보안 흐름

### PIN 설정 (Settings → 앱 잠금 ON)

```
1. settings_page.dart:392-394  SwitchListTile ON → Navigator.push(PinScreen(mode: PinMode.setup))
2. pin_screen.dart:41-48  사용자 4자리 입력 → _onComplete()
3. pin_screen.dart:85-88  _handleSetup(): _firstPin = null → _firstPin = _input, 재입력 대기
4. pin_screen.dart:93-97  재입력 일치 시:
   securityProvider.state = ...copyWith(pinEnabled: true, pin: _input)
   Navigator.pop(true)
```

### 앱 시작 잠금 해제

```
1. app.dart:57-60  security.pinEnabled == true && isUnlocked == false
   → return PinScreen(mode: PinMode.unlock)
2. pin_screen.dart:72-82  _handleUnlock():
   _input == security.pin → isUnlockedProvider.state = true
   → _AuthGate 리빌드 → HomePage 표시
```

### 자동 잠금

```
1. home_page.dart:47-54  didChangeAppLifecycleState():
   paused/hidden → _lastActivity = DateTime.now()
   resumed → _checkAutoLock()
2. home_page.dart:56-65  _checkAutoLock():
   elapsed >= autoLockDuration.seconds → isUnlockedProvider.state = false
   → _AuthGate 리빌드 → PinScreen 표시
```

### 탭 전환 잠금

```
1. home_page.dart:67-87  _onTabSelected(int i):
   security.pinEnabled && security.lockOnTabSwitch && i != _navIndex
   → Navigator.push(PinScreen(mode: PinMode.confirm, onSuccess: ...))
   → 성공 시 setState(() => _navIndex = i)
```

---

## 10. 결정·하드코딩된 값

| 값 | 위치 | 내용 |
|---|---|---|
| `'default-couple'` | `firestore_service.dart:8` | `static const defaultCoupleId = 'default-couple'` |
| `'default-couple'` | `home_page.dart:96` | `ChatScreen(coupleId: 'default-couple', myUid: 'me')` |
| `'me'` | `home_page.dart:96` | ChatScreen의 myUid 파라미터 |
| `'me'` | `photo_service.dart:89` | `FirebaseAuth.instance.currentUser?.uid ?? 'me'` |
| `'me'` / `'partner'` | `firestore_service.dart:108` | `ensureCoupleExists` members 배열 |
| `_bypassAuth = true` | `app.dart:53` | 인증 우회 플래그 |
| `'v1.3.0'` | `settings_page.dart:305` | 앱 버전 표시 (실제와 불일치) |
| `allow read, write: if true` | `firestore.rules:7` | Firestore 보안 규칙 전체 개방 |
| `allow read, write: if true` | `storage.rules:7` | Storage 보안 규칙 전체 개방 |
| `limit: 500` | `photo_service.dart:98` | 앨범 사진 최대 조회 수 |
| `limit: 50` | `chat_service.dart:17` | 채팅 메시지 최대 조회 수 |
| Google OAuth Client ID | `auth_provider.dart:17` | `'242440576982-pekndtmvlqvq3ms5k69ej6s643gp0ic0.apps.googleusercontent.com'` (웹 전용) |
| `maxLength: 12` | `settings_page.dart:337` | 앱 이름 최대 길이 |
| CORS | `cors.json` | `origin: ["*"], method: ["GET"]` |

### Firestore Rules TODO 주석

- `firestore.rules:4`: `// TODO: Auth 연동 후 members 배열 검증으로 교체`
- `storage.rules:4`: `// TODO: Auth 연동 후 members 배열 검증으로 교체`

### app_strings.dart 내 Phase 언급

- `app_strings.dart:63`: `photoPlaceholder` → "Phase 3에서 구현 예정" (현재 사진 업로드 구현됨, 문자열만 미삭제)
- `app_strings.dart:184`: `chatExportSoon` → "Phase 2에서 구현 예정"

---

## 부록: 발견된 코드 이상

1. **itemsForDateAndTypeProvider가 coupleIdProvider를 사용하지 않음** (`home_providers.dart:101`): `FirestoreService.defaultCoupleId`를 하드코딩으로 사용. 페어링 성공 후 `coupleIdProvider`가 업데이트되어도 캘린더 아이템은 여전히 `'default-couple'`에서 조회됨.

2. **eventCountByDateProvider도 동일** (`home_providers.dart:115`): `defaultCoupleId` 하드코딩.

3. **ItemCard에서도 defaultCoupleId 하드코딩** (`item_card.dart:15`): `final coupleId = FirestoreService.defaultCoupleId;`

4. **ChatScreen 생성자에 coupleId/myUid 하드코딩** (`home_page.dart:96`): `ChatScreen(coupleId: 'default-couple', myUid: 'me')` — Provider에서 읽지 않음.

5. **photosForDate 쿼리가 type 필터 없음** (`photo_service.dart:112-119`): `date == dateKey`만 필터하고 type 필터 없음. 해당 날짜의 event/note/date 문서도 가져온 뒤 `storagePath.isNotEmpty`로 걸러냄. 효율성 이슈.

6. **Item.toMap()에 checked 미포함** (`item_model.dart:69-77`): `toMap()`이 `checked` 필드를 포함하지 않음. 새 아이템 생성 시 Firestore 문서에 `checked` 필드가 없음 → `fromDoc`에서 `false` 기본값으로 처리되므로 동작에는 문제 없음.
