import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wesync_chat/wesync_chat.dart' show CS;
import 'core/constants/app_strings.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/auth/presentation/providers/auth_provider.dart';
import 'features/home/presentation/pages/home_page.dart';
import 'features/home/presentation/providers/home_providers.dart';
import 'features/security/presentation/pages/pin_screen.dart';
import 'features/security/presentation/providers/security_provider.dart';

class WesynkApp extends ConsumerWidget {
  const WesynkApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customization = ref.watch(appCustomizationProvider);
    final lang = ref.watch(appLanguageProvider);
    S.setLanguage(lang);
    CS.isKo = lang == AppLanguage.ko;

    final locale = lang == AppLanguage.ko
        ? const Locale('ko', 'KR')
        : const Locale('en', 'US');

    return MaterialApp(
      title: customization.appName,
      theme: AppTheme.fromColor(customization.themeColor,
          backgroundColor: customization.backgroundColor),
      debugShowCheckedModeBanner: false,
      locale: locale,
      supportedLocales: const [Locale('ko', 'KR'), Locale('en', 'US')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const _AuthGate(),
    );
  }
}

class _AuthGate extends ConsumerStatefulWidget {
  const _AuthGate();

  @override
  ConsumerState<_AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends ConsumerState<_AuthGate> {
  bool _settingsLoaded = false;

  Future<void> _loadSavedSettings() async {
    if (_settingsLoaded) return;
    _settingsLoaded = true;

    try {
      final service = ref.read(firestoreServiceProvider);
      final coupleId = ref.read(coupleIdProvider);
      final s = await service.loadSettings(coupleId);
      if (s == null) return;

      // 언어
      if (s['language'] != null) {
        final lang = AppLanguage.values.firstWhere(
          (l) => l.name == s['language'],
          orElse: () => AppLanguage.ko,
        );
        ref.read(appLanguageProvider.notifier).state = lang;
      }

      // 앱 커스터마이즈
      final iconCode = s['appIcon'] as int?;
      final matchedIcon = iconCode != null
          ? presetIcons
              .where((p) => p.icon.codePoint == iconCode)
              .firstOrNull
              ?.icon
          : null;

      ref.read(appCustomizationProvider.notifier).state = AppCustomization(
        appName: s['appName'] as String? ?? 'WeSync',
        themeColor: s['themeColor'] != null
            ? Color(s['themeColor'] as int)
            : const Color(0xFFE8757D),
        appIcon: matchedIcon ?? Icons.favorite,
        backgroundColor: s['bgColor'] != null
            ? Color(s['bgColor'] as int)
            : const Color(0xFFFFFBF8),
      );

      // 일정 색상
      if (s['myEventColor'] != null) {
        ref.read(myEventColorProvider.notifier).state =
            Color(s['myEventColor'] as int);
      }
      if (s['partnerEventColor'] != null) {
        ref.read(partnerEventColorProvider.notifier).state =
            Color(s['partnerEventColor'] as int);
      }
      if (s['googleEventColor'] != null) {
        ref.read(googleEventColorProvider.notifier).state =
            Color(s['googleEventColor'] as int);
      }
      if (s['googleCalEnabled'] != null) {
        ref.read(googleCalendarEnabledProvider.notifier).state =
            s['googleCalEnabled'] as bool;
      }
    } catch (e) {
      debugPrint('[AuthGate] loadSettings error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final security = ref.watch(securityProvider);
    final isUnlocked = ref.watch(isUnlockedProvider);

    if (security.pinEnabled && !isUnlocked) {
      return const PinScreen(mode: PinMode.unlock);
    }

    final authState = ref.watch(authStateProvider);
    return authState.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        body: Center(child: Text('${S.error}: $e')),
      ),
      data: (user) {
        debugPrint('[AuthGate] user=${user?.email ?? 'null'}');
        if (user == null) {
          _settingsLoaded = false;
          return const LoginPage();
        }
        _loadSavedSettings();
        return const HomePage();
      },
    );
  }
}
