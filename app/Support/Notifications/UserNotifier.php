<?php

namespace App\Support\Notifications;

use App\Models\NotificationPreference;
use App\Models\UserNotification;

class UserNotifier
{
    public function send(int $userId, string $type, array $data, string $category, string $deduplicationKey): UserNotification
    {
        $preference = NotificationPreference::query()->firstOrCreate(['user_id' => $userId]);
        $channels = $this->channels($preference, $category);

        abort_unless(in_array($category, ['new_matches', 'new_messages', 'private_photos', 'verification', 'account', 'marketing', 'safety'], true), 500, 'Unsupported notification category.');

        return UserNotification::query()->firstOrCreate(
            ['deduplication_key' => hash('sha256', $userId.'|'.$type.'|'.$deduplicationKey)],
            ['user_id' => $userId, 'type' => $type, 'data' => $data, 'delivery_channels' => $channels],
        );
    }

    private function channels(NotificationPreference $preference, string $category): array
    {
        if ($category === 'safety') {
            return ['in_app', 'push', 'email'];
        }
        $legacyPush = ['new_matches' => 'new_matches', 'new_messages' => 'new_messages'];
        $pushField = $legacyPush[$category] ?? 'push_'.$category;
        $emailField = 'email_'.$category;
        $channels = ['in_app'];
        if ((bool) $preference->{$pushField}) {
            $channels[] = 'push';
        }
        if ((bool) $preference->{$emailField}) {
            $channels[] = 'email';
        }

        return $channels;
    }
}
