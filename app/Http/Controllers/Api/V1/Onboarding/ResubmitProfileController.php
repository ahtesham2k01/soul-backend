<?php

namespace App\Http\Controllers\Api\V1\Onboarding;

use App\Enums\Profile\ProfileStatus;
use App\Http\Controllers\Controller;
use App\Http\Resources\Api\V1\ProfileLifecycleResource;
use App\Jobs\RunProfileAutomatedChecks;
use App\Models\UserProfile;
use App\Support\ApiResponse;
use App\Support\Onboarding\ProfileReadiness;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class ResubmitProfileController extends Controller
{
    public function __invoke(Request $request, ProfileReadiness $readiness): JsonResponse
    {
        $user = $request->user();
        $profile = $user->profile()->first();

        if ($profile === null || $profile->profile_status !== ProfileStatus::ChangesRequired) {
            return ApiResponse::error(
                code: 'PROFILE_NOT_CORRECTABLE',
                message: 'This profile is not awaiting corrections.',
                status: 409,
            );
        }

        $result = $readiness->for($user->unsetRelation('profile'));
        if (! $result['is_ready']) {
            return ApiResponse::error(
                code: 'CORRECTIONS_INCOMPLETE',
                message: 'Complete the requested corrections before resubmitting.',
                status: 422,
                details: ['missing_requirements' => $result['missing_requirements']],
            );
        }

        DB::transaction(function () use ($profile): void {
            $locked = UserProfile::query()->lockForUpdate()->findOrFail($profile->id);
            if ($locked->profile_status !== ProfileStatus::ChangesRequired) {
                return;
            }

            $locked->update([
                'profile_status' => ProfileStatus::Submitted,
                'submitted_at' => now(),
                'checks_completed_at' => null,
                'status_reason' => null,
                'correction_screen' => null,
            ]);
            DB::afterCommit(fn () => RunProfileAutomatedChecks::dispatch($locked->id));
        });

        return ApiResponse::success(
            data: ['profile' => (new ProfileLifecycleResource($profile->refresh()))->resolve($request)],
            message: 'Profile corrections submitted for automated checks.',
            status: 202,
        );
    }
}
