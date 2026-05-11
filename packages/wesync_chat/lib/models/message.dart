class Message {
  final String id;
  final String senderId;
  final String body;
  final DateTime sentAt;
  final Map<String, DateTime> readBy;
  final Map<String, List<String>> reactions; // emoji → [uids]
  final DateTime? hideAfter;
  final DateTime? editedAt;

  Message({
    required this.id,
    required this.senderId,
    required this.body,
    required this.sentAt,
    this.readBy = const {},
    this.reactions = const {},
    this.hideAfter,
    this.editedAt,
  });

  Message copyWith({
    Map<String, DateTime>? readBy,
    Map<String, List<String>>? reactions,
    DateTime? hideAfter,
    DateTime? editedAt,
  }) {
    return Message(
      id: id,
      senderId: senderId,
      body: body,
      sentAt: sentAt,
      readBy: readBy ?? this.readBy,
      reactions: reactions ?? this.reactions,
      hideAfter: hideAfter ?? this.hideAfter,
      editedAt: editedAt ?? this.editedAt,
    );
  }

  /// hideAfter가 null이면 영구 보관, 있으면 그 시점 후 숨김.
  bool isVisible([DateTime? now]) {
    final t = now ?? DateTime.now();
    return hideAfter == null || hideAfter!.isAfter(t);
  }

  /// 휘발 메시지인가? (sentAt과 5초 이상 차이나면 휘발)
  bool get isEphemeral {
    final h = hideAfter;
    if (h == null) return false;
    return h.difference(sentAt).inSeconds > 5;
  }

  /// 휘발 메시지의 남은 시간. 일반 메시지면 null.
  Duration? remainingLifetime([DateTime? now]) {
    if (!isEphemeral) return null;
    final t = now ?? DateTime.now();
    final remaining = hideAfter!.difference(t);
    return remaining.isNegative ? Duration.zero : remaining;
  }
}
