import 'package:flutter_test/flutter_test.dart';
import 'package:soul_member_app/src/features/events/event_repository.dart';
import 'package:soul_member_app/src/features/safety/safety_repository.dart';

void main() {
  test('verification summary keeps blocking state explicit', () {
    final summary = VerificationSummaryState.fromJson({
      'email': {
        'status': 'verified',
        'verified': true,
        'requirement': 'account',
        'blocks_profile': false,
      },
      'phone': {
        'status': 'not_verified',
        'verified': false,
        'requirement': 'account',
        'blocks_profile': false,
      },
      'selfie': {
        'status': 'not_requested',
        'verified': false,
        'requirement': 'optional',
        'blocks_profile': false,
      },
      'identity_age': {
        'status': 'pending',
        'verified': false,
        'requirement': 'required',
        'blocks_profile': true,
      },
    });

    expect(summary.email.verified, isTrue);
    expect(summary.identityAge.blocksProfile, isTrue);
    expect(summary.identityAge.status, 'pending');
  });

  test('verification case parses appeal state', () {
    final item = VerificationCaseState.fromJson({
      'id': '01HCASE',
      'type': 'identity',
      'status': 'appeal_pending',
      'requirement': 'required',
      'blocks_profile': true,
      'submitted_at': '2026-09-21T01:00:00Z',
      'appeal': {
        'status': 'pending',
      },
    });

    expect(item.id, '01HCASE');
    expect(item.appealStatus, 'pending');
    expect(item.blocksProfile, isTrue);
  });

  test('event response never requires illustrative Figma price data', () {
    final event = SoulEvent.fromJson({
      'id': '01HEVENT',
      'type': 'in_person',
      'title': 'SOUL Social',
      'description': 'Meet people in a respectful group setting.',
      'starts_at': '2026-10-10T18:00:00Z',
      'timezone': 'Asia/Karachi',
      'city': 'Karachi',
      'country_code': 'PK',
      'capacity': 50,
      'registration_count': 41,
      'spaces_remaining': 9,
      'is_joined': false,
    });

    expect(event.title, 'SOUL Social');
    expect(event.spacesRemaining, 9);
    expect(event.isJoined, isFalse);
    expect(event.city, 'Karachi');
  });
}
