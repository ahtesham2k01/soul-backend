<?php

namespace Tests\Feature\Models;

use App\Enums\Profile\Gender;
use App\Enums\Profile\RelationshipIntention;
use App\Models\SpokenLanguage;
use App\Models\User;
use App\Models\UserProfile;
use App\Models\UserProfileIntention;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Str;
use Tests\TestCase;

class UserProfileModelTest extends TestCase
{
    use RefreshDatabase;

    public function test_profile_generates_public_id_and_casts_core_values(): void
    {
        $profile = UserProfile::factory()->create([
            'date_of_birth' => '1995-04-12',
            'gender' => Gender::Woman,
            'height_cm' => 168,
        ]);

        $this->assertTrue(Str::isUlid($profile->public_id));
        $this->assertSame(
            '1995-04-12',
            $profile->date_of_birth->toDateString(),
        );
        $this->assertSame(Gender::Woman, $profile->gender);
        $this->assertSame(168, $profile->height_cm);
    }

    public function test_profile_exposes_languages_and_intentions(): void
    {
        $profile = UserProfile::factory()->create();
        $urdu = SpokenLanguage::factory()->create([
            'code' => 'ur',
            'name' => 'Urdu',
            'native_name' => 'اردو',
        ]);
        $profile->spokenLanguages()->attach($urdu);
        UserProfileIntention::factory()->for($profile)->create([
            'intention' => RelationshipIntention::Marriage,
        ]);

        $this->assertSame(
            'ur',
            $profile->spokenLanguages->sole()->code,
        );
        $this->assertSame(
            RelationshipIntention::Marriage,
            $profile->intentions->sole()->intention,
        );
    }

    public function test_deleting_user_removes_profile_and_selections(): void
    {
        $user = User::factory()->create();
        $profile = UserProfile::factory()->for($user)->create();
        $language = SpokenLanguage::factory()->create();
        $profile->spokenLanguages()->attach($language);
        UserProfileIntention::factory()->for($profile)->create();

        $user->delete();

        $this->assertDatabaseMissing('user_profiles', [
            'id' => $profile->id,
        ]);
        $this->assertDatabaseMissing('user_profile_intentions', [
            'user_profile_id' => $profile->id,
        ]);
        $this->assertDatabaseMissing('spoken_language_user_profile', [
            'user_profile_id' => $profile->id,
        ]);
        $this->assertModelExists($language);
    }
}
