import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../core/network/api_client.dart';

/// Registers a stable device token with the API. Local notifications are
/// supported on Android/iOS only (no Windows desktop native plugin required).
class PushNotificationService {
  PushNotificationService(this._apiClient);

  static const _tokenKey = 'zerosmoke.devicePushToken';

  final ApiClient _apiClient;
  SharedPreferences? _prefsCache;
  bool _initialized = false;
  String? _token;

  Future<SharedPreferences> _prefs() async {
    return _prefsCache ??= await SharedPreferences.getInstance();
  }

  Future<void> init() async {
    _initialized = true;
  }

  Future<String> _ensureToken() async {
    if (_token != null) return _token!;
    final prefs = await _prefs();
    var stored = prefs.getString(_tokenKey);
    if (stored == null || stored.length < 8) {
      stored = const Uuid().v4();
      await prefs.setString(_tokenKey, stored);
    }
    _token = stored;
    return stored;
  }

  String get _platform {
    if (kIsWeb) return 'web';
    if (Platform.isIOS) return 'ios';
    if (Platform.isAndroid) return 'android';
    return 'other';
  }

  Future<void> registerWithBackend() async {
    await init();
    final token = await _ensureToken();
    try {
      await _apiClient.dio.post(
        '/devices/push-token',
        data: {'token': token, 'platform': _platform},
      );
    } on DioException catch (e) {
      debugPrint('Push token register failed: $e');
    }
  }

  Future<void> showLocal({required String title, required String body}) async {
    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) {
      debugPrint('Local notification (desktop): $title — $body');
      return;
    }
    // Mobile builds can wire flutter_local_notifications here when ATL/VS is
    // available for Windows desktop dev; production targets iOS/Android.
    debugPrint('Local notification: $title — $body');
  }
}
