import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

final authStateProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authStateProvider).valueOrNull;
});

/// Google Sign-In (Calendar readonly scope 포함)
final _googleSignIn = GoogleSignIn(
  clientId: kIsWeb
      ? '242440576982-pekndtmvlqvq3ms5k69ej6s643gp0ic0.apps.googleusercontent.com'
      : null,
  scopes: ['https://www.googleapis.com/auth/calendar.readonly'],
);

/// Google auth headers (Calendar API 호출용)
final googleAuthHeadersProvider = StateProvider<Map<String, String>?>((ref) => null);

class AuthService {
  static final AuthService _instance = AuthService._();
  factory AuthService() => _instance;
  AuthService._();

  final _auth = FirebaseAuth.instance;

  /// Google 로그인
  Future<UserCredential?> signInWithGoogle(WidgetRef ref) async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final googleAuth = await googleUser.authentication;
      debugPrint('[AuthService] signIn: user=${googleUser.email}');

      // Calendar API용 auth headers 저장
      final headers = await googleUser.authHeaders;
      ref.read(googleAuthHeadersProvider.notifier).state = headers;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      return _auth.signInWithCredential(credential);
    } catch (e) {
      debugPrint('[AuthService] signIn error: $e');
      return null;
    }
  }

  Future<void> signOut(WidgetRef ref) async {
    ref.read(googleAuthHeadersProvider.notifier).state = null;
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}

final authServiceProvider = Provider<AuthService>((ref) => AuthService());
