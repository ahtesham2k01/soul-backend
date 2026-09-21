import '../../core/api_client.dart';

class SoulEvent {
  const SoulEvent({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.startsAt,
    required this.timezone,
    required this.isJoined,
    this.endsAt,
    this.city,
    this.countryCode,
    this.capacity,
    this.registrationCount,
    this.spacesRemaining,
    this.onlineUrl,
  });

  final String id;
  final String type;
  final String title;
  final String description;
  final DateTime startsAt;
  final DateTime? endsAt;
  final String timezone;
  final String? city;
  final String? countryCode;
  final int? capacity;
  final int? registrationCount;
  final int? spacesRemaining;
  final bool isJoined;
  final String? onlineUrl;

  factory SoulEvent.fromJson(Map<String, dynamic> json) => SoulEvent(
        id: json['id']?.toString() ?? '',
        type: json['type']?.toString() ?? 'in_person',
        title: json['title']?.toString() ?? 'SOUL event',
        description: json['description']?.toString() ?? '',
        startsAt: DateTime.tryParse(json['starts_at']?.toString() ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
        endsAt: DateTime.tryParse(json['ends_at']?.toString() ?? ''),
        timezone: json['timezone']?.toString() ?? 'UTC',
        city: json['city']?.toString(),
        countryCode: json['country_code']?.toString(),
        capacity: (json['capacity'] as num?)?.toInt(),
        registrationCount:
            (json['registration_count'] as num?)?.toInt(),
        spacesRemaining: (json['spaces_remaining'] as num?)?.toInt(),
        isJoined: json['is_joined'] == true,
        onlineUrl: json['online_url']?.toString(),
      );
}

class EventPage {
  const EventPage({required this.items, this.nextCursor});

  final List<SoulEvent> items;
  final String? nextCursor;
}

class EventRepository {
  EventRepository(this._api);

  final SoulApiClient _api;

  Future<EventPage> events({
    String? cursor,
    bool joinedOnly = false,
  }) async {
    final data = await _api.get(
      'events',
      query: {
        if (cursor != null && cursor.isNotEmpty) 'cursor': cursor,
        if (joinedOnly) 'joined': 'true',
      },
    );
    final raw = data['events'];
    return EventPage(
      items: raw is List
          ? raw
              .whereType<Map>()
              .map((item) =>
                  SoulEvent.fromJson(Map<String, dynamic>.from(item)))
              .where((item) => item.id.isNotEmpty)
              .toList(growable: false)
          : const [],
      nextCursor: data['next_cursor']?.toString(),
    );
  }

  Future<SoulEvent> event(String id) async {
    final data = await _api.get('events/${Uri.encodeComponent(id)}');
    final raw = data['event'];
    if (raw is! Map) {
      throw const SoulApiFailure(
        statusCode: null,
        code: 'INVALID_RESPONSE',
        message: 'SOUL returned an invalid event.',
      );
    }
    return SoulEvent.fromJson(Map<String, dynamic>.from(raw));
  }

  Future<void> join(String id) async {
    await _api.post(
      'events/${Uri.encodeComponent(id)}/registration',
      data: const <String, Object?>{},
    );
  }

  Future<void> leave(String id) async {
    await _api.delete('events/${Uri.encodeComponent(id)}/registration');
  }

  Future<void> report({
    required String id,
    required String category,
    String? details,
  }) async {
    await _api.post(
      'events/${Uri.encodeComponent(id)}/report',
      data: {
        'category': category,
        if (details != null && details.trim().isNotEmpty)
          'details': details.trim(),
      },
    );
  }
}
