import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../security/presentation/pages/pin_screen.dart';
import '../../../security/presentation/providers/security_provider.dart';

class SecurityCard extends ConsumerWidget {
  const SecurityCard({super.key});

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
                        .reset(),
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
            SwitchListTile(
              title: Text(S.lockOnTabSwitch),
              subtitle: Text(S.lockOnTabSwitchDesc),
              value: security.lockOnTabSwitch,
              onChanged: (v) => ref.read(securityProvider.notifier).update(
                  security.copyWith(lockOnTabSwitch: v)),
            ),
            const Divider(height: 1),
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
                  ref.read(securityProvider.notifier).update(
                      security.copyWith(autoLockDuration: d));
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
