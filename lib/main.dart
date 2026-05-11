import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'app.dart';
import 'core/services/firestore_service.dart';
import 'features/auth/presentation/providers/auth_provider.dart';
import 'firebase_options.dart';

/// 웹 URL에서 invite 코드 추출
String? _getInviteCodeFromUrl() {
  if (!kIsWeb) return null;
  try {
    final uri = Uri.base;
    return uri.queryParameters['invite'];
  } catch (_) {
    return null;
  }
}

/// 전역 invite 코드 (앱 시작 시 URL에서 추출)
String? pendingInviteCode;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final authService = AuthService();
  await authService.handleRedirectResult();

  final currentUser = FirebaseAuth.instance.currentUser;
  debugPrint('[main] currentUser=${currentUser?.email ?? 'null'}, token=${authService.accessToken != null}');

  // URL에서 초대 코드 확인
  pendingInviteCode = _getInviteCodeFromUrl();
  if (pendingInviteCode != null) {
    debugPrint('[main] invite code from URL: $pendingInviteCode');
  }

  await initializeDateFormatting('ko_KR');
  await initializeDateFormatting('en_US');

  GoogleFonts.config.allowRuntimeFetching = true;
  GoogleFonts.pendingFonts([GoogleFonts.notoSansKr()]);

  final firestore = FirestoreService();
  await firestore.ensureCoupleExists(FirestoreService.defaultCoupleId);
  await firestore.seedSampleData(FirestoreService.defaultCoupleId);

  runApp(const ProviderScope(child: WesynkApp()));
}
