import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
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
import 'core/services/fcm_service.dart';

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
  bool _initializing = false;
  String? _pendingInviteCode;

  /// 로그인 후 coupleId 결정 + 설정 로드
  Future<void> _initialize() async {
    if (_initializing) return;
    _initializing = true;

    try {
      debugPrint('[AuthGate] _initCoupleId starting...');
      await _initCoupleId();
      debugPrint('[AuthGate] _initCoupleId done. coupleId=${ref.read(coupleIdProvider)}');
      await _loadSavedSettings();
      debugPrint('[AuthGate] _loadSavedSettings done.');
      // FCM 초기화
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        final fcm = FcmService();
        await fcm.initialize(uid);
        fcm.onForegroundMessage((message) {
          final title = message.notification?.title;
          final body = message.notification?.body;
          if (title != null && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('$title: $body'),
                duration: const Duration(seconds: 3),
              ),
            );
          }
        });
      }
    } catch (e, stack) {
      debugPrint('[AuthGate] initialize error: $e\n$stack');
    }

    if (mounted) {
      setState(() => _initialized = true);
      // 초기화 후 pending invite 처리
      if (_pendingInviteCode != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showInviteCodeDialog();
        });
      }
    }
  }

  Future<void> _showInviteCodeDialog() async {
    final inviteCode = _pendingInviteCode;
    if (inviteCode == null) return;
    _pendingInviteCode = null;

    final codeCtrl = TextEditingController();
    final pairingCode = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text(S.isKo ? '페어링 코드 입력' : 'Enter Pairing Code'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              S.isKo
                  ? '파트너에게 받은 페어링 코드를 입력하세요'
                  : 'Enter the pairing code from your partner',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: codeCtrl,
              autofocus: true,
              maxLength: 20,
              decoration: InputDecoration(
                hintText: S.isKo ? '페어링 코드' : 'Pairing code',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.lock_outline),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(S.cancel),
          ),
          FilledButton(
            onPressed: () {
              final code = codeCtrl.text.trim();
              if (code.isNotEmpty) Navigator.pop(ctx, code);
            },
            child: Text(S.confirm),
          ),
        ],
      ),
    ).then((v) { codeCtrl.dispose(); return v; });

    if (pairingCode == null || pairingCode.isEmpty || !mounted) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final service = ref.read(firestoreServiceProvider);
    final coupleId = await service.acceptInvite(
      code: inviteCode,
      myUid: user.uid,
      myEmail: user.email?.toLowerCase() ?? '',
      pairingCode: pairingCode,
    );

    if (coupleId != null && mounted) {
      ref.read(coupleIdProvider.notifier).state = coupleId;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.isKo ? '파트너와 연결되었습니다!' : 'Connected with partner!')),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.isKo ? '페어링 코드가 일치하지 않습니다' : 'Pairing code does not match')),
      );
    }
  }

  /// pairing 문서에서 coupleId 복원 또는 임시 생성
  Future<void> _initCoupleId() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final email = user.email?.toLowerCase();
    final uid = user.uid;
    final db = FirebaseFirestore.instance;
    final service = ref.read(firestoreServiceProvider);

    debugPrint('[AuthGate] uid=$uid, email=$email');

    // 0. URL에 invite 파라미터가 있으면 저장 (초기화 후 다이얼로그 표시)
    if (kIsWeb) {
      final uri = Uri.base;
      final inviteCode = uri.queryParameters['invite'];
      if (inviteCode != null && inviteCode.isNotEmpty) {
        debugPrint('[AuthGate] invite code found: $inviteCode');
        _pendingInviteCode = inviteCode;
      }
    }

    // 1. pairing 문서에서 매칭된 coupleId 조회
    if (email != null) {
      debugPrint('[AuthGate] checking pairing/$email ...');
      final pairingDoc = await db.collection('pairing').doc(email).get();
      if (pairingDoc.exists) {
        final data = pairingDoc.data()!;
        final matched = data['matched'] == true;
        final matchedCoupleId = data['matchedCoupleId'] as String?;

        if (matched && matchedCoupleId != null) {
          ref.read(coupleIdProvider.notifier).state = matchedCoupleId;
          await service.ensureCoupleExists(matchedCoupleId, members: [uid]);
          debugPrint('[AuthGate] coupleId from pairing: $matchedCoupleId');
          return;
        }
      }
    }

    // 2. 하위 호환: default-couple에 데이터가 있으면 그대로 사용
    debugPrint('[AuthGate] checking default-couple items...');
    final defaultDoc = await db
        .collection('couples')
        .doc('default-couple')
        .collection('items')
        .limit(1)
        .get();
    if (defaultDoc.docs.isNotEmpty) {
      ref.read(coupleIdProvider.notifier).state = 'default-couple';
      await service.ensureCoupleExists('default-couple', members: [uid]);
      debugPrint('[AuthGate] coupleId: default-couple (legacy data)');
      return;
    }

    // 3. 새 사용자: 임시 coupleId 생성
    final tempCoupleId = 'couple-$uid';
    ref.read(coupleIdProvider.notifier).state = tempCoupleId;
    await service.ensureCoupleExists(tempCoupleId, members: [uid]);
    await service.seedSampleData(tempCoupleId);
    debugPrint('[AuthGate] coupleId: $tempCoupleId (new user)');
  }

  Future<void> _loadSavedSettings() async {
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
      if (s['myNickname'] != null) {
        ref.read(myNicknameProvider.notifier).state =
            s['myNickname'] as String;
      }
      if (s['partnerNickname'] != null) {
        ref.read(partnerNicknameProvider.notifier).state =
            s['partnerNickname'] as String;
      }
      if (s['chatTitle'] != null) {
        ref.read(chatTitleProvider.notifier).state =
            s['chatTitle'] as String;
      }
      // 보안 설정 로드 (개인 문서에서)
      ref.read(securityProvider.notifier).state =
          await loadSecurityFromFirestore();
      // 알림 설정 로드
      if (s['notif_chat'] != null) {
        ref.read(notifChatProvider.notifier).state = s['notif_chat'] as bool;
      }
      if (s['notif_calendar'] != null) {
        ref.read(notifCalendarProvider.notifier).state =
            s['notif_calendar'] as bool;
      }
      if (s['notif_album'] != null) {
        ref.read(notifAlbumProvider.notifier).state =
            s['notif_album'] as bool;
      }
      if (s['defaultTab'] != null) {
        ref.read(defaultTabProvider.notifier).state =
            (s['defaultTab'] as int).clamp(0, 2);
      }
    } catch (e) {
      debugPrint('[AuthGate] loadSettings error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
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
          _initializing = false;
          return const LoginPage();
        }
        if (!_initialized) {
          _initialize();
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        // PIN 체크 (Firestore 로드 완료 후)
        final security = ref.watch(securityProvider);
        final isUnlocked = ref.watch(isUnlockedProvider);
        if (security.pinEnabled && !isUnlocked) {
          if (security.pin == null) {
            return const PinScreen(mode: PinMode.setup);
          }
          return const PinScreen(mode: PinMode.unlock);
        }
        return const HomePage();
      },
    );
  }
}
