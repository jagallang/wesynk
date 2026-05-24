import 'package:flutter/material.dart';
import '../models/chat_settings.dart';
import '../models/chat_strings.dart';
import '../models/message.dart';

class MessageInput extends StatefulWidget {
  final Future<void> Function(String body, Duration? lifetime,
      {String? imageUrl, ReplyTo? replyTo}) onSend;
  final bool defaultEphemeral;
  final Duration defaultLifetime;
  final VoidCallback? onPickPhoto;
  final VoidCallback? onClear;
  final Message? replyingTo;
  final VoidCallback? onCancelReply;

  const MessageInput({
    super.key,
    required this.onSend,
    this.defaultEphemeral = false,
    this.defaultLifetime = const Duration(hours: 1),
    this.onPickPhoto,
    this.onClear,
    this.replyingTo,
    this.onCancelReply,
  });

  @override
  State<MessageInput> createState() => _MessageInputState();
}

class _MessageInputState extends State<MessageInput> {
  final _controller = TextEditingController();

  bool get _isEphemeral => widget.defaultEphemeral;
  Duration get _activeLifetime => widget.defaultLifetime;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final body = _controller.text.trim();
    if (body.isEmpty) return;
    final lifetime = _isEphemeral ? _activeLifetime : null;
    final replyTo = widget.replyingTo != null
        ? ReplyTo(
            id: widget.replyingTo!.id,
            body: widget.replyingTo!.body,
            senderId: widget.replyingTo!.senderId,
            imageUrl: widget.replyingTo!.imageUrl,
          )
        : null;
    _controller.clear();
    widget.onCancelReply?.call();
    await widget.onSend(body, lifetime, replyTo: replyTo);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(top: BorderSide(color: Colors.grey.shade300)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 답장 미리보기 바
            if (widget.replyingTo != null)
              Container(
                padding: const EdgeInsets.fromLTRB(16, 8, 8, 0),
                child: Row(
                  children: [
                    Container(
                      width: 3,
                      height: 36,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            CS.isKo ? '답장' : 'Reply',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          Text(
                            widget.replyingTo!.hasImage
                                ? (CS.isKo ? '📷 사진' : '📷 Photo')
                                : widget.replyingTo!.body,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: widget.onCancelReply,
                      constraints:
                          const BoxConstraints(minWidth: 32, minHeight: 32),
                      padding: EdgeInsets.zero,
                    ),
                  ],
                ),
              ),
            // 입력 영역
            Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 20),
                        color: Colors.grey,
                        onPressed: widget.onClear,
                        tooltip: CS.isKo ? '채팅 지우기' : 'Clear chat',
                        constraints:
                            const BoxConstraints(minWidth: 36, minHeight: 36),
                        padding: EdgeInsets.zero,
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_photo_alternate_outlined,
                            size: 20),
                        color: Colors.grey,
                        onPressed: widget.onPickPhoto,
                        tooltip: CS.isKo ? '사진 보내기' : 'Send photo',
                        constraints:
                            const BoxConstraints(minWidth: 36, minHeight: 36),
                        padding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      minLines: 2,
                      maxLines: 5,
                      textInputAction: TextInputAction.newline,
                      decoration: InputDecoration(
                        hintText: _isEphemeral
                            ? CS.ephemeralHint(formatLifetime(_activeLifetime))
                            : CS.chatInput,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20)),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        isDense: true,
                      ),
                    ),
                  ),
                  IconButton(icon: const Icon(Icons.send), onPressed: _send),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
