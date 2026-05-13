import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import '../../shared/models/item_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String get _myUid => FirebaseAuth.instance.currentUser?.uid ?? '';
  String get _myEmail =>
      FirebaseAuth.instance.currentUser?.email?.toLowerCase() ?? '';

  CollectionReference<Map<String, dynamic>> _itemsCol(String coupleId) =>
      _db.collection('couples').doc(coupleId).collection('items');

  // ─── 날짜 키 유틸 ───

  static String toDateKey(DateTime date) =>
      DateFormat('yyyy-MM-dd').format(date);

  // ─── 사용자 coupleId 조회 ───

  /// 현재 로그인 사용자의 coupleId를 pairing 문서에서 조회.
  /// 매칭되지 않았으면 null 반환.
  Future<String?> lookupCoupleId() async {
    if (_myEmail.isEmpty) return null;
    final doc = await _db.collection('pairing').doc(_myEmail).get();
    if (!doc.exists) return null;
    final data = doc.data()!;
    if (data['matched'] == true) {
      return data['matchedCoupleId'] as String?;
    }
    return null;
  }

  /// coupleId 실시간 스트림 (매칭 감지용)
  Stream<String?> coupleIdStream() {
    if (_myEmail.isEmpty) return Stream.value(null);
    return _db
        .collection('pairing')
        .doc(_myEmail)
        .snapshots()
        .map((snap) {
      final data = snap.data();
      if (data == null) return null;
      if (data['matched'] == true) {
        return data['matchedCoupleId'] as String?;
      }
      return null;
    });
  }

  // ─── 아이템 CRUD ───

  /// 특정 날짜 + 타입의 아이템 실시간 스트림
  Stream<List<Item>> itemsStream({
    required String coupleId,
    required String dateKey,
    required ItemType type,
  }) {
    return _itemsCol(coupleId)
        .where('date', isEqualTo: dateKey)
        .snapshots()
        .map((snap) {
      final items = snap.docs
          .map(Item.fromDoc)
          .where((item) => item.type == type)
          .where((item) => item.deletedAt == null)
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return items;
    });
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
        .snapshots()
        .map((snap) {
      final counts = <String, int>{};
      for (final doc in snap.docs) {
        final data = doc.data();
        if (data['deletedAt'] != null) continue;
        final d = data['date'] as String? ?? '';
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

  // ─── 초기화 ───

  /// couples 문서 초기화 (최초 1회)
  Future<void> ensureCoupleExists(String coupleId) async {
    final doc = _db.collection('couples').doc(coupleId);
    final snap = await doc.get();
    if (!snap.exists) {
      await doc.set({
        'members': [_myEmail],
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
    final todayStr = toDateKey(today);
    final yesterday = today.subtract(const Duration(days: 1));
    final yesterdayStr = toDateKey(yesterday);

    final samples = [
      {
        'type': 'event',
        'date': todayStr,
        'createdBy': _myUid,
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
        'createdBy': _myUid,
        'createdAt':
            Timestamp.fromDate(today.subtract(const Duration(hours: 1))),
        'deletedAt': null,
        'payload': {
          'body': '오늘 날씨가 너무 좋았다. 같이 산책하고 싶다.',
          'mood': '😊',
        },
      },
      {
        'type': 'date',
        'date': todayStr,
        'createdBy': _myUid,
        'createdAt':
            Timestamp.fromDate(today.subtract(const Duration(hours: 2))),
        'deletedAt': null,
        'payload': {
          'title': '성수동 카페 투어',
          'place': {'name': '○○카페'},
          'rating': 4,
          'review': '케이크가 진짜 맛있었음',
        },
      },
      {
        'type': 'event',
        'date': yesterdayStr,
        'createdBy': 'partner-sample',
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
        'createdBy': _myUid,
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

  // ─── 이메일 양방향 매칭 페어링 ───

  /// 내 이메일 + 파트너 이메일 등록 → 양방향 매칭 확인
  /// 매칭 성공 시 coupleId 반환, 대기 중이면 null
  Future<String?> registerForPairing({
    required String myEmail,
    required String partnerEmail,
    required String coupleId,
    required String pairingCode,
  }) async {
    final myKey = myEmail.toLowerCase();
    final partnerKey = partnerEmail.toLowerCase();
    final codeHash = pairingCode.hashCode.toString();

    // 내 등록 저장
    await _db.collection('pairing').doc(myKey).set({
      'myEmail': myKey,
      'partnerEmail': partnerKey,
      'coupleId': coupleId,
      'pairingCode': codeHash,
      'createdAt': Timestamp.fromDate(DateTime.now()),
    });
    debugPrint('[FirestoreService] pairing registered: $myKey → $partnerKey');

    // 상대방 등록 확인 → 양방향 매칭 체크
    return _checkMutualMatch(myKey, partnerKey, coupleId, codeHash);
  }

  /// 양방향 매칭 확인 (이메일 + 코드)
  /// 보안 규칙으로 인해 자기 문서만 업데이트 가능.
  /// 상대방의 매칭 상태는 상대방 클라이언트가 pairingStatusStream으로 감지.
  Future<String?> _checkMutualMatch(
      String myEmail, String partnerEmail, String myCoupleId, String myCodeHash) async {
    final partnerDoc =
        await _db.collection('pairing').doc(partnerEmail).get();

    if (!partnerDoc.exists) {
      debugPrint('[FirestoreService] partner not registered yet');
      return null;
    }

    final partnerData = partnerDoc.data()!;
    final theirPartner = partnerData['partnerEmail'] as String?;
    final theirCoupleId = partnerData['coupleId'] as String?;
    final theirCodeHash = partnerData['pairingCode'] as String?;

    // 상대방이 나를 파트너로 등록했는지 확인
    if (theirPartner != myEmail) {
      debugPrint('[FirestoreService] partner email mismatch: $theirPartner != $myEmail');
      return null;
    }

    // 페어링 코드 일치 확인
    if (theirCodeHash != myCodeHash) {
      debugPrint('[FirestoreService] pairing code mismatch');
      return null;
    }

    // 매칭 성공! 먼저 등록한 사람의 coupleId 사용
    final matchedCoupleId = theirCoupleId ?? myCoupleId;

    // 내 문서만 매칭 상태 기록 (상대방은 자기 클라이언트에서 감지 후 업데이트)
    final now = Timestamp.fromDate(DateTime.now());
    await _db.collection('pairing').doc(myEmail).update({
      'matched': true,
      'matchedCoupleId': matchedCoupleId,
      'matchedAt': now,
    });

    // couples 문서 생성/업데이트
    await _db.collection('couples').doc(matchedCoupleId).set({
      'members': [myEmail, partnerEmail],
      'createdAt': now,
    }, SetOptions(merge: true));

    debugPrint('[FirestoreService] MATCHED! coupleId=$matchedCoupleId');
    return matchedCoupleId;
  }

  /// 내 페어링 상태 실시간 스트림 (매칭 감지용)
  Stream<Map<String, dynamic>?> pairingStatusStream(String myEmail) {
    return _db
        .collection('pairing')
        .doc(myEmail.toLowerCase())
        .snapshots()
        .map((snap) => snap.data());
  }

  /// 상대방의 매칭 상태를 감지하여 내 문서도 업데이트
  /// pairingStatusStream에서 matched가 아닌 상태일 때 호출
  Future<String?> checkAndUpdateMatch(String myEmail) async {
    final myKey = myEmail.toLowerCase();
    final myDoc = await _db.collection('pairing').doc(myKey).get();
    if (!myDoc.exists) return null;

    final myData = myDoc.data()!;
    if (myData['matched'] == true) {
      return myData['matchedCoupleId'] as String?;
    }

    final partnerEmail = myData['partnerEmail'] as String?;
    if (partnerEmail == null) return null;

    final partnerDoc = await _db.collection('pairing').doc(partnerEmail).get();
    if (!partnerDoc.exists) return null;

    final partnerData = partnerDoc.data()!;
    if (partnerData['matched'] == true &&
        partnerData['matchedCoupleId'] != null) {
      // 상대방이 이미 매칭 완료 → 내 문서도 업데이트
      final matchedCoupleId = partnerData['matchedCoupleId'] as String;
      await _db.collection('pairing').doc(myKey).update({
        'matched': true,
        'matchedCoupleId': matchedCoupleId,
        'matchedAt': Timestamp.fromDate(DateTime.now()),
      });
      return matchedCoupleId;
    }

    return null;
  }

  /// 페어링 해제
  Future<void> disconnectPairing(String myEmail) async {
    // 본인 문서만 삭제 (보안 규칙에 의해 상대방 문서는 삭제 불가)
    await _db.collection('pairing').doc(myEmail.toLowerCase()).delete();
  }
}
