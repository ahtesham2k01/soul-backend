import 'package:flutter_test/flutter_test.dart';
import 'package:soul_member_app/src/features/onboarding/onboarding_repository.dart';

void main() {
  test('religion choice preserves the public id and hierarchy state', () {
    final choice = ReligionChoice.fromJson({
      'id': '01HRELIGION',
      'label': 'Islam',
      'has_children': true,
      'level': 'religion',
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
    });

    expect(choice.hasChildren, isFalse);
    expect(choice.level, isNull);
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
}
