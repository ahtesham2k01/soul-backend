<?php

namespace App\Http\Controllers\Api\V1\Events;

use App\Http\Controllers\Controller;
use App\Models\Event;
use App\Models\EventRegistration;
use App\Support\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class EventRegistrationController extends Controller
{
    public function store(Request $request, string $event): JsonResponse
    {
        $result = DB::transaction(function () use ($request, $event): array {
            $record = Event::query()->where('public_id', $event)->lockForUpdate()->first();
            if ($record === null || $record->status !== 'published' || $record->starts_at->isPast()) {
                return ['error' => 'unavailable'];
            }
            $existing = EventRegistration::query()->where('event_id', $record->id)->where('user_id', $request->user()->id)->first();
            if ($existing) {
                return ['registration' => $existing, 'duplicate' => true];
            }
            if ($record->capacity !== null && $record->registration_count >= $record->capacity) {
                return ['error' => 'full'];
            }
            $registration = EventRegistration::query()->create(['event_id' => $record->id, 'user_id' => $request->user()->id, 'joined_at' => now()]);
            $record->increment('registration_count');

            return ['registration' => $registration, 'duplicate' => false];
        });
        if (($result['error'] ?? null) === 'unavailable') {
            return ApiResponse::error('EVENT_NOT_FOUND', 'Event not found.', 404);
        }
        if (($result['error'] ?? null) === 'full') {
            return ApiResponse::error('EVENT_FULL', 'Event capacity has been reached.', 409);
        }

        return ApiResponse::success(['registration' => ['id' => $result['registration']->public_id, 'joined_at' => $result['registration']->joined_at->toIso8601String()], 'duplicate' => $result['duplicate']], 'Event joined successfully.', $result['duplicate'] ? 200 : 201);
    }

    public function destroy(Request $request, string $event): JsonResponse
    {
        $left = DB::transaction(function () use ($request, $event): bool {
            $record = Event::query()->where('public_id', $event)->lockForUpdate()->first();
            if ($record === null) {
                return false;
            }
            $deleted = EventRegistration::query()->where('event_id', $record->id)->where('user_id', $request->user()->id)->delete();
            if ($deleted) {
                $record->decrement('registration_count');
            }

            return (bool) $deleted;
        });

        return ApiResponse::success(['left' => $left], 'Event registration updated.');
    }
}
