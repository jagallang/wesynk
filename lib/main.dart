import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'app.dart';
import 'core/services/preferences_service.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await PreferencesService().init();

  await initializeDateFormatting('ko_KR');
  await initializeDateFormatting('en_US');

  GoogleFonts.config.allowRuntimeFetching = true;
  GoogleFonts.pendingFonts([GoogleFonts.notoSansKr()]);

  // 모든 uncaught error를 콘솔에 로그만 남기고 앱 크래시 방지
  FlutterError.onError = (details) {
    debugPrint('[FlutterError] ${details.exception}');
  };

  runZonedGuarded(
    () => runApp(const ProviderScope(child: WesynkApp())),
    (error, stack) {
      debugPrint('[UncaughtError] $error');
    },
  );
}
