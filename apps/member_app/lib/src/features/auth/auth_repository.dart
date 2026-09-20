import '../../core/api_client.dart';
import '../../core/session_store.dart';

class OtpChallenge {
  const OtpChallenge({required this.verificationId, required this.email});

  final String verificationId;
  final String email;
}

class AuthRepository {
  AuthRepository(this._api, this._sessions);

  final SoulApiClient _api;
  final SessionStore _sessions;

  Future<OtpChallenge> requestLoginOtp(String email) async {
    final data = await _api.post('auth/login/request-otp', data: {'email': email});
    return OtpChallenge(
      verificationId: data['verification_id']!.toString(),
      email: email,
    );
  }

  Future<OtpChallenge> requestRegistrationOtp(String email) async {
    final data = await _api.post('auth/register/request-otp', data: {'email': email});
    return OtpChallenge(
      verificationId: data['verification_id']!.toString(),
      email: email,
    );
  }

  Future<String> verifyLoginOtp({
    required OtpChallenge challenge,
    required String code,
    required String deviceName,
    required String locale,
  }) async {
    final data = await _api.post(
      'auth/login/verify-otp',
      data: {
        'email': challenge.email,
        'verification_id': challenge.verificationId,
        'code': code,
        'device_name': deviceName,
        'locale': locale,
      },
    );
    return _storeAuthentication(data);
  }

  Future<String> verifyRegistrationOtp({
    required OtpChallenge challenge,
    required String code,
    required String deviceName,
    required String locale,
  }) async {
    final data = await _api.post(
      'auth/register/verify-otp',
      data: {
        'email': challenge.email,
        'verification_id': challenge.verificationId,
        'code': code,
        'device_name': deviceName,
        'locale': locale,
      },
    );
    return _storeAuthentication(data);
  }

  Future<String> signInWithGoogle({
    required String idToken,
    required String deviceName,
    required String locale,
  }) async => _storeAuthentication(await _api.post('auth/google', data: {
        'id_token': idToken,
        'device_name': deviceName,
        'locale': locale,
      }));

  Future<String> signInWithApple({
    required String identityToken,
    required String rawNonce,
    required String deviceName,
    required String locale,
    String? givenName,
    String? familyName,
  }) async => _storeAuthentication(await _api.post('auth/apple', data: {
        'identity_token': identityToken,
        'raw_nonce': rawNonce,
        'device_name': deviceName,
        'locale': locale,
        if (givenName != null && givenName.isNotEmpty) 'given_name': givenName,
        if (familyName != null && familyName.isNotEmpty) 'family_name': familyName,
      }));

  Future<String> _storeAuthentication(Map<String, dynamic> data) async {
    final authentication = data['authentication'];
    final token = authentication is Map<String, dynamic>
        ? authentication['access_token']?.toString()
        : null;
    if (token == null || token.isEmpty) {
      throw const SoulApiFailure(
        statusCode: null,
        code: 'INVALID_AUTH_RESPONSE',
        message: 'SOUL did not return a session.',
      );
    }
    await _sessions.saveToken(token);
    return data['next_step']?.toString() ?? 'home';
  }
}
