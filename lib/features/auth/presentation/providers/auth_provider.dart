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
    debugPrint('[AuthService] no access token');
    return null;
  }

  /// 앱 시작 시 Drive 토큰 자동 복구 (3초 타임아웃)
  Future<void> handleRedirectResult() async {
    if (_auth.currentUser != null && _accessToken == null) {
      try {
        final googleUser = await _googleSignIn
            .signInSilently()
            .timeout(const Duration(seconds: 3), onTimeout: () => null);
        if (googleUser != null) {
          final auth = await googleUser.authentication;
          _accessToken = auth.accessToken;
          debugPrint('[AuthService] auto restore: token=${_accessToken != null}');
        } else {
          debugPrint('[AuthService] auto restore: silent sign-in returned null');
        }
      } catch (e) {
        debugPrint('[AuthService] auto restore error: $e');
      }
    }
  }

  Future<void> signOut() async {
    _accessToken = null;
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}

final authServiceProvider = Provider<AuthService>((ref) => AuthService());
