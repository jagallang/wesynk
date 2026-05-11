import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Firebase Auth 상태 스트림
final authStateProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

/// 현재 로그인된 유저
final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authStateProvider).valueOrNull;
});

/// Google Sign-In 인스턴스 (Drive 스코프 포함)
final _googleSignIn = GoogleSignIn(
  scopes: [
    'https://www.googleapis.com/auth/drive.readonly',
  ],
);

/// 현재 Google Auth 헤더 (Drive API 호출용)
final googleAuthHeadersProvider = FutureProvider<Map<String, String>?>((ref) async {
  final user = _googleSignIn.currentUser;
  if (user == null) return null;
  return await user.authHeaders;
});

/// Auth 서비스
class AuthService {
  final _auth = FirebaseAuth.instance;

  /// Google 로그인 (Drive 스코프 포함)
  Future<UserCredential?> signInWithGoogle() async {
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) return null;

    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    return _auth.signInWithCredential(credential);
  }

  /// 현재 Google Auth 헤더 가져오기
  Future<Map<String, String>?> getAuthHeaders() async {
    final user = _googleSignIn.currentUser;
    if (user == null) return null;
    return await user.authHeaders;
  }

  /// 로그아웃
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}

final authServiceProvider = Provider<AuthService>((ref) => AuthService());
