import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/message.dart';

class ChatService {
  final String coupleId;
  final String myUid;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  ChatService({required this.coupleId, required this.myUid});

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('couples').doc(coupleId).collection('messages');

  /// 최근 메시지 실시간 스트림
  Stream<List<Message>> recentMessagesStream({int limit = 50}) {
    return _col
        .orderBy('sentAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) {
      debugPrint('[ChatService] got ${snap.docs.length} messages');
      return snap.docs.map(Message.fromDoc).toList();
    });
  }

  /// 메시지 전송
  Future<void> send(String body, {Duration? lifetime}) async {
    final now = DateTime.now();
    final msg = Message(
      id: '',
      senderId: myUid,
      body: body,
      sentAt: now,
      readBy: {myUid: now},
      hideAfter: lifetime == null ? null : now.add(lifetime),
    );
    await _col.add(msg.toMap());
    debugPrint('[ChatService] sent: $body');
  }

  /// 본인 메시지 삭제 (숨김)
  Future<void> hide(String messageId) async {
    await _col.doc(messageId).update({
      'hideAfter': Timestamp.fromDate(DateTime.now()),
    });
  }

  /// 읽음 표시
  Future<void> markRead(String messageId) async {
    await _col.doc(messageId).update({
      'readBy.$myUid': Timestamp.fromDate(DateTime.now()),
    });
  }

  /// 이모지 리액션 토글 (트랜잭션)
  Future<void> toggleReaction(String messageId, String emoji) async {
    final ref = _col.doc(messageId);
    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      final reactions =
          Map<String, dynamic>.from(snap.data()?['reactions'] as Map? ?? {});
      final users = List<String>.from((reactions[emoji] as List?) ?? []);
      if (users.contains(myUid)) {
        users.remove(myUid);
      } else {
        users.add(myUid);
      }
      if (users.isEmpty) {
        reactions.remove(emoji);
      } else {
        reactions[emoji] = users;
      }
      tx.update(ref, {'reactions': reactions});
    });
  }

  /// 샘플 메시지 생성 (최초 1회)
  Future<void> seedSampleMessages() async {
    final existing = await _col.limit(1).get();
    if (existing.docs.isNotEmpty) return;

    final now = DateTime.now();
    final partnerUid = myUid == 'me' ? 'partner' : 'me';

    final samples = [
      {
        'senderId': partnerUid,
        'body': '오늘 뭐해? 🥰',
        'sentAt': Timestamp.fromDate(now.subtract(const Duration(minutes: 30))),
        'readBy': {
          partnerUid:
              Timestamp.fromDate(now.subtract(const Duration(minutes: 30)))
        },
        'reactions': <String, dynamic>{},
        'hideAfter': null,
        'editedAt': null,
      },
      {
        'senderId': myUid,
        'body': '카페 갈래? ☕',
        'sentAt': Timestamp.fromDate(now.subtract(const Duration(minutes: 28))),
        'readBy': {
          myUid:
              Timestamp.fromDate(now.subtract(const Duration(minutes: 28))),
          partnerUid:
              Timestamp.fromDate(now.subtract(const Duration(minutes: 27))),
        },
        'reactions': {
          '❤️': [partnerUid],
        },
        'hideAfter': null,
        'editedAt': null,
      },
      {
        'senderId': partnerUid,
        'body': '비밀이야...',
        'sentAt': Timestamp.fromDate(now.subtract(const Duration(minutes: 10))),
        'readBy': {
          partnerUid:
              Timestamp.fromDate(now.subtract(const Duration(minutes: 10)))
        },
        'reactions': <String, dynamic>{},
        'hideAfter': Timestamp.fromDate(now.add(const Duration(hours: 1))),
        'editedAt': null,
      },
    ];

    final batch = _db.batch();
    for (final data in samples) {
      batch.set(_col.doc(), data);
    }
    await batch.commit();
    debugPrint('[ChatService] seeded ${samples.length} sample messages');
  }

  // dispose 불필요 (Firestore 스트림은 위젯 dispose 시 자동 해제)
  void dispose() {}
}
