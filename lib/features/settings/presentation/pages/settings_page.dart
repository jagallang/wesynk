import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dynamic_icon/flutter_dynamic_icon.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../home/presentation/providers/home_providers.dart';
import '../../../security/presentation/pages/pin_screen.dart';
import '../../../security/presentation/providers/security_provider.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  bool _saving = false;

  Future<void> _saveSettings() async {
    setState(() => _saving = true);
    try {
      final customization = ref.read(appCustomizationProvider);
      final lang = ref.read(appLanguageProvider);
      final myColor = ref.read(myEventColorProvider);
      final partnerColor = ref.read(partnerEventColorProvider);
      final googleColor = ref.read(googleEventColorProvider);
      final googleCal = ref.read(googleCalendarEnabledProvider);
      final coupleId = ref.read(coupleIdProvider);
      final service = ref.read(firestoreServiceProvider);

      await service.saveSettings(
        coupleId: coupleId,
        settings: {
          'appName': customization.appName,
          'themeColor': customization.themeColor.toARGB32(),
          'appIcon': customization.appIcon.codePoint,
          'bgColor': customization.backgroundColor.toARGB32(),
          'language': lang.name,
          'myEventColor': myColor.toARGB32(),
          'partnerEventColor': partnerColor.toARGB32(),
          'googleEventColor': googleColor.toARGB32(),
          'googleCalEnabled': googleCal,
          'myNickname': ref.read(myNicknameProvider),
          'partnerNickname': ref.read(partnerNicknameProvider),
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(S.isKo ? '설정이 저장되었습니다' : 'Settings saved')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${S.error}: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showNicknameDialog(BuildContext context, WidgetRef ref,
      StateProvider<String> provider, String title) {
    final controller = TextEditingController(text: ref.read(provider));
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 20,
          decoration: InputDecoration(
            hintText: S.isKo ? '닉네임 입력' : 'Enter nickname',
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
              ref.read(provider.notifier).state = controller.text.trim();
              Navigator.pop(ctx);
            },
            child: Text(S.confirm),
          ),
        ],
      ),
    ).then((_) => controller.dispose());
  }

  @override
  Widget build(BuildContext context) {
    final customization = ref.watch(appCustomizationProvider);
    final user = FirebaseAuth.instance.currentUser;
    final lang = ref.watch(appLanguageProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(S.settingsTitle),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [

          // 프로필
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor:
                        customization.themeColor.withValues(alpha: 0.2),
                    child: Icon(Icons.person, color: customization.themeColor),
                  ),
                  title: Text(user?.displayName ?? S.myProfile),
                  subtitle: Text(user?.email ?? S.profilePlaceholder),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.badge_outlined),
                  title: Text(S.isKo ? '내 닉네임' : 'My Nickname'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        ref.watch(myNicknameProvider).isEmpty
                            ? (S.isKo ? '설정 안 됨' : 'Not set')
                            : ref.watch(myNicknameProvider),
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.chevron_right),
                    ],
                  ),
                  onTap: () => _showNicknameDialog(
                      context, ref, myNicknameProvider,
                      S.isKo ? '내 닉네임' : 'My Nickname'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.favorite_outline),
                  title: Text(S.isKo ? '파트너 닉네임' : 'Partner Nickname'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        ref.watch(partnerNicknameProvider).isEmpty
                            ? (S.isKo ? '설정 안 됨' : 'Not set')
                            : ref.watch(partnerNicknameProvider),
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.chevron_right),
                    ],
                  ),
                  onTap: () => _showNicknameDialog(
                      context, ref, partnerNicknameProvider,
                      S.isKo ? '파트너 닉네임' : 'Partner Nickname'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // 파트너
          _PartnerCard(),
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
                            .state = customization.copyWith(appIcon: preset.icon),
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
                            .state =
                            customization.copyWith(themeColor: preset.color),
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
                            .state = customization.copyWith(
                                backgroundColor: preset.color),
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
                  colorProvider: myEventColorProvider,
                ),
                const Divider(height: 1),
                _ColorPickerTile(
                  label: S.isKo ? '파트너 일정' : 'Partner Events',
                  icon: Icons.favorite,
                  colorProvider: partnerEventColorProvider,
                ),
                const Divider(height: 1),
                _ColorPickerTile(
                  label: S.isKo ? 'Google 일정' : 'Google Events',
                  icon: Icons.calendar_month,
                  colorProvider: googleEventColorProvider,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ─── 홈화면 앱 아이콘 (iOS/Android만) ───
          if (!kIsWeb) ...[
            _AppIconSelector(),
            const SizedBox(height: 24),
          ],

          // ─── 시작 페이지 ───
          Text(S.isKo ? '시작 페이지' : 'Start Page',
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(color: Colors.grey.shade600)),
          const SizedBox(height: 8),
          _DefaultTabSelector(),
          const SizedBox(height: 24),

          // ─── 알림 ───
          Text(S.isKo ? '알림' : 'Notifications',
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(color: Colors.grey.shade600)),
          const SizedBox(height: 8),
          _NotificationCard(),
          const SizedBox(height: 24),

          // ─── 보안 ───
          Text(S.security,
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(color: Colors.grey.shade600)),
          const SizedBox(height: 8),
          _SecurityCard(),
          const SizedBox(height: 8),

          // 기타
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: Text(S.appInfo),
                  trailing: const Text('v2.7.0'),
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
            const SizedBox(height: 24),

            // ─── 저장 버튼 ───
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton.icon(
                onPressed: _saving ? null : _saveSettings,
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.save),
                label: Text(S.isKo ? '설정 저장' : 'Save Settings'),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
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
                ref.read(appCustomizationProvider.notifier).state =
                    current.copyWith(appName: name);
              }
              Navigator.pop(ctx);
            },
            child: Text(S.change),
          ),
        ],
      ),
    ).then((_) => controller.dispose());
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

class _SecurityCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final security = ref.watch(securityProvider);

    return Card(
      child: Column(
        children: [
          SwitchListTile(
            title: Text(S.appLock),
            subtitle: Text(security.pinEnabled
                ? (security.pin != null ? S.appLockOn : (S.isKo ? '비밀번호를 설정해주세요' : 'Please set a PIN'))
                : S.appLockOff),
            value: security.pinEnabled,
            onChanged: (v) async {
              if (v) {
                // 활성화: PIN 설정 화면으로
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => const PinScreen(mode: PinMode.setup)));
              } else {
                // 비활성화: 기존 PIN 확인 후 해제
                if (security.pin != null) {
                  Navigator.of(context).push<bool>(MaterialPageRoute(
                    builder: (_) => PinScreen(
                      mode: PinMode.confirm,
                      onSuccess: () async {
                        const disabled = SecuritySettings(pinEnabled: false);
                        ref.read(securityProvider.notifier).state = disabled;
                        await saveSecurityToFirestore(ref);
                      },
                    ),
                  ));
                } else {
                  const disabled = SecuritySettings(pinEnabled: false);
                  ref.read(securityProvider.notifier).state = disabled;
                  await saveSecurityToFirestore(ref);
                }
              }
            },
          ),
          if (security.pinEnabled) ...[
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.lock_reset),
              title: Text(S.changePin),
              trailing: const Icon(Icons.chevron_right),
              onTap: () async {
                final confirmed = await Navigator.of(context).push<bool>(
                  MaterialPageRoute(
                    builder: (_) => const PinScreen(mode: PinMode.confirm),
                  ),
                );
                if (confirmed == true && context.mounted) {
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const PinScreen(mode: PinMode.change),
                    ),
                  );
                }
              },
            ),
            const Divider(height: 1),
            // 앱 복귀 시 잠금
            SwitchListTile(
              title: Text(S.isKo ? '앱 복귀 시 잠금' : 'Lock on Resume'),
              subtitle: Text(S.isKo
                  ? '앱을 다시 열 때 비밀번호 입력'
                  : 'Require PIN when returning to app'),
              value: security.lockOnResume,
              onChanged: (v) async {
                final updated = security.copyWith(lockOnResume: v);
                ref.read(securityProvider.notifier).state = updated;
                await saveSecurityToFirestore(ref);
              },
            ),
            const Divider(height: 1),
            // 탭 전환 시 잠금
            SwitchListTile(
              title: Text(S.lockOnTabSwitch),
              subtitle: Text(S.lockOnTabSwitchDesc),
              value: security.lockOnTabSwitch,
              onChanged: (v) async {
                final updated = security.copyWith(lockOnTabSwitch: v);
                ref.read(securityProvider.notifier).state = updated;
                await saveSecurityToFirestore(ref);
              },
            ),
            const Divider(height: 1),
            // 자동 잠금 시간
            ListTile(
              leading: const Icon(Icons.timer_outlined),
              title: Text(S.autoLock),
              subtitle: Text(S.autoLockDesc),
              trailing: Text(
                S.isKo
                    ? security.autoLockDuration.labelKo
                    : security.autoLockDuration.labelEn,
                style: TextStyle(
                    color: Theme.of(context).colorScheme.primary),
              ),
              onTap: () => _showAutoLockPicker(context, ref, security),
            ),
          ],
        ],
      ),
    );
  }

  void _showAutoLockPicker(
      BuildContext context, WidgetRef ref, SecuritySettings security) {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(S.autoLock,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            ...AutoLockDuration.values.map((d) {
              final isSelected = d == security.autoLockDuration;
              return ListTile(
                title: Text(S.isKo ? d.labelKo : d.labelEn),
                trailing: isSelected
                    ? const Icon(Icons.check, color: Colors.green)
                    : null,
                onTap: () async {
                  final updated = security.copyWith(autoLockDuration: d);
                  ref.read(securityProvider.notifier).state = updated;
                  await saveSecurityToFirestore(ref);
                  if (context.mounted) Navigator.pop(context);
                },
              );
            }),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _PartnerCard extends ConsumerStatefulWidget {
  @override
  ConsumerState<_PartnerCard> createState() => _PartnerCardState();
}

class _PartnerCardState extends ConsumerState<_PartnerCard> {
  bool _loading = false;
  String? _inviteLink;
  String? _pairingCode;

  Future<void> _createInvite() async {
    setState(() => _loading = true);
    try {
      final user = FirebaseAuth.instance.currentUser!;
      final coupleId = ref.read(coupleIdProvider);
      final service = ref.read(firestoreServiceProvider);
      final result = await service.createInvite(
        uid: user.uid,
        coupleId: coupleId,
        email: user.email ?? '',
      );
      setState(() {
        _inviteLink = 'https://wesynk-app.web.app/?invite=${result.code}';
        _pairingCode = result.pairingCode;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${S.error}: $e')),
        );
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  void _copyLink() {
    if (_inviteLink == null) return;
    Clipboard.setData(ClipboardData(text: _inviteLink!));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(S.isKo ? '초대 링크가 복사되었습니다' : 'Invite link copied')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor:
                      theme.colorScheme.primary.withValues(alpha: 0.2),
                  child:
                      Icon(Icons.favorite, color: theme.colorScheme.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(S.partner,
                          style:
                              const TextStyle(fontWeight: FontWeight.w600)),
                      Text(
                          S.isKo
                              ? '초대 링크로 파트너를 연결하세요'
                              : 'Connect your partner with an invite link',
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey.shade600)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            if (_inviteLink == null) ...[
              Text(
                S.isKo
                    ? '초대 링크를 생성해서 파트너에게 보내주세요.\n링크와 페어링 코드를 함께 전달하세요.'
                    : 'Create an invite link and share it with your partner.\nShare the link and pairing code together.',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _loading ? null : _createInvite,
                  icon: _loading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.link),
                  label: Text(
                      S.isKo ? '초대 링크 생성' : 'Create Invite Link'),
                ),
              ),
            ] else ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: theme.colorScheme.primary.withValues(alpha: 0.3)),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.check_circle_outline,
                        size: 32, color: Colors.green),
                    const SizedBox(height: 8),
                    Text(
                      S.isKo ? '초대 링크가 생성되었습니다' : 'Invite link created',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      S.isKo ? '페어링 코드' : 'Pairing Code',
                      style: TextStyle(
                          fontSize: 11, color: Colors.grey.shade500),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _pairingCode ?? '',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 6,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      S.isKo
                          ? '링크와 함께 이 코드를 파트너에게 알려주세요'
                          : 'Share this code with the link to your partner',
                      style: TextStyle(
                          fontSize: 11, color: Colors.grey.shade500),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _inviteLink!,
                      style: TextStyle(
                          fontSize: 11, color: Colors.grey.shade600),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      S.isKo ? '24시간 후 만료 · 1회용' : 'Expires in 24h · One-time use',
                      style: TextStyle(
                          fontSize: 10, color: Colors.grey.shade400),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _copyLink,
                            icon: const Icon(Icons.copy, size: 16),
                            label: Text(S.isKo ? '링크 복사' : 'Copy'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: () {
                              _inviteLink = null;
                              _pairingCode = null;
                              _createInvite();
                            },
                            icon: const Icon(Icons.refresh, size: 16),
                            label: Text(S.isKo ? '새로 생성' : 'New Link'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
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

class _ColorPickerTile extends ConsumerWidget {
  final String label;
  final IconData icon;
  final StateProvider<Color> colorProvider;

  const _ColorPickerTile({
    required this.label,
    required this.icon,
    required this.colorProvider,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(colorProvider);

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
      onTap: () => _showColorPicker(context, ref, current),
    );
  }

  void _showColorPicker(BuildContext context, WidgetRef ref, Color current) {
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
                      ref.read(colorProvider.notifier).state = preset.color;
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

class _DefaultTabSelector extends ConsumerWidget {
  static const _tabs = [
    (icon: Icons.calendar_month, ko: '캘린더', en: 'Calendar'),
    (icon: Icons.chat_bubble_outline, ko: '채팅', en: 'Chat'),
    (icon: Icons.photo_library_outlined, ko: '앨범', en: 'Album'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(defaultTabProvider);

    return Card(
      child: Column(
        children: List.generate(_tabs.length, (i) {
          final tab = _tabs[i];
          return RadioListTile<int>(
            secondary: Icon(tab.icon),
            title: Text(S.isKo ? tab.ko : tab.en),
            value: i,
            groupValue: current,
            onChanged: (v) {
              if (v == null) return;
              ref.read(defaultTabProvider.notifier).state = v;
              final coupleId = ref.read(coupleIdProvider);
              final service = ref.read(firestoreServiceProvider);
              service.saveSettings(
                  coupleId: coupleId, settings: {'defaultTab': v});
            },
          );
        }),
      ),
    );
  }
}

class _NotificationCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatOn = ref.watch(notifChatProvider);
    final calendarOn = ref.watch(notifCalendarProvider);
    final albumOn = ref.watch(notifAlbumProvider);

    void save(String key, bool value) {
      final coupleId = ref.read(coupleIdProvider);
      final service = ref.read(firestoreServiceProvider);
      service.saveSettings(coupleId: coupleId, settings: {key: value});
    }

    return Card(
      child: Column(
        children: [
          SwitchListTile(
            secondary: const Icon(Icons.chat_bubble_outline),
            title: Text(S.isKo ? '채팅 알림' : 'Chat Notifications'),
            subtitle: Text(S.isKo ? '새 메시지 수신 시 알림' : 'Notify on new messages'),
            value: chatOn,
            onChanged: (v) {
              ref.read(notifChatProvider.notifier).state = v;
              save('notif_chat', v);
            },
          ),
          const Divider(height: 1),
          SwitchListTile(
            secondary: const Icon(Icons.calendar_month_outlined),
            title: Text(S.isKo ? '캘린더 알림' : 'Calendar Notifications'),
            subtitle: Text(S.isKo ? '새 일정/메모 추가 시 알림' : 'Notify on new events'),
            value: calendarOn,
            onChanged: (v) {
              ref.read(notifCalendarProvider.notifier).state = v;
              save('notif_calendar', v);
            },
          ),
          const Divider(height: 1),
          SwitchListTile(
            secondary: const Icon(Icons.photo_library_outlined),
            title: Text(S.isKo ? '앨범 알림' : 'Album Notifications'),
            subtitle: Text(S.isKo ? '새 사진 업로드 시 알림' : 'Notify on new photos'),
            value: albumOn,
            onChanged: (v) {
              ref.read(notifAlbumProvider.notifier).state = v;
              save('notif_album', v);
            },
          ),
        ],
      ),
    );
  }
}

class _AppIconSelector extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIcon = ref.watch(selectedAppIconProvider);
    final customization = ref.watch(appCustomizationProvider);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        leading: Icon(Icons.app_shortcut, color: customization.themeColor),
        title: Text(S.isKo ? '홈화면 앱 아이콘' : 'App Icon'),
        subtitle: Text(
          S.isKo
              ? '홈화면에 표시되는 앱 아이콘을 변경합니다'
              : 'Change the app icon on your home screen',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
        ),
        initiallyExpanded: false,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 10,
                mainAxisSpacing: 14,
                childAspectRatio: 0.75,
              ),
              itemCount: appIconPresets.length,
              itemBuilder: (context, index) {
                final preset = appIconPresets[index];
                final isSelected = selectedIcon == preset.id ||
                    (selectedIcon == null && preset.id == 'wesync_coral');
                return GestureDetector(
                  onTap: () => _changeIcon(context, ref, preset),
                  child: Column(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: preset.color,
                          borderRadius: BorderRadius.circular(14),
                          border: isSelected
                              ? Border.all(
                                  color: customization.themeColor, width: 3)
                              : Border.all(
                                  color: Colors.grey.shade200, width: 1),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color:
                                        preset.color.withValues(alpha: 0.4),
                                    blurRadius: 8,
                                    spreadRadius: 1,
                                  )
                                ]
                              : null,
                        ),
                        child: Icon(preset.icon,
                                color: Colors.white, size: 28),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        preset.shapeName,
                        style: TextStyle(
                          fontSize: 10,
                          color: isSelected
                              ? customization.themeColor
                              : Colors.grey.shade500,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                      Text(
                        preset.colorName,
                        style: TextStyle(
                          fontSize: 9,
                          color: isSelected
                              ? preset.color
                              : Colors.grey.shade400,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _changeIcon(
      BuildContext context, WidgetRef ref, AppIconPreset preset) async {
    try {
      final current = ref.read(selectedAppIconProvider);
      if (current == preset.id) return;

      if (!kIsWeb) {
        await FlutterDynamicIcon.setAlternateIconName(preset.id);
      }
      ref.read(selectedAppIconProvider.notifier).state = preset.id;

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                S.isKo ? '앱 아이콘이 변경되었습니다' : 'App icon changed'),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${S.error}: $e')),
        );
      }
    }
  }
}
