import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/services/preferences_service.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../home/presentation/providers/home_providers.dart';
import '../widgets/partner_card.dart';
import '../widgets/security_card.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customization = ref.watch(appCustomizationProvider);
    final user = FirebaseAuth.instance.currentUser;
    final lang = ref.watch(appLanguageProvider);

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(S.settingsTitle,
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),

          // 프로필
          Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor:
                    customization.themeColor.withValues(alpha: 0.2),
                child: Icon(Icons.person, color: customization.themeColor),
              ),
              title: Text(user?.displayName ?? S.myProfile),
              subtitle: Text(user?.email ?? S.profilePlaceholder),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {},
            ),
          ),
          const SizedBox(height: 8),

          // 파트너
          const PartnerCard(),
          const SizedBox(height: 24),

          // ─── 언어 ───
          Text(S.language,
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(color: Colors.grey.shade600)),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: AppLanguage.values.map((l) {
                final selected = l == lang;
                return RadioListTile<AppLanguage>(
                  title: Text(l.label),
                  value: l,
                  groupValue: lang,
                  onChanged: (v) {
                    if (v != null) {
                      ref.read(appLanguageProvider.notifier).state = v;
                      PreferencesService().setLanguage(v.name);
                    }
                  },
                  secondary: selected
                      ? Icon(Icons.check,
                          color: customization.themeColor)
                      : null,
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 24),

          // ─── 앱 꾸미기 ───
          Text(S.customize,
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(color: Colors.grey.shade600)),
          const SizedBox(height: 8),

          Card(
            clipBehavior: Clip.antiAlias,
            child: ExpansionTile(
              leading: Icon(Icons.palette_outlined,
                  color: customization.themeColor),
              title: Text(S.customize),
              initiallyExpanded: false,
              children: [
                ListTile(
                  leading:
                      Icon(Icons.edit, color: customization.themeColor),
                  title: Text(S.appNameSetting),
                  trailing: Text(customization.appName,
                      style: TextStyle(color: customization.themeColor)),
                  onTap: () => _showNameDialog(context, ref),
                ),
                const Divider(height: 1),

                // 앱 아이콘
                _SectionLabel(S.appIcon),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: List.generate(presetIcons.length, (i) {
                      final preset = presetIcons[i];
                      final isSelected = preset.icon == customization.appIcon;
                      return GestureDetector(
                        onTap: () => ref
                            .read(appCustomizationProvider.notifier)
                            .update(customization.copyWith(appIcon: preset.icon)),
                        child: Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? customization.themeColor
                                    .withValues(alpha: 0.15)
                                : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(12),
                            border: isSelected
                                ? Border.all(
                                    color: customization.themeColor, width: 2)
                                : null,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(preset.icon,
                                  size: 24,
                                  color: isSelected
                                      ? customization.themeColor
                                      : Colors.grey.shade600),
                              Text(S.iconNames[i],
                                  style: TextStyle(
                                      fontSize: 9,
                                      color: isSelected
                                          ? customization.themeColor
                                          : Colors.grey.shade500)),
                            ],
                          ),
                        ),
                      );
                    }),
                  ),
                ),
                const Divider(height: 1),

                // 테마 색상
                _SectionLabel(S.themeColor),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
                  child: Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: List.generate(presetColors.length, (i) {
                      final preset = presetColors[i];
                      final isSelected =
                          preset.color == customization.themeColor;
                      return GestureDetector(
                        onTap: () => ref
                            .read(appCustomizationProvider.notifier)
                            .update(customization.copyWith(themeColor: preset.color)),
                        child: Column(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: preset.color,
                                shape: BoxShape.circle,
                                border: isSelected
                                    ? Border.all(color: Colors.white, width: 3)
                                    : null,
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                            color: preset.color
                                                .withValues(alpha: 0.5),
                                            blurRadius: 8,
                                            spreadRadius: 1)
                                      ]
                                    : null,
                              ),
                              child: isSelected
                                  ? const Icon(Icons.check,
                                      color: Colors.white, size: 20)
                                  : null,
                            ),
                            const SizedBox(height: 4),
                            Text(S.colorNames[i],
                                style: TextStyle(
                                    fontSize: 10,
                                    color: isSelected
                                        ? preset.color
                                        : Colors.grey.shade500,
                                    fontWeight: isSelected
                                        ? FontWeight.w600
                                        : FontWeight.normal)),
                          ],
                        ),
                      );
                    }),
                  ),
                ),
                const Divider(height: 1),

                // 배경 색상
                _SectionLabel(S.bgColor),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
                  child: Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: List.generate(presetBackgrounds.length, (i) {
                      final preset = presetBackgrounds[i];
                      final isSelected =
                          preset.color == customization.backgroundColor;
                      final isDark =
                          ThemeData.estimateBrightnessForColor(preset.color) ==
                              Brightness.dark;
                      return GestureDetector(
                        onTap: () => ref
                            .read(appCustomizationProvider.notifier)
                            .update(customization.copyWith(
                                backgroundColor: preset.color)),
                        child: Column(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: preset.color,
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: isSelected
                                        ? customization.themeColor
                                        : Colors.grey.shade300,
                                    width: isSelected ? 3 : 1),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                            color: customization.themeColor
                                                .withValues(alpha: 0.4),
                                            blurRadius: 8,
                                            spreadRadius: 1)
                                      ]
                                    : null,
                              ),
                              child: isSelected
                                  ? Icon(Icons.check,
                                      color: isDark
                                          ? Colors.white
                                          : customization.themeColor,
                                      size: 20)
                                  : null,
                            ),
                            const SizedBox(height: 4),
                            Text(S.bgNames[i],
                                style: TextStyle(
                                    fontSize: 10,
                                    color: isSelected
                                        ? customization.themeColor
                                        : Colors.grey.shade500,
                                    fontWeight: isSelected
                                        ? FontWeight.w600
                                        : FontWeight.normal)),
                          ],
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ─── Google Calendar 연동 ───
          Text(S.isKo ? '캘린더 연동' : 'Calendar Sync',
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(color: Colors.grey.shade600)),
          const SizedBox(height: 8),
          _GoogleCalendarToggle(),
          const SizedBox(height: 24),

          // ─── 일정 색상 ───
          Text(S.isKo ? '일정 색상' : 'Event Colors',
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(color: Colors.grey.shade600)),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                _ColorPickerTile(
                  label: S.isKo ? '내 일정' : 'My Events',
                  icon: Icons.person,
                  current: ref.watch(myEventColorProvider),
                  onChanged: (c) =>
                      ref.read(myEventColorProvider.notifier).update(c),
                ),
                const Divider(height: 1),
                _ColorPickerTile(
                  label: S.isKo ? '파트너 일정' : 'Partner Events',
                  icon: Icons.favorite,
                  current: ref.watch(partnerEventColorProvider),
                  onChanged: (c) =>
                      ref.read(partnerEventColorProvider.notifier).update(c),
                ),
                const Divider(height: 1),
                _ColorPickerTile(
                  label: S.isKo ? 'Google 일정' : 'Google Events',
                  icon: Icons.calendar_month,
                  current: ref.watch(googleEventColorProvider),
                  onChanged: (c) =>
                      ref.read(googleEventColorProvider.notifier).update(c),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ─── 보안 ───
          Text(S.security,
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(color: Colors.grey.shade600)),
          const SizedBox(height: 8),
          const SecurityCard(),
          const SizedBox(height: 8),

          // 기타
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: Text(S.appInfo),
                  trailing: const Text('v2.7.1'),
                  onTap: () {},
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title: Text(S.logout,
                      style: const TextStyle(color: Colors.red)),
                  onTap: () => ref.read(authServiceProvider).signOut(ref),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showNameDialog(BuildContext context, WidgetRef ref) {
    final current = ref.read(appCustomizationProvider);
    final controller = TextEditingController(text: current.appName);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(S.changeAppName),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 12,
          decoration: InputDecoration(
            hintText: S.newAppName,
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(S.cancel),
          ),
          FilledButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                ref.read(appCustomizationProvider.notifier).update(
                    current.copyWith(appName: name));
              }
              Navigator.pop(ctx);
            },
            child: Text(S.change),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
      ),
    );
  }
}

class _GoogleCalendarToggle extends ConsumerStatefulWidget {
  @override
  ConsumerState<_GoogleCalendarToggle> createState() =>
      _GoogleCalendarToggleState();
}

class _GoogleCalendarToggleState extends ConsumerState<_GoogleCalendarToggle> {
  bool _loading = false;

  Future<void> _toggle(bool enable) async {
    if (enable) {
      // auth headers가 없으면 Google 재인증
      final headers = ref.read(googleAuthHeadersProvider);
      if (headers == null) {
        setState(() => _loading = true);
        try {
          await ref.read(authServiceProvider).signInWithGoogle(ref);
        } finally {
          if (mounted) setState(() => _loading = false);
        }
        // 인증 실패 시 토글 안 함
        if (ref.read(googleAuthHeadersProvider) == null) return;
      }
    }
    ref.read(googleCalendarEnabledProvider.notifier).state = enable;
    PreferencesService().setGoogleCalendarEnabled(enable);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = ref.watch(googleCalendarEnabledProvider);
    final customization = ref.watch(appCustomizationProvider);

    return Card(
      child: SwitchListTile(
        secondary: _loading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2))
            : Icon(Icons.calendar_month, color: customization.themeColor),
        title: Text(S.isKo ? 'Google 캘린더 연동' : 'Google Calendar'),
        subtitle: Text(
          enabled
              ? (S.isKo ? '연동 중 — 일정 탭에 Google 일정 표시' : 'Syncing — Google events shown')
              : (S.isKo ? '꺼짐' : 'Off'),
        ),
        value: enabled,
        onChanged: _loading ? null : _toggle,
      ),
    );
  }
}

class _ColorPickerTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color current;
  final ValueChanged<Color> onChanged;

  const _ColorPickerTile({
    required this.label,
    required this.icon,
    required this.current,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: current),
      title: Text(label),
      trailing: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: current,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.grey.shade300),
        ),
      ),
      onTap: () => _showColorPicker(context),
    );
  }

  void _showColorPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: calendarColorPresets.map((preset) {
                  final isSelected = preset.color == current;
                  return GestureDetector(
                    onTap: () {
                      onChanged(preset.color);
                      Navigator.pop(context);
                    },
                    child: Column(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: preset.color,
                            shape: BoxShape.circle,
                            border: isSelected
                                ? Border.all(color: Colors.white, width: 3)
                                : null,
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: preset.color.withValues(alpha: 0.5),
                                      blurRadius: 8,
                                      spreadRadius: 1,
                                    )
                                  ]
                                : null,
                          ),
                          child: isSelected
                              ? const Icon(Icons.check,
                                  color: Colors.white, size: 20)
                              : null,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          preset.name,
                          style: TextStyle(
                            fontSize: 10,
                            color: isSelected
                                ? preset.color
                                : Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
