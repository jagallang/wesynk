import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/chat_strings.dart';
import '../models/message.dart';

class MessageBubble extends StatefulWidget {
  final Message message;
  final bool isMine;
  final VoidCallback onLongPress;
  final double fontSize;
  final bool showReadReceipts;
  final String? senderName;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMine,
    required this.onLongPress,
    this.fontSize = 14,
    this.showReadReceipts = true,
    this.senderName,
  });

  @override
  State<MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<MessageBubble> {
  final List<TapGestureRecognizer> _recognizers = [];

  @override
  void dispose() {
    for (final r in _recognizers) {
      r.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bgColor = widget.isMine
        ? theme.colorScheme.primary.withValues(alpha: 0.15)
        : theme.colorScheme.surfaceContainerHighest;
    final align =
        widget.isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Align(
        alignment:
            widget.isMine ? Alignment.centerRight : Alignment.centerLeft,
        child: Column(
          crossAxisAlignment: align,
          children: [
            if (!widget.isMine &&
                widget.senderName != null &&
                widget.senderName!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 2),
                child: Text(
                  widget.senderName!,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
            GestureDetector(
              onLongPress: widget.onLongPress,
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.72,
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(16),
                  border: widget.message.isEphemeral
                      ? Border.all(
                          color: theme.colorScheme.primary
                              .withValues(alpha: 0.5),
                          width: 1,
                        )
                      : null,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.message.replyTo != null)
                      Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: widget.isMine
                              ? theme.colorScheme.primary
                                  .withValues(alpha: 0.08)
                              : theme.colorScheme.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(8),
                          border: Border(
                            left: BorderSide(
                              color: theme.colorScheme.primary,
                              width: 3,
                            ),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.message.replyTo!.senderId ==
                                      widget.message.senderId
                                  ? (CS.isKo ? '나' : 'Me')
                                  : (widget.senderName ??
                                      (CS.isKo ? '상대방' : 'Partner')),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              widget.message.replyTo!.imageUrl != null
                                  ? (CS.isKo ? '📷 사진' : '📷 Photo')
                                  : widget.message.replyTo!.body,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (widget.message.hasImage)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            widget.message.imageUrl!,
                            width: 200,
                            fit: BoxFit.cover,
                            loadingBuilder: (_, child, progress) {
                              if (progress == null) return child;
                              return const SizedBox(
                                width: 200,
                                height: 150,
                                child: Center(
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2)),
                              );
                            },
                            errorBuilder: (_, __, ___) => const SizedBox(
                              width: 200,
                              height: 100,
                              child: Icon(Icons.broken_image,
                                  color: Colors.grey),
                            ),
                          ),
                        ),
                      ),
                    if (widget.message.body.isNotEmpty) _buildBody(context),
                    const SizedBox(height: 2),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          DateFormat('HH:mm').format(widget.message.sentAt),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: Colors.grey,
                          ),
                        ),
                        if (widget.showReadReceipts &&
                            widget.isMine &&
                            widget.message.readBy.length > 1) ...[
                          const SizedBox(width: 4),
                          Text(
                            CS.chatRead,
                            style: const TextStyle(
                                fontSize: 10, color: Colors.grey),
                          ),
                        ],
                        if (widget.message.isEphemeral) ...[
                          const SizedBox(width: 6),
                          _RemainingBadge(message: widget.message),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
            if (widget.message.reactions.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Wrap(
                  spacing: 4,
                  children: widget.message.reactions.entries.map((e) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Text(
                        '${e.key} ${e.value.length}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    );
                  }).toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  static final _urlRegex = RegExp(
    r'https?://[^\s<>\"\)]+',
    caseSensitive: false,
  );

  Widget _buildBody(BuildContext context) {
    final text = widget.message.body;
    final matches = _urlRegex.allMatches(text).toList();

    if (matches.isEmpty) {
      return Text(text, style: TextStyle(fontSize: widget.fontSize));
    }

    // 이전 recognizer 정리
    for (final r in _recognizers) {
      r.dispose();
    }
    _recognizers.clear();

    final spans = <InlineSpan>[];
    var lastEnd = 0;
    for (final m in matches) {
      if (m.start > lastEnd) {
        spans.add(TextSpan(
          text: text.substring(lastEnd, m.start),
          style: TextStyle(fontSize: widget.fontSize),
        ));
      }
      final url = m.group(0)!;
      final recognizer = TapGestureRecognizer()
        ..onTap = () => launchUrl(Uri.parse(url),
            mode: LaunchMode.externalApplication);
      _recognizers.add(recognizer);
      spans.add(TextSpan(
        text: url,
        style: TextStyle(
          fontSize: widget.fontSize,
          color: Colors.blue,
          decoration: TextDecoration.underline,
        ),
        recognizer: recognizer,
      ));
      lastEnd = m.end;
    }
    if (lastEnd < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastEnd),
        style: TextStyle(fontSize: widget.fontSize),
      ));
    }

    return RichText(text: TextSpan(children: spans));
  }
}

class _RemainingBadge extends StatelessWidget {
  final Message message;
  const _RemainingBadge({required this.message});

  @override
  Widget build(BuildContext context) {
    final remaining = message.remainingLifetime();
    if (remaining == null) return const SizedBox.shrink();

    final txt = _formatRemaining(remaining);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.timer_outlined, size: 12, color: Colors.grey),
        const SizedBox(width: 2),
        Text(txt, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }

  String _formatRemaining(Duration d) {
    if (d.inDays > 0) return CS.daysAfter(d.inDays);
    if (d.inHours > 0) return CS.hoursAfter(d.inHours);
    if (d.inMinutes > 0) return CS.minutesAfter(d.inMinutes);
    return CS.secondsAfter(d.inSeconds);
  }
}
