import 'package:cloud_firestore/cloud_firestore.dart';

class Message {
  final String id;
  final String senderId;
  final String body;
  final DateTime sentAt;
  final Map<String, DateTime> readBy;
  final Map<String, List<String>> reactions; // emoji → [uids]
  final DateTime? hideAfter;
  final DateTime? editedAt;
  final String? imageUrl;

  Message({
    required this.id,
    required this.senderId,
    required this.body,
    required this.sentAt,
    this.readBy = const {},
    this.reactions = const {},
    this.hideAfter,
    this.editedAt,
    this.imageUrl,
  });

  bool get hasImage => imageUrl != null && imageUrl!.isNotEmpty;

  /// Firestore 문서 → Message
  factory Message.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return Message(
      id: doc.id,
      senderId: d['senderId'] as String? ?? '',
      body: d['body'] as String? ?? '',
      sentAt: (d['sentAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      readBy: (d['readBy'] as Map<String, dynamic>? ?? {}).map(
        (k, v) => MapEntry(k, (v as Timestamp).toDate()),
      ),
      reactions: (d['reactions'] as Map<String, dynamic>? ?? {}).map(
        (k, v) => MapEntry(k, List<String>.from(v as List)),
      ),
      hideAfter: (d['hideAfter'] as Timestamp?)?.toDate(),
      editedAt: (d['editedAt'] as Timestamp?)?.toDate(),
      imageUrl: d['imageUrl'] as String?,
    );
  }

  /// Message → Firestore 문서
  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'body': body,
      'sentAt': Timestamp.fromDate(sentAt),
      'readBy': readBy.map((k, v) => MapEntry(k, Timestamp.fromDate(v))),
      'reactions': reactions,
      'hideAfter': hideAfter == null ? null : Timestamp.fromDate(hideAfter!),
      'editedAt': editedAt == null ? null : Timestamp.fromDate(editedAt!),
      if (imageUrl != null) 'imageUrl': imageUrl,
    };
  }

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
      imageUrl: imageUrl,
    );
  }

  bool isVisible([DateTime? now]) {
    final t = now ?? DateTime.now();
    return hideAfter == null || hideAfter!.isAfter(t);
  }

  bool get isEphemeral {
    final h = hideAfter;
    if (h == null) return false;
    return h.difference(sentAt).inSeconds > 5;
  }

  Duration? remainingLifetime([DateTime? now]) {
    if (!isEphemeral) return null;
    final t = now ?? DateTime.now();
    final remaining = hideAfter!.difference(t);
    return remaining.isNegative ? Duration.zero : remaining;
  }
}
