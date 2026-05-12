import 'package:firebase_auth/firebase_auth.dart';
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

  final currentUser = FirebaseAuth.instance.currentUser;
  debugPrint('[main] currentUser=${currentUser?.email ?? 'null'}');

  await initializeDateFormatting('ko_KR');
  await initializeDateFormatting('en_US');

  GoogleFonts.config.allowRuntimeFetching = true;
  GoogleFonts.pendingFonts([GoogleFonts.notoSansKr()]);

  final firestore = FirestoreService();
  await firestore.ensureCoupleExists(FirestoreService.defaultCoupleId);
  await firestore.seedSampleData(FirestoreService.defaultCoupleId);

  runApp(const ProviderScope(child: WesynkApp()));
}
