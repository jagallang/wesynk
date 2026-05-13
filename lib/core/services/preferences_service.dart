import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 앱 설정 영구 저장 서비스
class PreferencesService {
  SharedPreferences? _prefs;

  static final PreferencesService _instance = PreferencesService._();
  PreferencesService._();
  factory PreferencesService() => _instance;

  /// 앱 시작 시 1회 호출
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // ─── 언어 ───

  static const _keyLanguage = 'app_language';

  String get language => _prefs?.getString(_keyLanguage) ?? 'ko';
  Future<void> setLanguage(String lang) async {
    await _prefs?.setString(_keyLanguage, lang);
  }

  // ─── 앱 커스터마이즈 ───

  static const _keyAppName = 'app_name';
  static const _keyThemeColor = 'theme_color';
  static const _keyAppIcon = 'app_icon';
  static const _keyBgColor = 'bg_color';

  String get appName => _prefs?.getString(_keyAppName) ?? 'WeSync';
  Future<void> setAppName(String name) async {
    await _prefs?.setString(_keyAppName, name);
  }

  int get themeColor => _prefs?.getInt(_keyThemeColor) ?? 0xFFE8757D;
  Future<void> setThemeColor(int color) async {
    await _prefs?.setInt(_keyThemeColor, color);
  }

  int get appIcon => _prefs?.getInt(_keyAppIcon) ?? Icons.favorite.codePoint;
  Future<void> setAppIcon(int codePoint) async {
    await _prefs?.setInt(_keyAppIcon, codePoint);
  }

  int get bgColor => _prefs?.getInt(_keyBgColor) ?? 0xFFFFFBF8;
  Future<void> setBgColor(int color) async {
    await _prefs?.setInt(_keyBgColor, color);
  }

  // ─── 일정 색상 ───

  static const _keyMyEventColor = 'my_event_color';
  static const _keyPartnerEventColor = 'partner_event_color';
  static const _keyGoogleEventColor = 'google_event_color';

  int get myEventColor => _prefs?.getInt(_keyMyEventColor) ?? 0xFFE53935;
  Future<void> setMyEventColor(int c) async {
    await _prefs?.setInt(_keyMyEventColor, c);
  }

  int get partnerEventColor =>
      _prefs?.getInt(_keyPartnerEventColor) ?? 0xFF1E88E5;
  Future<void> setPartnerEventColor(int c) async {
    await _prefs?.setInt(_keyPartnerEventColor, c);
  }

  int get googleEventColor =>
      _prefs?.getInt(_keyGoogleEventColor) ?? 0xFF8E24AA;
  Future<void> setGoogleEventColor(int c) async {
    await _prefs?.setInt(_keyGoogleEventColor, c);
  }

  // ─── Google Calendar ───

  static const _keyGoogleCalEnabled = 'google_cal_enabled';

  bool get googleCalendarEnabled =>
      _prefs?.getBool(_keyGoogleCalEnabled) ?? false;
  Future<void> setGoogleCalendarEnabled(bool v) async {
    await _prefs?.setBool(_keyGoogleCalEnabled, v);
  }

  // ─── 보안 (PIN도 SharedPreferences에 저장 — 웹 호환) ───

  static const _keyPinEnabled = 'pin_enabled';
  static const _keyLockOnTabSwitch = 'lock_on_tab_switch';
  static const _keyAutoLockDuration = 'auto_lock_duration';
  static const _keyPin = 'user_pin';

  bool get pinEnabled => _prefs?.getBool(_keyPinEnabled) ?? false;
  Future<void> setPinEnabled(bool v) async {
    await _prefs?.setBool(_keyPinEnabled, v);
  }

  bool get lockOnTabSwitch => _prefs?.getBool(_keyLockOnTabSwitch) ?? false;
  Future<void> setLockOnTabSwitch(bool v) async {
    await _prefs?.setBool(_keyLockOnTabSwitch, v);
  }

  String get autoLockDuration =>
      _prefs?.getString(_keyAutoLockDuration) ?? 'off';
  Future<void> setAutoLockDuration(String v) async {
    await _prefs?.setString(_keyAutoLockDuration, v);
  }

  /// PIN 저장
  Future<void> setPin(String? pin) async {
    if (pin == null) {
      await _prefs?.remove(_keyPin);
    } else {
      await _prefs?.setString(_keyPin, pin);
    }
  }

  /// PIN 읽기
  Future<String?> getPin() async {
    return _prefs?.getString(_keyPin);
  }

  // ─── coupleId 캐시 ───

  static const _keyCoupleId = 'couple_id';

  String get coupleId => _prefs?.getString(_keyCoupleId) ?? '';
  Future<void> setCoupleId(String id) async {
    await _prefs?.setString(_keyCoupleId, id);
  }
}
