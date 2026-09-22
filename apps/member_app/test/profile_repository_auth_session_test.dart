import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soul_member_app/src/core/api_client.dart';
import 'package:soul_member_app/src/core/session_store.dart';
import 'package:soul_member_app/src/features/profile/profile_repository.dart';

class _MemorySessionStore extends SessionStore {
  _MemorySessionStore() : super(const FlutterSecureStorage());

  String? token = 'session-token';
  String? pushDeviceId = 'push-device-id';

  @override
  Future<String?> readToken() async => token;

  @override
  Future<void> clear() async {
    token = null;
  }

  @override
  Future<String?> readPushDeviceId() async => pushDeviceId;

  @override
  Future<void> clearPushDeviceId() async {
    pushDeviceId = null;
  }
}

class _FakeApiClient extends SoulApiClient {
  _FakeApiClient(super.sessions);

  bool logoutUnauthorized = false;
  bool currentSessionRevoked = false;
  final List<String> posts = [];
  final List<String> deletes = [];

  @override
  Future<Map<String, dynamic>> post(String path, {Object? data}) async {
    posts.add(path);
    if (logoutUnauthorized) {
      throw const SoulApiFailure(
        statusCode: 401,
        code: 'UNAUTHENTICATED',
        message: 'Session expired.',
      );
    }
    return const <String, dynamic>{};
  }

  @override
  Future<Map<String, dynamic>> delete(String path, {Object? data}) async {
    deletes.add(path);
    if (path.startsWith('auth/devices/')) {
      return {'revoked': true, 'was_current': currentSessionRevoked};
    }
    return const <String, dynamic>{};
  }
}

void main() {
  test('logout treats an already-invalid server session as success', () async {
    final sessions = _MemorySessionStore();
    final api = _FakeApiClient(sessions)..logoutUnauthorized = true;
    final repository = ProfileRepository(api, sessions);

    await repository.logout();

    expect(api.posts, ['auth/logout']);
    expect(api.deletes, isEmpty);
    expect(sessions.token, isNull);
    expect(sessions.pushDeviceId, isNull);
  });

  test('revoking current active-device session clears all local session ids',
      () async {
    final sessions = _MemorySessionStore();
    final api = _FakeApiClient(sessions)..currentSessionRevoked = true;
    final repository = ProfileRepository(api, sessions);

    final wasCurrent = await repository.revokeSession('session-1');

    expect(wasCurrent, isTrue);
    expect(api.deletes, ['auth/devices/session-1']);
    expect(sessions.token, isNull);
    expect(sessions.pushDeviceId, isNull);
  });
}
