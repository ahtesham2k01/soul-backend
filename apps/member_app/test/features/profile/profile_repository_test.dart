import 'package:flutter_test/flutter_test.dart';
import 'package:soul_member_app/src/features/profile/profile_repository.dart';

void main() {
  test('privacy settings preserve supported visibility controls', () {
    final settings = PrivacySettings.fromJson({
      'show_city': false,
      'discoverable': true,
      'incognito': true,
      'profile_paused': false,
      'hide_contacts': true,
      'screenshot_protection_enabled': true,
    });

    expect(settings.showCity, isFalse);
    expect(settings.incognito, isTrue);
    expect(settings.hideContacts, isTrue);
    expect(settings.toJson()['screenshot_protection_enabled'], isTrue);
  });

  test('notification settings keep push and email independent', () {
    final settings = NotificationSettings.fromJson({
      'push': {
        'new_matches': true,
        'new_messages': false,
        'private_photos': true,
        'verification': true,
        'account': true,
        'marketing': false,
      },
      'email': {
        'new_matches': false,
        'new_messages': true,
        'private_photos': false,
        'verification': false,
        'account': true,
        'marketing': true,
      },
    });

    expect(settings.pushNewMessages, isFalse);
    expect(settings.emailNewMessages, isTrue);
    expect(settings.pushMarketing, isFalse);
    expect(settings.emailMarketing, isTrue);
  });

  test('blocked profile response exposes only public profile data', () {
    final blocked = BlockedProfile.fromJson({
      'profile': {
        'id': '01HPROFILE',
        'first_name': 'Sara',
        'photo': {
          'id': '01HPHOTO',
          'position': 1,
          'url': 'https://example.test/photo.jpg',
        },
      },
      'blocked_at': '2026-09-21T02:00:00Z',
    });

    expect(blocked.id, '01HPROFILE');
    expect(blocked.firstName, 'Sara');
    expect(blocked.photoUrl, 'https://example.test/photo.jpg');
    expect(blocked.blockedAt, isNotNull);
  });

  test('profile catalog keeps canonical values separate from labels', () {
    final catalog = ProfileCatalog.fromJson({
      'interests': [
        {'key': 'travel', 'label': 'Travel'},
      ],
      'personality_traits': [
        {'key': 'kind', 'label': 'Kind'},
      ],
      'spoken_languages': [
        {'code': 'ur', 'name': 'Urdu', 'native_name': 'Roman Urdu'},
      ],
    });

    expect(catalog.interests.single.value, 'travel');
    expect(catalog.interests.single.label, 'Travel');
    expect(catalog.personalityTraits.single.value, 'kind');
    expect(catalog.languages.single.value, 'ur');
    expect(catalog.languages.single.label, 'Roman Urdu');
  });
}
