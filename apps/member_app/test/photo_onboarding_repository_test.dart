import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:soul_member_app/src/features/onboarding/photo_onboarding_repository.dart';

void main() {
  test('photo state preserves moderation and privacy fields', () {
    final photo = ProfilePhotoState.fromJson({
      'position': 2,
      'visibility': 'private',
      'moderation_status': 'approved',
      'face_detected': true,
    });

    expect(photo.position, 2);
    expect(photo.visibility, 'private');
    expect(photo.moderationStatus, 'approved');
    expect(photo.faceDetected, isTrue);
  });

  test('rejected photo keeps its safe member-facing reason', () {
    final photo = ProfilePhotoState.fromJson({
      'position': 1,
      'visibility': 'public',
      'moderation_status': 'rejected',
      'rejection_reason': 'Face is not clearly visible.',
    });

    expect(photo.rejectionReason, 'Face is not clearly visible.');
    expect(photo.faceDetected, isNull);
  });
  test('photo upload repository exposes provider progress callback', () {
    const sourcePath =
        'lib/src/features/onboarding/photo_onboarding_repository.dart';
    final source = File(sourcePath).readAsStringSync();

    expect(source, contains('void Function(double progress)? onProgress'));
    expect(source, contains('onSendProgress: (sent, total)'));
    expect(source, contains('onProgress?.call(progress)'));
  });

}
