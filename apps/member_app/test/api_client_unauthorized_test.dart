import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soul_member_app/src/core/api_client.dart';
import 'package:soul_member_app/src/core/session_store.dart';

class _MemorySessionStore extends SessionStore {
  _MemorySessionStore() : super(const FlutterSecureStorage());

  String? token = 'session-token';

  @override
  Future<String?> readToken() async => token;

  @override
  Future<void> saveToken(String value) async {
    token = value;
  }

  @override
  Future<String?> readLocale() async => 'en';

  @override
  Future<void> clear() async {
    token = null;
  }
}

class _UnauthorizedAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async =>
      ResponseBody.fromString(
        '{"success":false,"error":{"code":"UNAUTHENTICATED","message":"Session expired.","details":{}},"meta":{}}',
        401,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );

  @override
  void close({bool force = false}) {}
}

void main() {
  test('401 clears token and emits global unauthorized signal', () async {
    final sessions = _MemorySessionStore();
    final dio = Dio(BaseOptions(baseUrl: 'https://example.test/api/v1/'))
      ..httpClientAdapter = _UnauthorizedAdapter();
    var invalidations = 0;
    final api = SoulApiClient(
      sessions,
      dio: dio,
      onUnauthorized: () => invalidations++,
    );

    await expectLater(
      api.get('auth/me'),
      throwsA(
        isA<SoulApiFailure>().having(
          (failure) => failure.statusCode,
          'statusCode',
          401,
        ),
      ),
    );

    expect(await sessions.readToken(), isNull);
    expect(invalidations, 1);
  });
}
