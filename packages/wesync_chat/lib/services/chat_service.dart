import 'dart:async';
import 'package:uuid/uuid.dart';
import '../models/message.dart';

/// Mock 인메모리 ChatService.
/// Phase 2에서 Firestore 버전으로 교체 예정.
class ChatService {
  final String coupleId;
  final String myUid;

  ChatService({required this.coupleId, required this.myUid});

  final List<Message> _messages = [];
  final _controller = StreamController<List<Message>>.broadcast();

  void _notify() {
    _controller.add(List.unmodifiable(_messages));
  }

  /// 최근 메시지 스트림. hideAfter 필터링은 UI가 처리.
  Stream<List<Message>> recentMessagesStream({int limit = 50}) {
    // 초기 데이터 전송
    Future.microtask(_notify);
    return _controller.stream;
  }

  /// 메시지 전송. lifetime이 null이면 보관, 있으면 휘발.
  Future<void> send(String body, {Duration? lifetime}) async {
    final now = DateTime.now();
    final msg = Message(
      id: const Uuid().v4(),
      senderId: myUid,
      body: body,
      sentAt: now,
      readBy: {myUid: now},
      hideAfter: lifetime == null ? null : now.add(lifetime),
    );
    _messages.insert(0, msg);
    _notify();
  }

  /// 본인 메시지 삭제 (숨김 처리).
  Future<void> hide(String messageId) async {
    final idx = _messages.indexWhere((m) => m.id == messageId);
    if (idx == -1) return;
    _messages[idx] = _messages[idx].copyWith(
      hideAfter: DateTime.now(),
    );
    _notify();
  }

  /// 읽음 표시.
  Future<void> markRead(String messageId) async {
    final idx = _messages.indexWhere((m) => m.id == messageId);
    if (idx == -1) return;
    final msg = _messages[idx];
    final newReadBy = Map<String, DateTime>.from(msg.readBy);
    newReadBy[myUid] = DateTime.now();
    _messages[idx] = msg.copyWith(readBy: newReadBy);
    _notify();
  }

  /// 이모지 리액션 토글.
  Future<void> toggleReaction(String messageId, String emoji) async {
    final idx = _messages.indexWhere((m) => m.id == messageId);
    if (idx == -1) return;
    final msg = _messages[idx];
    final newReactions = Map<String, List<String>>.from(
      msg.reactions.map((k, v) => MapEntry(k, List<String>.from(v))),
    );
    final users = newReactions[emoji] ?? [];
    if (users.contains(myUid)) {
      users.remove(myUid);
    } else {
      users.add(myUid);
    }
    if (users.isEmpty) {
      newReactions.remove(emoji);
    } else {
      newReactions[emoji] = users;
    }
    _messages[idx] = msg.copyWith(reactions: newReactions);
    _notify();
  }

  /// 샘플 데이터 주입 (테스트용).
  void addSampleMessages() {
    final now = DateTime.now();
    final partnerUid = myUid == 'me' ? 'partner' : 'me';

    _messages.addAll([
      Message(
        id: 'sample-1',
        senderId: partnerUid,
        body: '오늘 뭐해? 🥰',
        sentAt: now.subtract(const Duration(minutes: 30)),
        readBy: {partnerUid: now.subtract(const Duration(minutes: 30))},
      ),
      Message(
        id: 'sample-2',
        senderId: myUid,
        body: '카페 갈래? ☕',
        sentAt: now.subtract(const Duration(minutes: 28)),
        readBy: {
          myUid: now.subtract(const Duration(minutes: 28)),
          partnerUid: now.subtract(const Duration(minutes: 27)),
        },
        reactions: {
          '❤️': [partnerUid],
        },
      ),
      Message(
        id: 'sample-3',
        senderId: partnerUid,
        body: '비밀이야...',
        sentAt: now.subtract(const Duration(minutes: 10)),
        readBy: {partnerUid: now.subtract(const Duration(minutes: 10))},
        hideAfter: now.add(const Duration(hours: 1)),
      ),
    ]);
    _notify();
  }

  void dispose() {
    _controller.close();
  }
}
