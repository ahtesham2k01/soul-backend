import fs from 'node:fs';
import path from 'node:path';

export const flutterContractVersion = 2;

const id = (suffix) => `01J000000000000000000000${suffix}`;

export const flutterOperationModels = {
    'api.v1.bootstrap': { request: null, response: 'SoulBootstrap' },
    'api.v1.auth.register.request-otp': { request: 'SoulRequestOtpRequest', response: 'SoulOtpChallenge' },
    'api.v1.auth.register.verify-otp': { request: 'SoulVerifyOtpRequest', response: 'SoulAuthSession' },
    'api.v1.auth.login.request-otp': { request: 'SoulRequestOtpRequest', response: 'SoulOtpChallenge' },
    'api.v1.auth.login.verify-otp': { request: 'SoulVerifyOtpRequest', response: 'SoulAuthSession' },
    'api.v1.auth.google': { request: 'SoulGoogleSignInRequest', response: 'SoulAuthSession' },
    'api.v1.auth.apple': { request: 'SoulAppleSignInRequest', response: 'SoulAuthSession' },
    'api.v1.auth.me': { request: null, response: 'SoulCurrentAccount' },
    'api.v1.location.resolve': { request: 'SoulResolveLocationRequest', response: 'SoulResolvedLocation' },
    'api.v1.onboarding.religion-options': { request: null, response: 'SoulReligionOptions' },
    'api.v1.onboarding.religion-profile.store': { request: 'SoulReligionSelectionRequest', response: 'SoulReligionProfile' },
    'api.v1.onboarding.profile.show': { request: null, response: 'SoulProfileDraft?' },
    'api.v1.onboarding.profile.update': { request: 'SoulUpdateProfileDraftRequest', response: 'SoulProfileDraft' },
    'api.v1.onboarding.readiness.show': { request: null, response: 'SoulReadiness' },
    'api.v1.onboarding.photos.upload-session.create': { request: 'SoulPhotoUploadSessionRequest', response: 'SoulPhotoUploadSession' },
    'api.v1.onboarding.photos.register': { request: 'SoulRegisterProfilePhotoRequest', response: 'SoulProfilePhoto' },
    'api.v1.discovery.preferences.update': { request: 'SoulDiscoveryPreferencesRequest', response: 'SoulDiscoveryPreferencesRequest' },
    'api.v1.discovery.candidates.index': { request: null, response: 'SoulCursorPage<SoulDiscoveryCandidate>' },
    'api.v1.profiles.show': { request: null, response: 'SoulPublicProfile' },
    'api.v1.matching.decisions.store': { request: 'SoulProfileDecisionRequest', response: null },
    'api.v1.matches.index': { request: null, response: 'SoulCursorPage<SoulMatchSummary>' },
    'api.v1.messages.index': { request: null, response: 'SoulCursorPage<SoulMessage>' },
    'api.v1.messages.store': { request: 'SoulSendMessageRequest', response: 'SoulMessage' },
};

export const flutterFixtures = [
    {
        file: 'auth-session.success.json', operationId: 'api.v1.auth.login.verify-otp', kind: 'success',
        payload: { success: true, message: 'Signed in successfully.', data: { user: { id: id('01'), name: null, email: 'member@example.test', email_verified: true, preferred_locale: 'en', status: 'active', onboarding_completed: false }, is_new_user: false, next_step: 'onboarding', authentication: { token_type: 'Bearer', access_token: '<redacted-example-access-token>', expires_at: '2026-12-13T12:00:00Z' } }, meta: { request_id: id('90') } },
    },
    {
        file: 'bootstrap.success.json', operationId: 'api.v1.bootstrap', kind: 'success',
        payload: { success: true, message: 'App bootstrap loaded successfully.', data: { brand: { name: 'SOUL', translate: false }, locale: { requested: 'ur-PK', matched: 'ur', resolved: 'ur', fallback: 'en', direction: 'ltr' }, translations: { version: '17', hash: 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa', values: { 'auth.login': 'Login' } }, supported_languages: [{ code: 'en', name: 'English', native_name: 'English', direction: 'ltr', is_launch_target: true, is_launch_ready: true }], location: null, location_status: 'unavailable', capabilities: null }, meta: { request_id: id('91') } },
    },
    {
        file: 'religion-options.success.json', operationId: 'api.v1.onboarding.religion-options', kind: 'success',
        payload: { success: true, message: 'Religion options loaded successfully.', data: { parent: null, options: [{ id: id('10'), type: 'religion', slug: 'islam', label: 'Islam', label_locale: 'en', has_children: true }] }, meta: { request_id: id('89'), locale: 'en', country: 'PK' } },
    },
    {
        file: 'onboarding-profile.success.json', operationId: 'api.v1.onboarding.profile.show', kind: 'success',
        payload: { success: true, message: 'Profile draft loaded successfully.', data: { profile: { id: id('02'), profile_status: 'draft', first_name: 'Ayesha', date_of_birth: '1998-04-12', gender: 'woman', city_name: 'Karachi', country_code: 'PK', marital_status: 'never_married', interests: ['reading'], personality_traits: ['kind'], intentions: ['marriage'], spoken_languages: [{ code: 'ur', name: 'Urdu', native_name: 'Urdu' }] } }, meta: { request_id: id('92') } },
    },
    {
        file: 'onboarding-readiness.success.json', operationId: 'api.v1.onboarding.readiness.show', kind: 'success',
        payload: { success: true, message: 'Onboarding readiness loaded successfully.', data: { readiness: { is_ready: false, missing_requirements: ['cover_photo', 'clear_face_photo'] } }, meta: { request_id: id('93') } },
    },
    {
        file: 'discovery-candidates.success.json', operationId: 'api.v1.discovery.candidates.index', kind: 'success',
        payload: { success: true, message: 'OK', data: { candidates: [{ id: id('03'), first_name: 'Sara', age: 28, marital_status: 'never_married', city: 'Karachi', country: 'PK', distance_band: 'distance.within_10_km', photos: [{ id: id('05'), position: 1, url: 'https://res.cloudinary.com/demo/image/upload/c_fill,g_auto,h_1600,q_auto,w_1200/soul/users/example.jpg' }] }], next_cursor: '<opaque-example-cursor>' }, meta: { request_id: id('94') } },
    },
    {
        file: 'public-profile.success.json', operationId: 'api.v1.profiles.show', kind: 'success',
        payload: { success: true, message: 'OK', data: { profile: { id: id('03'), first_name: 'Sara', age: 28, gender: 'woman', marital_status: 'never_married', city: 'Karachi', country: 'PK', intentions: ['marriage'], interests: ['Reading'], personality_traits: ['Kind'], spoken_languages: [], religion: null, photos: [{ id: id('05'), position: 1, url: 'https://res.cloudinary.com/demo/image/upload/c_fill,g_auto,h_1600,q_auto,w_1200/soul/users/example.jpg' }], verification_badges: { phone: true, selfie: false, identity_age: false } } }, meta: { request_id: id('95') } },
    },
    {
        file: 'matches.success.json', operationId: 'api.v1.matches.index', kind: 'success',
        payload: { success: true, message: 'OK', data: { matches: [{ id: id('06'), matched_at: '2026-09-14T12:15:00Z', profile: { id: id('03'), first_name: 'Sara' }, presence: { is_online: true, last_seen_at: '2026-09-14T12:16:00Z' }, conversation: { last_message: null, unread_count: 0 } }], next_cursor: null }, meta: { request_id: id('96') } },
    },
    {
        file: 'messages.success.json', operationId: 'api.v1.messages.index', kind: 'success',
        payload: { success: true, message: 'OK', data: { messages: [{ id: id('07'), body: 'Salam', is_mine: false, read_at: null, sent_at: '2026-09-14T12:16:00Z' }], next_cursor: null }, meta: { request_id: id('97') } },
    },
    {
        file: 'photo-upload-session.success.json', operationId: 'api.v1.onboarding.photos.upload-session.create', kind: 'success',
        payload: { success: true, message: 'Photo upload session created successfully.', data: { upload: { token: id('08'), position: 1, expires_at: '2026-09-14T12:10:00Z', url: 'https://api.cloudinary.com/v1_1/example/image/upload', parameters: { api_key: '<redacted-example-api-key>', timestamp: 1789387200, public_id: '<redacted-example-asset-id>', type: 'upload', signature: '<redacted-example-signature>' } } }, meta: { request_id: id('98') } },
    },
    {
        file: 'validation-error.json', operationId: 'api.v1.onboarding.profile.update', kind: 'error',
        payload: { success: false, error: { code: 'VALIDATION_ERROR', message: 'The given data was invalid.', details: { fields: { first_name: ['The first name field is required.'] } } }, meta: { request_id: id('99') } },
    },
];

export const flutterTypedHandoff = {
    dartModels: 'docs/contracts/soul_v1_models.dart',
    fixtureDirectory: 'docs/contracts/fixtures',
    fixtures: flutterFixtures.map(({ file, operationId, kind }) => ({ file, operationId, kind })),
    coveredJourneys: ['bootstrap', 'authentication', 'onboarding', 'photo_upload', 'discovery', 'matches', 'chat'],
    operationModels: flutterOperationModels,
    sessionPolicy: { refreshEndpoint: null, unauthorizedAction: 'clear_secure_token_and_reauthenticate' },
    retryPolicy: { maximumAttempts: 3, idempotentMethods: ['GET', 'PUT', 'DELETE'], statuses: [429, 502, 503, 504] },
};

const dart = `// GENERATED FILE. DO NOT EDIT.
// Source: docs/SOUL_V1_MASTER_DOCUMENTATION.md
// Null-safe core DTOs for SOUL Flutter integration.

typedef SoulJson = Map<String, Object?>;

SoulJson soulJson(Object? value, String key) {
  if (value is Map<String, Object?>) return value;
  throw FormatException('Expected object at \$key');
}

String soulString(SoulJson json, String key) {
  final value = json[key];
  if (value is String) return value;
  throw FormatException('Expected string at \$key');
}

String? soulNullableString(SoulJson json, String key) {
  final value = json[key];
  if (value == null || value is String) return value as String?;
  throw FormatException('Expected nullable string at \$key');
}

int soulInt(SoulJson json, String key) {
  final value = json[key];
  if (value is int) return value;
  throw FormatException('Expected integer at \$key');
}

bool soulBool(SoulJson json, String key) {
  final value = json[key];
  if (value is bool) return value;
  throw FormatException('Expected boolean at \$key');
}

List<SoulJson> soulObjectList(SoulJson json, String key) {
  final value = json[key];
  if (value is! List) throw FormatException('Expected list at \$key');
  return value.map((item) => soulJson(item, key)).toList(growable: false);
}

List<String> soulStringList(SoulJson json, String key) {
  final value = json[key];
  if (value == null) return const [];
  if (value is! List || value.any((item) => item is! String)) {
    throw FormatException('Expected string list at \$key');
  }
  return List<String>.unmodifiable(value.cast<String>());
}

class SoulPatch<T> {
  const SoulPatch.absent() : isPresent = false, value = null;
  const SoulPatch.value(this.value) : isPresent = true;
  final bool isPresent;
  final T? value;
  void write(SoulJson json, String key) { if (isPresent) json[key] = value; }
}

class SoulApiMeta {
  const SoulApiMeta({required this.requestId});
  final String requestId;
  factory SoulApiMeta.fromJson(SoulJson json) => SoulApiMeta(requestId: soulString(json, 'request_id'));
}

class SoulApiError {
  const SoulApiError({required this.code, required this.message, required this.details, required this.requestId});
  final String code;
  final String message;
  final SoulJson details;
  final String requestId;
  factory SoulApiError.fromResponse(SoulJson response) {
    final error = soulJson(response['error'], 'error');
    final meta = soulJson(response['meta'], 'meta');
    return SoulApiError(code: soulString(error, 'code'), message: soulString(error, 'message'), details: soulJson(error['details'], 'details'), requestId: soulString(meta, 'request_id'));
  }
}

class SoulApiException implements Exception {
  const SoulApiException(this.error);
  final SoulApiError error;
  @override String toString() => 'SoulApiException(\${error.code}): \${error.message}';
}

class SoulApiSuccess<T> {
  const SoulApiSuccess({required this.message, required this.data, required this.meta});
  final String message;
  final T data;
  final SoulApiMeta meta;
  static SoulApiSuccess<R> parse<R>(SoulJson response, R Function(Object?) decode) {
    if (response['success'] != true) throw SoulApiException(SoulApiError.fromResponse(response));
    return SoulApiSuccess<R>(message: soulString(response, 'message'), data: decode(response['data']), meta: SoulApiMeta.fromJson(soulJson(response['meta'], 'meta')));
  }
}

class SoulCursorPage<T> {
  const SoulCursorPage({required this.items, required this.nextCursor});
  final List<T> items;
  final String? nextCursor;
  factory SoulCursorPage.fromData(SoulJson data, {required String itemsKey, required T Function(SoulJson) decodeItem}) => SoulCursorPage<T>(items: soulObjectList(data, itemsKey).map(decodeItem).toList(growable: false), nextCursor: soulNullableString(data, 'next_cursor'));
}

abstract final class SoulTransportPolicy {
  static const maximumAttempts = 3;
  static const retryStatuses = <int>{429, 502, 503, 504};
  static bool mayRetry(String method) => const {'GET', 'PUT', 'DELETE'}.contains(method.toUpperCase());
  static Duration backoff(int attempt) => Duration(milliseconds: 250 * (1 << attempt.clamp(0, 4).toInt()));
  static String actionFor(int status) => switch (status) { 401 => 'clear_secure_token_and_reauthenticate', 403 => 'render_account_restriction', 409 => 'follow_returned_state', 422 => 'render_field_errors', 429 => 'retry_after', _ => 'surface_error' };
}

class SoulRequestOtpRequest {
  const SoulRequestOtpRequest({required this.email, this.locale});
  final String email; final String? locale;
  SoulJson toJson() => {'email': email, if (locale != null) 'locale': locale};
}

class SoulVerifyOtpRequest {
  const SoulVerifyOtpRequest({required this.email, required this.verificationId, required this.code, required this.deviceName, this.locale});
  final String email; final String verificationId; final String code; final String deviceName; final String? locale;
  SoulJson toJson() => {'email': email, 'verification_id': verificationId, 'code': code, 'device_name': deviceName, if (locale != null) 'locale': locale};
}

class SoulGoogleSignInRequest {
  const SoulGoogleSignInRequest({required this.idToken, required this.deviceName, this.locale});
  final String idToken; final String deviceName; final String? locale;
  SoulJson toJson() => {'id_token': idToken, 'device_name': deviceName, if (locale != null) 'locale': locale};
}

class SoulAppleSignInRequest {
  const SoulAppleSignInRequest({required this.identityToken, required this.rawNonce, required this.deviceName, this.givenName, this.familyName, this.locale});
  final String identityToken; final String rawNonce; final String deviceName; final String? givenName; final String? familyName; final String? locale;
  SoulJson toJson() => {'identity_token': identityToken, 'raw_nonce': rawNonce, 'device_name': deviceName, if (givenName != null) 'given_name': givenName, if (familyName != null) 'family_name': familyName, if (locale != null) 'locale': locale};
}

class SoulResolveLocationRequest {
  const SoulResolveLocationRequest({required this.latitude, required this.longitude, this.accuracyMeters});
  final double latitude; final double longitude; final double? accuracyMeters;
  SoulJson toJson() => {'latitude': latitude, 'longitude': longitude, if (accuracyMeters != null) 'accuracy_meters': accuracyMeters};
}

class SoulReligionSelectionRequest {
  const SoulReligionSelectionRequest({required this.selectedNodeId, this.country});
  final String selectedNodeId; final String? country;
  SoulJson toJson() => {'selected_node_id': selectedNodeId, if (country != null) 'country': country};
}

class SoulUpdateProfileDraftRequest {
  const SoulUpdateProfileDraftRequest({this.firstName = const SoulPatch.absent(), this.dateOfBirth = const SoulPatch.absent(), this.gender = const SoulPatch.absent(), this.cityName = const SoulPatch.absent(), this.countryCode = const SoulPatch.absent(), this.latitude = const SoulPatch.absent(), this.longitude = const SoulPatch.absent(), this.nationalityCountryCode = const SoulPatch.absent(), this.maritalStatus = const SoulPatch.absent(), this.professionStatus = const SoulPatch.absent(), this.smoking = const SoulPatch.absent(), this.alcohol = const SoulPatch.absent(), this.currentChildren = const SoulPatch.absent(), this.futureChildren = const SoulPatch.absent(), this.bio = const SoulPatch.absent(), this.education = const SoulPatch.absent(), this.heightCm = const SoulPatch.absent(), this.jobTitle = const SoulPatch.absent(), this.employer = const SoulPatch.absent(), this.grewUpIn = const SoulPatch.absent(), this.ethnicOrigin = const SoulPatch.absent(), this.religiousPractice = const SoulPatch.absent(), this.prayer = const SoulPatch.absent(), this.diet = const SoulPatch.absent(), this.dress = const SoulPatch.absent(), this.detailedReligionVisible = const SoulPatch.absent(), this.relocationPreference = const SoulPatch.absent(), this.familyInvolvementPreference = const SoulPatch.absent(), this.interests = const SoulPatch.absent(), this.personalityTraits = const SoulPatch.absent(), this.preferNotToSayFields = const SoulPatch.absent(), this.intentions = const SoulPatch.absent(), this.spokenLanguageCodes = const SoulPatch.absent()});
  final SoulPatch<String> firstName; final SoulPatch<String> dateOfBirth; final SoulPatch<String> gender; final SoulPatch<String> cityName; final SoulPatch<String> countryCode; final SoulPatch<double> latitude; final SoulPatch<double> longitude; final SoulPatch<String> nationalityCountryCode; final SoulPatch<String> maritalStatus; final SoulPatch<String> professionStatus; final SoulPatch<String> smoking; final SoulPatch<String> alcohol; final SoulPatch<String> currentChildren; final SoulPatch<String> futureChildren; final SoulPatch<String> bio; final SoulPatch<String> education; final SoulPatch<int> heightCm; final SoulPatch<String> jobTitle; final SoulPatch<String> employer; final SoulPatch<String> grewUpIn; final SoulPatch<String> ethnicOrigin; final SoulPatch<String> religiousPractice; final SoulPatch<String> prayer; final SoulPatch<String> diet; final SoulPatch<String> dress; final SoulPatch<bool> detailedReligionVisible; final SoulPatch<String> relocationPreference; final SoulPatch<String> familyInvolvementPreference; final SoulPatch<List<String>> interests; final SoulPatch<List<String>> personalityTraits; final SoulPatch<List<String>> preferNotToSayFields; final SoulPatch<List<String>> intentions; final SoulPatch<List<String>> spokenLanguageCodes;
  SoulJson toJson() { final json = <String, Object?>{}; firstName.write(json, 'first_name'); dateOfBirth.write(json, 'date_of_birth'); gender.write(json, 'gender'); cityName.write(json, 'city_name'); countryCode.write(json, 'country_code'); latitude.write(json, 'latitude'); longitude.write(json, 'longitude'); nationalityCountryCode.write(json, 'nationality_country_code'); maritalStatus.write(json, 'marital_status'); professionStatus.write(json, 'profession_status'); smoking.write(json, 'smoking'); alcohol.write(json, 'alcohol'); currentChildren.write(json, 'current_children'); futureChildren.write(json, 'future_children'); bio.write(json, 'bio'); education.write(json, 'education'); heightCm.write(json, 'height_cm'); jobTitle.write(json, 'job_title'); employer.write(json, 'employer'); grewUpIn.write(json, 'grew_up_in'); ethnicOrigin.write(json, 'ethnic_origin'); religiousPractice.write(json, 'religious_practice'); prayer.write(json, 'prayer'); diet.write(json, 'diet'); dress.write(json, 'dress'); detailedReligionVisible.write(json, 'detailed_religion_visible'); relocationPreference.write(json, 'relocation_preference'); familyInvolvementPreference.write(json, 'family_involvement_preference'); interests.write(json, 'interests'); personalityTraits.write(json, 'personality_traits'); preferNotToSayFields.write(json, 'prefer_not_to_say_fields'); intentions.write(json, 'intentions'); spokenLanguageCodes.write(json, 'spoken_language_codes'); return json; }
}

class SoulDiscoveryPreferencesRequest {
  const SoulDiscoveryPreferencesRequest({required this.preferredGender, required this.minimumAge, required this.maximumAge, required this.sameCountryOnly, required this.religionMode, required this.locationMode, required this.intentions, this.radiusKm});
  final String preferredGender; final int minimumAge; final int maximumAge; final bool sameCountryOnly; final String religionMode; final String locationMode; final List<String> intentions; final int? radiusKm;
  SoulJson toJson() => {'preferred_gender': preferredGender, 'minimum_age': minimumAge, 'maximum_age': maximumAge, 'same_country_only': sameCountryOnly, 'religion_mode': religionMode, 'location_mode': locationMode, 'intentions': intentions, if (radiusKm != null) 'radius_km': radiusKm};
}

class SoulProfileDecisionRequest { const SoulProfileDecisionRequest(this.decision); final String decision; SoulJson toJson() => {'decision': decision}; }
class SoulSendMessageRequest { const SoulSendMessageRequest(this.body); final String body; SoulJson toJson() => {'body': body}; }
class SoulPhotoUploadSessionRequest { const SoulPhotoUploadSessionRequest(this.position); final int position; SoulJson toJson() => {'position': position}; }

class SoulCloudinaryUploadResult {
  const SoulCloudinaryUploadResult({required this.assetId, required this.version, required this.format, required this.signature});
  final String assetId; final int version; final String format; final String signature;
}

class SoulRegisterProfilePhotoRequest {
  const SoulRegisterProfilePhotoRequest({required this.uploadToken, required this.result, required this.visibility});
  final String uploadToken; final SoulCloudinaryUploadResult result; final String visibility;
  SoulJson toJson() => {'upload_token': uploadToken, 'provider_asset_id': result.assetId, 'provider_version': result.version, 'provider_format': result.format, 'provider_signature': result.signature, 'visibility': visibility};
}

class SoulUser {
  const SoulUser({required this.id, required this.email, required this.emailVerified, required this.preferredLocale, required this.status, required this.onboardingCompleted, this.name});
  final String id; final String email; final bool emailVerified; final String preferredLocale; final String status; final bool onboardingCompleted; final String? name;
  factory SoulUser.fromJson(SoulJson json) => SoulUser(id: soulString(json, 'id'), email: soulString(json, 'email'), emailVerified: soulBool(json, 'email_verified'), preferredLocale: soulString(json, 'preferred_locale'), status: soulString(json, 'status'), onboardingCompleted: soulBool(json, 'onboarding_completed'), name: soulNullableString(json, 'name'));
}

class SoulAuthentication {
  const SoulAuthentication({required this.tokenType, required this.accessToken, required this.expiresAt});
  final String tokenType; final String accessToken; final DateTime expiresAt;
  factory SoulAuthentication.fromJson(SoulJson json) => SoulAuthentication(tokenType: soulString(json, 'token_type'), accessToken: soulString(json, 'access_token'), expiresAt: DateTime.parse(soulString(json, 'expires_at')));
}

class SoulAuthSession {
  const SoulAuthSession({required this.user, required this.isNewUser, required this.nextStep, required this.authentication});
  final SoulUser user; final bool isNewUser; final String nextStep; final SoulAuthentication authentication;
  factory SoulAuthSession.fromJson(SoulJson json) => SoulAuthSession(user: SoulUser.fromJson(soulJson(json['user'], 'user')), isNewUser: soulBool(json, 'is_new_user'), nextStep: soulString(json, 'next_step'), authentication: SoulAuthentication.fromJson(soulJson(json['authentication'], 'authentication')));
}

class SoulOtpChallenge {
  const SoulOtpChallenge({required this.verificationId, required this.expiresInSeconds, required this.resendAfterSeconds});
  final String verificationId; final int expiresInSeconds; final int resendAfterSeconds;
  factory SoulOtpChallenge.fromJson(SoulJson json) => SoulOtpChallenge(verificationId: soulString(json, 'verification_id'), expiresInSeconds: soulInt(json, 'expires_in_seconds'), resendAfterSeconds: soulInt(json, 'resend_after_seconds'));
}

class SoulCurrentAccount {
  const SoulCurrentAccount({required this.user, required this.nextStep});
  final SoulUser user; final String nextStep;
  factory SoulCurrentAccount.fromJson(SoulJson json) => SoulCurrentAccount(user: SoulUser.fromJson(soulJson(json['user'], 'user')), nextStep: soulString(json, 'next_step'));
}

class SoulLocation {
  const SoulLocation({required this.city, required this.countryCode, this.region});
  final String city; final String countryCode; final String? region;
  factory SoulLocation.fromJson(SoulJson json) => SoulLocation(city: soulString(json, 'city'), countryCode: soulString(json, 'country_code'), region: soulNullableString(json, 'region'));
}

class SoulResolvedLocation {
  const SoulResolvedLocation({required this.status, this.location});
  final String status; final SoulLocation? location;
  factory SoulResolvedLocation.fromJson(SoulJson json) => SoulResolvedLocation(status: soulString(json, 'location_status'), location: json['location'] == null ? null : SoulLocation.fromJson(soulJson(json['location'], 'location')));
}

class SoulReligionOption {
  const SoulReligionOption({required this.id, required this.type, required this.slug, required this.label, required this.hasChildren, this.labelLocale});
  final String id; final String type; final String slug; final String label; final bool hasChildren; final String? labelLocale;
  factory SoulReligionOption.fromJson(SoulJson json) => SoulReligionOption(id: soulString(json, 'id'), type: soulString(json, 'type'), slug: soulString(json, 'slug'), label: soulString(json, 'label'), hasChildren: soulBool(json, 'has_children'), labelLocale: soulNullableString(json, 'label_locale'));
}

class SoulReligionOptions {
  const SoulReligionOptions({required this.options});
  final List<SoulReligionOption> options;
  factory SoulReligionOptions.fromJson(SoulJson json) => SoulReligionOptions(options: soulObjectList(json, 'options').map(SoulReligionOption.fromJson).toList(growable: false));
}

class SoulReligionProfile {
  const SoulReligionProfile({required this.selectedNodeId, required this.path, this.rootNodeId, this.country});
  final String selectedNodeId; final List<SoulJson> path; final String? rootNodeId; final String? country;
  factory SoulReligionProfile.fromJson(SoulJson json) => SoulReligionProfile(selectedNodeId: soulString(json, 'selected_node_id'), rootNodeId: soulNullableString(json, 'root_node_id'), country: soulNullableString(json, 'country'), path: soulObjectList(json, 'path'));
}

class SoulSpokenLanguage {
  const SoulSpokenLanguage({required this.code, required this.name, required this.nativeName});
  final String code; final String name; final String nativeName;
  factory SoulSpokenLanguage.fromJson(SoulJson json) => SoulSpokenLanguage(code: soulString(json, 'code'), name: soulString(json, 'name'), nativeName: soulString(json, 'native_name'));
}

class SoulProfileDraft {
  const SoulProfileDraft({required this.id, required this.status, required this.interests, required this.personalityTraits, required this.intentions, required this.spokenLanguages, this.firstName, this.dateOfBirth, this.gender, this.cityName, this.countryCode, this.maritalStatus, this.bio});
  final String id; final String status; final List<String> interests; final List<String> personalityTraits; final List<String> intentions; final List<SoulSpokenLanguage> spokenLanguages; final String? firstName; final String? dateOfBirth; final String? gender; final String? cityName; final String? countryCode; final String? maritalStatus; final String? bio;
  factory SoulProfileDraft.fromJson(SoulJson json) => SoulProfileDraft(id: soulString(json, 'id'), status: soulString(json, 'profile_status'), interests: soulStringList(json, 'interests'), personalityTraits: soulStringList(json, 'personality_traits'), intentions: soulStringList(json, 'intentions'), spokenLanguages: soulObjectList(json, 'spoken_languages').map(SoulSpokenLanguage.fromJson).toList(growable: false), firstName: soulNullableString(json, 'first_name'), dateOfBirth: soulNullableString(json, 'date_of_birth'), gender: soulNullableString(json, 'gender'), cityName: soulNullableString(json, 'city_name'), countryCode: soulNullableString(json, 'country_code'), maritalStatus: soulNullableString(json, 'marital_status'), bio: soulNullableString(json, 'bio'));
}

class SoulReadiness {
  const SoulReadiness({required this.isReady, required this.missingRequirements});
  final bool isReady; final List<String> missingRequirements;
  factory SoulReadiness.fromJson(SoulJson json) => SoulReadiness(isReady: soulBool(json, 'is_ready'), missingRequirements: soulStringList(json, 'missing_requirements'));
}

class SoulProfilePhotoReference {
  const SoulProfilePhotoReference({required this.id, required this.position, this.url});
  final String id; final int position; final String? url;
  factory SoulProfilePhotoReference.fromJson(SoulJson json) => SoulProfilePhotoReference(id: soulString(json, 'id'), position: soulInt(json, 'position'), url: soulNullableString(json, 'url'));
}

class SoulDiscoveryCandidate {
  const SoulDiscoveryCandidate({required this.id, required this.firstName, required this.age, required this.maritalStatus, required this.country, required this.photos, this.city, this.distanceBand});
  final String id; final String firstName; final int age; final String maritalStatus; final String country; final List<SoulProfilePhotoReference> photos; final String? city; final String? distanceBand;
  factory SoulDiscoveryCandidate.fromJson(SoulJson json) => SoulDiscoveryCandidate(id: soulString(json, 'id'), firstName: soulString(json, 'first_name'), age: soulInt(json, 'age'), maritalStatus: soulString(json, 'marital_status'), country: soulString(json, 'country'), photos: soulObjectList(json, 'photos').map(SoulProfilePhotoReference.fromJson).toList(growable: false), city: soulNullableString(json, 'city'), distanceBand: soulNullableString(json, 'distance_band'));
}

class SoulVerificationBadges {
  const SoulVerificationBadges({required this.phone, required this.selfie, required this.identityAge});
  final bool phone; final bool selfie; final bool identityAge;
  factory SoulVerificationBadges.fromJson(SoulJson json) => SoulVerificationBadges(phone: soulBool(json, 'phone'), selfie: soulBool(json, 'selfie'), identityAge: soulBool(json, 'identity_age'));
}

class SoulPublicProfile {
  const SoulPublicProfile({required this.id, required this.firstName, required this.age, required this.gender, required this.maritalStatus, required this.country, required this.intentions, required this.photos, required this.verificationBadges, this.city});
  final String id; final String firstName; final int age; final String gender; final String maritalStatus; final String country; final List<String> intentions; final List<SoulProfilePhotoReference> photos; final SoulVerificationBadges verificationBadges; final String? city;
  factory SoulPublicProfile.fromJson(SoulJson json) => SoulPublicProfile(id: soulString(json, 'id'), firstName: soulString(json, 'first_name'), age: soulInt(json, 'age'), gender: soulString(json, 'gender'), maritalStatus: soulString(json, 'marital_status'), country: soulString(json, 'country'), intentions: soulStringList(json, 'intentions'), photos: soulObjectList(json, 'photos').map(SoulProfilePhotoReference.fromJson).toList(growable: false), verificationBadges: SoulVerificationBadges.fromJson(soulJson(json['verification_badges'], 'verification_badges')), city: soulNullableString(json, 'city'));
}

class SoulMessage {
  const SoulMessage({required this.id, required this.body, required this.isMine, required this.sentAt, this.readAt});
  final String id; final String body; final bool isMine; final DateTime sentAt; final DateTime? readAt;
  factory SoulMessage.fromJson(SoulJson json) => SoulMessage(id: soulString(json, 'id'), body: soulString(json, 'body'), isMine: soulBool(json, 'is_mine'), sentAt: DateTime.parse(soulString(json, 'sent_at')), readAt: soulNullableString(json, 'read_at') == null ? null : DateTime.parse(soulString(json, 'read_at')));
}

class SoulMatchSummary {
  const SoulMatchSummary({required this.id, required this.matchedAt, required this.profile, required this.unreadCount});
  final String id; final DateTime matchedAt; final SoulJson profile; final int unreadCount;
  factory SoulMatchSummary.fromJson(SoulJson json) { final conversation = soulJson(json['conversation'], 'conversation'); return SoulMatchSummary(id: soulString(json, 'id'), matchedAt: DateTime.parse(soulString(json, 'matched_at')), profile: soulJson(json['profile'], 'profile'), unreadCount: soulInt(conversation, 'unread_count')); }
}

class SoulPhotoUploadSession {
  const SoulPhotoUploadSession({required this.token, required this.position, required this.expiresAt, required this.url, required this.parameters});
  final String token; final int position; final DateTime expiresAt; final Uri url; final SoulJson parameters;
  factory SoulPhotoUploadSession.fromJson(SoulJson json) => SoulPhotoUploadSession(token: soulString(json, 'token'), position: soulInt(json, 'position'), expiresAt: DateTime.parse(soulString(json, 'expires_at')), url: Uri.parse(soulString(json, 'url')), parameters: soulJson(json['parameters'], 'parameters'));
}

class SoulProfilePhoto {
  const SoulProfilePhoto({required this.id, required this.position, required this.visibility, required this.moderationStatus, required this.screenshotProtectionEnabled, this.rejectionReason});
  final String id; final int position; final String visibility; final String moderationStatus; final bool screenshotProtectionEnabled; final String? rejectionReason;
  factory SoulProfilePhoto.fromJson(SoulJson json) => SoulProfilePhoto(id: soulString(json, 'id'), position: soulInt(json, 'position'), visibility: soulString(json, 'visibility'), moderationStatus: soulString(json, 'moderation_status'), screenshotProtectionEnabled: soulBool(json, 'screenshot_protection_enabled'), rejectionReason: soulNullableString(json, 'rejection_reason'));
}

class SoulBootstrap {
  const SoulBootstrap({required this.brand, required this.locale, required this.translations, required this.supportedLanguages, required this.locationStatus});
  final SoulJson brand; final SoulJson locale; final SoulJson translations; final List<SoulJson> supportedLanguages; final String locationStatus;
  factory SoulBootstrap.fromJson(SoulJson json) => SoulBootstrap(brand: soulJson(json['brand'], 'brand'), locale: soulJson(json['locale'], 'locale'), translations: soulJson(json['translations'], 'translations'), supportedLanguages: soulObjectList(json, 'supported_languages'), locationStatus: soulString(json, 'location_status'));
}

abstract final class SoulV1Decoders {
  static SoulAuthSession authSession(Object? data) => SoulAuthSession.fromJson(soulJson(data, 'data'));
  static SoulOtpChallenge otpChallenge(Object? data) => SoulOtpChallenge.fromJson(soulJson(data, 'data'));
  static SoulCurrentAccount currentAccount(Object? data) => SoulCurrentAccount.fromJson(soulJson(data, 'data'));
  static SoulBootstrap bootstrap(Object? data) => SoulBootstrap.fromJson(soulJson(data, 'data'));
  static SoulResolvedLocation resolvedLocation(Object? data) => SoulResolvedLocation.fromJson(soulJson(data, 'data'));
  static SoulReligionOptions religionOptions(Object? data) => SoulReligionOptions.fromJson(soulJson(data, 'data'));
  static SoulReligionProfile religionProfile(Object? data) { final json = soulJson(data, 'data'); return SoulReligionProfile.fromJson(soulJson(json['religion_profile'], 'religion_profile')); }
  static SoulProfileDraft? profileDraft(Object? data) { final json = soulJson(data, 'data'); return json['profile'] == null ? null : SoulProfileDraft.fromJson(soulJson(json['profile'], 'profile')); }
  static SoulReadiness readiness(Object? data) { final json = soulJson(data, 'data'); return SoulReadiness.fromJson(soulJson(json['readiness'], 'readiness')); }
  static SoulCursorPage<SoulDiscoveryCandidate> candidates(Object? data) => SoulCursorPage<SoulDiscoveryCandidate>.fromData(soulJson(data, 'data'), itemsKey: 'candidates', decodeItem: SoulDiscoveryCandidate.fromJson);
  static SoulPublicProfile publicProfile(Object? data) { final json = soulJson(data, 'data'); return SoulPublicProfile.fromJson(soulJson(json['profile'], 'profile')); }
  static SoulCursorPage<SoulMatchSummary> matches(Object? data) => SoulCursorPage<SoulMatchSummary>.fromData(soulJson(data, 'data'), itemsKey: 'matches', decodeItem: SoulMatchSummary.fromJson);
  static SoulCursorPage<SoulMessage> messages(Object? data) => SoulCursorPage<SoulMessage>.fromData(soulJson(data, 'data'), itemsKey: 'messages', decodeItem: SoulMessage.fromJson);
  static SoulMessage message(Object? data) { final json = soulJson(data, 'data'); return SoulMessage.fromJson(soulJson(json['message'], 'message')); }
  static SoulPhotoUploadSession photoUploadSession(Object? data) { final json = soulJson(data, 'data'); return SoulPhotoUploadSession.fromJson(soulJson(json['upload'], 'upload')); }
  static SoulProfilePhoto profilePhoto(Object? data) { final json = soulJson(data, 'data'); return SoulProfilePhoto.fromJson(soulJson(json['photo'], 'photo')); }
}
`;

export function writeFlutterTypedArtifacts(output) {
    const fixtureDirectory = path.join(output, 'fixtures');
    fs.mkdirSync(fixtureDirectory, { recursive: true });
    for (const fixture of flutterFixtures) {
        fs.writeFileSync(path.join(fixtureDirectory, fixture.file), `${JSON.stringify(fixture.payload, null, 2)}\n`);
    }
    fs.writeFileSync(path.join(output, 'soul_v1_models.dart'), dart);
}
