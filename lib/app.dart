import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wesync_chat/wesync_chat.dart' show CS;
import 'core/constants/app_strings.dart';
import 'core/services/preferences_service.dart';
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
  bool _initialized = false;

  void _ensureCoupleId() {
    if (_initialized) return;
    _initialized = true;

    // 즉시 동기적으로 coupleId 설정 (uid 기반)
    final uid = FirebaseAuth.instance.currentUser?.uid ?? 'temp';
    final cached = PreferencesService().coupleId;
    final coupleId = cached.isNotEmpty ? cached : 'couple-$uid';

    if (ref.read(coupleIdProvider).isEmpty) {
      ref.read(coupleIdProvider.notifier).state = coupleId;
    }

    // 비동기로 Firestore에서 최신 coupleId 조회 (백그라운드)
    _initCoupleDataAsync(uid);
  }

  Future<void> _initCoupleDataAsync(String uid) async {
    try {
      final service = ref.read(firestoreServiceProvider);
      final matched = await service.lookupCoupleId();
      final prefs = PreferencesService();

      if (matched != null && matched.isNotEmpty) {
        ref.read(coupleIdProvider.notifier).state = matched;
        await prefs.setCoupleId(matched);
        await service.ensureCoupleExists(matched);
      } else {
        final tempCoupleId = 'couple-$uid';
        await service.ensureCoupleExists(tempCoupleId);
        ref.read(coupleIdProvider.notifier).state = tempCoupleId;
        await prefs.setCoupleId(tempCoupleId);
      }
    } catch (e) {
      debugPrint('[AuthGate] _initCoupleDataAsync error: $e');
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
        if (user == null) {
          _initialized = false;
          return const LoginPage();
        }
        _ensureCoupleId();
        return const HomePage();
      },
    );
  }
}
