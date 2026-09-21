import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:soul_member_app/src/features/discovery/discovery_repository.dart';

void main() {
  test('candidate keeps safe public photo delivery URL', () {
    final candidate = DiscoveryCandidate.fromJson({
      'id': '01HCANDIDATE',
      'first_name': 'Sara',
      'age': 28,
      'marital_status': 'never_married',
      'intentions': ['marriage', 'serious_relationship'],
      'country': 'PK',
      'city': 'Karachi',
      'distance_band': 'distance.about_10_km',
      'photos': [
        {
          'id': '01HPHOTO',
          'position': 1,
          'url': 'https://res.cloudinary.com/demo/image/upload/photo.jpg',
        },
      ],
    });

    expect(candidate.photos.single.url, contains('res.cloudinary.com'));
    expect(candidate.distanceBand, 'distance.about_10_km');
    expect(candidate.intentions, ['marriage', 'serious_relationship']);
  });

  test('preferences serialize selected location only in selected mode', () {
    const preferences = DiscoveryPreferences(
      preferredGender: 'woman',
      minimumAge: 24,
      maximumAge: 35,
      sameCountryOnly: false,
      religionMode: 'all_religions',
      locationMode: 'selected',
      selectedLocations: [
        SelectedDiscoveryLocation(countryCode: 'pk', cityName: 'Karachi'),
      ],
      intentions: ['marriage'],
    );

    final json = preferences.toJson();

    expect(json['preferred_gender'], 'woman');
    expect(json['radius_km'], isNull);
    expect(
      (json['selected_locations'] as List).single,
      {'country_code': 'PK', 'city_name': 'Karachi'},
    );
  });

  test('incoming like reads optional cover photo', () {
    final like = IncomingLike.fromJson({
      'profile': {
        'id': '01HPROFILE',
        'first_name': 'Ayesha',
        'age': 27,
        'city': 'Karachi',
        'country': 'PK',
        'photo': {
          'id': '01HPHOTO',
          'position': 1,
          'url': 'https://example.test/photo.jpg',
        },
      },
      'received_at': '2026-09-21T01:00:00+00:00',
    });

    expect(like.profileId, '01HPROFILE');
    expect(like.firstName, 'Ayesha');
    expect(like.age, 27);
    expect(like.city, 'Karachi');
    expect(like.country, 'PK');
    expect(like.photoUrl, 'https://example.test/photo.jpg');
  });
  test('full profile preserves prominent marital status and intentions', () {
    final profile = DiscoveryProfile.fromJson({
      'id': '01HPROFILE',
      'first_name': 'Ayesha',
      'age': 27,
      'marital_status': 'divorced',
      'country': 'PK',
      'city': 'Karachi',
      'bio': 'Builder and reader',
      'intentions': ['marriage'],
      'interests': ['Reading'],
      'personality_traits': ['Kind'],
      'spoken_languages': [
        {'code': 'ur', 'name': 'Urdu', 'native_name': 'Roman Urdu'},
      ],
      'photos': [],
      'verification_badges': {
        'phone': true,
        'selfie': false,
        'identity_age': false,
      },
    });

    expect(profile.age, 27);
    expect(profile.maritalStatus, 'divorced');
    expect(profile.intentions, ['marriage']);
    expect(profile.spokenLanguages, ['Roman Urdu']);
    expect(profile.verificationBadges['phone'], isTrue);
  });

  test('discovery screen wires the full-profile endpoint', () {
    final source = File(
      'lib/src/features/discovery/discovery_screen.dart',
    ).readAsStringSync();
    final detail = File(
      'lib/src/features/discovery/discovery_profile_screen.dart',
    ).readAsStringSync();

    expect(source, contains('DiscoveryProfileScreen('));
    expect(detail, contains('repository.profile(widget.profileId)'));
    expect(detail, contains('profile.maritalStatus'));
    expect(detail, contains('profile.intentions'));
  });

  test('discovery privacy state keeps pause and incognito separate', () {
    final state = DiscoveryPrivacyState.fromJson({
      'discoverable': true,
      'incognito': true,
      'profile_paused': false,
    });

    expect(state.discoverable, isTrue);
    expect(state.incognito, isTrue);
    expect(state.profilePaused, isFalse);
    expect(state.limitedVisibility, isTrue);
  });

  test('filter UI stays within V1 backend contract', () {
    final source = File(
      'lib/src/features/discovery/discovery_filters_screen.dart',
    ).readAsStringSync();

    expect(source, contains("'my_religion'"));
    expect(source, contains("'all_religions'"));
    expect(source, contains("'current'"));
    expect(source, contains("'selected'"));
    expect(source, contains("'anywhere'"));
    expect(source, contains('RangeSlider('));
    expect(source, contains('_radiusKm'));
    expect(source, contains('_intentions'));

    expect(source.toLowerCase(), isNot(contains('sect filter')));
    expect(source.toLowerCase(), isNot(contains('premium')));
    expect(source.toLowerCase(), isNot(contains('upgrade to')));
  });

  test('pending like withdrawal uses the server route', () {
    final repository = File(
      'lib/src/features/discovery/discovery_repository.dart',
    ).readAsStringSync();
    final screen = File(
      'lib/src/features/discovery/discovery_screen.dart',
    ).readAsStringSync();

    expect(repository, contains("profiles/${Uri.encodeComponent(profileId)}/like"));
    expect(repository, contains('Future<void> withdrawLike'));
    expect(screen, contains('repository.withdrawLike(candidate.id)'));
    expect(screen, contains("decision == 'like'"));
  });

}
