import 'package:flutter_test/flutter_test.dart';
import 'package:soul_member_app/src/features/onboarding/onboarding_repository.dart';

void main() {
  test('religion choice preserves the public id and hierarchy state', () {
    final choice = ReligionChoice.fromJson({
      'id': '01HRELIGION',
      'label': 'Islam',
      'has_children': true,
      'type': 'religion',
    });

    expect(choice.id, '01HRELIGION');
    expect(choice.label, 'Islam');
    expect(choice.hasChildren, isTrue);
    expect(choice.level, 'religion');
  });

  test('religion leaf does not invent another hierarchy screen', () {
    final choice = ReligionChoice.fromJson({
      'id': '01HLEAF',
      'label': 'Hanafi',
      'has_children': false,
      'type': 'school',
    });

    expect(choice.hasChildren, isFalse);
    expect(choice.level, 'school');
  });

  test('spoken language prefers the member-facing native name', () {
    final language = SpokenLanguageChoice.fromJson({
      'code': 'ur',
      'name': 'Urdu',
      'native_name': 'Urdu',
    });

    expect(language.code, 'ur');
    expect(language.label, 'Urdu');
  });

  test('legal consent maps current versions into submission payload', () {
    final legal = LegalConsentState.fromJson({
      'requires_acceptance': true,
      'documents': [
        {'type': 'terms', 'current_version': '1.0'},
        {'type': 'privacy', 'current_version': '1.1'},
        {'type': 'community_guidelines', 'current_version': '2.0'},
        {'type': 'community_commitment', 'current_version': '1.0'},
      ],
      'commitment_keys': ['legal.commitment.respect'],
    });

    expect(legal.requiresAcceptance, isTrue);
    expect(legal.submissionPayload()['privacy_version'], '1.1');
    expect(legal.commitmentKeys, ['legal.commitment.respect']);
  });

  test('profile lifecycle preserves correction routing', () {
    final state = ProfileLifecycle.fromJson({
      'status': 'changes_required',
      'reason': 'Replace the rejected photo.',
      'correction_screen': 'onboarding.photos',
    });

    expect(state.correctable, isTrue);
    expect(state.processing, isFalse);
    expect(state.correctionScreen, 'onboarding.photos');
  });
  test('saved religion profile preserves the complete public path', () {
    final profile = ReligionProfileSnapshot.fromJson({
      'selected_node_id': '01HLEAF',
      'country': 'PK',
      'path': [
        {
          'id': '01HROOT',
          'type': 'religion',
          'slug': 'islam',
          'label': 'Islam',
          'label_locale': 'ur',
        },
        {'id': '01HSECT', 'type': 'sect', 'slug': 'sunni', 'label': 'Sunni'},
        {'id': '01HLEAF', 'type': 'school', 'slug': 'hanafi', 'label': 'Hanafi'},
      ],
    });

    expect(profile.selectedNodeId, '01HLEAF');
    expect(profile.country, 'PK');
    expect(profile.path.map((item) => item.id), [
      '01HROOT',
      '01HSECT',
      '01HLEAF',
    ]);
    expect(profile.path.last.type, 'school');
    expect(profile.path.first.label, 'Islam');
    expect(profile.path.first.labelLocale, 'ur');
  });

  test('profile catalog keeps stable keys and localized labels', () {
    final catalog = OnboardingProfileCatalog.fromJson({
      'interests': [
        {'key': 'reading', 'label': 'Kitabein parhna'},
      ],
      'personality_traits': [
        {'key': 'kind', 'label': 'Meharban'},
      ],
    });

    expect(catalog.interests.single.value, 'reading');
    expect(catalog.interests.single.label, 'Kitabein parhna');
    expect(catalog.personalityTraits.single.value, 'kind');
    expect(catalog.personalityTraits.single.label, 'Meharban');
  });

  test('saved religion profile restores localized hierarchy choices', () {
    final profile = ReligionProfileSnapshot.fromJson({
      'selected_node_id': '01HLEAF',
      'country': 'PK',
      'path': [
        {
          'id': '01HROOT',
          'type': 'religion',
          'slug': 'islam',
          'label': 'Islam',
        },
        {
          'id': '01HSECT',
          'type': 'sect',
          'slug': 'sunni',
          'label': 'Sunni',
        },
        {
          'id': '01HLEAF',
          'type': 'school',
          'slug': 'hanafi',
          'label': 'Hanafi',
        },
      ],
    });

    final choices = profile.restoreChoices();

    expect(choices.map((item) => item.id), [
      '01HROOT',
      '01HSECT',
      '01HLEAF',
    ]);
    expect(choices.map((item) => item.label), ['Islam', 'Sunni', 'Hanafi']);
    expect(choices[0].hasChildren, isTrue);
    expect(choices[1].hasChildren, isTrue);
    expect(choices[2].hasChildren, isFalse);
    expect(choices[2].level, 'school');
  });

}
