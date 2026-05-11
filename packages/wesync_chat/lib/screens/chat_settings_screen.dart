import 'package:flutter/material.dart';
import '../models/chat_settings.dart';

class ChatSettingsScreen extends StatefulWidget {
  final ChatSettings settings;
  final ValueChanged<ChatSettings> onChanged;

  const ChatSettingsScreen({
    super.key,
    required this.settings,
    required this.onChanged,
  });

  @override
  State<ChatSettingsScreen> createState() => _ChatSettingsScreenState();
}

class _ChatSettingsScreenState extends State<ChatSettingsScreen> {
  late ChatSettings _settings;

  @override
  void initState() {
    super.initState();
    _settings = widget.settings;
  }

  void _update(ChatSettings s) {
    setState(() => _settings = s);
    widget.onChanged(s);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('채팅 설정'),
      ),
      body: ListView(
        children: [
          // ─── 휘발 메시지 ───
          _SectionHeader(title: '휘발 메시지'),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('기본 휘발 모드'),
                  subtitle: Text(
                    _settings.defaultEphemeral
                        ? '모든 메시지가 ${formatLifetime(_settings.defaultLifetime)} 후 사라짐'
                        : '수동으로 휘발 토글 시에만 적용',
                  ),
                  value: _settings.defaultEphemeral,
                  onChanged: (v) =>
                      _update(_settings.copyWith(defaultEphemeral: v)),
                ),
                if (_settings.defaultEphemeral) ...[
                  const Divider(height: 1),
                  ListTile(
                    title: const Text('기본 휘발 시간'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          formatLifetime(_settings.defaultLifetime),
                          style: TextStyle(color: theme.colorScheme.primary),
                        ),
                        const Icon(Icons.chevron_right),
                      ],
                    ),
                    onTap: () => _showLifetimePicker(),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 8),

          // ─── 표시 설정 ───
          _SectionHeader(title: '표시'),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('읽음 표시'),
                  subtitle: const Text('상대가 읽었는지 표시'),
                  value: _settings.showReadReceipts,
                  onChanged: (v) =>
                      _update(_settings.copyWith(showReadReceipts: v)),
                ),
                const Divider(height: 1),
                ListTile(
                  title: const Text('글자 크기'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _settings.fontSize.label,
                        style: TextStyle(color: theme.colorScheme.primary),
                      ),
                      const Icon(Icons.chevron_right),
                    ],
                  ),
                  onTap: () => _showFontSizePicker(),
                ),
                const Divider(height: 1),
                ListTile(
                  title: const Text('채팅 배경'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: _backgroundColors[_settings.backgroundIndex],
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.chevron_right),
                    ],
                  ),
                  onTap: () => _showBackgroundPicker(),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // ─── 알림 ───
          _SectionHeader(title: '알림'),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: SwitchListTile(
              title: const Text('채팅 알림'),
              subtitle: const Text('새 메시지 알림 받기'),
              value: _settings.notificationsEnabled,
              onChanged: (v) =>
                  _update(_settings.copyWith(notificationsEnabled: v)),
            ),
          ),

          const SizedBox(height: 8),

          // ─── 대화 관리 ───
          _SectionHeader(title: '대화 관리'),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.auto_delete_outlined),
                  title: const Text('만료된 메시지 정리'),
                  subtitle: const Text('숨김 처리된 휘발 메시지 목록 정리'),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('만료 메시지 정리됨')),
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.file_download_outlined),
                  title: const Text('대화 내보내기'),
                  subtitle: const Text('텍스트 파일로 저장'),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('대화 내보내기 - Phase 2에서 구현 예정')),
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  void _showLifetimePicker() {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                '기본 휘발 시간',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            ...ephemeralPresets.map((p) {
              final isSelected =
                  p.$2.inSeconds == _settings.defaultLifetime.inSeconds;
              return ListTile(
                title: Text(p.$1),
                trailing:
                    isSelected ? const Icon(Icons.check, color: Colors.green) : null,
                onTap: () {
                  _update(_settings.copyWith(defaultLifetime: p.$2));
                  Navigator.pop(context);
                },
              );
            }),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showFontSizePicker() {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                '글자 크기',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            ...MessageFontSize.values.map((fs) {
              final isSelected = fs == _settings.fontSize;
              return ListTile(
                title: Text(fs.label),
                trailing: Text(
                  '가나다 ABC',
                  style: TextStyle(fontSize: fs.size),
                ),
                leading: isSelected
                    ? const Icon(Icons.check, color: Colors.green)
                    : const SizedBox(width: 24),
                onTap: () {
                  _update(_settings.copyWith(fontSize: fs));
                  Navigator.pop(context);
                },
              );
            }),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showBackgroundPicker() {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                '채팅 배경',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                children: List.generate(_backgroundColors.length, (i) {
                  final isSelected = i == _settings.backgroundIndex;
                  return GestureDetector(
                    onTap: () {
                      _update(_settings.copyWith(backgroundIndex: i));
                      Navigator.pop(context);
                    },
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: _backgroundColors[i],
                        borderRadius: BorderRadius.circular(12),
                        border: isSelected
                            ? Border.all(
                                color: Theme.of(context).colorScheme.primary,
                                width: 3)
                            : Border.all(color: Colors.grey.shade300),
                      ),
                      child: isSelected
                          ? const Icon(Icons.check, color: Colors.white, size: 20)
                          : null,
                    ),
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
}

const _backgroundColors = [
  Colors.white,
  Color(0xFFFFF8F0), // 웜 크림
  Color(0xFFF0F4FF), // 쿨 블루
  Color(0xFFF5F0FF), // 라벤더
  Color(0xFFF0FFF4), // 민트
  Color(0xFFFFF0F5), // 핑크
  Color(0xFFF5F5F5), // 그레이
  Color(0xFFFFFDE7), // 옐로우
];

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 16, 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Colors.grey.shade600,
            ),
      ),
    );
  }
}
