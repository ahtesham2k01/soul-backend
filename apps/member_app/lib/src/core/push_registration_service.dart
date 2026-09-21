import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import 'api_client.dart';
import 'environment.dart';
import 'session_store.dart';

class PushRegistrationService {
  PushRegistrationService(this._api, this._sessions);

  final SoulApiClient _api;
  final SessionStore _sessions;
  StreamSubscription<String>? _refreshSubscription;
  bool _started = false;

  bool get _supported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  FirebaseOptions? get _firebaseOptions {
    if (!SoulEnvironment.hasFirebaseConfiguration) return null;
    return FirebaseOptions(
      apiKey: SoulEnvironment.firebaseApiKey,
      appId: SoulEnvironment.firebaseAppId,
      messagingSenderId: SoulEnvironment.firebaseMessagingSenderId,
      projectId: SoulEnvironment.firebaseProjectId,
      iosBundleId: SoulEnvironment.firebaseIosBundleId.isEmpty
          ? null
          : SoulEnvironment.firebaseIosBundleId,
    );
  }

  Future<void> synchronize() async {
    if (_started || !_supported) return;
    _started = true;
    final options = _firebaseOptions;
    if (options == null) return;

    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(options: options);
      }
      final messaging = FirebaseMessaging.instance;
      final permission = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      if (permission.authorizationStatus == AuthorizationStatus.denied) {
        return;
      }
      await messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
      final token = await messaging.getToken();
      if (token != null && token.isNotEmpty) await _registerToken(token);
      await _refreshSubscription?.cancel();
      _refreshSubscription = messaging.onTokenRefresh.listen(
        (token) => unawaited(_registerToken(token)),
      );
    } on FirebaseException {
      // Provider credentials are an external release gate.
    } on SoulApiFailure {
      // A later authenticated launch retries registration.
    }
  }

  Future<void> _registerToken(String token) async {
    if (token.isEmpty) return;
    final previousDeviceId = await _sessions.readPushDeviceId();
    final data = await _api.post(
      'devices',
      data: {
        'platform':
            defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android',
        'push_token': token,
        'device_name': defaultTargetPlatform == TargetPlatform.iOS
            ? 'SOUL iOS'
            : 'SOUL Android',
      },
    );
    final raw = data['device'];
    final deviceId = raw is Map ? raw['id']?.toString() : null;
    if (deviceId == null || deviceId.isEmpty) return;

    if (previousDeviceId != null &&
        previousDeviceId.isNotEmpty &&
        previousDeviceId != deviceId) {
      try {
        await _api.delete(
          'devices/${Uri.encodeComponent(previousDeviceId)}',
        );
      } on SoulApiFailure {
        // Newly registered token remains authoritative.
      }
    }
    await _sessions.savePushDeviceId(deviceId);
  }

  Future<void> dispose() async {
    await _refreshSubscription?.cancel();
  }
}
