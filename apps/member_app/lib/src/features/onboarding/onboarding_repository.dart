import '../../core/api_client.dart';

class ReligionChoice {
  const ReligionChoice({
    required this.id,
    required this.label,
    required this.hasChildren,
    this.level,
  });

  final String id;
  final String label;
  final bool hasChildren;
  final String? level;

  factory ReligionChoice.fromJson(Map<String, dynamic> json) => ReligionChoice(
        id: json['id']!.toString(),
        label: json['label']?.toString() ?? '',
        hasChildren: json['has_children'] == true,
        level: json['type']?.toString() ?? json['level']?.toString(),
      );
}

class ReligionProfilePathNode {
  const ReligionProfilePathNode({
    required this.id,
    required this.type,
    required this.slug,
    this.label,
    this.labelLocale,
  });

  final String id;
  final String type;
  final String slug;
  final String? label;
  final String? labelLocale;

  factory ReligionProfilePathNode.fromJson(Map<String, dynamic> json) =>
      ReligionProfilePathNode(
        id: json['id']?.toString() ?? '',
        type: json['type']?.toString() ?? '',
        slug: json['slug']?.toString() ?? '',
        label: json['label']?.toString(),
        labelLocale: json['label_locale']?.toString(),
      );
}

class ReligionProfileSnapshot {
  const ReligionProfileSnapshot({
    required this.selectedNodeId,
    required this.country,
    required this.path,
  });

  final String selectedNodeId;
  final String? country;
  final List<ReligionProfilePathNode> path;

  factory ReligionProfileSnapshot.fromJson(Map<String, dynamic> json) {
    final rawPath = json['path'];
    return ReligionProfileSnapshot(
      selectedNodeId: json['selected_node_id']?.toString() ?? '',
      country: json['country']?.toString(),
      path: rawPath is List
          ? rawPath
              .whereType<Map>()
              .map(
                (item) => ReligionProfilePathNode.fromJson(
                  Map<String, dynamic>.from(item),
                ),
              )
              .where((item) => item.id.isNotEmpty)
              .toList(growable: false)
          : const [],
    );
  }

  List<ReligionChoice> restoreChoices() => List<ReligionChoice>.generate(
        path.length,
        (index) {
          final node = path[index];
          final label = node.label?.trim();
          return ReligionChoice(
            id: node.id,
            label: label != null && label.isNotEmpty
                ? label
                : node.slug.replaceAll('-', ' '),
            hasChildren: index < path.length - 1,
            level: node.type,
          );
        },
        growable: false,
      );
}

class OnboardingCatalogChoice {
  const OnboardingCatalogChoice({
    required this.value,
    required this.label,
  });

  final String value;
  final String label;

  factory OnboardingCatalogChoice.fromJson(Map<String, dynamic> json) {
    final value =
        json['key']?.toString() ?? json['code']?.toString() ?? '';
    final label = json['label']?.toString() ??
        json['native_name']?.toString() ??
        json['name']?.toString() ??
        value;
    return OnboardingCatalogChoice(value: value, label: label);
  }
}

class OnboardingProfileCatalog {
  const OnboardingProfileCatalog({
    required this.interests,
    required this.personalityTraits,
  });

  final List<OnboardingCatalogChoice> interests;
  final List<OnboardingCatalogChoice> personalityTraits;

  factory OnboardingProfileCatalog.fromJson(Map<String, dynamic> json) {
    List<OnboardingCatalogChoice> items(String key) {
      final raw = json[key];
      if (raw is! List) return const [];
      return raw
          .whereType<Map>()
          .map(
            (item) => OnboardingCatalogChoice.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .where((item) => item.value.isNotEmpty && item.label.isNotEmpty)
          .toList(growable: false);
    }

    return OnboardingProfileCatalog(
      interests: items('interests'),
      personalityTraits: items('personality_traits'),
    );
  }
}

class SpokenLanguageChoice {
  const SpokenLanguageChoice({required this.code, required this.label});

  final String code;
  final String label;

  factory SpokenLanguageChoice.fromJson(Map<String, dynamic> json) {
    final nativeName = json['native_name']?.toString().trim() ?? '';
    final name = json['name']?.toString().trim() ?? '';
    return SpokenLanguageChoice(
      code: json['code']?.toString() ?? '',
      label: nativeName.isNotEmpty ? nativeName : name,
    );
  }
}

class OnboardingRepository {
  OnboardingRepository(this._api);

  final SoulApiClient _api;

  Future<Map<String, dynamic>> profile() async {
    final data = await _api.get('onboarding/profile');
    final profile = data['profile'];
    return profile is Map
        ? Map<String, dynamic>.from(profile)
        : const <String, dynamic>{};
  }

  Future<Map<String, dynamic>> readiness() =>
      _api.get('onboarding/readiness');

  Future<ReligionProfileSnapshot?> religionProfile() async {
    final data = await _api.get('onboarding/religion-profile');
    final raw = data['religion_profile'];
    if (raw is! Map) return null;
    return ReligionProfileSnapshot.fromJson(
      Map<String, dynamic>.from(raw),
    );
  }

  Future<OnboardingProfileCatalog> profileCatalog() async {
    final data = await _api.get('catalogs/profile');
    return OnboardingProfileCatalog.fromJson(data);
  }

  Future<List<SpokenLanguageChoice>> spokenLanguages() async {
    final data = await _api.get('catalogs/profile');
    final raw = data['spoken_languages'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((item) => SpokenLanguageChoice.fromJson(Map<String, dynamic>.from(item)))
        .where((item) => item.code.isNotEmpty && item.label.isNotEmpty)
        .toList(growable: false);
  }

  Future<void> saveProfile(Map<String, Object?> changes) async {
    await _api.put('onboarding/profile', data: changes);
  }

  Future<List<ReligionChoice>> religionOptions({
    String? parentId,
    String? country,
  }) async {
    final query = <String, dynamic>{
      if (parentId != null) 'parent_id': parentId,
      if (country != null && country.isNotEmpty) 'country': country,
    };
    final data = await _api.get('onboarding/religion-options', query: query);
    final raw = data['options'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((item) => ReligionChoice.fromJson(Map<String, dynamic>.from(item)))
        .where((item) => item.id.isNotEmpty && item.label.isNotEmpty)
        .toList(growable: false);
  }

  Future<void> saveReligion({
    required String selectedNodeId,
    String? country,
  }) async {
    await _api.put('onboarding/religion-profile', data: {
      'selected_node_id': selectedNodeId,
      if (country != null && country.isNotEmpty) 'country': country,
    });
  }

  Future<Map<String, dynamic>> submit(Map<String, Object?> legalVersions) =>
      _api.post('onboarding/submit', data: legalVersions);

  Future<Map<String, dynamic>> resubmit() =>
      _api.post('onboarding/resubmit');

  Future<ProfileLifecycle> status() async {
    final data = await _api.get('onboarding/status');
    final profile = data['profile'];
    return ProfileLifecycle.fromJson(
      profile is Map ? Map<String, dynamic>.from(profile) : const {},
    );
  }

  Future<LegalConsentState> legalConsent() async {
    final data = await _api.get('legal/consent');
    final legal = data['legal'];
    return LegalConsentState.fromJson(
      legal is Map ? Map<String, dynamic>.from(legal) : const {},
    );
  }

  Future<void> acceptLegal(Map<String, Object?> versions) async {
    await _api.post('legal/consent', data: versions);
  }
}

class LegalConsentState {
  const LegalConsentState({
    required this.requiresAcceptance,
    required this.versions,
    required this.commitmentKeys,
  });

  final bool requiresAcceptance;
  final Map<String, String> versions;
  final List<String> commitmentKeys;

  factory LegalConsentState.fromJson(Map<String, dynamic> json) {
    final versions = <String, String>{};
    final documents = json['documents'];
    if (documents is List) {
      for (final document in documents.whereType<Map>()) {
        final type = document['type']?.toString();
        final version = document['current_version']?.toString();
        if (type != null && version != null) versions[type] = version;
      }
    }
    return LegalConsentState(
      requiresAcceptance: json['requires_acceptance'] == true,
      versions: versions,
      commitmentKeys: json['commitment_keys'] is List
          ? (json['commitment_keys'] as List).map((item) => item.toString()).toList(growable: false)
          : const [],
    );
  }

  Map<String, Object?> submissionPayload() => {
        'terms_version': versions['terms'],
        'privacy_version': versions['privacy'],
        'community_guidelines_version': versions['community_guidelines'],
        'community_commitment_version': versions['community_commitment'],
      };
}

class ProfileLifecycle {
  const ProfileLifecycle({
    required this.status,
    this.reason,
    this.correctionScreen,
  });
  final String status;
  final String? reason;
  final String? correctionScreen;

  bool get processing => status == 'submitted' || status == 'automated_checks';
  bool get live => status == 'live';
  bool get correctable => status == 'changes_required';

  factory ProfileLifecycle.fromJson(Map<String, dynamic> json) => ProfileLifecycle(
        status: json['status']?.toString() ?? 'draft',
        reason: json['reason']?.toString(),
        correctionScreen: json['correction_screen']?.toString(),
      );
}
