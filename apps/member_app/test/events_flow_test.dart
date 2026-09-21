import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('events use server-side joined pagination for My events', () {
    final repository = File(
      'lib/src/features/events/event_repository.dart',
    ).readAsStringSync();
    final screen = File(
      'lib/src/features/events/events_screen.dart',
    ).readAsStringSync();

    expect(repository, contains('bool joinedOnly = false'));
    expect(repository, contains("if (joinedOnly) 'joined': 'true'"));
    expect(screen, contains('joinedOnly: _myEvents'));
    expect(screen, isNot(contains('where((event) => event.isJoined)')));
    expect(
      screen,
      isNot(contains('if (!_myEvents &&')),
    );
  });
}
