import '../../core/api_client.dart';

class DiscoveryPrivacyState {
  const DiscoveryPrivacyState({
    required this.discoverable,
    required this.incognito,
    required this.profilePaused,
  });

  final bool discoverable;
  final bool incognito;
  final bool profilePaused;

  bool get limitedVisibility => !discoverable || incognito || profilePaused;

  factory DiscoveryPrivacyState.fromJson(Map<String, dynamic> json) =>
      DiscoveryPrivacyState(
        discoverable: json['discoverable'] != false,
        incognito: json['incognito'] == true,
        profilePaused: json['profile_paused'] == true,
      );
}

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
    required this.intentions,
    required this.country,
    required this.photos,
    this.city,
    this.distanceBand,
  });

  final String id;
  final String firstName;
  final int age;
  final String maritalStatus;
  final List<String> intentions;
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
      intentions: json['intentions'] is List
          ? (json['intentions'] as List)
              .map((item) => item.toString())
              .toList(growable: false)
          : const [],
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


class DiscoveryProfile {
  const DiscoveryProfile({
    required this.id,
    required this.firstName,
    required this.age,
    required this.maritalStatus,
    required this.country,
    required this.intentions,
    required this.photos,
    required this.spokenLanguages,
    required this.interests,
    required this.personalityTraits,
    required this.verificationBadges,
    this.city,
    this.bio,
    this.education,
    this.heightCm,
    this.jobTitle,
    this.employer,
    this.grewUpIn,
    this.ethnicOrigin,
    this.religiousPractice,
    this.prayer,
    this.diet,
    this.dress,
    this.relocationPreference,
    this.familyInvolvementPreference,
  });

  final String id;
  final String firstName;
  final int age;
  final String maritalStatus;
  final String country;
  final String? city;
  final String? bio;
  final String? education;
  final int? heightCm;
  final String? jobTitle;
  final String? employer;
  final String? grewUpIn;
  final String? ethnicOrigin;
  final String? religiousPractice;
  final String? prayer;
  final String? diet;
  final String? dress;
  final String? relocationPreference;
  final String? familyInvolvementPreference;
  final List<String> intentions;
  final List<DiscoveryPhoto> photos;
  final List<String> spokenLanguages;
  final List<String> interests;
  final List<String> personalityTraits;
  final Map<String, bool> verificationBadges;

  factory DiscoveryProfile.fromJson(Map<String, dynamic> json) {
    List<String> strings(Object? value) => value is List
        ? value.map((item) => item.toString()).toList(growable: false)
        : const [];

    final rawLanguages = json['spoken_languages'];
    final rawPhotos = json['photos'];
    final rawBadges = json['verification_badges'];

    return DiscoveryProfile(
      id: json['id']?.toString() ?? '',
      firstName: json['first_name']?.toString() ?? '',
      age: (json['age'] as num?)?.toInt() ?? 0,
      maritalStatus: json['marital_status']?.toString() ?? '',
      country: json['country']?.toString() ?? '',
      city: json['city']?.toString(),
      bio: json['bio']?.toString(),
      education: json['education']?.toString(),
      heightCm: (json['height_cm'] as num?)?.toInt(),
      jobTitle: json['job_title']?.toString(),
      employer: json['employer']?.toString(),
      grewUpIn: json['grew_up_in']?.toString(),
      ethnicOrigin: json['ethnic_origin']?.toString(),
      religiousPractice: json['religious_practice']?.toString(),
      prayer: json['prayer']?.toString(),
      diet: json['diet']?.toString(),
      dress: json['dress']?.toString(),
      relocationPreference: json['relocation_preference']?.toString(),
      familyInvolvementPreference:
          json['family_involvement_preference']?.toString(),
      intentions: strings(json['intentions']),
      interests: strings(json['interests']),
      personalityTraits: strings(json['personality_traits']),
      spokenLanguages: rawLanguages is List
          ? rawLanguages
              .whereType<Map>()
              .map((item) {
                final mapped = Map<String, dynamic>.from(item);
                final native = mapped['native_name']?.toString() ?? '';
                final name = mapped['name']?.toString() ?? '';
                return native.isNotEmpty ? native : name;
              })
              .where((value) => value.isNotEmpty)
              .toList(growable: false)
          : const [],
      photos: rawPhotos is List
          ? rawPhotos
              .whereType<Map>()
              .map(
                (item) => DiscoveryPhoto.fromJson(
                  Map<String, dynamic>.from(item),
                ),
              )
              .toList(growable: false)
          : const [],
      verificationBadges: rawBadges is Map
          ? Map<String, dynamic>.from(rawBadges).map(
              (key, value) => MapEntry(key, value == true),
            )
          : const {},
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
    this.age,
    this.city,
    this.country,
    this.photoUrl,
  });

  final String profileId;
  final String firstName;
  final DateTime? receivedAt;
  final int? age;
  final String? city;
  final String? country;
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
      age: (mapped['age'] as num?)?.toInt(),
      city: mapped['city']?.toString(),
      country: mapped['country']?.toString(),
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

  Future<DiscoveryPrivacyState> privacyState() async {
    final data = await _api.get('privacy/settings');
    final raw = data['privacy'];
    return DiscoveryPrivacyState.fromJson(
      raw is Map ? Map<String, dynamic>.from(raw) : const {},
    );
  }

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


  Future<DiscoveryProfile> profile(String profileId) async {
    final data = await _api.get(
      'profiles/${Uri.encodeComponent(profileId)}',
    );
    final raw = data['profile'];
    if (raw is! Map) {
      throw const SoulApiFailure(
        statusCode: null,
        code: 'INVALID_PROFILE_RESPONSE',
        message: 'SOUL returned an invalid profile response.',
      );
    }
    return DiscoveryProfile.fromJson(
      Map<String, dynamic>.from(raw),
    );
  }

  Future<DecisionResult> decide(String profileId, String decision) async {
    final data = await _api.post(
      'profiles/${Uri.encodeComponent(profileId)}/decision',
      data: {'decision': decision},
    );
    return DecisionResult.fromJson(data);
  }

  Future<void> withdrawLike(String profileId) async {
    await _api.delete(
      'profiles/${Uri.encodeComponent(profileId)}/like',
    );
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
