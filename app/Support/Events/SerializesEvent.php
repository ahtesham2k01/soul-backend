<?php

namespace App\Support\Events;

use App\Models\Event;

trait SerializesEvent
{
    private function serializeEvent(Event $event, string $locale, ?int $userId = null, bool $admin = false): array
    {
        $translation = $event->translations->firstWhere('locale', $locale)
            ?? $event->translations->firstWhere('locale', 'en')
            ?? $event->translations->first();
        $data = [
            'id' => $event->public_id, 'type' => $event->type, 'status' => $event->status,
            'title' => $translation?->title, 'description' => $translation?->description,
            'locale' => $translation?->locale, 'starts_at' => $event->starts_at->toIso8601String(),
            'ends_at' => $event->ends_at?->toIso8601String(), 'timezone' => $event->timezone,
            'city' => $event->city, 'country_code' => $event->country_code,
            'capacity' => $event->capacity, 'registration_count' => $event->registration_count,
            'spaces_remaining' => $event->capacity === null ? null : max(0, $event->capacity - $event->registration_count),
            'is_joined' => $userId ? $event->registrations->contains('user_id', $userId) : false,
        ];
        if ($event->type === 'online' && ($admin || ($userId && $data['is_joined']))) {
            $data['online_url'] = $event->online_url;
        }
        if ($admin) {
            $data['translations'] = $event->translations->map(fn ($item) => $item->only(['locale', 'title', 'description']))->values();
        }

        return $data;
    }
}
