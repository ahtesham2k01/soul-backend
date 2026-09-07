<?php

namespace Tests\Feature\Api\V1\Matching;

use App\Models\PrivatePhotoAccessRequest;
use App\Models\ProfilePhoto;
use App\Models\User;
use App\Models\UserMatch;
use App\Models\UserProfile;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Str;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class PrivatePhotoAccessEndpointTest extends TestCase
{
    use RefreshDatabase;

    public function test_only_an_active_match_participant_can_request_without_a_message(): void
    {
        [$owner, $requester, $match] = $this->matchedUsers();
        Sanctum::actingAs($requester);

        $this->postJson("/api/v1/matches/{$match->public_id}/private-photo-access", ['message' => 'Please'])
            ->assertUnprocessable();
        $response = $this->postJson("/api/v1/matches/{$match->public_id}/private-photo-access")
            ->assertOk()->assertJsonPath('data.request.status', 'pending')->assertJsonPath('data.request.direction', 'outgoing');
        $this->postJson("/api/v1/matches/{$match->public_id}/private-photo-access")
            ->assertOk()->assertJsonPath('data.request.id', $response->json('data.request.id'));
        $this->assertDatabaseCount('private_photo_access_requests', 1);
        $this->assertDatabaseCount('user_notifications', 1);

        Sanctum::actingAs(User::factory()->create(['status' => User::STATUS_ACTIVE]));
        $this->postJson("/api/v1/matches/{$match->public_id}/private-photo-access")->assertNotFound();
    }

    public function test_owner_can_approve_and_all_current_approved_private_photos_unlock(): void
    {
        [$owner, $requester, $match] = $this->matchedUsers();
        $private = ProfilePhoto::factory()->for($owner->profile)->create(['position' => 2, 'visibility' => 'private', 'moderation_status' => 'approved', 'delivery_type' => 'authenticated']);
        ProfilePhoto::factory()->for($owner->profile)->create(['position' => 3, 'visibility' => 'private', 'moderation_status' => 'pending', 'delivery_type' => 'authenticated']);

        Sanctum::actingAs($requester);
        $requestId = $this->postJson("/api/v1/matches/{$match->public_id}/private-photo-access")->json('data.request.id');
        $this->getJson("/api/v1/matches/{$match->public_id}/private-photos")->assertForbidden();

        Sanctum::actingAs($owner);
        $this->putJson("/api/v1/private-photo-access/{$requestId}", ['decision' => 'approve'])
            ->assertOk()->assertJsonPath('data.request.status', 'approved');

        Sanctum::actingAs($requester);
        $this->getJson("/api/v1/matches/{$match->public_id}/private-photos")
            ->assertOk()->assertJsonCount(1, 'data.photos')
            ->assertJsonPath('data.photos.0.id', $private->public_id)
            ->assertJsonPath('data.protection.android_secure_window_required', true)
            ->assertJsonPath('data.protection.viewer_watermark', $requester->public_id);

        ProfilePhoto::factory()->for($owner->profile)->create(['position' => 1, 'visibility' => 'public', 'moderation_status' => 'approved']);
        $this->getJson("/api/v1/matches/{$match->public_id}/private-photos")->assertJsonCount(1, 'data.photos');
    }

    public function test_owner_can_reject_or_revoke_and_requester_cannot_decide(): void
    {
        [$owner, $requester, $match] = $this->matchedUsers();
        Sanctum::actingAs($requester);
        $requestId = $this->postJson("/api/v1/matches/{$match->public_id}/private-photo-access")->json('data.request.id');
        $this->putJson("/api/v1/private-photo-access/{$requestId}", ['decision' => 'approve'])->assertNotFound();

        Sanctum::actingAs($owner);
        $this->putJson("/api/v1/private-photo-access/{$requestId}", ['decision' => 'reject'])
            ->assertOk()->assertJsonPath('data.request.status', 'rejected');

        Sanctum::actingAs($requester);
        $this->postJson("/api/v1/matches/{$match->public_id}/private-photo-access")->assertJsonPath('data.request.status', 'pending');
        Sanctum::actingAs($owner);
        $this->putJson("/api/v1/private-photo-access/{$requestId}", ['decision' => 'approve'])->assertOk();
        $this->deleteJson("/api/v1/private-photo-access/{$requestId}")->assertOk()->assertJsonPath('data.request.status', 'revoked');
        $this->deleteJson("/api/v1/private-photo-access/{$requestId}")->assertOk();
    }

    public function test_private_content_is_proxied_only_for_an_active_approved_grant(): void
    {
        config(['soul.media.cloudinary.cloud_name' => 'soul-test', 'soul.media.cloudinary.api_secret' => 'secret']);
        Http::fake(['res.cloudinary.com/*' => Http::response('image-bytes', 200, ['Content-Type' => 'image/webp'])]);
        [$owner, $requester, $match] = $this->matchedUsers();
        $photo = ProfilePhoto::factory()->for($owner->profile)->create(['position' => 2, 'visibility' => 'private', 'moderation_status' => 'approved', 'delivery_type' => 'authenticated']);
        $access = $this->approvedAccess($owner, $requester, $match);

        Sanctum::actingAs($requester);
        $this->get("/api/v1/private-photos/{$photo->public_id}/content")
            ->assertOk()->assertHeader('Content-Type', 'image/webp')->assertHeader('Cache-Control', 'max-age=0, no-store, private')->assertSee('image-bytes');
        Http::assertSent(fn ($request) => str_contains($request->url(), '/image/authenticated/s--') && ! str_contains($request->url(), $access->public_id));

        $match->update(['status' => 'unmatched']);
        $this->getJson("/api/v1/private-photos/{$photo->public_id}/content")->assertNotFound();
    }

    public function test_capture_signals_are_idempotent_and_notify_the_owner_best_effort(): void
    {
        [$owner, $requester, $match] = $this->matchedUsers();
        $photo = ProfilePhoto::factory()->for($owner->profile)->create(['position' => 2, 'visibility' => 'private', 'moderation_status' => 'approved', 'delivery_type' => 'authenticated']);
        $this->approvedAccess($owner, $requester, $match);
        $eventId = (string) Str::ulid();
        Sanctum::actingAs($requester);

        $this->postJson("/api/v1/private-photos/{$photo->public_id}/capture-events", ['client_event_id' => $eventId, 'event_type' => 'screenshot'])
            ->assertOk()->assertJsonPath('data.duplicate', false);
        $this->postJson("/api/v1/private-photos/{$photo->public_id}/capture-events", ['client_event_id' => $eventId, 'event_type' => 'screenshot'])
            ->assertOk()->assertJsonPath('data.duplicate', true);
        $this->assertDatabaseCount('private_photo_capture_events', 1);
        $this->assertDatabaseHas('user_notifications', ['user_id' => $owner->id, 'type' => 'private_photo_capture_detected']);
    }

    public function test_unmatch_automatically_revokes_private_photo_access(): void
    {
        [$owner, $requester, $match] = $this->matchedUsers();
        $access = $this->approvedAccess($owner, $requester, $match);
        Sanctum::actingAs($requester);
        $this->deleteJson("/api/v1/matches/{$match->public_id}")->assertOk();
        $this->assertDatabaseHas('private_photo_access_requests', ['id' => $access->id, 'status' => 'revoked']);
    }

    public function test_block_automatically_revokes_private_photo_access(): void
    {
        [$owner, $requester, $match] = $this->matchedUsers();
        $access = $this->approvedAccess($owner, $requester, $match);
        Sanctum::actingAs($requester);
        $this->postJson("/api/v1/profiles/{$owner->profile->public_id}/block")->assertOk();
        $this->assertDatabaseHas('private_photo_access_requests', ['id' => $access->id, 'status' => 'revoked']);
    }

    public function test_screenshot_setting_defaults_on_and_updates_existing_photos(): void
    {
        [$owner] = $this->matchedUsers();
        $photo = ProfilePhoto::factory()->for($owner->profile)->create(['position' => 2, 'visibility' => 'private']);
        Sanctum::actingAs($owner);
        $this->getJson('/api/v1/privacy/settings')->assertJsonPath('data.privacy.screenshot_protection_enabled', true);
        $this->putJson('/api/v1/privacy/settings', ['screenshot_protection_enabled' => false])
            ->assertOk()->assertJsonPath('data.privacy.screenshot_protection_enabled', false);
        $this->assertFalse($photo->fresh()->screenshot_protection_enabled);
    }

    private function matchedUsers(): array
    {
        $owner = User::factory()->create(['status' => User::STATUS_ACTIVE]);
        $requester = User::factory()->create(['status' => User::STATUS_ACTIVE]);
        UserProfile::factory()->for($owner)->create(['profile_status' => 'live']);
        UserProfile::factory()->for($requester)->create(['profile_status' => 'live']);
        $ids = [$owner->id, $requester->id];
        sort($ids);
        $match = UserMatch::query()->create(['first_user_id' => $ids[0], 'second_user_id' => $ids[1], 'status' => 'active', 'matched_at' => now()]);

        return [$owner->load('profile'), $requester->load('profile'), $match];
    }

    private function approvedAccess(User $owner, User $requester, UserMatch $match)
    {
        return PrivatePhotoAccessRequest::query()->create(['match_id' => $match->id, 'owner_user_id' => $owner->id, 'requester_user_id' => $requester->id, 'status' => 'approved', 'decided_at' => now()]);
    }
}
