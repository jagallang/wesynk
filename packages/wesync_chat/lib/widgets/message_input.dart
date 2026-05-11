import 'package:flutter/material.dart';
import '../models/chat_settings.dart';
import '../models/chat_strings.dart';

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
  bool? _ephemeralOverride;
  Duration _lastLifetime = const Duration(hours: 1);

  bool get _isEphemeral => _ephemeralOverride ?? widget.defaultEphemeral;
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
    final result =
        await _pickMessageMode(context, _isEphemeral, _lastLifetime);
    if (result == null) return;
    if (result == Duration.zero) {
      setState(() => _ephemeralOverride = false);
    } else {
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
              icon: Icon(Icons.timer_outlined,
                  color: ephemeral ? theme.colorScheme.primary : Colors.grey),
              onPressed: _toggleEphemeral,
              tooltip: ephemeral
                  ? CS.ephemeralTooltip(formatLifetime(lifetime))
                  : CS.ephemeral,
            ),
            Expanded(
              child: TextField(
                controller: _controller,
                minLines: 3,
                maxLines: 5,
                textInputAction: TextInputAction.newline,
                decoration: InputDecoration(
                  hintText: ephemeral
                      ? CS.ephemeralHint(formatLifetime(lifetime))
                      : CS.chatInput,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20)),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  isDense: true,
                ),
              ),
            ),
            IconButton(icon: const Icon(Icons.send), onPressed: _send),
          ],
        ),
      ),
    );
  }
}

Future<Duration?> _pickMessageMode(
    BuildContext context, bool currentlyEphemeral, Duration lastLifetime) async {
  return showModalBottomSheet<Duration>(
    context: context,
    builder: (_) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(CS.messageMode,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
          ListTile(
            leading: Icon(Icons.save_outlined,
                color: !currentlyEphemeral
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey),
            title: Text(CS.permanent),
            subtitle: Text(CS.permanentDesc),
            trailing: !currentlyEphemeral
                ? Icon(Icons.check_circle,
                    color: Theme.of(context).colorScheme.primary)
                : null,
            onTap: () => Navigator.pop(context, Duration.zero),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(CS.ephemeralSection,
                  style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(ephemeralPresets.length, (i) {
                final p = ephemeralPresets[i];
                final isSelected = currentlyEphemeral &&
                    p.$2.inSeconds == lastLifetime.inSeconds;
                return ActionChip(
                  label: Text(CS.lifetimeLabels[i]),
                  side: isSelected
                      ? BorderSide(
                          color: Theme.of(context).colorScheme.primary)
                      : null,
                  onPressed: () => Navigator.pop(context, p.$2),
                );
              }),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    ),
  );
}
