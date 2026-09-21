import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:soul_member_app/src/features/onboarding/location_repository.dart';

void main() {
  test('resolved location parses server-safe city and country code', () {
    final location = ResolvedMemberLocation.fromJson({
      'city': 'Karachi',
      'country_code': 'pk',
      'country': 'Pakistan',
      'region': 'Sindh',
      'is_approximate': false,
    });

    expect(location.city, 'Karachi');
    expect(location.countryCode, 'PK');
    expect(location.region, 'Sindh');
    expect(location.isApproximate, isFalse);
  });

  test('onboarding location flow calls server resolver and keeps manual fallback', () {
    final repository = File(
      'lib/src/features/onboarding/location_repository.dart',
    ).readAsStringSync();
    final screen = File(
      'lib/src/features/onboarding/onboarding_screen.dart',
    ).readAsStringSync();

    expect(repository, contains("'location/resolve'"));
    expect(repository, contains("'accuracy_meters': position.accuracy"));
    expect(screen, contains('Use current location'));
    expect(screen, contains("'profile.city'"));
    expect(screen, contains("'profile.country'"));
    expect(screen, contains('_resolveCurrentLocation'));
  });
}
