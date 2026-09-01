<?php

namespace Tests\Feature\Api\V1\Onboarding;

use App\Enums\Profile\ProfilePhotoModerationStatus;
use App\Models\ProfilePhoto;
use App\Models\User;
use App\Models\UserProfile;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class ProfilePhotoEndpointTest extends TestCase
{
    use RefreshDatabase;

    private const SECRET = 'test-cloudinary-secret';

    protected function setUp(): void
    {
        parent::setUp();

        config()->set('soul.media.cloudinary.api_secret', self::SECRET);
        config()->set(
            'soul.media.cloudinary.response_signature_algorithm',
            'sha1',
        );
    }

    public function test_endpoints_require_authentication(): void
    {
        $this->getJson('/api/v1/onboarding/photos')->assertUnauthorized();
        $this->putJson('/api/v1/onboarding/photos/1', [])->assertUnauthorized();
    }

    public function test_cover_must_be_public_and_position_must_be_one_to_three(): void
    {
        $user = User::factory()->create(['status' => User::STATUS_ACTIVE]);
        UserProfile::factory()->for($user)->create();
        Sanctum::actingAs($user);

        $this->putJson('/api/v1/onboarding/photos/1', $this->payload(
            assetId: 'soul/users/cover',
            visibility: 'private',
        ))->assertUnprocessable();

        $this->putJson('/api/v1/onboarding/photos/4', $this->payload(
            assetId: 'soul/users/fourth',
        ))->assertUnprocessable();
        $this->assertDatabaseCount('profile_photos', 0);
    }

    public function test_rejects_tampered_cloudinary_upload_proof(): void
    {
        $user = User::factory()->create(['status' => User::STATUS_ACTIVE]);
        UserProfile::factory()->for($user)->create();
        Sanctum::actingAs($user);

        $payload = $this->payload('soul/users/cover');
        $payload['provider_signature'] = str_repeat('a', 40);

        $this->putJson('/api/v1/onboarding/photos/1', $payload)
            ->assertUnprocessable()
            ->assertJsonPath('error.code', 'VALIDATION_ERROR');
        $this->assertDatabaseCount('profile_photos', 0);
    }

    public function test_registers_verified_photo_and_lists_safe_metadata(): void
    {
        $user = User::factory()->create(['status' => User::STATUS_ACTIVE]);
        UserProfile::factory()->for($user)->create();
        Sanctum::actingAs($user);

        $this->putJson(
            '/api/v1/onboarding/photos/1',
            $this->payload('soul/users/cover'),
        )
            ->assertOk()
            ->assertJsonPath('data.photo.position', 1)
            ->assertJsonPath('data.photo.visibility', 'public')
            ->assertJsonPath('data.photo.moderation_status', 'pending')
            ->assertJsonMissingPath('data.photo.provider_asset_id');

        $this->getJson('/api/v1/onboarding/photos')
            ->assertOk()
            ->assertJsonPath('data.maximum_photos', 3)
            ->assertJsonCount(1, 'data.photos')
            ->assertJsonPath('data.photos.0.position', 1);
        $this->assertDatabaseHas('profile_photos', [
            'user_profile_id' => $user->profile->id,
            'position' => 1,
            'provider_asset_id' => 'soul/users/cover',
            'moderation_status' => 'pending',
        ]);
    }

    public function test_idempotent_retry_preserves_moderation_but_replacement_resets_it(): void
    {
        $user = User::factory()->create(['status' => User::STATUS_ACTIVE]);
        $profile = UserProfile::factory()->for($user)->create();
        Sanctum::actingAs($user);
        $photo = ProfilePhoto::factory()->for($profile)->create([
            'position' => 2,
            'visibility' => 'public',
            'provider_asset_id' => 'soul/users/existing',
            'moderation_status' => ProfilePhotoModerationStatus::Approved,
            'face_detected' => true,
        ]);

        $this->putJson('/api/v1/onboarding/photos/2', $this->payload(
            assetId: 'soul/users/existing',
            visibility: 'private',
        ))
            ->assertOk()
            ->assertJsonPath('data.photo.visibility', 'private')
            ->assertJsonPath('data.photo.moderation_status', 'approved');

        $this->putJson('/api/v1/onboarding/photos/2', $this->payload(
            assetId: 'soul/users/replacement',
            visibility: 'private',
        ))
            ->assertOk()
            ->assertJsonPath('data.photo.moderation_status', 'pending')
            ->assertJsonPath('data.photo.face_detected', null);

        $this->assertDatabaseCount('profile_photos', 1);
        $this->assertDatabaseHas('profile_photos', [
            'id' => $photo->id,
            'provider_asset_id' => 'soul/users/replacement',
            'moderation_status' => 'pending',
            'face_detected' => null,
        ]);
    }

    public function test_asset_cannot_be_registered_to_two_photo_slots(): void
    {
        $user = User::factory()->create(['status' => User::STATUS_ACTIVE]);
        $profile = UserProfile::factory()->for($user)->create();
        ProfilePhoto::factory()->for($profile)->create([
            'position' => 1,
            'provider_asset_id' => 'soul/users/shared',
        ]);
        Sanctum::actingAs($user);

        $this->putJson('/api/v1/onboarding/photos/2', $this->payload(
            assetId: 'soul/users/shared',
            visibility: 'private',
        ))
            ->assertUnprocessable()
            ->assertJsonPath('error.code', 'VALIDATION_ERROR');

        $this->assertDatabaseCount('profile_photos', 1);
    }

    /** @return array<string, int|string> */
    private function payload(
        string $assetId,
        string $visibility = 'public',
        int $version = 1788220800,
    ): array {
        return [
            'provider_asset_id' => $assetId,
            'provider_version' => $version,
            'provider_signature' => hash(
                'sha1',
                "public_id={$assetId}&version={$version}".self::SECRET,
            ),
            'visibility' => $visibility,
        ];
    }
}
