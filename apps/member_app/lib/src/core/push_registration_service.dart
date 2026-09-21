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

  /// Signed-in launches may synchronize an already-authorized device, but
  /// must never trigger the operating-system permission prompt by themselves.
  Future<void> synchronize() async {
    final messaging = await _messaging();
    if (messaging == null) return;

    try {
      final settings = await messaging.getNotificationSettings();
      if (!_authorized(settings.authorizationStatus)) return;
      await _synchronizeAuthorized(messaging);
    } on FirebaseException {
      // Provider credentials are an external release gate.
    } on SoulApiFailure {
      // A later authenticated launch retries registration.
    }
  }

  /// Called only from the explicit onboarding/settings permission action.
  /// A denial is returned to the UI but never blocks profile completion.
  Future<bool> requestPermissionAndSynchronize() async {
    final messaging = await _messaging();
    if (messaging == null) return false;

    try {
      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      if (!_authorized(settings.authorizationStatus)) return false;
      await _synchronizeAuthorized(messaging);
      return true;
    } on FirebaseException {
      return false;
    } on SoulApiFailure {
      return false;
    }
  }

  Future<FirebaseMessaging?> _messaging() async {
    if (!_supported) return null;
    final options = _firebaseOptions;
    if (options == null) return null;

    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(options: options);
    }
    return FirebaseMessaging.instance;
  }

  bool _authorized(AuthorizationStatus status) =>
      status == AuthorizationStatus.authorized ||
      status == AuthorizationStatus.provisional;

  Future<void> _synchronizeAuthorized(FirebaseMessaging messaging) async {
    await messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    final token = await messaging.getToken();
    if (token != null && token.isNotEmpty) {
      await _registerToken(token);
    }

    await _refreshSubscription?.cancel();
    _refreshSubscription = messaging.onTokenRefresh.listen(
      (token) => unawaited(_registerToken(token)),
    );
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
