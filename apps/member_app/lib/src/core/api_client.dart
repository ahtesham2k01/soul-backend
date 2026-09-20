import 'package:dio/dio.dart';

import 'environment.dart';
import 'session_store.dart';

class SoulApiFailure implements Exception {
  const SoulApiFailure({
    required this.statusCode,
    required this.code,
    required this.message,
    this.requestId,
    this.fieldErrors = const {},
  });

  final int? statusCode;
  final String code;
  final String message;
  final String? requestId;
  final Map<String, List<String>> fieldErrors;
}

class SoulApiClient {
  SoulApiClient(this._sessions)
      : _dio = Dio(
          BaseOptions(
            baseUrl: SoulEnvironment.apiBaseUri.toString(),
            contentType: Headers.jsonContentType,
            responseType: ResponseType.json,
            connectTimeout: const Duration(seconds: 15),
            receiveTimeout: const Duration(seconds: 20),
          ),
        ) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _sessions.readToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          options.headers['Accept-Language'] = 'en';
          handler.next(options);
        },
      ),
    );
  }

  final SessionStore _sessions;
  final Dio _dio;

  Future<Map<String, dynamic>> get(String path, {Map<String, dynamic>? query}) =>
      _request('GET', path, query: query);

  Future<Map<String, dynamic>> post(String path, {Object? data}) =>
      _request('POST', path, data: data);

  Future<Map<String, dynamic>> put(String path, {Object? data}) =>
      _request('PUT', path, data: data);

  Future<Map<String, dynamic>> delete(String path, {Object? data}) =>
      _request('DELETE', path, data: data);

  Future<Map<String, dynamic>> _request(
    String method,
    String path, {
    Object? data,
    Map<String, dynamic>? query,
  }) async {
    try {
      final response = await _dio.request<dynamic>(
        path,
        data: data,
        queryParameters: query,
        options: Options(method: method),
      );
      return _unwrap(response);
    } on DioException catch (error) {
      final body = error.response?.data;
      final envelope = body is Map<String, dynamic> ? body : const <String, dynamic>{};
      final errorBody = envelope['error'];
      final details = errorBody is Map<String, dynamic>
          ? errorBody['details']
          : null;
      final Map<String, List<String>> fields =
          details is Map<String, dynamic> && details['fields'] is Map
          ? (details['fields'] as Map<dynamic, dynamic>).map<String, List<String>>(
              (key, value) => MapEntry(
                key.toString(),
                value is List
                    ? value.map((item) => item.toString()).toList()
                    : const <String>[],
              ),
            )
          : const <String, List<String>>{};
      if (error.response?.statusCode == 401) {
        await _sessions.clear();
      }
      throw SoulApiFailure(
        statusCode: error.response?.statusCode,
        code: errorBody is Map<String, dynamic>
            ? (errorBody['code']?.toString() ?? 'REQUEST_FAILED')
            : 'NETWORK_ERROR',
        message: errorBody is Map<String, dynamic>
            ? (errorBody['message']?.toString() ?? 'Request failed.')
            : 'Unable to reach SOUL. Please try again.',
        requestId: _requestId(envelope),
        fieldErrors: fields,
      );
    }
  }

  Map<String, dynamic> _unwrap(Response<dynamic> response) {
    final body = response.data;
    if (body is! Map<String, dynamic> || body['success'] != true) {
      throw SoulApiFailure(
        statusCode: response.statusCode,
        code: 'INVALID_RESPONSE',
        message: 'SOUL returned an invalid response.',
      );
    }
    final data = body['data'];
    return data is Map<String, dynamic> ? data : const <String, dynamic>{};
  }

  String? _requestId(Map<String, dynamic> body) {
    final meta = body['meta'];
    return meta is Map<String, dynamic> ? meta['request_id']?.toString() : null;
  }
}
