import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

class FcmService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// FCM 초기화: 권한 요청 + 토큰 등록
  Future<void> initialize(String uid) async {
    // 1. 알림 권한 요청
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    debugPrint('[FCM] permission: ${settings.authorizationStatus}');

    if (settings.authorizationStatus != AuthorizationStatus.authorized) {
      debugPrint('[FCM] permission denied');
      return;
    }

    // 2. 웹용 VAPID 키 (Firebase Console > 프로젝트 설정 > Cloud Messaging에서 확인)
    String? token;
    if (kIsWeb) {
      token = await _messaging.getToken(
        vapidKey: _vapidKey,
      );
    } else {
      token = await _messaging.getToken();
    }

    if (token != null) {
      await _saveToken(uid, token);
      debugPrint('[FCM] token saved: ${token.substring(0, 20)}...');
    }

    // 3. 토큰 갱신 리스너
    _messaging.onTokenRefresh.listen((newToken) {
      _saveToken(uid, newToken);
      debugPrint('[FCM] token refreshed');
    });
  }

  /// Firestore에 FCM 토큰 저장
  Future<void> _saveToken(String uid, String token) async {
    final platform = kIsWeb
        ? 'web'
        : (defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android');

    await _db
        .collection('users')
        .doc(uid)
        .collection('tokens')
        .doc(token.hashCode.toString())
        .set({
      'token': token,
      'platform': platform,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// 포그라운드 메시지 수신 리스너 등록
  void onForegroundMessage(void Function(RemoteMessage) handler) {
    FirebaseMessaging.onMessage.listen(handler);
  }

  // Firebase Console > 프로젝트 설정 > Cloud Messaging > 웹 푸시 인증서 키
  static const _vapidKey = '';  // TODO: Firebase Console에서 VAPID 키 입력
}
