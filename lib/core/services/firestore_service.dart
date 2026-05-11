import 'package:cloud_firestore/cloud_firestore.dart';
import '../../shared/models/item_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// 바이패스 모드에서 사용할 기본 coupleId
  /// TODO: 실제 페어링 구현 후 동적으로 변경
  static const defaultCoupleId = 'default-couple';

  CollectionReference<Map<String, dynamic>> _itemsCol(String coupleId) =>
      _db.collection('couples').doc(coupleId).collection('items');

  /// 특정 날짜 + 타입의 아이템 실시간 스트림
  Stream<List<Item>> itemsStream({
    required String coupleId,
    required String dateKey,
    required ItemType type,
  }) {
    return _itemsCol(coupleId)
        .where('date', isEqualTo: dateKey)
        .where('type', isEqualTo: type.name)
        .where('deletedAt', isNull: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(Item.fromDoc).toList());
  }

  /// 월간 이벤트 개수 (캘린더 마커용)
  Stream<Map<String, int>> eventCountsStream({
    required String coupleId,
    required String firstDay,
    required String lastDay,
  }) {
    return _itemsCol(coupleId)
        .where('type', isEqualTo: 'event')
        .where('date', isGreaterThanOrEqualTo: firstDay)
        .where('date', isLessThanOrEqualTo: lastDay)
        .where('deletedAt', isNull: true)
        .snapshots()
        .map((snap) {
      final counts = <String, int>{};
      for (final doc in snap.docs) {
        final d = doc.data()['date'] as String;
        counts[d] = (counts[d] ?? 0) + 1;
      }
      return counts;
    });
  }

  /// 아이템 추가
  Future<void> addItem({
    required String coupleId,
    required Item item,
  }) async {
    await _itemsCol(coupleId).add(item.toMap());
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
}
