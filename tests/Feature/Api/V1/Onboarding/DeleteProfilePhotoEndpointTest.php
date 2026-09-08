<?php

namespace Tests\Feature\Api\V1\Onboarding;

use App\Jobs\DestroyCloudinaryAsset;
use App\Models\ProfilePhoto;
use App\Models\User;
use App\Models\UserProfile;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Bus;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class DeleteProfilePhotoEndpointTest extends TestCase
{
    use RefreshDatabase;

    public function test_endpoint_requires_authentication(): void
    {
        $this->deleteJson('/api/v1/onboarding/photos/1')->assertUnauthorized();
    }

    public function test_deletes_owned_photo_and_queues_provider_cleanup(): void
    {
        Bus::fake();
        $user = User::factory()->create(['status' => User::STATUS_ACTIVE]);
        $profile = UserProfile::factory()->for($user)->create();
        $photo = ProfilePhoto::factory()->for($profile)->create([
            'position' => 2,
            'provider_asset_id' => 'soul/profile-photos/owned',
        ]);
        Sanctum::actingAs($user);

        $this->deleteJson('/api/v1/onboarding/photos/2')
            ->assertOk()
            ->assertJsonPath('success', true);

        $this->assertDatabaseMissing('profile_photos', ['id' => $photo->id]);
        Bus::assertDispatched(
            DestroyCloudinaryAsset::class,
            fn (DestroyCloudinaryAsset $job): bool => $job->providerAssetId === 'soul/profile-photos/owned',
        );
    }

    public function test_delete_is_idempotent_and_cannot_delete_another_users_photo(): void
    {
        Bus::fake();
        $owner = User::factory()->create(['status' => User::STATUS_ACTIVE]);
        $ownerProfile = UserProfile::factory()->for($owner)->create();
        $photo = ProfilePhoto::factory()->for($ownerProfile)->create([
            'position' => 3,
        ]);
        $requester = User::factory()->create(['status' => User::STATUS_ACTIVE]);
        UserProfile::factory()->for($requester)->create();
        Sanctum::actingAs($requester);

        $this->deleteJson('/api/v1/onboarding/photos/3')->assertOk();
        $this->deleteJson('/api/v1/onboarding/photos/3')->assertOk();

        $this->assertDatabaseHas('profile_photos', ['id' => $photo->id]);
        Bus::assertNothingDispatched();
    }

    public function test_rejects_position_outside_supported_slots(): void
    {
        $user = User::factory()->create(['status' => User::STATUS_ACTIVE]);
        Sanctum::actingAs($user);

        $this->deleteJson('/api/v1/onboarding/photos/4')
            ->assertUnprocessable()
            ->assertJsonPath('error.code', 'VALIDATION_ERROR');
    }
}
