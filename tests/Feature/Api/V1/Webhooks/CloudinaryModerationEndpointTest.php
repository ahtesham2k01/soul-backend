<?php

namespace Tests\Feature\Api\V1\Webhooks;

use App\Models\ProfilePhoto;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Carbon;
use Tests\TestCase;

class CloudinaryModerationEndpointTest extends TestCase
{
    use RefreshDatabase;

    private const SECRET = 'notification-secret';

    protected function setUp(): void
    {
        parent::setUp();

        Carbon::setTestNow('2026-09-01 06:00:00');
        config()->set('soul.media.cloudinary.api_secret', self::SECRET);
        config()->set('soul.media.cloudinary.response_signature_algorithm', 'sha1');
        config()->set('soul.media.cloudinary.webhook_tolerance_seconds', 7200);
    }

    public function test_rejects_unsigned_and_expired_notifications(): void
    {
        $body = json_encode([
            'public_id' => 'soul/profile-photos/example',
            'moderation_status' => 'approved',
        ], JSON_THROW_ON_ERROR);

        $this->notification($body, 1788242400, str_repeat('0', 40))
            ->assertUnauthorized();

        $expiredTimestamp = 1788235199;
        $this->notification(
            $body,
            $expiredTimestamp,
            $this->signature($body, $expiredTimestamp),
        )->assertUnauthorized();
    }

    public function test_approved_notification_updates_exact_asset_and_face_result(): void
    {
        $photo = ProfilePhoto::factory()->create([
            'provider_asset_id' => 'soul/profile-photos/approved',
            'moderation_status' => 'pending',
            'face_detected' => null,
        ]);
        $body = json_encode([
            'public_id' => 'soul/profile-photos/approved',
            'moderation_status' => 'approved',
            'moderation_kind' => 'aws_rek',
            'face_detected' => true,
        ], JSON_THROW_ON_ERROR);

        $this->signedNotification($body)->assertOk()
            ->assertJsonPath('accepted', true);

        $this->assertDatabaseHas('profile_photos', [
            'id' => $photo->id,
            'moderation_status' => 'approved',
            'rejection_reason' => null,
            'face_detected' => true,
        ]);
    }

    public function test_rejected_notification_stores_curated_reason_for_correction(): void
    {
        $photo = ProfilePhoto::factory()->create([
            'provider_asset_id' => 'soul/profile-photos/rejected',
        ]);
        $body = json_encode([
            'public_id' => 'soul/profile-photos/rejected',
            'moderation_status' => 'rejected',
            'moderation_kind' => 'duplicate',
            'face_detected' => false,
        ], JSON_THROW_ON_ERROR);

        $this->signedNotification($body)->assertOk();

        $this->assertDatabaseHas('profile_photos', [
            'id' => $photo->id,
            'moderation_status' => 'rejected',
            'rejection_reason' => 'Photo appears to duplicate another uploaded image.',
            'face_detected' => false,
        ]);
        $this->assertDatabaseHas('user_profiles', [
            'id' => $photo->user_profile_id,
            'profile_status' => 'changes_required',
            'correction_screen' => 'onboarding.photos',
        ]);
    }

    public function test_unknown_or_replaced_asset_is_acknowledged_without_mutation(): void
    {
        $photo = ProfilePhoto::factory()->create([
            'provider_asset_id' => 'soul/profile-photos/current',
            'moderation_status' => 'pending',
        ]);
        $body = json_encode([
            'public_id' => 'soul/profile-photos/replaced',
            'moderation_status' => 'approved',
        ], JSON_THROW_ON_ERROR);

        $this->signedNotification($body)->assertOk()
            ->assertJsonPath('accepted', true);

        $this->assertDatabaseHas('profile_photos', [
            'id' => $photo->id,
            'moderation_status' => 'pending',
        ]);
    }

    private function signedNotification(string $body)
    {
        $timestamp = now()->timestamp;

        return $this->notification(
            $body,
            $timestamp,
            $this->signature($body, $timestamp),
        );
    }

    private function notification(string $body, int $timestamp, string $signature)
    {
        return $this->call(
            'POST',
            '/api/v1/webhooks/cloudinary/moderation',
            server: [
                'CONTENT_TYPE' => 'application/json',
                'HTTP_ACCEPT' => 'application/json',
                'HTTP_X_CLD_TIMESTAMP' => (string) $timestamp,
                'HTTP_X_CLD_SIGNATURE' => $signature,
            ],
            content: $body,
        );
    }

    private function signature(string $body, int $timestamp): string
    {
        return hash('sha1', $body.$timestamp.self::SECRET);
    }
}
