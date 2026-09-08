<?php

namespace App\Http\Controllers\Api\V1\Safety;

use App\Enums\Safety\ReportCategory;
use App\Http\Controllers\Controller;
use App\Models\ProfileVerificationCase;
use App\Models\SafetyCase;
use App\Models\UserProfile;
use App\Models\UserReport;
use App\Support\ApiResponse;
use App\Support\Notifications\UserNotifier;
use App\Support\Safety\CloseUserInteraction;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\Rule;

class ReportUserController extends Controller
{
    public function __invoke(Request $request, string $profile, CloseUserInteraction $closer, UserNotifier $notifier): JsonResponse
    {
        $validated = $request->validate([
            'category' => ['required', Rule::enum(ReportCategory::class)],
            'details' => ['nullable', 'string', 'max:1000'],
            'action' => ['sometimes', Rule::in(['report_only', 'report_and_block'])],
        ]);
        $target = UserProfile::query()->where('public_id', $profile)->first();
        if ($target === null || $target->user_id === $request->user()->id) {
            return ApiResponse::error('PROFILE_UNAVAILABLE', 'Profile unavailable.', 404);
        }
        $action = $validated['action'] ?? 'report_only';
        $report = DB::transaction(function () use ($request, $target, $validated, $action, $closer, $notifier): UserReport {
            $report = UserReport::query()->create([
                'reporter_user_id' => $request->user()->id, 'reported_user_id' => $target->user_id,
                'category' => $validated['category'], 'details' => $validated['details'] ?? null,
                'reporter_action' => $action, 'status' => 'pending',
            ]);
            if ($action === 'report_and_block') {
                $closer->block($request->user()->id, $target->user_id, $validated['details'] ?? null);
            }
            if ($validated['category'] === ReportCategory::Underage->value) {
                $previousStatus = $target->profile_status->value;
                $target->update(['profile_status' => 'paused_verification']);
                SafetyCase::query()->create([
                    'user_id' => $target->user_id, 'source_report_id' => $report->id,
                    'type' => 'underage_suspicion', 'severity' => 'critical', 'status' => 'open',
                    'reason' => 'Age verification required after an underage safety report.',
                    'previous_profile_status' => $previousStatus,
                ]);
                $verification = ProfileVerificationCase::query()->where('user_id', $target->user_id)
                    ->where('type', 'identity')->whereIn('status', ['pending', 'under_review'])->first();
                $verification?->update(['requirement' => 'required', 'reason' => 'Age verification is required.']);
                $verification ??= ProfileVerificationCase::query()->create([
                    'user_id' => $target->user_id, 'type' => 'identity', 'requirement' => 'required',
                    'status' => 'pending', 'reason' => 'Age verification is required.', 'submitted_at' => now(),
                ]);
                $notifier->send($target->user_id, 'identity_verification_required', ['action_required' => true], 'safety', 'underage-report:'.$report->public_id);
            }

            return $report;
        });

        return ApiResponse::success([
            'report_id' => $report->public_id, 'status' => 'pending',
            'action' => $action, 'blocked' => $action === 'report_and_block',
        ], 'Report submitted successfully.', 201);
    }
}
