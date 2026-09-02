<?php

namespace Tests\Feature\Models;

use App\Enums\Profile\ProfilePhotoModerationStatus;
use App\Enums\Profile\ProfilePhotoVisibility;
use App\Models\ProfilePhoto;
use App\Models\UserProfile;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Str;
use Tests\TestCase;

class ProfilePhotoModelTest extends TestCase
{
    use RefreshDatabase;

    public function test_photo_generates_public_id_and_casts_safety_state(): void
    {
        $photo = ProfilePhoto::factory()->create([
            'visibility' => ProfilePhotoVisibility::Private,
            'moderation_status' => ProfilePhotoModerationStatus::Approved,
            'face_detected' => true,
            'screenshot_protection_enabled' => true,
        ]);

        $this->assertTrue(Str::isUlid($photo->public_id));
        $this->assertSame(ProfilePhotoVisibility::Private, $photo->visibility);
        $this->assertSame(
            ProfilePhotoModerationStatus::Approved,
            $photo->moderation_status,
        );
        $this->assertTrue($photo->face_detected);
        $this->assertTrue($photo->screenshot_protection_enabled);
    }

    public function test_profile_returns_photos_in_position_order(): void
    {
        $profile = UserProfile::factory()->create();
        ProfilePhoto::factory()->for($profile)->create([
            'position' => 2,
        ]);
        ProfilePhoto::factory()->for($profile)->create([
            'position' => 1,
        ]);

        $this->assertSame(
            [1, 2],
            $profile->photos->pluck('position')->all(),
        );
    }

    public function test_deleting_profile_removes_photo_metadata(): void
    {
        $profile = UserProfile::factory()->create();
        $photo = ProfilePhoto::factory()->for($profile)->create();

        $profile->delete();

        $this->assertDatabaseMissing('profile_photos', [
            'id' => $photo->id,
        ]);
    }
}
