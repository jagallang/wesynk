import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/services/firestore_service.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../home/presentation/providers/home_providers.dart';
import '../../../security/presentation/pages/pin_screen.dart';
import '../../../security/presentation/providers/security_provider.dart';

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
                  trailing: const Text('v1.3.0'),
                  onTap: () {},
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title: Text(S.logout,
                      style: const TextStyle(color: Colors.red)),
                  onTap: () => ref.read(authServiceProvider).signOut(),
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
                ref.read(appCustomizationProvider.notifier).state =
                    current.copyWith(appName: name);
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

class _SecurityCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final security = ref.watch(securityProvider);

    return Card(
      child: Column(
        children: [
          SwitchListTile(
            title: Text(S.appLock),
            subtitle:
                Text(security.pinEnabled ? S.appLockOn : S.appLockOff),
            value: security.pinEnabled,
            onChanged: (v) {
              if (v) {
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => const PinScreen(mode: PinMode.setup)));
              } else {
                Navigator.of(context).push<bool>(MaterialPageRoute(
                  builder: (_) => PinScreen(
                    mode: PinMode.confirm,
                    onSuccess: () => ref
                        .read(securityProvider.notifier)
                        .state = const SecuritySettings(),
                  ),
                ));
              }
            },
          ),
          if (security.pinEnabled) ...[
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.lock_reset),
              title: Text(S.changePin),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.of(context).push<bool>(MaterialPageRoute(
                  builder: (_) => PinScreen(
                    mode: PinMode.confirm,
                    onSuccess: () => Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                          builder: (_) =>
                              const PinScreen(mode: PinMode.change)),
                    ),
                  ),
                ));
              },
            ),
          ],
        ],
      ),
    );
  }
}

class _PartnerCard extends ConsumerStatefulWidget {
  @override
  ConsumerState<_PartnerCard> createState() => _PartnerCardState();
}

class _PartnerCardState extends ConsumerState<_PartnerCard> {
  String? _inviteCode;
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    final coupleId = ref.watch(coupleIdProvider);
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
                  backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.2),
                  child: Icon(Icons.favorite, color: theme.colorScheme.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(S.partner,
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      Text(S.partnerPlaceholder,
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey.shade600)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(S.inviteDesc,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
            const SizedBox(height: 16),

            // 초대 링크 생성 버튼
            if (_inviteCode == null)
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
                  label: Text(S.createInvite),
                ),
              )
            else ...[
              // 초대 코드 표시
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: theme.colorScheme.primary.withValues(alpha: 0.3)),
                ),
                child: Column(
                  children: [
                    Text(S.inviteCode,
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade600)),
                    const SizedBox(height: 4),
                    Text(
                      _inviteCode!,
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 8,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(S.inviteExpiresIn,
                        style: TextStyle(
                            fontSize: 11, color: Colors.grey.shade500)),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _copyLink(coupleId),
                      icon: const Icon(Icons.copy, size: 18),
                      label: Text(S.copyLink),
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),

            // 코드 직접 입력
            Text(S.orEnterCode,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
            const SizedBox(height: 8),
            _InviteCodeInput(onAccepted: (newCoupleId) {
              ref.read(coupleIdProvider.notifier).state = newCoupleId;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(S.inviteSuccess)),
              );
            }),
          ],
        ),
      ),
    );
  }

  Future<void> _createInvite() async {
    setState(() => _loading = true);
    try {
      final coupleId = ref.read(coupleIdProvider);
      final service = ref.read(firestoreServiceProvider);

      // 기존 활성 초대 확인
      var code = await service.getActiveInvite(coupleId);
      code ??= await service.createInvite(coupleId: coupleId);

      setState(() => _inviteCode = code);
    } finally {
      setState(() => _loading = false);
    }
  }

  void _copyLink(String coupleId) {
    final link = 'https://wesynk-app.web.app?invite=$_inviteCode';
    Clipboard.setData(ClipboardData(text: link));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(S.linkCopied)),
    );
  }
}

class _InviteCodeInput extends StatefulWidget {
  final ValueChanged<String> onAccepted;
  const _InviteCodeInput({required this.onAccepted});

  @override
  State<_InviteCodeInput> createState() => _InviteCodeInputState();
}

class _InviteCodeInputState extends State<_InviteCodeInput> {
  final _controller = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _controller,
            maxLength: 6,
            textCapitalization: TextCapitalization.characters,
            decoration: InputDecoration(
              hintText: S.enterCodeHint,
              border: const OutlineInputBorder(),
              counterText: '',
              isDense: true,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
          ),
        ),
        const SizedBox(width: 8),
        FilledButton(
          onPressed: _loading ? null : _accept,
          child: _loading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : Text(S.joinPartner),
        ),
      ],
    );
  }

  Future<void> _accept() async {
    final code = _controller.text.trim().toUpperCase();
    if (code.length != 6) return;

    setState(() => _loading = true);
    try {
      final service = FirestoreService();
      final coupleId = await service.acceptInvite(code: code);

      if (coupleId != null) {
        widget.onAccepted(coupleId);
        _controller.clear();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(S.inviteInvalid)),
          );
        }
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}
