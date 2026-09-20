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
        level: json['level']?.toString(),
      );
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
}
