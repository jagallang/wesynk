import 'package:flutter/material.dart';
import '../models/chat_settings.dart';

class MessageInput extends StatefulWidget {
  final Future<void> Function(String body, Duration? lifetime) onSend;
  final bool defaultEphemeral;
  final Duration defaultLifetime;

  const MessageInput({
    super.key,
    required this.onSend,
    this.defaultEphemeral = false,
    this.defaultLifetime = const Duration(hours: 1),
  });

  @override
  State<MessageInput> createState() => _MessageInputState();
}

class _MessageInputState extends State<MessageInput> {
  final _controller = TextEditingController();
  bool? _ephemeralOverride; // null이면 설정 기본값 사용
  Duration _lastLifetime = const Duration(hours: 1);

  bool get _isEphemeral =>
      _ephemeralOverride ?? widget.defaultEphemeral;

  Duration get _activeLifetime =>
      widget.defaultEphemeral ? widget.defaultLifetime : _lastLifetime;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final body = _controller.text.trim();
    if (body.isEmpty) return;

    final lifetime = _isEphemeral ? _activeLifetime : null;
    _controller.clear();
    setState(() => _ephemeralOverride = null);

    await widget.onSend(body, lifetime);
  }

  Future<void> _toggleEphemeral() async {
    final result = await _pickMessageMode(context, _isEphemeral, _lastLifetime);
    if (result == null) return;
    if (result == Duration.zero) {
      // 영구 저장 선택
      setState(() => _ephemeralOverride = false);
    } else {
      // 휘발 수명 선택
      setState(() {
        _ephemeralOverride = true;
        _lastLifetime = result;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ephemeral = _isEphemeral;
    final lifetime = _activeLifetime;

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(top: BorderSide(color: Colors.grey.shade300)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            IconButton(
              icon: Icon(
                Icons.timer_outlined,
                color: ephemeral ? theme.colorScheme.primary : Colors.grey,
              ),
              onPressed: _toggleEphemeral,
              tooltip: ephemeral
                  ? '${formatLifetime(lifetime)} 휘발 (탭하면 해제)'
                  : '휘발 메시지',
            ),
            Expanded(
              child: TextField(
                controller: _controller,
                minLines: 3,
                maxLines: 5,
                textInputAction: TextInputAction.newline,
                decoration: InputDecoration(
                  hintText: ephemeral
                      ? '${formatLifetime(lifetime)} 후 사라질 메시지'
                      : '메시지 입력...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  isDense: true,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.send),
              onPressed: _send,
            ),
          ],
        ),
      ),
    );
  }
}

/// 메시지 모드 선택: 영구 저장(Duration.zero) 또는 휘발(Duration).
/// null이면 취소.
Future<Duration?> _pickMessageMode(
    BuildContext context, bool currentlyEphemeral, Duration lastLifetime) async {
  return showModalBottomSheet<Duration>(
    context: context,
    builder: (_) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              '메시지 보관 방식',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          // 영구 저장
          ListTile(
            leading: Icon(
              Icons.save_outlined,
              color: !currentlyEphemeral ? Theme.of(context).colorScheme.primary : Colors.grey,
            ),
            title: const Text('영구 저장'),
            subtitle: const Text('메시지가 삭제 전까지 보관됩니다'),
            trailing: !currentlyEphemeral
                ? Icon(Icons.check_circle, color: Theme.of(context).colorScheme.primary)
                : null,
            onTap: () => Navigator.pop(context, Duration.zero),
          ),
          const Divider(height: 1),
          // 휘발 섹션 헤더
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '휘발 메시지 (자동 사라짐)',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ephemeralPresets.map((p) {
                final isSelected = currentlyEphemeral &&
                    p.$2.inSeconds == lastLifetime.inSeconds;
                return ActionChip(
                  label: Text(p.$1),
                  side: isSelected
                      ? BorderSide(color: Theme.of(context).colorScheme.primary)
                      : null,
                  onPressed: () => Navigator.pop(context, p.$2),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    ),
  );
}
