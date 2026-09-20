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
}
