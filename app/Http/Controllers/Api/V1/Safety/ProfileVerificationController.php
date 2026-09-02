<?php

namespace App\Http\Controllers\Api\V1\Safety;

use App\Enums\Profile\ProfilePhotoModerationStatus;
use App\Http\Controllers\Controller;
use App\Models\ProfileVerificationCase;
use App\Support\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class ProfileVerificationController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $cases = ProfileVerificationCase::query()->where('user_id', $request->user()->id)
            ->with('appeal')->latest('id')->limit(20)->get();
        return ApiResponse::success(['verification_cases' => $cases->map(fn ($case) => $this->serialize($case))]);
    }

    public function store(Request $request): JsonResponse
    {
        $request->validate(['type' => ['required', 'in:identity,selfie_review']]);
        $user = $request->user();
        $profile = $user->profile()->first();
        $hasApprovedFace = $profile?->photos()->where('moderation_status', ProfilePhotoModerationStatus::Approved->value)
            ->where('face_detected', true)->exists() ?? false;
        if (! $hasApprovedFace) return ApiResponse::error('VERIFICATION_NOT_READY', 'An approved clear-face photo is required.', 422);
        $case = ProfileVerificationCase::query()->where('user_id', $user->id)
            ->whereIn('status', ['pending', 'under_review'])->latest('id')->first();
        $case ??= ProfileVerificationCase::query()->create([
            'user_id' => $user->id, 'type' => $request->string('type')->toString(),
            'status' => 'pending', 'submitted_at' => now(),
        ]);
        return ApiResponse::success(['verification_case' => $this->serialize($case)], 'Verification request submitted.', 202);
    }

    private function serialize(ProfileVerificationCase $case): array
    {
        return [
            'id' => $case->public_id, 'type' => $case->type, 'status' => $case->status,
            'reason' => $case->reason, 'submitted_at' => $case->submitted_at->toIso8601String(),
            'reviewed_at' => $case->reviewed_at?->toIso8601String(),
            'appeal' => $case->appeal ? [
                'id' => $case->appeal->public_id, 'status' => $case->appeal->status,
                'submitted_at' => $case->appeal->submitted_at->toIso8601String(),
            ] : null,
        ];
    }
}
