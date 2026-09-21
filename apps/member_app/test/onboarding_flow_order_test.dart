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
    expect(source, contains('next.isEmpty'));
    expect(source, contains('religionOptions('));
    expect(source, contains('parentId: choice.id'));
    expect(source, contains('saveReligion('));
    expect(source, contains('selectedNodeId: choice.id'));
    expect(source, contains("setState(() => _step = 6);"));
    expect(source, contains('path.last.label'));
    expect(source, isNot(contains('Which sect do you follow?')));
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

  test('live profile exits legal submission and refreshes the session route', () {
    final onboarding = File(
      'lib/src/features/onboarding/onboarding_screen.dart',
    ).readAsStringSync();
    final legal = File(
      'lib/src/features/onboarding/legal_submission_screen.dart',
    ).readAsStringSync();

    expect(legal, contains('if (lifecycle.live)'));
    expect(legal, contains("Navigator.of(context).pop('home')"));
    expect(legal, contains('_handleLifecycle(lifecycle)'));
    expect(onboarding, contains("if (outcome == 'home')"));
    expect(onboarding, contains('ref.invalidate(sessionRouteProvider)'));
  });


  test('resume restores the saved religion path before later onboarding steps', () {
    final source = File(
      'lib/src/features/onboarding/onboarding_screen.dart',
    ).readAsStringSync();

    expect(source, contains('religionProfile?.restoreChoices()'));
    expect(source, contains('..addAll(restoredReligionPath)'));
    expect(source, contains('_religionPath.clear()'));
  });

}
