import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/message.dart';

class MessageBubble extends StatelessWidget {
  final Message message;
  final bool isMine;
  final VoidCallback onLongPress;
  final double fontSize;
  final bool showReadReceipts;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMine,
    required this.onLongPress,
    this.fontSize = 14,
    this.showReadReceipts = true,
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
      child: Column(
        crossAxisAlignment: align,
        children: [
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
                        const Text(
                          '읽음',
                          style: TextStyle(fontSize: 10, color: Colors.grey),
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
    if (d.inDays > 0) return '${d.inDays}일 후';
    if (d.inHours > 0) return '${d.inHours}시간 후';
    if (d.inMinutes > 0) return '${d.inMinutes}분 후';
    return '${d.inSeconds}초 후';
  }
}
