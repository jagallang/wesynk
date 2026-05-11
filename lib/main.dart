import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'app.dart';
import 'core/services/firestore_service.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await initializeDateFormatting('ko_KR');

  // 폰트 로딩 실패 시 기본 폰트로 fallback (콘솔 경고 방지)
  GoogleFonts.config.allowRuntimeFetching = true;
  GoogleFonts.pendingFonts([
    GoogleFonts.notoSansKr(),
  ]);

  // Firestore 초기화 + 샘플 데이터 시딩
  final firestore = FirestoreService();
  await firestore.ensureCoupleExists(FirestoreService.defaultCoupleId);
  await firestore.seedSampleData(FirestoreService.defaultCoupleId);

  runApp(const ProviderScope(child: WesynkApp()));
}
