import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_strings.dart';
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
            const Divider(height: 1),
            // 탭 전환 시 잠금
            SwitchListTile(
              title: Text(S.lockOnTabSwitch),
              subtitle: Text(S.lockOnTabSwitchDesc),
              value: security.lockOnTabSwitch,
              onChanged: (v) => ref.read(securityProvider.notifier).state =
                  security.copyWith(lockOnTabSwitch: v),
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
                onTap: () {
                  ref.read(securityProvider.notifier).state =
                      security.copyWith(autoLockDuration: d);
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
}

class _PartnerCard extends ConsumerStatefulWidget {
  @override
  ConsumerState<_PartnerCard> createState() => _PartnerCardState();
}

class _PartnerCardState extends ConsumerState<_PartnerCard> {
  final _myEmailCtrl = TextEditingController();
  final _partnerEmailCtrl = TextEditingController();
  bool _loading = false;
  bool _registered = false;

  @override
  void dispose() {
    _myEmailCtrl.dispose();
    _partnerEmailCtrl.dispose();
    super.dispose();
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w\.\-]+@[\w\.\-]+\.\w+$').hasMatch(email);
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
            // 헤더
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
                      Text(S.partnerPlaceholder,
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey.shade600)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(S.pairingDesc,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
            const SizedBox(height: 16),

            if (!_registered) ...[
              // 내 이메일
              TextField(
                controller: _myEmailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: S.myEmail,
                  hintText: 'me@gmail.com',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.email_outlined),
                  isDense: true,
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),

              // 파트너 이메일
              TextField(
                controller: _partnerEmailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: S.partnerEmail,
                  hintText: S.partnerEmailHint,
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.person_add_outlined),
                  isDense: true,
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 16),

              // 페어링 등록 버튼
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _loading ||
                          !_isValidEmail(_myEmailCtrl.text.trim()) ||
                          !_isValidEmail(_partnerEmailCtrl.text.trim())
                      ? null
                      : _register,
                  icon: _loading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.link),
                  label: Text(S.requestPairing),
                ),
              ),
            ] else ...[
              // 등록 완료 → 매칭 대기/완료 상태 표시
              _PairingStatusView(
                myEmail: _myEmailCtrl.text.trim().toLowerCase(),
                partnerEmail: _partnerEmailCtrl.text.trim().toLowerCase(),
                onMatched: (coupleId) {
                  ref.read(coupleIdProvider.notifier).state = coupleId;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(S.pairingSuccess)),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _register() async {
    setState(() => _loading = true);
    try {
      final coupleId = ref.read(coupleIdProvider);
      final service = ref.read(firestoreServiceProvider);
      final matchedId = await service.registerForPairing(
        myEmail: _myEmailCtrl.text.trim(),
        partnerEmail: _partnerEmailCtrl.text.trim(),
        coupleId: coupleId,
      );

      setState(() => _registered = true);

      if (matchedId != null && mounted) {
        ref.read(coupleIdProvider.notifier).state = matchedId;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(S.pairingSuccess)),
        );
      }
    } finally {
      setState(() => _loading = false);
    }
  }
}

/// 페어링 상태 실시간 감시 (등록 후 매칭 대기/완료)
class _PairingStatusView extends ConsumerWidget {
  final String myEmail;
  final String partnerEmail;
  final ValueChanged<String> onMatched;

  const _PairingStatusView({
    required this.myEmail,
    required this.partnerEmail,
    required this.onMatched,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final service = ref.read(firestoreServiceProvider);
    final theme = Theme.of(context);

    return StreamBuilder<Map<String, dynamic>?>(
      stream: service.pairingStatusStream(myEmail),
      builder: (context, snap) {
        final data = snap.data;
        final matched = data?['matched'] == true;
        final matchedCoupleId = data?['matchedCoupleId'] as String?;

        if (matched && matchedCoupleId != null) {
          // 매칭 완료 → coupleId 업데이트
          WidgetsBinding.instance.addPostFrameCallback((_) {
            onMatched(matchedCoupleId);
          });

          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.shade300),
            ),
            child: Column(
              children: [
                const Icon(Icons.check_circle, size: 40, color: Colors.green),
                const SizedBox(height: 8),
                Text(S.partnerConnected,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 16)),
                const SizedBox(height: 4),
                Text(partnerEmail,
                    style: TextStyle(color: theme.colorScheme.primary)),
              ],
            ),
          );
        }

        // 매칭 대기 중
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              const Icon(Icons.hourglass_top, size: 32),
              const SizedBox(height: 8),
              Text(S.pairingPending,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade600)),
              const SizedBox(height: 4),
              Text(partnerEmail,
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.primary)),
              const SizedBox(height: 8),
              Text(
                S.isKo
                    ? '파트너도 같은 방법으로 이메일을 등록하면 자동 연결됩니다'
                    : 'Your partner also needs to register emails the same way',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
              ),
            ],
          ),
        );
      },
    );
  }
}
