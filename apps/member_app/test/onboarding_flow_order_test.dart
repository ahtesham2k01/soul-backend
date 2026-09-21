import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('onboarding keeps religion immediately after nationality', () {
    final source = File(
      'lib/src/features/onboarding/onboarding_screen.dart',
    ).readAsStringSync();

    final nationality = source.indexOf('4 => _TextStep(');
    final religion = source.indexOf('5 => _ReligionStep(');
    final maritalStatus = source.indexOf('6 => _singleChoice(');

    expect(nationality, greaterThanOrEqualTo(0));
    expect(religion, greaterThan(nationality));
    expect(maritalStatus, greaterThan(religion));
  });

  test('religion hierarchy stays backend-driven and skips absent levels', () {
    final source = File(
      'lib/src/features/onboarding/onboarding_screen.dart',
    ).readAsStringSync();

    expect(source, contains('choice.hasChildren'));
    expect(source, contains('religionOptions('));
    expect(source, contains('parentId: choice.id'));
    expect(source, contains('saveReligion('));
    expect(source, contains('selectedNodeId: choice.id'));
    expect(source, contains("setState(() => _step = 6);"));
  });
  test('resume flow uses the server draft and completes after future children', () {
    final source = File(
      'lib/src/features/onboarding/onboarding_screen.dart',
    ).readAsStringSync();

    expect(source, contains('repository.religionProfile()'));
    expect(source, contains('final resumeStep = _resumeStep('));
    expect(source, contains('if (!hasReligion) return 5;'));
    expect(source, contains("if ((profile['future_children']?.toString().isEmpty ?? true)) return 13;"));
    expect(source, contains('setState(() => _step = 14);'));
    expect(source, contains('await _loadReadiness();'));
  });

}
