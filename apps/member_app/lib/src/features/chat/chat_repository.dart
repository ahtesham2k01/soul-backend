import 'dart:typed_data';

import '../../core/api_client.dart';

class ChatPhoto {
  const ChatPhoto({
    required this.id,
    required this.position,
    this.url,
  });

  final String id;
  final int position;
  final String? url;

  factory ChatPhoto.fromJson(Map<String, dynamic> json) => ChatPhoto(
        id: json['id']?.toString() ?? '',
        position: (json['position'] as num?)?.toInt() ?? 0,
        url: json['url']?.toString(),
      );
}

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.body,
    required this.isMine,
    required this.sentAt,
    this.readAt,
  });

  final String id;
  final String body;
  final bool isMine;
  final DateTime sentAt;
  final DateTime? readAt;

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
        id: json['id']?.toString() ?? '',
        body: json['body']?.toString() ?? '',
        isMine: json['is_mine'] == true,
        sentAt: DateTime.tryParse(json['sent_at']?.toString() ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
        readAt: DateTime.tryParse(json['read_at']?.toString() ?? ''),
      );
}

class ChatMatch {
  const ChatMatch({
    required this.id,
    required this.profileId,
    required this.firstName,
    required this.matchedAt,
    required this.isOnline,
    required this.unreadCount,
    this.lastSeenAt,
    this.lastMessage,
    this.photo,
  });

  final String id;
  final String profileId;
  final String firstName;
  final DateTime matchedAt;
  final bool isOnline;
  final DateTime? lastSeenAt;
  final ChatMessage? lastMessage;
  final int unreadCount;
  final ChatPhoto? photo;

  factory ChatMatch.fromJson(Map<String, dynamic> json) {
    final profile = json['profile'] is Map
        ? Map<String, dynamic>.from(json['profile'] as Map)
        : const <String, dynamic>{};
    final presence = json['presence'] is Map
        ? Map<String, dynamic>.from(json['presence'] as Map)
        : const <String, dynamic>{};
    final conversation = json['conversation'] is Map
        ? Map<String, dynamic>.from(json['conversation'] as Map)
        : const <String, dynamic>{};
    final lastMessage = conversation['last_message'];
    final photo = profile['photo'];

    return ChatMatch(
      id: json['id']?.toString() ?? '',
      profileId: profile['id']?.toString() ?? '',
      firstName: profile['first_name']?.toString() ?? '',
      matchedAt: DateTime.tryParse(json['matched_at']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      isOnline: presence['is_online'] == true,
      lastSeenAt:
          DateTime.tryParse(presence['last_seen_at']?.toString() ?? ''),
      lastMessage: lastMessage is Map
          ? ChatMessage.fromJson(Map<String, dynamic>.from(lastMessage))
          : null,
      unreadCount: (conversation['unread_count'] as num?)?.toInt() ?? 0,
      photo: photo is Map
          ? ChatPhoto.fromJson(Map<String, dynamic>.from(photo))
          : null,
    );
  }

  ChatMatch copyWith({
    bool? isOnline,
    DateTime? lastSeenAt,
    ChatMessage? lastMessage,
    int? unreadCount,
  }) =>
      ChatMatch(
        id: id,
        profileId: profileId,
        firstName: firstName,
        matchedAt: matchedAt,
        isOnline: isOnline ?? this.isOnline,
        lastSeenAt: lastSeenAt ?? this.lastSeenAt,
        lastMessage: lastMessage ?? this.lastMessage,
        unreadCount: unreadCount ?? this.unreadCount,
        photo: photo,
      );
}

class ChatMatchPage {
  const ChatMatchPage({required this.items, this.nextCursor});

  final List<ChatMatch> items;
  final String? nextCursor;
}

class ChatMessagePage {
  const ChatMessagePage({required this.items, this.nextCursor});

  final List<ChatMessage> items;
  final String? nextCursor;
}

class ChatPresence {
  const ChatPresence({
    required this.isOnline,
    required this.isTyping,
    required this.typingExpiresInSeconds,
    this.lastSeenAt,
  });

  final bool isOnline;
  final bool isTyping;
  final int typingExpiresInSeconds;
  final DateTime? lastSeenAt;

  factory ChatPresence.fromJson(Map<String, dynamic> json) => ChatPresence(
        isOnline: json['is_online'] == true,
        isTyping: json['is_typing'] == true,
        typingExpiresInSeconds:
            (json['typing_expires_in_seconds'] as num?)?.toInt() ?? 8,
        lastSeenAt:
            DateTime.tryParse(json['last_seen_at']?.toString() ?? ''),
      );
}

class PrivateChatPhoto {
  const PrivateChatPhoto({
    required this.id,
    required this.position,
    required this.contentPath,
  });

  final String id;
  final int position;
  final String contentPath;

  factory PrivateChatPhoto.fromJson(Map<String, dynamic> json) =>
      PrivateChatPhoto(
        id: json['id']?.toString() ?? '',
        position: (json['position'] as num?)?.toInt() ?? 0,
        contentPath: json['content_path']?.toString() ?? '',
      );
}

class PrivatePhotoProtection {
  const PrivatePhotoProtection({
    required this.enabled,
    required this.androidSecureWindowRequired,
    required this.iosCaptureDetectionRequired,
    required this.iosRecordingMaskRequired,
    required this.captureNotificationsBestEffort,
    this.viewerWatermark,
  });

  final bool enabled;
  final bool androidSecureWindowRequired;
  final bool iosCaptureDetectionRequired;
  final bool iosRecordingMaskRequired;
  final bool captureNotificationsBestEffort;
  final String? viewerWatermark;

  factory PrivatePhotoProtection.fromJson(Map<String, dynamic> json) =>
      PrivatePhotoProtection(
        enabled: json['enabled'] == true,
        androidSecureWindowRequired:
            json['android_secure_window_required'] == true,
        iosCaptureDetectionRequired:
            json['ios_capture_detection_required'] == true,
        iosRecordingMaskRequired:
            json['ios_recording_mask_required'] == true,
        viewerWatermark: json['viewer_watermark']?.toString(),
        captureNotificationsBestEffort:
            json['capture_notifications_best_effort'] == true,
      );
}

class PrivatePhotoAlbum {
  const PrivatePhotoAlbum({
    required this.photos,
    required this.protection,
  });

  final List<PrivateChatPhoto> photos;
  final PrivatePhotoProtection protection;
}

class PrivatePhotoRequestResult {
  const PrivatePhotoRequestResult({
    required this.status,
    required this.requestId,
  });

  final String status;
  final String requestId;

  factory PrivatePhotoRequestResult.fromJson(Map<String, dynamic> json) {
    final request = json['request'] is Map
        ? Map<String, dynamic>.from(json['request'] as Map)
        : const <String, dynamic>{};
    return PrivatePhotoRequestResult(
      status: request['status']?.toString() ?? 'pending',
      requestId: request['id']?.toString() ?? '',
    );
  }
}

class ChatRepository {
  ChatRepository(this._api);

  final SoulApiClient _api;

  Future<ChatMatchPage> matches({String? cursor}) async {
    final data = await _api.get(
      'matches',
      query: {if (cursor != null && cursor.isNotEmpty) 'cursor': cursor},
    );
    final raw = data['matches'];
    return ChatMatchPage(
      items: raw is List
          ? raw
              .whereType<Map>()
              .map((item) =>
                  ChatMatch.fromJson(Map<String, dynamic>.from(item)))
              .where((item) => item.id.isNotEmpty)
              .toList(growable: false)
          : const [],
      nextCursor: data['next_cursor']?.toString(),
    );
  }

  Future<ChatMessagePage> messages(
    String matchId, {
    String? cursor,
  }) async {
    final data = await _api.get(
      'matches/${Uri.encodeComponent(matchId)}/messages',
      query: {if (cursor != null && cursor.isNotEmpty) 'cursor': cursor},
    );
    final raw = data['messages'];
    return ChatMessagePage(
      items: raw is List
          ? raw
              .whereType<Map>()
              .map((item) =>
                  ChatMessage.fromJson(Map<String, dynamic>.from(item)))
              .where((item) => item.id.isNotEmpty)
              .toList(growable: false)
          : const [],
      nextCursor: data['next_cursor']?.toString(),
    );
  }

  Future<ChatMessage> sendMessage(String matchId, String body) async {
    final data = await _api.post(
      'matches/${Uri.encodeComponent(matchId)}/messages',
      data: {'body': body},
    );
    final raw = data['message'];
    if (raw is! Map) {
      throw const SoulApiFailure(
        statusCode: null,
        code: 'INVALID_RESPONSE',
        message: 'SOUL returned an invalid message.',
      );
    }
    return ChatMessage.fromJson(Map<String, dynamic>.from(raw));
  }

  Future<void> markRead(String matchId) async {
    await _api.post(
      'matches/${Uri.encodeComponent(matchId)}/messages/read',
    );
  }

  Future<ChatPresence> presence(String matchId) async {
    final data = await _api.get(
      'matches/${Uri.encodeComponent(matchId)}/presence',
    );
    return ChatPresence.fromJson(data);
  }

  Future<void> setTyping(String matchId, bool isTyping) async {
    await _api.put(
      'matches/${Uri.encodeComponent(matchId)}/typing',
      data: {'is_typing': isTyping},
    );
  }

  Future<PrivatePhotoAlbum> privatePhotos(String matchId) async {
    final data = await _api.get(
      'matches/${Uri.encodeComponent(matchId)}/private-photos',
    );
    final rawPhotos = data['photos'];
    final protection = data['protection'];
    return PrivatePhotoAlbum(
      photos: rawPhotos is List
          ? rawPhotos
              .whereType<Map>()
              .map((item) => PrivateChatPhoto.fromJson(
                    Map<String, dynamic>.from(item),
                  ))
              .where((item) => item.id.isNotEmpty && item.contentPath.isNotEmpty)
              .toList(growable: false)
          : const [],
      protection: protection is Map
          ? PrivatePhotoProtection.fromJson(
              Map<String, dynamic>.from(protection),
            )
          : const PrivatePhotoProtection(
              enabled: false,
              androidSecureWindowRequired: false,
              iosCaptureDetectionRequired: false,
              iosRecordingMaskRequired: false,
              captureNotificationsBestEffort: true,
            ),
    );
  }

  Future<PrivatePhotoRequestResult> requestPrivatePhotos(
    String matchId,
  ) async {
    final data = await _api.post(
      'matches/${Uri.encodeComponent(matchId)}/private-photo-access',
      data: const <String, Object?>{},
    );
    return PrivatePhotoRequestResult.fromJson(data);
  }

  Future<Uint8List> privatePhotoContent(String contentPath) =>
      _api.getBytes(contentPath);
}
