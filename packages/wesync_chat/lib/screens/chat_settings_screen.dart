import 'package:flutter/material.dart';
import '../models/chat_settings.dart';
import '../models/chat_strings.dart';

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
      appBar: AppBar(title: Text(CS.settings)),
      body: ListView(
        children: [
          _SectionHeader(title: CS.ephemeral),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Column(
              children: [
                SwitchListTile(
                  title: Text(CS.defaultEphemeral),
                  subtitle: Text(_settings.defaultEphemeral
                      ? CS.defaultEphemeralOn(
                          formatLifetime(_settings.defaultLifetime))
                      : CS.defaultEphemeralOff),
                  value: _settings.defaultEphemeral,
                  onChanged: (v) =>
                      _update(_settings.copyWith(defaultEphemeral: v)),
                ),
                if (_settings.defaultEphemeral) ...[
                  const Divider(height: 1),
                  ListTile(
                    title: Text(CS.defaultLifetime),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(formatLifetime(_settings.defaultLifetime),
                            style:
                                TextStyle(color: theme.colorScheme.primary)),
                        const Icon(Icons.chevron_right),
                      ],
                    ),
                    onTap: _showLifetimePicker,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 8),

          _SectionHeader(title: CS.display),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Column(
              children: [
                SwitchListTile(
                  title: Text(CS.showRead),
                  subtitle: Text(CS.showReadDesc),
                  value: _settings.showReadReceipts,
                  onChanged: (v) =>
                      _update(_settings.copyWith(showReadReceipts: v)),
                ),
                const Divider(height: 1),
                ListTile(
                  title: Text(CS.fontSize),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(CS.fontSizeLabels[_settings.fontSize.index],
                          style:
                              TextStyle(color: theme.colorScheme.primary)),
                      const Icon(Icons.chevron_right),
                    ],
                  ),
                  onTap: _showFontSizePicker,
                ),
                const Divider(height: 1),
                ListTile(
                  title: Text(CS.background),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color:
                              _backgroundColors[_settings.backgroundIndex],
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.chevron_right),
                    ],
                  ),
                  onTap: _showBackgroundPicker,
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          _SectionHeader(title: CS.notification),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: SwitchListTile(
              title: Text(CS.notification),
              subtitle: Text(CS.notificationDesc),
              value: _settings.notificationsEnabled,
              onChanged: (v) =>
                  _update(_settings.copyWith(notificationsEnabled: v)),
            ),
          ),
          const SizedBox(height: 8),

          _SectionHeader(title: CS.manage),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.auto_delete_outlined),
                  title: Text(CS.cleanExpired),
                  subtitle: Text(CS.cleanExpiredDesc),
                  onTap: () => ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text(CS.cleaned))),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.file_download_outlined),
                  title: Text(CS.export),
                  subtitle: Text(CS.exportDesc),
                  onTap: () => ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text(CS.exportSoon))),
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
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(CS.defaultLifetime,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            ...List.generate(ephemeralPresets.length, (i) {
              final p = ephemeralPresets[i];
              final isSelected =
                  p.$2.inSeconds == _settings.defaultLifetime.inSeconds;
              return ListTile(
                title: Text(CS.lifetimeLabels[i]),
                trailing: isSelected
                    ? const Icon(Icons.check, color: Colors.green)
                    : null,
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
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(CS.fontSize,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            ...MessageFontSize.values.map((fs) {
              final isSelected = fs == _settings.fontSize;
              return ListTile(
                title: Text(CS.fontSizeLabels[fs.index]),
                trailing: Text('ABC 가나다',
                    style: TextStyle(fontSize: fs.size)),
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
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(CS.background,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                children:
                    List.generate(_backgroundColors.length, (i) {
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
                                color:
                                    Theme.of(context).colorScheme.primary,
                                width: 3)
                            : Border.all(color: Colors.grey.shade300),
                      ),
                      child: isSelected
                          ? const Icon(Icons.check,
                              color: Colors.white, size: 20)
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
  Color(0xFFFFF8F0),
  Color(0xFFF0F4FF),
  Color(0xFFF5F0FF),
  Color(0xFFF0FFF4),
  Color(0xFFFFF0F5),
  Color(0xFFF5F5F5),
  Color(0xFFFFFDE7),
];

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 16, 4),
      child: Text(title,
          style: Theme.of(context)
              .textTheme
              .titleSmall
              ?.copyWith(color: Colors.grey.shade600)),
    );
  }
}
