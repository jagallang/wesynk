import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/message.dart';
import '../models/chat_settings.dart';
import '../services/chat_service.dart';
import '../widgets/message_bubble.dart';
import '../widgets/message_input.dart';
import 'chat_settings_screen.dart';

class ChatScreen extends StatefulWidget {
  final String coupleId;
  final String myUid;

  const ChatScreen({
    super.key,
    required this.coupleId,
    required this.myUid,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late final ChatService _service;
  Timer? _refreshTimer;
  ChatSettings _chatSettings = const ChatSettings();

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
          // 헤더
          SafeArea(
            bottom: false,
            child: Container(
              color: Theme.of(context).colorScheme.surface,
              padding: const EdgeInsets.fromLTRB(20, 12, 8, 8),
              child: Row(
                children: [
                  Text(
                    '우리',
                    style:
                        Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                  ),
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
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.settings_outlined),
                    onPressed: _openSettings,
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 1),

          // 메시지 목록
          Expanded(
            child: StreamBuilder<List<Message>>(
              stream: _service.recentMessagesStream(),
              builder: (context, snap) {
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final all = snap.data!;
                final visible = all.where((m) => m.isVisible()).toList();

                if (visible.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble_outline,
                            size: 48, color: Colors.grey),
                        SizedBox(height: 12),
                        Text('아직 대화가 없어요',
                            style: TextStyle(color: Colors.grey)),
                        SizedBox(height: 4),
                        Text('첫 메시지를 보내보세요',
                            style:
                                TextStyle(color: Colors.grey, fontSize: 12)),
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

          // 입력창
          MessageInput(
            defaultEphemeral: _chatSettings.defaultEphemeral,
            defaultLifetime: _chatSettings.defaultLifetime,
            onSend: (body, lifetime) async {
              await _service.send(body, lifetime: lifetime);
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
              title: const Text('복사'),
              onTap: () {
                Clipboard.setData(ClipboardData(text: msg.body));
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('복사됨')),
                );
              },
            ),
            if (isMine)
              ListTile(
                leading:
                    const Icon(Icons.delete_outline, color: Colors.red),
                title:
                    const Text('삭제', style: TextStyle(color: Colors.red)),
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
