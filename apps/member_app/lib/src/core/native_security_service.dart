import 'package:flutter/services.dart';

class NativeCaptureEvent {
  const NativeCaptureEvent({required this.type, required this.active});
  final String type;
  final bool active;
}

class NativeSecurityService {
  const NativeSecurityService();

  static const _methods = MethodChannel('com.soul/member_security');
  static const _events = EventChannel('com.soul/member_security_events');

  Future<bool> setPrivateScreenProtected(bool enabled) async {
    try {
      return await _methods.invokeMethod<bool>(
            'setProtected',
            {'enabled': enabled},
          ) ??
          false;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }

  Stream<NativeCaptureEvent> captureEvents() async* {
    try {
      await for (final raw in _events.receiveBroadcastStream()) {
        if (raw is! Map) continue;
        final type = raw['type']?.toString() ?? '';
        if (type != 'screenshot' && type != 'screen_recording') continue;
        yield NativeCaptureEvent(type: type, active: raw['active'] == true);
      }
    } on MissingPluginException {
      return;
    } on PlatformException {
      return;
    }
  }
}
