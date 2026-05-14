import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/message.dart';
import '../models/chat_settings.dart';
import '../models/chat_strings.dart';
import '../services/chat_service.dart';
import '../widgets/message_bubble.dart';
import '../widgets/message_input.dart';
import 'chat_settings_screen.dart';

class ChatScreen extends StatefulWidget {
  final String coupleId;
  final String myUid;
  final Future<String?> Function()? onPickPhoto;
  final VoidCallback? onOpenAppSettings;

  const ChatScreen({
    super.key,
    required this.coupleId,
    required this.myUid,
    this.onPickPhoto,
    this.onOpenAppSettings,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late final ChatService _service;
  Timer? _refreshTimer;
  ChatSettings _chatSettings = const ChatSettings();
  DateTime? _clearBefore;

  @override
  void initState() {
    super.initState();
    _service = ChatService(
      coupleId: widget.coupleId,
      myUid: widget.myUid,
    );
    _service.seedSampleMessages();
    _refreshTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _service.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = _backgroundColors[_chatSettings.backgroundIndex];

    return ColoredBox(
      color: bgColor,
      child: Column(
        children: [
          SafeArea(
            bottom: false,
            child: Container(
              color: Theme.of(context).colorScheme.surface,
              padding: const EdgeInsets.fromLTRB(20, 12, 8, 8),
              child: Row(
                children: [
                  Text(CS.chatTitle,
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  if (_chatSettings.defaultEphemeral) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.timer_outlined,
                              size: 14,
                              color: Theme.of(context).colorScheme.primary),
                          const SizedBox(width: 4),
                          Text(
                            formatLifetime(_chatSettings.defaultLifetime),
                            style: TextStyle(
                                fontSize: 12,
                                color:
                                    Theme.of(context).colorScheme.primary),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.tune_outlined),
                    onPressed: _openSettings,
                  ),
                  if (widget.onOpenAppSettings != null)
                    IconButton(
                      icon: const Icon(Icons.settings_outlined),
                      onPressed: widget.onOpenAppSettings,
                    ),
                ],
              ),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: StreamBuilder<List<Message>>(
              stream: _service.recentMessagesStream(),
              builder: (context, snap) {
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final all = snap.data!;
                final visible = all.where((m) {
                  if (!m.isVisible()) return false;
                  if (_clearBefore != null && m.sentAt.isBefore(_clearBefore!)) {
                    return false;
                  }
                  return true;
                }).toList();

                if (visible.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.chat_bubble_outline,
                            size: 48, color: Colors.grey),
                        const SizedBox(height: 12),
                        Text(CS.chatEmpty,
                            style: const TextStyle(color: Colors.grey)),
                        const SizedBox(height: 4),
                        Text(CS.chatFirst,
                            style: const TextStyle(
                                color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: visible.length,
                  itemBuilder: (context, i) {
                    final msg = visible[i];
                    final isMine = msg.senderId == widget.myUid;
                    return MessageBubble(
                      message: msg,
                      isMine: isMine,
                      fontSize: _chatSettings.fontSize.size,
                      showReadReceipts: _chatSettings.showReadReceipts,
                      onLongPress: () => _showActions(msg, isMine),
                    );
                  },
                );
              },
            ),
          ),
          MessageInput(
            defaultEphemeral: _chatSettings.defaultEphemeral,
            defaultLifetime: _chatSettings.defaultLifetime,
            onSend: (body, lifetime, {imageUrl}) async {
              await _service.send(body, lifetime: lifetime, imageUrl: imageUrl);
            },
            onClear: () {
              setState(() => _clearBefore = DateTime.now());
            },
            onPickPhoto: widget.onPickPhoto == null
                ? null
                : () async {
                    final url = await widget.onPickPhoto!();
                    if (url != null) {
                      await _service.send('', imageUrl: url);
                    }
                  },
          ),
        ],
      ),
    );
  }

  void _openSettings() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChatSettingsScreen(
          settings: _chatSettings,
          onChanged: (s) => setState(() => _chatSettings = s),
        ),
      ),
    );
  }

  void _showActions(Message msg, bool isMine) {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: ['❤️', '😂', '👍', '😮', '😢', '🔥'].map((e) {
                  return GestureDetector(
                    onTap: () {
                      _service.toggleReaction(msg.id, e);
                      Navigator.pop(context);
                    },
                    child: Text(e, style: const TextStyle(fontSize: 28)),
                  );
                }).toList(),
              ),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.copy),
              title: Text(CS.copy),
              onTap: () {
                Clipboard.setData(ClipboardData(text: msg.body));
                Navigator.pop(context);
                ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text(CS.copied)));
              },
            ),
            if (isMine)
              ListTile(
                leading:
                    const Icon(Icons.delete_outline, color: Colors.red),
                title: Text(CS.delete,
                    style: const TextStyle(color: Colors.red)),
                onTap: () {
                  _service.hide(msg.id);
                  Navigator.pop(context);
                },
              ),
          ],
        ),
      ),
    );
  }
}

const _backgroundColors = [
  Colors.white,
  Color(0xFFFFF8F0),
  Color(0xFFF0F4FF),
  Color(0xFFF5F0FF),
  Color(0xFFF0FFF4),
  Color(0xFFFFF0F5),
  Color(0xFFF5F5F5),
  Color(0xFFFFFDE7),
];
