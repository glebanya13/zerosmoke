import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';

import '../../core/network/api_client.dart';

/// Registers a stable device token with the API and shows local notifications
/// when new test assignments arrive (respects in-app notify settings via backend).
class PushNotificationService {
  PushNotificationService(this._apiClient);

  static const _tokenKey = 'zerosmoke.devicePushToken';

  final ApiClient _apiClient;
  final _storage = const FlutterSecureStorage();
  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  String? _token;

  Future<void> init() async {
    if (_initialized) return;
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );
    _initialized = true;
  }

  Future<String> _ensureToken() async {
    if (_token != null) return _token!;
    var stored = await _storage.read(key: _tokenKey);
    if (stored == null || stored.length < 8) {
      stored = const Uuid().v4();
      await _storage.write(key: _tokenKey, value: stored);
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
    await init();
    const android = AndroidNotificationDetails(
      'zerosmoke_tests',
      'Тесты',
      channelDescription: 'Уведомления о новых тестах',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );
    const details = NotificationDetails(
      android: android,
      iOS: DarwinNotificationDetails(),
    );
    await _plugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
    );
  }
}
