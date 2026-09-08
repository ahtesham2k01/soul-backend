<?php

namespace Tests\Feature\Jobs;

use App\Jobs\RunProfileAutomatedChecks;
use App\Models\User;
use App\Models\UserProfile;
use App\Support\Onboarding\ProfileReadiness;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class RunProfileAutomatedChecksTest extends TestCase
{
    use RefreshDatabase;

    public function test_incomplete_submitted_profile_moves_to_changes_required(): void
    {
        $user = User::factory()->create();
        $profile = UserProfile::factory()->for($user)->create([
            'profile_status' => 'submitted',
        ]);

        (new RunProfileAutomatedChecks($profile->id))
            ->handle(app(ProfileReadiness::class));

        $profile->refresh();
        $this->assertSame('changes_required', $profile->profile_status->value);
        $this->assertSame('onboarding.profile', $profile->correction_screen);
        $this->assertNotNull($profile->checks_completed_at);
    }

    public function test_job_is_safe_when_profile_no_longer_awaits_checks(): void
    {
        $profile = UserProfile::factory()->create([
            'profile_status' => 'live',
            'live_at' => now(),
        ]);

        (new RunProfileAutomatedChecks($profile->id))
            ->handle(app(ProfileReadiness::class));

        $this->assertSame('live', $profile->refresh()->profile_status->value);
    }
}
