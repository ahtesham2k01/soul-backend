import '../../core/api_client.dart';
import '../../core/session_store.dart';

class AccountSnapshot {
  const AccountSnapshot({
    required this.id,
    required this.status,
    required this.preferredLocale,
    this.name,
    this.email,
    this.phone,
  });

  final String id;
  final String status;
  final String preferredLocale;
  final String? name;
  final String? email;
  final String? phone;

  factory AccountSnapshot.fromJson(Map<String, dynamic> json) => AccountSnapshot(
        id: json['id']?.toString() ?? '',
        status: json['status']?.toString() ?? '',
        preferredLocale: json['preferred_locale']?.toString() ?? 'en',
        name: json['name']?.toString(),
        email: json['email']?.toString(),
        phone: json['phone']?.toString(),
      );
}

class OwnProfilePhoto {
  const OwnProfilePhoto({
    required this.id,
    required this.position,
    required this.visibility,
    required this.moderationStatus,
    required this.screenshotProtectionEnabled,
    this.url,
    this.rejectionReason,
    this.faceDetected,
  });

  final String id;
  final int position;
  final String visibility;
  final String moderationStatus;
  final bool screenshotProtectionEnabled;
  final String? url;
  final String? rejectionReason;
  final bool? faceDetected;

  factory OwnProfilePhoto.fromJson(Map<String, dynamic> json) => OwnProfilePhoto(
        id: json['id']?.toString() ?? '',
        position: (json['position'] as num?)?.toInt() ?? 0,
        visibility: json['visibility']?.toString() ?? 'public',
        moderationStatus: json['moderation_status']?.toString() ?? 'pending',
        screenshotProtectionEnabled:
            json['screenshot_protection_enabled'] != false,
        url: json['url']?.toString(),
        rejectionReason: json['rejection_reason']?.toString(),
        faceDetected: json['face_detected'] as bool?,
      );
}

class PrivacySettings {
  const PrivacySettings({
    required this.showCity,
    required this.discoverable,
    required this.incognito,
    required this.profilePaused,
    required this.hideContacts,
    required this.screenshotProtectionEnabled,
  });

  final bool showCity;
  final bool discoverable;
  final bool incognito;
  final bool profilePaused;
  final bool hideContacts;
  final bool screenshotProtectionEnabled;

  factory PrivacySettings.fromJson(Map<String, dynamic> json) =>
      PrivacySettings(
        showCity: json['show_city'] != false,
        discoverable: json['discoverable'] != false,
        incognito: json['incognito'] == true,
        profilePaused: json['profile_paused'] == true,
        hideContacts: json['hide_contacts'] == true,
        screenshotProtectionEnabled:
            json['screenshot_protection_enabled'] != false,
      );

  Map<String, Object?> toJson() => {
        'show_city': showCity,
        'discoverable': discoverable,
        'incognito': incognito,
        'profile_paused': profilePaused,
        'hide_contacts': hideContacts,
        'screenshot_protection_enabled': screenshotProtectionEnabled,
      };

  PrivacySettings copyWith({
    bool? showCity,
    bool? discoverable,
    bool? incognito,
    bool? profilePaused,
    bool? hideContacts,
    bool? screenshotProtectionEnabled,
  }) =>
      PrivacySettings(
        showCity: showCity ?? this.showCity,
        discoverable: discoverable ?? this.discoverable,
        incognito: incognito ?? this.incognito,
        profilePaused: profilePaused ?? this.profilePaused,
        hideContacts: hideContacts ?? this.hideContacts,
        screenshotProtectionEnabled:
            screenshotProtectionEnabled ?? this.screenshotProtectionEnabled,
      );
}

class NotificationSettings {
  const NotificationSettings({
    required this.pushNewMatches,
    required this.pushNewMessages,
    required this.pushPrivatePhotos,
    required this.pushVerification,
    required this.pushAccount,
    required this.pushMarketing,
    required this.emailNewMatches,
    required this.emailNewMessages,
    required this.emailPrivatePhotos,
    required this.emailVerification,
    required this.emailAccount,
    required this.emailMarketing,
  });

  final bool pushNewMatches;
  final bool pushNewMessages;
  final bool pushPrivatePhotos;
  final bool pushVerification;
  final bool pushAccount;
  final bool pushMarketing;
  final bool emailNewMatches;
  final bool emailNewMessages;
  final bool emailPrivatePhotos;
  final bool emailVerification;
  final bool emailAccount;
  final bool emailMarketing;

  factory NotificationSettings.fromJson(Map<String, dynamic> json) {
    final push = json['push'] is Map
        ? Map<String, dynamic>.from(json['push'] as Map)
        : const <String, dynamic>{};
    final email = json['email'] is Map
        ? Map<String, dynamic>.from(json['email'] as Map)
        : const <String, dynamic>{};
    return NotificationSettings(
      pushNewMatches: push['new_matches'] != false,
      pushNewMessages: push['new_messages'] != false,
      pushPrivatePhotos: push['private_photos'] != false,
      pushVerification: push['verification'] != false,
      pushAccount: push['account'] != false,
      pushMarketing: push['marketing'] == true,
      emailNewMatches: email['new_matches'] == true,
      emailNewMessages: email['new_messages'] == true,
      emailPrivatePhotos: email['private_photos'] == true,
      emailVerification: email['verification'] == true,
      emailAccount: email['account'] == true,
      emailMarketing: email['marketing'] == true,
    );
  }

  Map<String, Object?> toJson() => {
        'push': {
          'new_matches': pushNewMatches,
          'new_messages': pushNewMessages,
          'private_photos': pushPrivatePhotos,
          'verification': pushVerification,
          'account': pushAccount,
          'marketing': pushMarketing,
        },
        'email': {
          'new_matches': emailNewMatches,
          'new_messages': emailNewMessages,
          'private_photos': emailPrivatePhotos,
          'verification': emailVerification,
          'account': emailAccount,
          'marketing': emailMarketing,
        },
      };

  NotificationSettings copyWith({
    bool? pushNewMatches,
    bool? pushNewMessages,
    bool? pushPrivatePhotos,
    bool? pushVerification,
    bool? pushAccount,
    bool? pushMarketing,
    bool? emailNewMatches,
    bool? emailNewMessages,
    bool? emailPrivatePhotos,
    bool? emailVerification,
    bool? emailAccount,
    bool? emailMarketing,
  }) =>
      NotificationSettings(
        pushNewMatches: pushNewMatches ?? this.pushNewMatches,
        pushNewMessages: pushNewMessages ?? this.pushNewMessages,
        pushPrivatePhotos: pushPrivatePhotos ?? this.pushPrivatePhotos,
        pushVerification: pushVerification ?? this.pushVerification,
        pushAccount: pushAccount ?? this.pushAccount,
        pushMarketing: pushMarketing ?? this.pushMarketing,
        emailNewMatches: emailNewMatches ?? this.emailNewMatches,
        emailNewMessages: emailNewMessages ?? this.emailNewMessages,
        emailPrivatePhotos: emailPrivatePhotos ?? this.emailPrivatePhotos,
        emailVerification: emailVerification ?? this.emailVerification,
        emailAccount: emailAccount ?? this.emailAccount,
        emailMarketing: emailMarketing ?? this.emailMarketing,
      );
}

class MemberNotification {
  const MemberNotification({
    required this.id,
    required this.type,
    required this.data,
    required this.createdAt,
    this.readAt,
  });

  final String id;
  final String type;
  final Map<String, dynamic> data;
  final DateTime createdAt;
  final DateTime? readAt;

  bool get unread => readAt == null;

  factory MemberNotification.fromJson(Map<String, dynamic> json) =>
      MemberNotification(
        id: json['id']?.toString() ?? '',
        type: json['type']?.toString() ?? 'notification',
        data: json['data'] is Map
            ? Map<String, dynamic>.from(json['data'] as Map)
            : const <String, dynamic>{},
        createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
        readAt: DateTime.tryParse(json['read_at']?.toString() ?? ''),
      );
}

class MemberNotificationPage {
  const MemberNotificationPage({required this.items, this.nextCursor});

  final List<MemberNotification> items;
  final String? nextCursor;
}

class BlockedProfile {
  const BlockedProfile({
    required this.id,
    required this.firstName,
    required this.blockedAt,
    this.photoUrl,
  });

  final String id;
  final String firstName;
  final DateTime? blockedAt;
  final String? photoUrl;

  factory BlockedProfile.fromJson(Map<String, dynamic> json) {
    final profile = json['profile'] is Map
        ? Map<String, dynamic>.from(json['profile'] as Map)
        : const <String, dynamic>{};
    final photo = profile['photo'] is Map
        ? Map<String, dynamic>.from(profile['photo'] as Map)
        : const <String, dynamic>{};
    return BlockedProfile(
      id: profile['id']?.toString() ?? '',
      firstName: profile['first_name']?.toString() ?? '',
      blockedAt: DateTime.tryParse(json['blocked_at']?.toString() ?? ''),
      photoUrl: photo['url']?.toString(),
    );
  }
}

class BlockedProfilePage {
  const BlockedProfilePage({required this.items, this.nextCursor});

  final List<BlockedProfile> items;
  final String? nextCursor;
}

class DeviceSession {
  const DeviceSession({
    required this.id,
    required this.deviceName,
    required this.isCurrent,
    this.lastUsedAt,
    this.createdAt,
    this.expiresAt,
  });

  final String id;
  final String deviceName;
  final bool isCurrent;
  final DateTime? lastUsedAt;
  final DateTime? createdAt;
  final DateTime? expiresAt;

  factory DeviceSession.fromJson(Map<String, dynamic> json) => DeviceSession(
        id: json['id']?.toString() ?? '',
        deviceName: json['device_name']?.toString() ?? 'Device',
        isCurrent: json['is_current'] == true,
        lastUsedAt:
            DateTime.tryParse(json['last_used_at']?.toString() ?? ''),
        createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
        expiresAt: DateTime.tryParse(json['expires_at']?.toString() ?? ''),
      );
}

class DataExportState {
  const DataExportState({
    required this.id,
    required this.status,
    required this.downloadAvailable,
    this.completedAt,
    this.expiresAt,
  });

  final String id;
  final String status;
  final bool downloadAvailable;
  final DateTime? completedAt;
  final DateTime? expiresAt;

  factory DataExportState.fromJson(Map<String, dynamic> json) => DataExportState(
        id: json['id']?.toString() ?? '',
        status: json['status']?.toString() ?? 'pending',
        downloadAvailable: json['download_available'] == true,
        completedAt:
            DateTime.tryParse(json['completed_at']?.toString() ?? ''),
        expiresAt: DateTime.tryParse(json['expires_at']?.toString() ?? ''),
      );
}

class ReligionOption {
  const ReligionOption({
    required this.id,
    required this.label,
    required this.hasChildren,
  });

  final String id;
  final String label;
  final bool hasChildren;

  factory ReligionOption.fromJson(Map<String, dynamic> json) => ReligionOption(
        id: json['id']?.toString() ?? '',
        label: json['label']?.toString() ?? '',
        hasChildren: json['has_children'] == true,
      );
}

class CatalogChoice {
  const CatalogChoice({required this.value, required this.label});

  final String value;
  final String label;
}

class ProfileCatalog {
  const ProfileCatalog({
    required this.interests,
    required this.personalityTraits,
    required this.languages,
  });

  final List<CatalogChoice> interests;
  final List<CatalogChoice> personalityTraits;
  final List<CatalogChoice> languages;

  factory ProfileCatalog.fromJson(Map<String, dynamic> json) {
    List<CatalogChoice> profileItems(String key) {
      final raw = json[key];
      if (raw is! List) return const [];
      return raw
          .whereType<Map>()
          .map((item) {
            final mapped = Map<String, dynamic>.from(item);
            final value =
                mapped['key']?.toString() ?? mapped['label']?.toString() ?? '';
            final label = mapped['label']?.toString() ?? value;
            return CatalogChoice(value: value, label: label);
          })
          .where((item) => item.value.isNotEmpty && item.label.isNotEmpty)
          .toList(growable: false);
    }

    final rawLanguages = json['spoken_languages'];
    final languages = rawLanguages is List
        ? rawLanguages.whereType<Map>().map((item) {
            final mapped = Map<String, dynamic>.from(item);
            final code = mapped['code']?.toString() ?? '';
            final native = mapped['native_name']?.toString() ?? '';
            final name = mapped['name']?.toString() ?? '';
            return CatalogChoice(
              value: code,
              label: native.isNotEmpty ? native : name,
            );
          }).where((item) => item.value.isNotEmpty).toList(growable: false)
        : const <CatalogChoice>[];

    return ProfileCatalog(
      interests: profileItems('interests'),
      personalityTraits: profileItems('personality_traits'),
      languages: languages,
    );
  }
}

class SubscriptionProduct {
  const SubscriptionProduct({
    required this.id,
    required this.productId,
    required this.planKey,
    required this.planName,
    required this.trialDays,
    this.description,
  });

  final String id;
  final String productId;
  final String planKey;
  final String planName;
  final int trialDays;
  final String? description;

  factory SubscriptionProduct.fromJson(Map<String, dynamic> json) {
    final plan = json['plan'] is Map
        ? Map<String, dynamic>.from(json['plan'] as Map)
        : const <String, dynamic>{};
    return SubscriptionProduct(
      id: json['id']?.toString() ?? '',
      productId: json['product_id']?.toString() ?? '',
      planKey: plan['key']?.toString() ?? '',
      planName: plan['name']?.toString() ?? '',
      trialDays: (plan['trial_days'] as num?)?.toInt() ?? 0,
      description: plan['description']?.toString(),
    );
  }
}

class ProfileRepository {
  ProfileRepository(this._api, this._sessions);

  final SoulApiClient _api;
  final SessionStore _sessions;

  Future<AccountSnapshot> account() async {
    final data = await _api.get('auth/me');
    final raw = data['user'];
    return AccountSnapshot.fromJson(
      raw is Map ? Map<String, dynamic>.from(raw) : const {},
    );
  }

  Future<Map<String, dynamic>> profile() async {
    final data = await _api.get('onboarding/profile');
    final raw = data['profile'];
    return raw is Map
        ? Map<String, dynamic>.from(raw)
        : const <String, dynamic>{};
  }

  Future<void> saveProfile(Map<String, Object?> changes) async {
    await _api.put('onboarding/profile', data: changes);
  }

  Future<List<OwnProfilePhoto>> photos() async {
    final data = await _api.get('onboarding/photos');
    final raw = data['photos'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((item) => OwnProfilePhoto.fromJson(
              Map<String, dynamic>.from(item),
            ))
        .toList(growable: false);
  }

  Future<PrivacySettings> privacy() async {
    final data = await _api.get('privacy/settings');
    final raw = data['privacy'];
    return PrivacySettings.fromJson(
      raw is Map ? Map<String, dynamic>.from(raw) : const {},
    );
  }

  Future<PrivacySettings> savePrivacy(PrivacySettings settings) async {
    final data = await _api.put(
      'privacy/settings',
      data: settings.toJson(),
    );
    final raw = data['privacy'];
    return PrivacySettings.fromJson(
      raw is Map ? Map<String, dynamic>.from(raw) : const {},
    );
  }

  Future<NotificationSettings> notifications() async {
    final data = await _api.get('notification-preferences');
    final raw = data['preferences'];
    return NotificationSettings.fromJson(
      raw is Map ? Map<String, dynamic>.from(raw) : const {},
    );
  }

  Future<NotificationSettings> saveNotifications(
    NotificationSettings settings,
  ) async {
    final data = await _api.put(
      'notification-preferences',
      data: settings.toJson(),
    );
    final raw = data['preferences'];
    return NotificationSettings.fromJson(
      raw is Map ? Map<String, dynamic>.from(raw) : const {},
    );
  }

  Future<MemberNotificationPage> notificationFeed({
    String? cursor,
  }) async {
    final data = await _api.get(
      'notifications',
      query: {if (cursor != null && cursor.isNotEmpty) 'cursor': cursor},
    );
    final raw = data['notifications'];
    return MemberNotificationPage(
      items: raw is List
          ? raw
              .whereType<Map>()
              .map((item) => MemberNotification.fromJson(
                    Map<String, dynamic>.from(item),
                  ))
              .where((item) => item.id.isNotEmpty)
              .toList(growable: false)
          : const [],
      nextCursor: data['next_cursor']?.toString(),
    );
  }

  Future<void> markNotificationRead(String id) async {
    await _api.post(
      'notifications/${Uri.encodeComponent(id)}/read',
      data: const <String, Object?>{},
    );
  }

  Future<BlockedProfilePage> blockedProfiles({String? cursor}) async {
    final data = await _api.get(
      'blocks',
      query: {if (cursor != null && cursor.isNotEmpty) 'cursor': cursor},
    );
    final raw = data['blocks'];
    return BlockedProfilePage(
      items: raw is List
          ? raw
              .whereType<Map>()
              .map((item) => BlockedProfile.fromJson(
                    Map<String, dynamic>.from(item),
                  ))
              .where((item) => item.id.isNotEmpty)
              .toList(growable: false)
          : const [],
      nextCursor: data['next_cursor']?.toString(),
    );
  }

  Future<void> unblock(String profileId) async {
    await _api.delete('profiles/${Uri.encodeComponent(profileId)}/block');
  }

  Future<List<DeviceSession>> sessions() async {
    final data = await _api.get('auth/devices');
    final raw = data['sessions'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((item) =>
            DeviceSession.fromJson(Map<String, dynamic>.from(item)))
        .where((item) => item.id.isNotEmpty)
        .toList(growable: false);
  }

  Future<bool> revokeSession(String sessionId) async {
    final data = await _api.delete(
      'auth/devices/${Uri.encodeComponent(sessionId)}',
    );
    final wasCurrent = data['was_current'] == true;
    if (wasCurrent) await _sessions.clear();
    return wasCurrent;
  }

  Future<void> requestDataExport() async {
    await _api.post('privacy/exports');
  }

  Future<List<DataExportState>> exports() async {
    final data = await _api.get('privacy/exports');
    final raw = data['exports'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((item) =>
            DataExportState.fromJson(Map<String, dynamic>.from(item)))
        .toList(growable: false);
  }

  Future<void> scheduleDeletion() async {
    await _api.post(
      'privacy/deletion',
      data: {'confirmation': 'DELETE MY ACCOUNT'},
    );
  }

  Future<Map<String, dynamic>?> deletionStatus() async {
    final data = await _api.get('privacy/deletion');
    final raw = data['deletion'];
    return raw is Map ? Map<String, dynamic>.from(raw) : null;
  }

  Future<void> cancelDeletion() async {
    await _api.delete('privacy/deletion');
  }

  Future<Map<String, dynamic>?> accountAppeal() async {
    final data = await _api.get('account-appeal');
    final raw = data['appeal'];
    return raw is Map ? Map<String, dynamic>.from(raw) : null;
  }

  Future<Map<String, dynamic>> submitAccountAppeal(String statement) async {
    final data = await _api.post(
      'account-appeal',
      data: {'statement': statement.trim()},
    );
    final raw = data['appeal'];
    return raw is Map
        ? Map<String, dynamic>.from(raw)
        : const <String, dynamic>{};
  }

  Future<void> clearLocalSession() => _sessions.clear();

  Future<void> logout({bool allDevices = false}) async {
    await _api.post(allDevices ? 'auth/logout-all' : 'auth/logout');
    await _sessions.clear();
  }

  Future<void> saveLocale(String locale) async {
    await _api.put('auth/preferences', data: {'preferred_locale': locale});
    await _sessions.saveLocale(locale);
  }

  Future<List<ReligionOption>> religionOptions({
    String? parentId,
    String? country,
  }) async {
    final data = await _api.get(
      'onboarding/religion-options',
      query: {
        if (parentId != null) 'parent_id': parentId,
        if (country != null && country.isNotEmpty) 'country': country,
      },
    );
    final raw = data['options'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((item) =>
            ReligionOption.fromJson(Map<String, dynamic>.from(item)))
        .where((item) => item.id.isNotEmpty && item.label.isNotEmpty)
        .toList(growable: false);
  }

  Future<void> saveReligion({
    required String selectedNodeId,
    String? country,
  }) async {
    await _api.put(
      'onboarding/religion-profile',
      data: {
        'selected_node_id': selectedNodeId,
        if (country != null && country.isNotEmpty)
          'country': country.toUpperCase(),
      },
    );
  }

  Future<Map<String, dynamic>?> religionProfile() async {
    final data = await _api.get('onboarding/religion-profile');
    final raw = data['religion_profile'];
    return raw is Map ? Map<String, dynamic>.from(raw) : null;
  }

  Future<ProfileCatalog> catalog() async {
    final data = await _api.get('catalogs/profile');
    return ProfileCatalog.fromJson(data);
  }

  Future<List<SubscriptionProduct>> subscriptionProducts(
    String platform,
  ) async {
    final data = await _api.get(
      'subscription/products',
      query: {'platform': platform},
    );
    final raw = data['products'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((item) => SubscriptionProduct.fromJson(
              Map<String, dynamic>.from(item),
            ))
        .where((item) => item.id.isNotEmpty)
        .toList(growable: false);
  }

  Future<Map<String, dynamic>> entitlements(String platform) async {
    final data = await _api.get(
      'subscription/entitlements',
      query: {'platform': platform},
    );
    final raw = data['capabilities'];
    return raw is Map
        ? Map<String, dynamic>.from(raw)
        : const <String, dynamic>{};
  }
}
