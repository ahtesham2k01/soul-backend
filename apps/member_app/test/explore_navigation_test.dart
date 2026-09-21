import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Explore exposes incoming likes and events from the main navigation', () {
    final explore = File(
      'lib/src/features/likes/received_likes_screen.dart',
    ).readAsStringSync();
    final app = File('lib/src/app.dart').readAsStringSync();

    expect(explore, contains("'likes.received'"));
    expect(explore, contains('EventsScreen('));
    expect(explore, contains('widget.eventRepository'));
    expect(app, contains('eventRepository: events'));
  });

  test('Explore does not invent an unsupported outgoing-likes listing API', () {
    final repository = File(
      'lib/src/features/discovery/discovery_repository.dart',
    ).readAsStringSync();

    expect(repository, contains("'likes/received'"));
    expect(repository, contains("'profiles/${Uri.encodeComponent(profileId)}/like'"));
    expect(repository, isNot(contains("'likes/sent'")));
    expect(repository, isNot(contains("'likes/outgoing'")));
  });
}
