import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'app.dart';
import 'core/services/firestore_service.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await initializeDateFormatting('ko_KR');

  // Firestore 초기화 + 샘플 데이터 시딩
  final firestore = FirestoreService();
  await firestore.ensureCoupleExists(FirestoreService.defaultCoupleId);
  await firestore.seedSampleData(FirestoreService.defaultCoupleId);

  runApp(const ProviderScope(child: WesynkApp()));
}
