import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../shared/models/item_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  static const defaultCoupleId = 'default-couple';

  CollectionReference<Map<String, dynamic>> _itemsCol(String coupleId) =>
      _db.collection('couples').doc(coupleId).collection('items');

  /// 특정 날짜 + 타입의 아이템 실시간 스트림
  /// 단순 쿼리 (date만 필터) + 클라이언트에서 type 필터/정렬
  Stream<List<Item>> itemsStream({
    required String coupleId,
    required String dateKey,
    required ItemType type,
  }) {
    debugPrint('[FirestoreService] itemsStream: date=$dateKey, type=${type.name}');
    return _itemsCol(coupleId)
        .where('date', isEqualTo: dateKey)
        .snapshots()
        .map((snap) {
      debugPrint('[FirestoreService] got ${snap.docs.length} docs for date=$dateKey');
      final items = snap.docs
          .map(Item.fromDoc)
          .where((item) => item.type == type)
          .where((item) => item.deletedAt == null)
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      debugPrint('[FirestoreService] filtered to ${items.length} items for type=${type.name}');
      return items;
    });
  }

  /// 월간 이벤트 개수 (캘린더 마커용)
  /// 단순 쿼리 (type만 필터) + 클라이언트에서 날짜 범위 필터
  Stream<Map<String, int>> eventCountsStream({
    required String coupleId,
    required String firstDay,
    required String lastDay,
  }) {
    return _itemsCol(coupleId)
        .where('type', isEqualTo: 'event')
        .snapshots()
        .map((snap) {
      final counts = <String, int>{};
      for (final doc in snap.docs) {
        final data = doc.data();
        if (data['deletedAt'] != null) continue;
        final d = data['date'] as String? ?? '';
        if (d.compareTo(firstDay) >= 0 && d.compareTo(lastDay) <= 0) {
          counts[d] = (counts[d] ?? 0) + 1;
        }
      }
      return counts;
    });
  }

  /// 아이템 추가
  Future<void> addItem({
    required String coupleId,
    required Item item,
  }) async {
    debugPrint('[FirestoreService] addItem: type=${item.type.name}, date=${item.date}');
    await _itemsCol(coupleId).add(item.toMap());
    debugPrint('[FirestoreService] addItem: 성공');
  }

  /// 아이템 체크 토글
  Future<void> toggleChecked({
    required String coupleId,
    required String itemId,
    required bool checked,
  }) async {
    await _itemsCol(coupleId).doc(itemId).update({'checked': checked});
  }

  /// 아이템 수정 (payload 업데이트)
  Future<void> updateItem({
    required String coupleId,
    required String itemId,
    required Map<String, dynamic> payload,
  }) async {
    await _itemsCol(coupleId).doc(itemId).update({
      'payload': payload,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  /// 아이템 삭제 (soft delete)
  Future<void> deleteItem({
    required String coupleId,
    required String itemId,
  }) async {
    await _itemsCol(coupleId).doc(itemId).update({
      'deletedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  /// couples 문서 초기화 (최초 1회)
  Future<void> ensureCoupleExists(String coupleId) async {
    final doc = _db.collection('couples').doc(coupleId);
    final snap = await doc.get();
    if (!snap.exists) {
      await doc.set({
        'members': ['me', 'partner'],
        'createdAt': Timestamp.fromDate(DateTime.now()),
      });
    }
  }

  /// 샘플 데이터 생성 (Firestore에 아이템이 없을 때 1회)
  Future<void> seedSampleData(String coupleId) async {
    final col = _itemsCol(coupleId);
    final existing = await col.limit(1).get();
    if (existing.docs.isNotEmpty) return;

    final today = DateTime.now();
    final todayStr =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    final yesterday = today.subtract(const Duration(days: 1));
    final yesterdayStr =
        '${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}';

    final samples = [
      {
        'type': 'event',
        'date': todayStr,
        'createdBy': 'me',
        'createdAt': Timestamp.fromDate(today),
        'deletedAt': null,
        'payload': {
          'title': '카페 데이트',
          'location': '성수동 ○○카페',
          'startAt': today.toIso8601String(),
          'allDay': false,
        },
      },
      {
        'type': 'note',
        'date': todayStr,
        'createdBy': 'me',
        'createdAt': Timestamp.fromDate(
            today.subtract(const Duration(hours: 1))),
        'deletedAt': null,
        'payload': {
          'body': '오늘 날씨가 너무 좋았다. 같이 산책하고 싶다.',
          'mood': '😊',
        },
      },
      {
        'type': 'date',
        'date': todayStr,
        'createdBy': 'me',
        'createdAt': Timestamp.fromDate(
            today.subtract(const Duration(hours: 2))),
        'deletedAt': null,
        'payload': {
          'title': '성수동 카페 투어',
          'place': {'name': '○○카페', 'lat': 37.54, 'lng': 127.05},
          'cost': {'amount': 45000, 'currency': 'KRW', 'payer': 'me'},
          'rating': 4,
          'review': '케이크가 진짜 맛있었음',
        },
      },
      {
        'type': 'event',
        'date': yesterdayStr,
        'createdBy': 'partner',
        'createdAt': Timestamp.fromDate(yesterday),
        'deletedAt': null,
        'payload': {
          'title': '영화 보기',
          'location': 'CGV 강남',
          'startAt': yesterday.toIso8601String(),
          'allDay': false,
        },
      },
      {
        'type': 'note',
        'date': yesterdayStr,
        'createdBy': 'me',
        'createdAt': Timestamp.fromDate(
            yesterday.subtract(const Duration(hours: 1))),
        'deletedAt': null,
        'payload': {
          'body': '같이 본 영화가 재밌었다!',
          'mood': '🎬',
        },
      },
    ];

    final batch = _db.batch();
    for (final data in samples) {
      batch.set(col.doc(), data);
    }
    await batch.commit();
    debugPrint('[FirestoreService] seedSampleData: ${samples.length}건 생성');
  }
}
