<?php

namespace Tests\Feature\Api\V1\Onboarding;

use App\Models\ProfilePhotoUpload;
use App\Models\User;
use App\Models\UserProfile;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Carbon;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class ProfilePhotoUploadSessionEndpointTest extends TestCase
{
    use RefreshDatabase;

    private const SECRET = 'upload-signing-secret';

    protected function setUp(): void
    {
        parent::setUp();

        config()->set('soul.media.cloudinary.cloud_name', 'soul-test');
        config()->set('soul.media.cloudinary.api_key', 'test-key');
        config()->set('soul.media.cloudinary.api_secret', self::SECRET);
        config()->set('soul.media.cloudinary.upload_session_ttl_minutes', 10);
        config()->set('soul.media.cloudinary.response_signature_algorithm', 'sha1');
    }

    public function test_endpoint_requires_authentication(): void
    {
        $this->postJson('/api/v1/onboarding/photos/upload-session', [
            'position' => 1,
        ])->assertUnauthorized();
    }

    public function test_provider_configuration_and_started_profile_are_required(): void
    {
        $user = User::factory()->create(['status' => User::STATUS_ACTIVE]);
        Sanctum::actingAs($user);

        config()->set('soul.media.cloudinary.api_key', null);
        $this->postJson('/api/v1/onboarding/photos/upload-session', ['position' => 1])
            ->assertStatus(503)->assertJsonPath('error.code', 'MEDIA_PROVIDER_UNAVAILABLE');

        config()->set('soul.media.cloudinary.api_key', 'test-key');
        $this->postJson('/api/v1/onboarding/photos/upload-session', ['position' => 1])
            ->assertStatus(409)->assertJsonPath('error.code', 'PROFILE_NOT_STARTED');
    }

    public function test_creates_short_lived_user_bound_signed_upload_session(): void
    {
        Carbon::setTestNow('2026-09-01 04:30:00');
        $user = User::factory()->create(['status' => User::STATUS_ACTIVE]);
        UserProfile::factory()->for($user)->create();
        Sanctum::actingAs($user);

        $response = $this->postJson('/api/v1/onboarding/photos/upload-session', [
            'position' => 2,
        ])->assertOk()
            ->assertJsonPath('data.upload.position', 2)
            ->assertJsonPath('data.upload.expires_at', '2026-09-01T04:40:00+00:00')
            ->assertJsonPath('data.upload.url', 'https://api.cloudinary.com/v1_1/soul-test/image/upload')
            ->assertJsonPath('data.upload.parameters.api_key', 'test-key')
            ->assertJsonPath('data.upload.parameters.timestamp', 1788237000)
            ->assertJsonMissingPath('data.upload.parameters.api_secret');

        $upload = ProfilePhotoUpload::query()->sole();
        $publicId = $response->json('data.upload.parameters.public_id');
        $this->assertSame($upload->public_id, $response->json('data.upload.token'));
        $this->assertSame($upload->provider_asset_id, $publicId);
        $this->assertStringStartsWith("soul/profile-photos/{$user->public_id}/", $publicId);
        $this->assertSame(
            hash('sha1', "public_id={$publicId}&timestamp=1788237000".self::SECRET),
            $response->json('data.upload.parameters.signature'),
        );
    }

    public function test_new_same_slot_session_expires_previous_session(): void
    {
        $user = User::factory()->create(['status' => User::STATUS_ACTIVE]);
        UserProfile::factory()->for($user)->create();
        Sanctum::actingAs($user);

        $firstToken = $this->postJson('/api/v1/onboarding/photos/upload-session', ['position' => 3])
            ->assertOk()->json('data.upload.token');
        $secondToken = $this->postJson('/api/v1/onboarding/photos/upload-session', ['position' => 3])
            ->assertOk()->json('data.upload.token');

        $this->assertNotSame($firstToken, $secondToken);
        $this->assertFalse(ProfilePhotoUpload::where('public_id', $firstToken)->sole()->expires_at->isFuture());
        $this->assertTrue(ProfilePhotoUpload::where('public_id', $secondToken)->sole()->expires_at->isFuture());
    }

    public function test_position_must_be_one_to_three(): void
    {
        $user = User::factory()->create(['status' => User::STATUS_ACTIVE]);
        UserProfile::factory()->for($user)->create();
        Sanctum::actingAs($user);

        $this->postJson('/api/v1/onboarding/photos/upload-session', ['position' => 4])
            ->assertUnprocessable();
    }
}
