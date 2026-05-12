import 'package:flutter/material.dart';
import '../models/chat_settings.dart';
import '../models/chat_strings.dart';

class MessageInput extends StatefulWidget {
  final Future<void> Function(String body, Duration? lifetime,
      {String? imageUrl}) onSend;
  final bool defaultEphemeral;
  final Duration defaultLifetime;
  final VoidCallback? onPickPhoto;

  const MessageInput({
    super.key,
    required this.onSend,
    this.defaultEphemeral = false,
    this.defaultLifetime = const Duration(hours: 1),
    this.onPickPhoto,
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
    _controller.clear();
    await widget.onSend(body, lifetime);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(top: BorderSide(color: Colors.grey.shade300)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.add_photo_alternate_outlined),
              color: Colors.grey,
              onPressed: widget.onPickPhoto,
              tooltip: CS.isKo ? '사진 보내기' : 'Send photo',
            ),
            Expanded(
              child: TextField(
                controller: _controller,
                minLines: 1,
                maxLines: 5,
                textInputAction: TextInputAction.newline,
                decoration: InputDecoration(
                  hintText: _isEphemeral
                      ? CS.ephemeralHint(formatLifetime(_activeLifetime))
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
