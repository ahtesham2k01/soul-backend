<?php

namespace App\Http\Controllers\Api\V1\Matching;

use App\Enums\Profile\ProfilePhotoModerationStatus;
use App\Enums\Profile\ProfilePhotoVisibility;
use App\Http\Controllers\Controller;
use App\Models\PrivatePhotoAccessRequest as AccessRequest;
use App\Models\PrivatePhotoCaptureEvent;
use App\Models\ProfilePhoto;
use App\Models\UserMatch;
use App\Support\ApiResponse;
use App\Support\Media\CloudinaryDeliveryUrl;
use App\Support\Notifications\UserNotifier;
use Illuminate\Http\Client\ConnectionException;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Http;
use Symfony\Component\HttpFoundation\Response;

class PrivatePhotoAccessController extends Controller
{
    public function __construct(private readonly UserNotifier $notifier) {}

    public function index(Request $request): JsonResponse
    {
        $user = $request->user();
        $page = AccessRequest::query()
            ->with(['owner.profile', 'requester.profile', 'match'])
            ->where(fn ($query) => $query->where('owner_user_id', $user->id)->orWhere('requester_user_id', $user->id))
            ->latest('id')->cursorPaginate(30);

        return ApiResponse::success([
            'requests' => collect($page->items())->map(fn (AccessRequest $item) => $this->serialize($item, $user->id))->values(),
            'next_cursor' => $page->nextCursor()?->encode(),
        ]);
    }

    public function store(Request $request, string $match): JsonResponse
    {
        $request->validate(['reason' => ['prohibited'], 'message' => ['prohibited']]);
        $user = $request->user();
        $record = $this->activeMatch($match, $user->id);
        if ($record === null) {
            return ApiResponse::error('MATCH_NOT_FOUND', 'Active match not found.', 404);
        }

        $ownerId = $record->first_user_id === $user->id ? $record->second_user_id : $record->first_user_id;
        [$access, $notify] = DB::transaction(function () use ($record, $ownerId, $user): array {
            $access = AccessRequest::query()->firstOrCreate([
                'match_id' => $record->id,
                'owner_user_id' => $ownerId,
                'requester_user_id' => $user->id,
            ], ['status' => 'pending']);
            $created = $access->wasRecentlyCreated;
            $access = AccessRequest::query()->lockForUpdate()->findOrFail($access->id);
            $notify = $created || ! in_array($access->status, ['pending', 'approved'], true);
            if ($notify) {
                $access->fill(['status' => 'pending', 'decided_at' => null, 'revoked_at' => null])->save();
            }

            return [$access->fresh(['owner.profile', 'requester.profile', 'match']), $notify];
        });
        if ($notify) {
            $this->notifier->send($ownerId, 'private_photo_access_requested', ['request_id' => $access->public_id, 'match_id' => $record->public_id, 'requester_profile_id' => $user->profile?->public_id], 'private_photos', 'private-photo:'.$access->public_id.':requested');
        }

        return ApiResponse::success(['request' => $this->serialize($access, $user->id)], 'Private photo access requested.');
    }

    public function decide(Request $request, string $accessRequest): JsonResponse
    {
        $validated = $request->validate(['decision' => ['required', 'in:approve,reject'], 'reason' => ['prohibited'], 'message' => ['prohibited']]);
        $access = AccessRequest::query()->with(['owner.profile', 'requester.profile', 'match'])->where('public_id', $accessRequest)->where('owner_user_id', $request->user()->id)->first();
        if ($access === null) {
            return ApiResponse::error('PRIVATE_PHOTO_REQUEST_NOT_FOUND', 'Private photo request not found.', 404);
        }
        if ($access->match->status !== 'active') {
            return ApiResponse::error('MATCH_NOT_ACTIVE', 'Private photo access requires an active match.', 409);
        }

        $next = $validated['decision'] === 'approve' ? 'approved' : 'rejected';
        $outcome = DB::transaction(function () use ($access, $next): string {
            $locked = AccessRequest::query()->lockForUpdate()->findOrFail($access->id);
            if ($locked->status === $next) {
                return 'unchanged';
            }
            if ($locked->status !== 'pending') {
                return 'invalid';
            }
            $locked->update(['status' => $next, 'decided_at' => now(), 'revoked_at' => null]);

            return 'changed';
        });
        if ($outcome === 'invalid') {
            return ApiResponse::error('PRIVATE_PHOTO_REQUEST_NOT_PENDING', 'A new request is required before another decision.', 409);
        }
        $access->refresh();
        if ($outcome === 'changed') {
            $this->notifier->send($access->requester_user_id, "private_photo_access_{$access->status}", ['request_id' => $access->public_id, 'match_id' => $access->match->public_id, 'owner_profile_id' => $request->user()->profile?->public_id], 'private_photos', 'private-photo:'.$access->public_id.':'.$access->status);
        }

        return ApiResponse::success(['request' => $this->serialize($access, $request->user()->id)], 'Private photo request updated.');
    }

    public function destroy(Request $request, string $accessRequest): JsonResponse
    {
        $access = AccessRequest::query()->with(['owner.profile', 'requester.profile', 'match'])->where('public_id', $accessRequest)->where('owner_user_id', $request->user()->id)->first();
        if ($access === null) {
            return ApiResponse::error('PRIVATE_PHOTO_REQUEST_NOT_FOUND', 'Private photo request not found.', 404);
        }
        $changed = AccessRequest::query()->whereKey($access->id)->whereIn('status', ['pending', 'approved'])->update(['status' => 'revoked', 'revoked_at' => now()]);
        $access->refresh();
        if ($changed) {
            $this->notifier->send($access->requester_user_id, 'private_photo_access_revoked', ['request_id' => $access->public_id, 'match_id' => $access->match->public_id], 'private_photos', 'private-photo:'.$access->public_id.':revoked');
        }

        return ApiResponse::success(['request' => $this->serialize($access, $request->user()->id)], 'Private photo access revoked.');
    }

    public function photos(Request $request, string $match): JsonResponse
    {
        $record = $this->activeMatch($match, $request->user()->id);
        if ($record === null) {
            return ApiResponse::error('MATCH_NOT_FOUND', 'Active match not found.', 404);
        }
        $access = AccessRequest::query()->where('match_id', $record->id)->where('requester_user_id', $request->user()->id)->where('status', 'approved')->first();
        if ($access === null) {
            return ApiResponse::error('PRIVATE_PHOTO_ACCESS_REQUIRED', 'Private photo access has not been approved.', 403);
        }

        $photos = ProfilePhoto::query()->whereHas('userProfile', fn ($query) => $query->where('user_id', $access->owner_user_id))
            ->where('visibility', ProfilePhotoVisibility::Private)->where('delivery_type', 'authenticated')->whereNotNull('format')->where('moderation_status', ProfilePhotoModerationStatus::Approved)->orderBy('position')->get();
        $protection = (bool) ($access->owner->privacySetting?->screenshot_protection_enabled ?? true);

        return ApiResponse::success([
            'photos' => $photos->map(fn (ProfilePhoto $photo) => ['id' => $photo->public_id, 'position' => $photo->position, 'content_path' => "/api/v1/private-photos/{$photo->public_id}/content"])->values(),
            'protection' => $this->protection($request->user()->public_id, $protection),
        ]);
    }

    public function content(Request $request, string $photo, CloudinaryDeliveryUrl $deliveryUrl): Response|JsonResponse
    {
        [$record, $access] = $this->authorizedPhoto($request, $photo);
        if ($record === null || $access === null) {
            return ApiResponse::error('PRIVATE_PHOTO_NOT_FOUND', 'Private photo not found.', 404);
        }
        if (! filled(config('soul.media.cloudinary.cloud_name')) || ! filled(config('soul.media.cloudinary.api_secret'))) {
            return ApiResponse::error('MEDIA_PROVIDER_UNAVAILABLE', 'Private photo delivery is temporarily unavailable.', 503);
        }

        try {
            $provider = Http::timeout(15)->get($deliveryUrl->forAuthenticatedImage($record->provider_asset_id, $record->format));
        } catch (ConnectionException) {
            return ApiResponse::error('MEDIA_PROVIDER_UNAVAILABLE', 'Private photo delivery is temporarily unavailable.', 503);
        }
        if (! $provider->successful()) {
            return ApiResponse::error('MEDIA_PROVIDER_UNAVAILABLE', 'Private photo delivery is temporarily unavailable.', 503);
        }
        $contentType = $provider->header('Content-Type') ?: 'image/jpeg';
        if (! str_starts_with(strtolower($contentType), 'image/')) {
            return ApiResponse::error('MEDIA_PROVIDER_UNAVAILABLE', 'Private photo delivery is temporarily unavailable.', 503);
        }

        return response($provider->body(), 200, ['Content-Type' => $contentType, 'Cache-Control' => 'private, no-store, max-age=0', 'Pragma' => 'no-cache', 'X-Content-Type-Options' => 'nosniff']);
    }

    public function capture(Request $request, string $photo): JsonResponse
    {
        $validated = $request->validate(['client_event_id' => ['required', 'ulid'], 'event_type' => ['required', 'in:screenshot,screen_recording']]);
        [$record, $access] = $this->authorizedPhoto($request, $photo);
        if ($record === null || $access === null) {
            return ApiResponse::error('PRIVATE_PHOTO_NOT_FOUND', 'Private photo not found.', 404);
        }
        if (! $record->screenshot_protection_enabled) {
            return ApiResponse::success(['recorded' => false], 'Screenshot protection is disabled.');
        }

        $event = PrivatePhotoCaptureEvent::query()->firstOrCreate(
            ['viewer_user_id' => $request->user()->id, 'client_event_id' => $validated['client_event_id']],
            ['private_photo_access_request_id' => $access->id, 'profile_photo_id' => $record->id, 'owner_user_id' => $access->owner_user_id, 'event_type' => $validated['event_type'], 'occurred_at' => now()],
        );
        if ($event->wasRecentlyCreated) {
            $this->notifier->send($access->owner_user_id, 'private_photo_capture_detected', ['request_id' => $access->public_id, 'event_type' => $event->event_type, 'viewer_profile_id' => $request->user()->profile?->public_id], 'safety', 'private-photo-capture:'.$event->client_event_id);
        }

        return ApiResponse::success(['recorded' => true, 'duplicate' => ! $event->wasRecentlyCreated], 'Capture signal recorded.');
    }

    private function activeMatch(string $publicId, int $userId): ?UserMatch
    {
        return UserMatch::query()->where('public_id', $publicId)->where('status', 'active')
            ->whereHas('firstUser', fn ($query) => $query->where('status', 'active'))
            ->whereHas('secondUser', fn ($query) => $query->where('status', 'active'))
            ->where(fn ($query) => $query->where('first_user_id', $userId)->orWhere('second_user_id', $userId))->first();
    }

    private function authorizedPhoto(Request $request, string $publicId): array
    {
        $photo = ProfilePhoto::query()->with('userProfile')->where('public_id', $publicId)->where('visibility', ProfilePhotoVisibility::Private)->where('delivery_type', 'authenticated')->whereNotNull('format')->where('moderation_status', ProfilePhotoModerationStatus::Approved)->first();
        if ($photo === null) {
            return [null, null];
        }
        $access = AccessRequest::query()->where('owner_user_id', $photo->userProfile->user_id)->where('requester_user_id', $request->user()->id)->where('status', 'approved')
            ->whereHas('match', fn ($query) => $query->where('status', 'active')->whereHas('firstUser', fn ($query) => $query->where('status', 'active'))->whereHas('secondUser', fn ($query) => $query->where('status', 'active')))->first();

        return $access === null ? [null, null] : [$photo, $access];
    }

    private function serialize(AccessRequest $access, int $viewerId): array
    {
        $incoming = $access->owner_user_id === $viewerId;
        $counterpart = $incoming ? $access->requester : $access->owner;

        return ['id' => $access->public_id, 'match_id' => $access->match->public_id, 'direction' => $incoming ? 'incoming' : 'outgoing', 'status' => $access->status, 'profile' => ['id' => $counterpart->profile?->public_id, 'first_name' => $counterpart->profile?->first_name], 'decided_at' => $access->decided_at?->toIso8601String(), 'revoked_at' => $access->revoked_at?->toIso8601String(), 'created_at' => $access->created_at->toIso8601String()];
    }

    private function protection(string $viewerId, bool $enabled): array
    {
        return ['enabled' => $enabled, 'android_secure_window_required' => $enabled, 'ios_capture_detection_required' => $enabled, 'ios_recording_mask_required' => $enabled, 'viewer_watermark' => $enabled ? $viewerId : null, 'capture_notifications_best_effort' => true];
    }
}
