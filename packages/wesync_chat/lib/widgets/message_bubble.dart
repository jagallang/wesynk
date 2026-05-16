import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/chat_strings.dart';
import '../models/message.dart';

class MessageBubble extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bgColor = isMine
        ? theme.colorScheme.primary.withValues(alpha: 0.15)
        : theme.colorScheme.surfaceContainerHighest;
    final align = isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Align(
        alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
        child: Column(
          crossAxisAlignment: align,
          children: [
            if (!isMine && senderName != null && senderName!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 2),
                child: Text(
                  senderName!,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
            GestureDetector(
            onLongPress: onLongPress,
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.72,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(16),
                border: message.isEphemeral
                    ? Border.all(
                        color: theme.colorScheme.primary.withValues(alpha: 0.5),
                        width: 1,
                      )
                    : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (message.hasImage)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          message.imageUrl!,
                          width: 200,
                          fit: BoxFit.cover,
                          loadingBuilder: (_, child, progress) {
                            if (progress == null) return child;
                            return const SizedBox(
                              width: 200, height: 150,
                              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                            );
                          },
                          errorBuilder: (_, __, ___) => const SizedBox(
                            width: 200, height: 100,
                            child: Icon(Icons.broken_image, color: Colors.grey),
                          ),
                        ),
                      ),
                    ),
                  if (message.body.isNotEmpty)
                    Text(message.body, style: TextStyle(fontSize: fontSize)),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        DateFormat('HH:mm').format(message.sentAt),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: Colors.grey,
                        ),
                      ),
                      if (showReadReceipts && isMine && message.readBy.length > 1) ...[
                        const SizedBox(width: 4),
                        Text(
                          CS.chatRead,
                          style: const TextStyle(fontSize: 10, color: Colors.grey),
                        ),
                      ],
                      if (message.isEphemeral) ...[
                        const SizedBox(width: 6),
                        _RemainingBadge(message: message),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (message.reactions.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Wrap(
                spacing: 4,
                children: message.reactions.entries.map((e) {
                  return Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
