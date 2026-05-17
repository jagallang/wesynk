import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import '../../shared/models/item_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

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

  // ─── 앱 설정 저장/로드 ───

  /// 설정을 Firestore에 저장
  Future<void> saveSettings({
    required String coupleId,
    required Map<String, dynamic> settings,
  }) async {
    await _db.collection('couples').doc(coupleId).set(
      {'settings': settings},
      SetOptions(merge: true),
    );
  }

  /// Firestore에서 설정 로드
  Future<Map<String, dynamic>?> loadSettings(String coupleId) async {
    try {
      final doc = await _db.collection('couples').doc(coupleId).get();
      return doc.data()?['settings'] as Map<String, dynamic>?;
    } catch (_) {
      return null;
    }
  }

  // ─── 채팅 지우기 타임스탬프 ───

  /// 채팅 지우기 시점 저장 (사용자별)
  Future<void> saveChatClearedAt(String coupleId, DateTime clearedAt) async {
    await _db.collection('couples').doc(coupleId).set({
      'chatClearedAt_me': Timestamp.fromDate(clearedAt),
    }, SetOptions(merge: true));
  }

  /// 채팅 지우기 시점 조회
  Future<DateTime?> getChatClearedAt(String coupleId) async {
    try {
      final doc = await _db.collection('couples').doc(coupleId).get();
      final ts = doc.data()?['chatClearedAt_me'] as Timestamp?;
      return ts?.toDate();
    } catch (_) {
      return null;
    }
  }

  /// couples 문서 초기화 + members에 uid 추가 (기존 문서도 merge)
  Future<void> ensureCoupleExists(String coupleId, {List<String>? members}) async {
    final doc = _db.collection('couples').doc(coupleId);
    final snap = await doc.get();
    if (!snap.exists) {
      await doc.set({
        'members': members ?? [],
        'createdAt': Timestamp.fromDate(DateTime.now()),
      });
    } else if (members != null && members.isNotEmpty) {
      // 기존 문서에 uid가 없으면 추가
      final existing = List<String>.from(snap.data()?['members'] ?? []);
      final updated = {...existing, ...members}.toList();
      if (updated.length != existing.length) {
        await doc.update({'members': updated});
      }
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

  // ─── 이메일 양방향 매칭 페어링 ───

  /// 내 이메일 + 파트너 이메일 등록 → 양방향 매칭 확인
  /// 매칭 성공 시 coupleId 반환, 대기 중이면 null
  Future<String?> registerForPairing({
    required String myEmail,
    required String myUid,
    required String partnerEmail,
    required String coupleId,
    required String pairingCode,
  }) async {
    final myKey = myEmail.toLowerCase();
    final partnerKey = partnerEmail.toLowerCase();
    final codeHash = sha256.convert(utf8.encode(pairingCode)).toString();

    // 내 등록 저장
    await _db.collection('pairing').doc(myKey).set({
      'myEmail': myKey,
      'uid': myUid,
      'partnerEmail': partnerKey,
      'coupleId': coupleId,
      'pairingCode': codeHash,
      'createdAt': Timestamp.fromDate(DateTime.now()),
    });
    debugPrint('[FirestoreService] pairing registered: $myKey → $partnerKey');

    // 상대방 등록 확인 → 양방향 매칭 체크
    return _checkMutualMatch(myKey, myUid, partnerKey, coupleId, codeHash);
  }

  /// 양방향 매칭 확인 (이메일 + 코드)
  Future<String?> _checkMutualMatch(
      String myEmail, String myUid, String partnerEmail, String myCoupleId, String myCodeHash) async {
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

    // 양쪽 문서에 매칭 상태 기록
    final now = Timestamp.fromDate(DateTime.now());
    await _db.collection('pairing').doc(myEmail).update({
      'matched': true,
      'matchedCoupleId': matchedCoupleId,
      'matchedAt': now,
    });
    await _db.collection('pairing').doc(partnerEmail).update({
      'matched': true,
      'matchedCoupleId': matchedCoupleId,
      'matchedAt': now,
    });

    // couples 문서 업데이트 (members는 uid 배열 — Rules에서 검증용)
    final partnerUid = partnerData['uid'] as String? ?? '';
    await _db.collection('couples').doc(matchedCoupleId).set({
      'members': [myUid, if (partnerUid.isNotEmpty) partnerUid],
      'memberEmails': [myEmail, partnerEmail],
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

  /// 페어링 해제
  Future<void> disconnectPairing(String myEmail) async {
    final doc = await _db.collection('pairing').doc(myEmail.toLowerCase()).get();
    if (doc.exists) {
      final partnerEmail = doc.data()?['partnerEmail'] as String?;
      await _db.collection('pairing').doc(myEmail.toLowerCase()).delete();
      if (partnerEmail != null) {
        await _db.collection('pairing').doc(partnerEmail).delete();
      }
    }
  }
}
