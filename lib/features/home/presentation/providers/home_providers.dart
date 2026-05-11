import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/services/firestore_service.dart';
import '../../../../shared/models/item_model.dart';

// ─── 앱 커스터마이즈 ───

class AppCustomization {
  final String appName;
  final Color themeColor;
  final IconData appIcon;
  final Color backgroundColor;

  const AppCustomization({
    this.appName = 'WeSync',
    this.themeColor = const Color(0xFFE8757D),
    this.appIcon = Icons.favorite,
    this.backgroundColor = const Color(0xFFFFFBF8),
  });

  AppCustomization copyWith({
    String? appName,
    Color? themeColor,
    IconData? appIcon,
    Color? backgroundColor,
  }) {
    return AppCustomization(
      appName: appName ?? this.appName,
      themeColor: themeColor ?? this.themeColor,
      appIcon: appIcon ?? this.appIcon,
      backgroundColor: backgroundColor ?? this.backgroundColor,
    );
  }
}

/// 프리셋 테마 색상
const presetColors = <({String name, Color color})>[
  (name: '코랄핑크', color: Color(0xFFE8757D)),
  (name: '라벤더', color: Color(0xFF9B8EC4)),
  (name: '스카이블루', color: Color(0xFF6AABDB)),
  (name: '민트', color: Color(0xFF5BBFAD)),
  (name: '피치', color: Color(0xFFF4A683)),
  (name: '로즈골드', color: Color(0xFFB76E79)),
  (name: '인디고', color: Color(0xFF5C6BC0)),
  (name: '슬레이트', color: Color(0xFF607D8B)),
];

/// 프리셋 앱 아이콘
const presetIcons = <({String name, IconData icon})>[
  (name: '하트', icon: Icons.favorite),
  (name: '반려동물', icon: Icons.pets),
  (name: '공원', icon: Icons.park),
  (name: '커피', icon: Icons.coffee),
  (name: '별', icon: Icons.star),
  (name: '다이아', icon: Icons.diamond),
  (name: '스파', icon: Icons.spa),
  (name: '여행', icon: Icons.flight),
];

/// 프리셋 배경 색상
const presetBackgrounds = <({String name, Color color})>[
  (name: '웜크림', color: Color(0xFFFFFBF8)),
  (name: '쿨화이트', color: Color(0xFFF8FAFC)),
  (name: '라벤더', color: Color(0xFFF5F0FF)),
  (name: '민트', color: Color(0xFFF0FFF4)),
  (name: '핑크', color: Color(0xFFFFF0F5)),
  (name: '스카이', color: Color(0xFFF0F4FF)),
  (name: '그레이', color: Color(0xFFF5F5F5)),
  (name: '다크', color: Color(0xFF1E1E2E)),
];

final appCustomizationProvider = StateProvider<AppCustomization>(
  (ref) => const AppCustomization(),
);

// ─── Firestore 서비스 ───

final firestoreServiceProvider = Provider<FirestoreService>(
  (ref) => FirestoreService(),
);

/// 현재 선택된 날짜
final selectedDateProvider = StateProvider<DateTime>((ref) => DateTime.now());

/// 선택된 날짜의 키 문자열 ("YYYY-MM-DD")
final selectedDateKeyProvider = Provider<String>((ref) {
  final date = ref.watch(selectedDateProvider);
  return DateFormat('yyyy-MM-dd').format(date);
});

/// 특정 날짜 + 특정 타입의 아이템 (Firestore 실시간 스트림)
final itemsForDateAndTypeProvider = StreamProvider.family<List<Item>,
    ({String dateKey, ItemType type})>((ref, params) {
  final service = ref.watch(firestoreServiceProvider);
  return service.itemsStream(
    coupleId: FirestoreService.defaultCoupleId,
    dateKey: params.dateKey,
    type: params.type,
  );
});

/// 월별 이벤트 개수 (캘린더 dot 마커용, Firestore 실시간 스트림)
final eventCountByDateProvider =
    StreamProvider.family<Map<String, int>, DateTime>((ref, month) {
  final service = ref.watch(firestoreServiceProvider);
  final firstDay = DateTime(month.year, month.month, 1);
  final lastDay = DateTime(month.year, month.month + 1, 0);
  return service.eventCountsStream(
    coupleId: FirestoreService.defaultCoupleId,
    firstDay: DateFormat('yyyy-MM-dd').format(firstDay),
    lastDay: DateFormat('yyyy-MM-dd').format(lastDay),
  );
});
