import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

    return MaterialApp(
      title: customization.appName,
      theme: AppTheme.fromColor(customization.themeColor,
          backgroundColor: customization.backgroundColor),
      debugShowCheckedModeBanner: false,
      locale: const Locale('ko', 'KR'),
      supportedLocales: const [Locale('ko', 'KR')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const _AuthGate(),
    );
  }
}

/// Auth 상태 → PIN 잠금 → 홈 분기
/// TODO: Google 로그인 활성화 후 바이패스 제거
class _AuthGate extends ConsumerWidget {
  const _AuthGate();

  // Auth 바이패스 플래그 — Google 로그인 연동 시 false로 변경
  static const _bypassAuth = true;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // PIN 체크 (Auth 바이패스와 무관하게 동작)
    final security = ref.watch(securityProvider);
    final isUnlocked = ref.watch(isUnlockedProvider);

    if (security.pinEnabled && !isUnlocked) {
      return const PinScreen(mode: PinMode.unlock);
    }

    if (_bypassAuth) return const HomePage();

    // 실제 Auth 흐름
    final authState = ref.watch(authStateProvider);
    return authState.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        body: Center(child: Text('오류: $e')),
      ),
      data: (user) {
        if (user == null) return const LoginPage();
        return const HomePage();
      },
    );
  }
}
