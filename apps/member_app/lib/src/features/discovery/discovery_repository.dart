import '../../core/api_client.dart';

class DiscoveryPhoto {
  const DiscoveryPhoto({
    required this.id,
    required this.position,
    this.url,
  });

  final String id;
  final int position;
  final String? url;

  factory DiscoveryPhoto.fromJson(Map<String, dynamic> json) => DiscoveryPhoto(
        id: json['id']?.toString() ?? '',
        position: (json['position'] as num?)?.toInt() ?? 0,
        url: json['url']?.toString(),
      );
}

class DiscoveryCandidate {
  const DiscoveryCandidate({
    required this.id,
    required this.firstName,
    required this.age,
    required this.maritalStatus,
    required this.country,
    required this.photos,
    this.city,
    this.distanceBand,
  });

  final String id;
  final String firstName;
  final int age;
  final String maritalStatus;
  final String country;
  final String? city;
  final String? distanceBand;
  final List<DiscoveryPhoto> photos;

  factory DiscoveryCandidate.fromJson(Map<String, dynamic> json) {
    final rawPhotos = json['photos'];
    return DiscoveryCandidate(
      id: json['id']?.toString() ?? '',
      firstName: json['first_name']?.toString() ?? '',
      age: (json['age'] as num?)?.toInt() ?? 0,
      maritalStatus: json['marital_status']?.toString() ?? '',
      country: json['country']?.toString() ?? '',
      city: json['city']?.toString(),
      distanceBand: json['distance_band']?.toString(),
      photos: rawPhotos is List
          ? rawPhotos
              .whereType<Map>()
              .map((item) => DiscoveryPhoto.fromJson(Map<String, dynamic>.from(item)))
              .toList(growable: false)
          : const [],
    );
  }
}

class SelectedDiscoveryLocation {
  const SelectedDiscoveryLocation({required this.countryCode, this.cityName});

  final String countryCode;
  final String? cityName;

  factory SelectedDiscoveryLocation.fromJson(Map<String, dynamic> json) =>
      SelectedDiscoveryLocation(
        countryCode: json['country_code']?.toString() ?? '',
        cityName: json['city_name']?.toString(),
      );

  Map<String, Object?> toJson() => {
        'country_code': countryCode.toUpperCase(),
        if (cityName != null && cityName!.trim().isNotEmpty)
          'city_name': cityName!.trim(),
      };
}

class DiscoveryPreferences {
  const DiscoveryPreferences({
    required this.preferredGender,
    required this.minimumAge,
    required this.maximumAge,
    required this.sameCountryOnly,
    required this.religionMode,
    required this.locationMode,
    required this.intentions,
    this.radiusKm,
    this.selectedLocations = const [],
  });

  final String preferredGender;
  final int minimumAge;
  final int maximumAge;
  final bool sameCountryOnly;
  final String religionMode;
  final String locationMode;
  final int? radiusKm;
  final List<SelectedDiscoveryLocation> selectedLocations;
  final List<String> intentions;

  factory DiscoveryPreferences.fromJson(Map<String, dynamic> json) {
    final rawLocations = json['selected_locations'];
    final rawIntentions = json['intentions'];
    return DiscoveryPreferences(
      preferredGender: json['preferred_gender']?.toString() ?? 'woman',
      minimumAge: (json['minimum_age'] as num?)?.toInt() ?? 18,
      maximumAge: (json['maximum_age'] as num?)?.toInt() ?? 45,
      sameCountryOnly: json['same_country_only'] != false,
      religionMode: json['religion_mode']?.toString() ?? 'my_religion',
      locationMode: json['location_mode']?.toString() ?? 'current',
      radiusKm: (json['radius_km'] as num?)?.toInt(),
      selectedLocations: rawLocations is List
          ? rawLocations
              .whereType<Map>()
              .map((item) => SelectedDiscoveryLocation.fromJson(
                    Map<String, dynamic>.from(item),
                  ))
              .toList(growable: false)
          : const [],
      intentions: rawIntentions is List
          ? rawIntentions.map((item) => item.toString()).toList(growable: false)
          : const [],
    );
  }

  Map<String, Object?> toJson() => {
        'preferred_gender': preferredGender,
        'minimum_age': minimumAge,
        'maximum_age': maximumAge,
        'same_country_only': sameCountryOnly,
        'religion_mode': religionMode,
        'location_mode': locationMode,
        'radius_km': locationMode == 'current' ? radiusKm : null,
        if (locationMode == 'selected')
          'selected_locations':
              selectedLocations.map((item) => item.toJson()).toList(growable: false),
        'intentions': intentions,
      };
}

class CandidatePage {
  const CandidatePage({required this.items, this.nextCursor});

  final List<DiscoveryCandidate> items;
  final String? nextCursor;
}

class IncomingLike {
  const IncomingLike({
    required this.profileId,
    required this.firstName,
    required this.receivedAt,
    this.photoUrl,
  });

  final String profileId;
  final String firstName;
  final DateTime? receivedAt;
  final String? photoUrl;

  factory IncomingLike.fromJson(Map<String, dynamic> json) {
    final profile = json['profile'];
    final mapped = profile is Map
        ? Map<String, dynamic>.from(profile)
        : const <String, dynamic>{};
    final photo = mapped['photo'];
    final photoMap =
        photo is Map ? Map<String, dynamic>.from(photo) : const <String, dynamic>{};
    return IncomingLike(
      profileId: mapped['id']?.toString() ?? '',
      firstName: mapped['first_name']?.toString() ?? '',
      receivedAt: DateTime.tryParse(json['received_at']?.toString() ?? ''),
      photoUrl: photoMap['url']?.toString(),
    );
  }
}

class IncomingLikePage {
  const IncomingLikePage({required this.items, this.nextCursor});

  final List<IncomingLike> items;
  final String? nextCursor;
}

class DecisionResult {
  const DecisionResult({
    required this.matched,
    this.matchId,
  });

  final bool matched;
  final String? matchId;

  factory DecisionResult.fromJson(Map<String, dynamic> json) => DecisionResult(
        matched: json['matched'] == true,
        matchId: json['match_id']?.toString(),
      );
}

class DiscoveryRepository {
  DiscoveryRepository(this._api);

  final SoulApiClient _api;

  Future<DiscoveryPreferences?> preferences() async {
    final data = await _api.get('discovery/preferences');
    final raw = data['preferences'];
    if (raw is! Map) return null;
    return DiscoveryPreferences.fromJson(Map<String, dynamic>.from(raw));
  }

  Future<DiscoveryPreferences> savePreferences(
    DiscoveryPreferences preferences,
  ) async {
    final data = await _api.put(
      'discovery/preferences',
      data: preferences.toJson(),
    );
    final raw = data['preferences'];
    if (raw is! Map) {
      throw const SoulApiFailure(
        statusCode: null,
        code: 'INVALID_RESPONSE',
        message: 'SOUL returned invalid discovery preferences.',
      );
    }
    return DiscoveryPreferences.fromJson(Map<String, dynamic>.from(raw));
  }

  Future<CandidatePage> candidates({String? cursor}) async {
    final data = await _api.get(
      'discovery/candidates',
      query: {if (cursor != null && cursor.isNotEmpty) 'cursor': cursor},
    );
    final raw = data['candidates'];
    return CandidatePage(
      items: raw is List
          ? raw
              .whereType<Map>()
              .map((item) => DiscoveryCandidate.fromJson(
                    Map<String, dynamic>.from(item),
                  ))
              .where((item) => item.id.isNotEmpty)
              .toList(growable: false)
          : const [],
      nextCursor: data['next_cursor']?.toString(),
    );
  }

  Future<DecisionResult> decide(String profileId, String decision) async {
    final data = await _api.post(
      'profiles/${Uri.encodeComponent(profileId)}/decision',
      data: {'decision': decision},
    );
    return DecisionResult.fromJson(data);
  }

  Future<IncomingLikePage> receivedLikes({String? cursor}) async {
    final data = await _api.get(
      'likes/received',
      query: {if (cursor != null && cursor.isNotEmpty) 'cursor': cursor},
    );
    final raw = data['requests'];
    return IncomingLikePage(
      items: raw is List
          ? raw
              .whereType<Map>()
              .map((item) => IncomingLike.fromJson(
                    Map<String, dynamic>.from(item),
                  ))
              .where((item) => item.profileId.isNotEmpty)
              .toList(growable: false)
          : const [],
      nextCursor: data['next_cursor']?.toString(),
    );
  }

  Future<DecisionResult> respondToLike(
    String profileId,
    String decision,
  ) async {
    final data = await _api.put(
      'profiles/${Uri.encodeComponent(profileId)}/like',
      data: {'decision': decision},
    );
    return DecisionResult.fromJson(data);
  }
}
