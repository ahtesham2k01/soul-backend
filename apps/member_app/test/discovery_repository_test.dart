import 'package:flutter_test/flutter_test.dart';
import 'package:soul_member_app/src/features/discovery/discovery_repository.dart';

void main() {
  test('candidate keeps safe public photo delivery URL', () {
    final candidate = DiscoveryCandidate.fromJson({
      'id': '01HCANDIDATE',
      'first_name': 'Sara',
      'age': 28,
      'marital_status': 'never_married',
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
}
