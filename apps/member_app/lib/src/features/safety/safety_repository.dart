import '../../core/api_client.dart';

class VerificationState {
  const VerificationState({
    required this.status,
    required this.verified,
    required this.requirement,
    required this.blocksProfile,
  });

  final String status;
  final bool verified;
  final String requirement;
  final bool blocksProfile;

  factory VerificationState.fromJson(Map<String, dynamic> json) =>
      VerificationState(
        status: json['status']?.toString() ?? 'not_requested',
        verified: json['verified'] == true,
        requirement: json['requirement']?.toString() ?? 'optional',
        blocksProfile: json['blocks_profile'] == true,
      );
}

class VerificationSummaryState {
  const VerificationSummaryState({
    required this.email,
    required this.phone,
    required this.selfie,
    required this.identityAge,
  });

  final VerificationState email;
  final VerificationState phone;
  final VerificationState selfie;
  final VerificationState identityAge;

  factory VerificationSummaryState.fromJson(Map<String, dynamic> json) {
    VerificationState value(String key) {
      final raw = json[key];
      return VerificationState.fromJson(
        raw is Map ? Map<String, dynamic>.from(raw) : const {},
      );
    }

    return VerificationSummaryState(
      email: value('email'),
      phone: value('phone'),
      selfie: value('selfie'),
      identityAge: value('identity_age'),
    );
  }
}

class VerificationCaseState {
  const VerificationCaseState({
    required this.id,
    required this.type,
    required this.status,
    required this.requirement,
    required this.blocksProfile,
    this.reason,
    this.submittedAt,
    this.reviewedAt,
    this.verifiedAt,
    this.appealStatus,
  });

  final String id;
  final String type;
  final String status;
  final String requirement;
  final bool blocksProfile;
  final String? reason;
  final DateTime? submittedAt;
  final DateTime? reviewedAt;
  final DateTime? verifiedAt;
  final String? appealStatus;

  factory VerificationCaseState.fromJson(Map<String, dynamic> json) {
    final appeal = json['appeal'] is Map
        ? Map<String, dynamic>.from(json['appeal'] as Map)
        : const <String, dynamic>{};
    return VerificationCaseState(
      id: json['id']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      requirement: json['requirement']?.toString() ?? 'optional',
      blocksProfile: json['blocks_profile'] == true,
      reason: json['reason']?.toString(),
      submittedAt:
          DateTime.tryParse(json['submitted_at']?.toString() ?? ''),
      reviewedAt: DateTime.tryParse(json['reviewed_at']?.toString() ?? ''),
      verifiedAt: DateTime.tryParse(json['verified_at']?.toString() ?? ''),
      appealStatus: appeal['status']?.toString(),
    );
  }
}

class SafetyRepository {
  SafetyRepository(this._api);

  final SoulApiClient _api;

  Future<VerificationSummaryState> verificationSummary() async {
    final data = await _api.get('verification/summary');
    final raw = data['verification'];
    return VerificationSummaryState.fromJson(
      raw is Map ? Map<String, dynamic>.from(raw) : const {},
    );
  }

  Future<List<VerificationCaseState>> verificationCases() async {
    final data = await _api.get('verification/cases');
    final raw = data['verification_cases'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((item) => VerificationCaseState.fromJson(
              Map<String, dynamic>.from(item),
            ))
        .where((item) => item.id.isNotEmpty)
        .toList(growable: false);
  }

  Future<VerificationCaseState> requestVerification(String type) async {
    final data = await _api.post(
      'verification/cases',
      data: {'type': type},
    );
    final raw = data['verification_case'];
    if (raw is! Map) {
      throw const SoulApiFailure(
        statusCode: null,
        code: 'INVALID_RESPONSE',
        message: 'SOUL returned an invalid verification response.',
      );
    }
    return VerificationCaseState.fromJson(
      Map<String, dynamic>.from(raw),
    );
  }

  Future<void> appealVerification(
    String caseId,
    String statement,
  ) async {
    await _api.post(
      'verification/cases/${Uri.encodeComponent(caseId)}/appeal',
      data: {'statement': statement.trim()},
    );
  }

  Future<void> blockProfile(String profileId) async {
    await _api.post(
      'profiles/${Uri.encodeComponent(profileId)}/block',
      data: const <String, Object?>{},
    );
  }

  Future<void> reportProfile({
    required String profileId,
    required String category,
    String? details,
    required bool block,
  }) async {
    await _api.post(
      'profiles/${Uri.encodeComponent(profileId)}/report',
      data: {
        'category': category,
        if (details != null && details.trim().isNotEmpty)
          'details': details.trim(),
        'action': block ? 'report_and_block' : 'report_only',
      },
    );
  }
}
