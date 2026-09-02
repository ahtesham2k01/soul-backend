<?php

namespace App\Http\Controllers\Api\V1\Onboarding;

use App\Enums\Profile\ProfileStatus;
use App\Http\Controllers\Controller;
use App\Http\Requests\Api\V1\Onboarding\SubmitProfileRequest;
use App\Http\Resources\Api\V1\ProfileLifecycleResource;
use App\Jobs\RunProfileAutomatedChecks;
use App\Support\ApiResponse;
use App\Support\Onboarding\ProfileReadiness;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\DB;

class SubmitProfileController extends Controller
{
    public function __invoke(
        SubmitProfileRequest $request,
        ProfileReadiness $readiness,
    ): JsonResponse {
        $user = $request->user();
        $profile = $user->profile;
        $result = $readiness->for($user);

        if ($profile === null || ! $result['is_ready']) {
            return ApiResponse::error(
                code: 'ONBOARDING_INCOMPLETE',
                message: 'Complete all required onboarding steps before submitting.',
                status: 422,
                details: ['missing_requirements' => $result['missing_requirements']],
            );
        }

        $validated = $request->validated();
        DB::transaction(function () use ($request, $user, $profile, $validated): void {
            $lockedProfile = $user->profile()->lockForUpdate()->firstOrFail();
            if (in_array($lockedProfile->profile_status, [
                ProfileStatus::Submitted,
                ProfileStatus::AutomatedChecks,
                ProfileStatus::Live,
            ], true)) {
                return;
            }

            $context = trim((string) $request->userAgent().'|'.($validated['device_id'] ?? ''));
            foreach ([
                'terms' => $validated['terms_version'],
                'privacy' => $validated['privacy_version'],
            ] as $type => $version) {
                $user->legalAcceptances()->firstOrCreate([
                    'document_type' => $type,
                    'document_version' => $version,
                ], [
                    'accepted_at' => now(),
                    'ip_address' => $request->ip(),
                    'device_context_hash' => $context === '' ? null : hash('sha256', $context),
                ]);
            }

            $lockedProfile->update([
                'profile_status' => ProfileStatus::Submitted,
                'submitted_at' => $lockedProfile->submitted_at ?? now(),
                'checks_completed_at' => null,
                'status_reason' => null,
                'correction_screen' => null,
            ]);

            DB::afterCommit(
                fn () => RunProfileAutomatedChecks::dispatch($lockedProfile->id),
            );
        });

        return ApiResponse::success(
            data: [
                'profile' => (new ProfileLifecycleResource($profile->refresh()))
                    ->resolve($request),
            ],
            message: 'Profile submitted for automated checks.',
            status: 202,
        );
    }

}
