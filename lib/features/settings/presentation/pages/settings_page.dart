import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            '설정',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 24),

          // 프로필 카드
          Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor:
                    customization.themeColor.withValues(alpha: 0.2),
                child: Icon(Icons.person, color: customization.themeColor),
              ),
              title: Text(user?.displayName ?? '내 프로필'),
              subtitle: Text(user?.email ?? '로그인 후 표시됩니다'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {},
            ),
          ),
          const SizedBox(height: 8),

          // 파트너 카드
          Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.grey.shade300,
                child: const Icon(Icons.favorite, color: Colors.white),
              ),
              title: const Text('파트너'),
              subtitle: const Text('페어링 후 표시됩니다'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {},
            ),
          ),
          const SizedBox(height: 24),

          // ─── 앱 꾸미기 ───
          Text(
            '앱 꾸미기',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Colors.grey.shade600,
                ),
          ),
          const SizedBox(height: 8),

          Card(
            child: Column(
              children: [
                // 앱 이름 변경
                ListTile(
                  leading: Icon(Icons.edit, color: customization.themeColor),
                  title: const Text('앱 이름'),
                  trailing: Text(
                    customization.appName,
                    style: TextStyle(color: customization.themeColor),
                  ),
                  onTap: () => _showNameDialog(context, ref),
                ),
                const Divider(height: 1),

                // 앱 아이콘 선택
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '앱 아이콘',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: presetIcons.map((preset) {
                      final isSelected =
                          preset.icon == customization.appIcon;
                      return GestureDetector(
                        onTap: () {
                          ref
                              .read(appCustomizationProvider.notifier)
                              .state = customization.copyWith(
                            appIcon: preset.icon,
                          );
                        },
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
                                    color: customization.themeColor,
                                    width: 2)
                                : null,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                preset.icon,
                                size: 24,
                                color: isSelected
                                    ? customization.themeColor
                                    : Colors.grey.shade600,
                              ),
                              Text(
                                preset.name,
                                style: TextStyle(
                                  fontSize: 9,
                                  color: isSelected
                                      ? customization.themeColor
                                      : Colors.grey.shade500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const Divider(height: 1),

                // 테마 색상 선택
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '테마 색상',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
                  child: Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: presetColors.map((preset) {
                      final isSelected =
                          preset.color == customization.themeColor;
                      return GestureDetector(
                        onTap: () {
                          ref
                              .read(appCustomizationProvider.notifier)
                              .state = customization.copyWith(
                            themeColor: preset.color,
                          );
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
                                    ? Border.all(
                                        color: Colors.white, width: 3)
                                    : null,
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: preset.color
                                              .withValues(alpha: 0.5),
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
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const Divider(height: 1),

                // 배경 색상 선택
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '배경 색상',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
                  child: Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: presetBackgrounds.map((preset) {
                      final isSelected =
                          preset.color == customization.backgroundColor;
                      final isDark =
                          ThemeData.estimateBrightnessForColor(preset.color) ==
                              Brightness.dark;
                      return GestureDetector(
                        onTap: () {
                          ref
                              .read(appCustomizationProvider.notifier)
                              .state = customization.copyWith(
                            backgroundColor: preset.color,
                          );
                        },
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
                                  width: isSelected ? 3 : 1,
                                ),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: customization.themeColor
                                              .withValues(alpha: 0.4),
                                          blurRadius: 8,
                                          spreadRadius: 1,
                                        )
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
                            Text(
                              preset.name,
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
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ─── 보안 설정 ───
          Text(
            '보안',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Colors.grey.shade600,
                ),
          ),
          const SizedBox(height: 8),

          _SecurityCard(),
          const SizedBox(height: 8),

          // 기타
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: const Text('앱 정보'),
                  trailing: const Text('v1.0.0'),
                  onTap: () {},
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title: const Text('로그아웃',
                      style: TextStyle(color: Colors.red)),
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
        title: const Text('앱 이름 변경'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 12,
          decoration: const InputDecoration(
            hintText: '새 앱 이름',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('취소'),
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
            child: const Text('변경'),
          ),
        ],
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
            title: const Text('앱 잠금 (비밀번호)'),
            subtitle: Text(
              security.pinEnabled
                  ? '앱 시작 시 4자리 비밀번호 입력'
                  : '꺼짐',
            ),
            value: security.pinEnabled,
            onChanged: (v) {
              if (v) {
                // ON → PIN 설정 화면
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const PinScreen(mode: PinMode.setup),
                  ),
                );
              } else {
                // OFF → 현재 비밀번호 확인 후 해제
                Navigator.of(context).push<bool>(
                  MaterialPageRoute(
                    builder: (_) => PinScreen(
                      mode: PinMode.confirm,
                      onSuccess: () {
                        ref.read(securityProvider.notifier).state =
                            const SecuritySettings();
                      },
                    ),
                  ),
                );
              }
            },
          ),
          if (security.pinEnabled) ...[
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.lock_reset),
              title: const Text('비밀번호 변경'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                // 현재 비번 확인 → 새 비번 설정
                Navigator.of(context).push<bool>(
                  MaterialPageRoute(
                    builder: (_) => PinScreen(
                      mode: PinMode.confirm,
                      onSuccess: () {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (_) =>
                                const PinScreen(mode: PinMode.change),
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}
