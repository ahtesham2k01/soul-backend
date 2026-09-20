import 'package:flutter_test/flutter_test.dart';
import 'package:soul_member_app/src/features/chat/chat_repository.dart';

void main() {
  test('chat match parses cover photo, presence and unread state', () {
    final match = ChatMatch.fromJson({
      'id': '01HMATCH',
      'matched_at': '2026-09-21T01:00:00Z',
      'profile': {
        'id': '01HPROFILE',
        'first_name': 'Sara',
        'photo': {
          'id': '01HPHOTO',
          'position': 1,
          'url': 'https://example.test/cover.jpg',
        },
      },
      'presence': {
        'is_online': true,
        'last_seen_at': '2026-09-21T01:02:00Z',
      },
      'conversation': {
        'last_message': {
          'id': '01HMESSAGE',
          'body': 'Salam',
          'is_mine': false,
          'read_at': null,
          'sent_at': '2026-09-21T01:03:00Z',
        },
        'unread_count': 2,
      },
    });

    expect(match.firstName, 'Sara');
    expect(match.photo?.url, 'https://example.test/cover.jpg');
    expect(match.isOnline, isTrue);
    expect(match.unreadCount, 2);
    expect(match.lastMessage?.body, 'Salam');
  });

  test('message parser preserves read receipts', () {
    final message = ChatMessage.fromJson({
      'id': '01HMESSAGE',
      'body': 'Hello',
      'is_mine': true,
      'sent_at': '2026-09-21T01:03:00Z',
      'read_at': '2026-09-21T01:04:00Z',
    });

    expect(message.isMine, isTrue);
    expect(message.readAt, isNotNull);
  });

  test('private photo protection parses server requirements', () {
    final protection = PrivatePhotoProtection.fromJson({
      'enabled': true,
      'android_secure_window_required': true,
      'ios_capture_detection_required': true,
      'ios_recording_mask_required': true,
      'viewer_watermark': '01HVIEWER',
      'capture_notifications_best_effort': true,
    });

    expect(protection.enabled, isTrue);
    expect(protection.androidSecureWindowRequired, isTrue);
    expect(protection.viewerWatermark, '01HVIEWER');
  });
}
