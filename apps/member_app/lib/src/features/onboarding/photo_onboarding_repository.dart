import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/api_client.dart';

class ProfilePhotoState {
  const ProfilePhotoState({
    required this.position,
    required this.visibility,
    required this.moderationStatus,
    this.rejectionReason,
    this.faceDetected,
  });

  final int position;
  final String visibility;
  final String moderationStatus;
  final String? rejectionReason;
  final bool? faceDetected;

  factory ProfilePhotoState.fromJson(Map<String, dynamic> json) =>
      ProfilePhotoState(
        position: (json['position'] as num?)?.toInt() ?? 0,
        visibility: json['visibility']?.toString() ?? 'public',
        moderationStatus: json['moderation_status']?.toString() ?? 'pending',
        rejectionReason: json['rejection_reason']?.toString(),
        faceDetected: json['face_detected'] as bool?,
      );
}

class PhotoOnboardingRepository {
  PhotoOnboardingRepository(this._api);

  final SoulApiClient _api;
  final Dio _cloudinary = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 45),
      sendTimeout: const Duration(seconds: 45),
    ),
  );

  Future<List<ProfilePhotoState>> list() async {
    final data = await _api.get('onboarding/photos');
    final photos = data['photos'];
    if (photos is! List) return const [];
    return photos
        .whereType<Map>()
        .map((item) => ProfilePhotoState.fromJson(
              Map<String, dynamic>.from(item),
            ))
        .where((item) => item.position >= 1 && item.position <= 3)
        .toList(growable: false);
  }

  Future<void> upload({
    required int position,
    required String visibility,
    required XFile file,
  }) async {
    final sessionData = await _api.post(
      'onboarding/photos/upload-session',
      data: {'position': position},
    );
    final rawUpload = sessionData['upload'];
    if (rawUpload is! Map) {
      throw const SoulApiFailure(
        statusCode: null,
        code: 'INVALID_UPLOAD_SESSION',
        message: 'SOUL could not prepare this photo upload.',
      );
    }
    final upload = Map<String, dynamic>.from(rawUpload);
    final rawParameters = upload['parameters'];
    if (rawParameters is! Map || upload['url'] is! String) {
      throw const SoulApiFailure(
        statusCode: null,
        code: 'INVALID_UPLOAD_SESSION',
        message: 'SOUL could not prepare this photo upload.',
      );
    }

    final form = FormData.fromMap({
      ...Map<String, dynamic>.from(rawParameters),
      'file': await MultipartFile.fromFile(
        file.path,
        filename: file.name,
      ),
    });

    late final Map<String, dynamic> providerResult;
    try {
      final response = await _cloudinary.post<dynamic>(
        upload['url'] as String,
        data: form,
      );
      if (response.data is! Map) throw const FormatException();
      providerResult = Map<String, dynamic>.from(response.data as Map);
    } on DioException catch (error) {
      throw SoulApiFailure(
        statusCode: error.response?.statusCode,
        code: 'PHOTO_UPLOAD_FAILED',
        message: 'The photo could not be uploaded. Please try again.',
      );
    } on FormatException {
      throw const SoulApiFailure(
        statusCode: null,
        code: 'INVALID_PROVIDER_RESPONSE',
        message: 'The photo provider returned an invalid response.',
      );
    }

    await _api.put('onboarding/photos/$position', data: {
      'upload_token': upload['token'],
      'provider_asset_id': providerResult['public_id'],
      'provider_version': providerResult['version'],
      'provider_format': providerResult['format'],
      'provider_signature': providerResult['signature'],
      'visibility': position == 1 ? 'public' : visibility,
    });
  }

  Future<void> delete(int position) =>
      _api.delete('onboarding/photos/$position');
}
