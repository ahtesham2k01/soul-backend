<?php

namespace App\Jobs;

use App\Enums\Profile\ProfileStatus;
use App\Models\UserProfile;
use App\Support\Onboarding\ProfileReadiness;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Queue\Queueable;

class RunProfileAutomatedChecks implements ShouldQueue
{
    use Queueable;

    public int $tries = 3;

    public function __construct(public readonly int $profileId) {}

    public function handle(ProfileReadiness $readiness): void
    {
        $profile = UserProfile::query()->find($this->profileId);
        if ($profile === null || ! in_array($profile->profile_status, [
            ProfileStatus::Submitted,
            ProfileStatus::AutomatedChecks,
        ], true)) {
            return;
        }

        $profile->update([
            'profile_status' => ProfileStatus::AutomatedChecks,
            'status_reason' => null,
            'correction_screen' => null,
        ]);

        $result = $readiness->for($profile->user);
        if ($result['is_ready']) {
            $profile->update([
                'profile_status' => ProfileStatus::Live,
                'checks_completed_at' => now(),
                'live_at' => $profile->live_at ?? now(),
            ]);

            return;
        }

        $profile->update([
            'profile_status' => ProfileStatus::ChangesRequired,
            'checks_completed_at' => now(),
            'status_reason' => 'Complete the required profile information before going live.',
            'correction_screen' => $this->correctionScreen(
                $result['missing_requirements'][0] ?? 'profile',
            ),
        ]);
    }

    private function correctionScreen(string $requirement): string
    {
        return match ($requirement) {
            'religion' => 'onboarding.religion',
            'cover_photo', 'clear_face_photo' => 'onboarding.photos',
            default => 'onboarding.profile',
        };
    }
}
