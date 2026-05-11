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

final _googleSignIn = GoogleSignIn(
  scopes: ['https://www.googleapis.com/auth/drive.readonly'],
  clientId: kIsWeb
      ? '242440576982-pekndtmvlqvq3ms5k69ej6s643gp0ic0.apps.googleusercontent.com'
      : null,
);

class AuthService {
  static final AuthService _instance = AuthService._();
  factory AuthService() => _instance;
  AuthService._();

  final _auth = FirebaseAuth.instance;
  String? _accessToken;

  String? get accessToken => _accessToken;

  /// Google 로그인 (google_sign_in 패키지 통합)
  Future<UserCredential?> signInWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        debugPrint('[AuthService] signIn cancelled');
        return null;
      }

      final googleAuth = await googleUser.authentication;
      _accessToken = googleAuth.accessToken;
      debugPrint('[AuthService] signIn: token=${_accessToken != null}, user=${googleUser.email}');

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

  /// Drive Auth 헤더
  Future<Map<String, String>?> getAuthHeaders() async {
    if (_accessToken != null) {
      return {'Authorization': 'Bearer $_accessToken'};
    }

    // silent sign-in으로 토큰 복구 시도
    try {
      final googleUser = await _googleSignIn.signInSilently();
      if (googleUser != null) {
        final auth = await googleUser.authentication;
        _accessToken = auth.accessToken;
        debugPrint('[AuthService] silent refresh: token=${_accessToken != null}');
        return {'Authorization': 'Bearer $_accessToken'};
      }
    } catch (e) {
      debugPrint('[AuthService] silent refresh error: $e');
    }

    debugPrint('[AuthService] no access token');
    return null;
  }

  Future<void> handleRedirectResult() async {
    // google_sign_in 방식에서는 불필요
  }

  Future<void> signOut() async {
    _accessToken = null;
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}

final authServiceProvider = Provider<AuthService>((ref) => AuthService());
