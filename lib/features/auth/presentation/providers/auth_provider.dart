import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
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

/// Google Sign-In 인스턴스 (모바일용, Drive 스코프 포함)
final _googleSignIn = GoogleSignIn(
  scopes: ['https://www.googleapis.com/auth/drive.readonly'],
);

/// Auth 서비스
class AuthService {
  final _auth = FirebaseAuth.instance;

  /// Google 로그인 (웹/모바일 분기)
  Future<UserCredential?> signInWithGoogle() async {
    if (kIsWeb) {
      return _signInWithGoogleWeb();
    }
    return _signInWithGoogleMobile();
  }

  /// 웹: Firebase Auth의 signInWithPopup 사용
  Future<UserCredential?> _signInWithGoogleWeb() async {
    final provider = GoogleAuthProvider();
    provider.addScope('https://www.googleapis.com/auth/drive.readonly');
    return _auth.signInWithPopup(provider);
  }

  /// 모바일: google_sign_in 패키지 사용
  Future<UserCredential?> _signInWithGoogleMobile() async {
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) return null;

    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    return _auth.signInWithCredential(credential);
  }

  /// Google Auth 헤더 가져오기 (Drive API용)
  Future<Map<String, String>?> getAuthHeaders() async {
    if (kIsWeb) {
      // 웹: Firebase Auth에서 토큰 가져오기
      final user = _auth.currentUser;
      if (user == null) return null;
      // OAuthCredential에서 accessToken 가져오기
      // 웹에서는 재인증으로 토큰 갱신
      final provider = GoogleAuthProvider();
      provider.addScope('https://www.googleapis.com/auth/drive.readonly');
      try {
        final result = await user.reauthenticateWithPopup(provider);
        final accessToken = result.credential?.accessToken;
        if (accessToken == null) return null;
        return {'Authorization': 'Bearer $accessToken'};
      } catch (e) {
        debugPrint('[AuthService] getAuthHeaders error: $e');
        return null;
      }
    }
    // 모바일: google_sign_in 헤더
    final user = _googleSignIn.currentUser;
    if (user == null) return null;
    return await user.authHeaders;
  }

  /// 로그아웃
  Future<void> signOut() async {
    if (!kIsWeb) await _googleSignIn.signOut();
    await _auth.signOut();
  }
}

final authServiceProvider = Provider<AuthService>((ref) => AuthService());
