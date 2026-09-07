<?php

namespace App\Http\Controllers\Api\V1\Admin;

use App\Http\Controllers\Controller;
use App\Models\AdminAuditLog;
use App\Models\ProfileVerificationCase;
use App\Models\SafetyCase;
use App\Models\User;
use App\Models\UserReport;
use App\Support\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\Rule;

class ModerationController extends Controller
{
    public function dashboard(Request $r): JsonResponse
    {
        return ApiResponse::success(['actor' => ['id' => $r->user()->public_id, 'email' => $r->user()->email, 'role' => $r->user()->admin_role], 'counts' => ['pending_reports' => UserReport::where('status', 'pending')->count(), 'open_safety_cases' => SafetyCase::where('status', 'open')->count(), 'pending_verifications' => ProfileVerificationCase::whereIn('status', ['pending', 'under_review'])->count(), 'pending_appeals' => ProfileVerificationCase::where('status', 'appeal_pending')->count(), 'active_users' => User::where('status', User::STATUS_ACTIVE)->count()]]);
    }

    public function reports(): JsonResponse
    {
        $p = UserReport::where('status', 'pending')->latest('id')->cursorPaginate(30);

        return ApiResponse::success(['reports' => collect($p->items())->map(fn ($x) => ['id' => $x->public_id, 'category' => $x->category, 'details' => $x->details, 'reporter_action' => $x->reporter_action, 'created_at' => $x->created_at->toIso8601String()])->values(), 'next_cursor' => $p->nextCursor()?->encode()]);
    }

    public function decideReport(Request $r, string $report): JsonResponse
    {
        $v = $r->validate(['decision' => ['required', Rule::in(['resolved', 'dismissed', 'pause_for_review'])], 'reason' => ['required', 'string', 'max:1000']]);
        $record = UserReport::where('public_id', $report)->first();
        if (! $record) {
            return ApiResponse::error('REPORT_NOT_FOUND', 'Report not found.', 404);
        }
        DB::transaction(function () use ($r, $record, $v): void {
            $status = $v['decision'] === 'pause_for_review' ? 'under_review' : $v['decision'];
            $this->auditUpdate($r, $record, 'report.'.$v['decision'], [
                'status' => $status, 'reviewed_at' => now(), 'reviewed_by_admin_id' => $r->user()->id,
            ], $v['reason']);
            if ($v['decision'] === 'pause_for_review') {
                $profile = User::query()->find($record->reported_user_id)?->profile;
                $previousStatus = $profile?->profile_status->value;
                $profile?->update(['profile_status' => 'paused_verification']);
                SafetyCase::query()->create([
                    'user_id' => $record->reported_user_id, 'source_report_id' => $record->id,
                    'type' => 'moderator_risk_review', 'severity' => 'high', 'status' => 'open', 'reason' => $v['reason'],
                    'previous_profile_status' => $previousStatus,
                ]);
            }
        });

        return ApiResponse::success(['id' => $record->public_id, 'status' => $record->status]);
    }

    public function safetyCases(): JsonResponse
    {
        $page = SafetyCase::query()->where('status', 'open')->latest('id')->cursorPaginate(30);

        return ApiResponse::success(['cases' => collect($page->items())->map(fn (SafetyCase $case): array => [
            'id' => $case->public_id, 'type' => $case->type, 'severity' => $case->severity,
            'reason' => $case->reason, 'created_at' => $case->created_at->toIso8601String(),
        ])->values(), 'next_cursor' => $page->nextCursor()?->encode()]);
    }

    public function decideSafetyCase(Request $request, string $case): JsonResponse
    {
        $validated = $request->validate([
            'decision' => ['required', Rule::in(['cleared', 'verification_required'])],
            'reason' => ['required', 'string', 'min:5', 'max:1000'],
        ]);
        $record = SafetyCase::query()->where('public_id', $case)->where('status', 'open')->first();
        if ($record === null) {
            return ApiResponse::error('SAFETY_CASE_NOT_FOUND', 'Open safety case not found.', 404);
        }
        DB::transaction(function () use ($request, $record, $validated): void {
            $this->auditUpdate($request, $record, 'safety_case.'.$validated['decision'], [
                'status' => $validated['decision'], 'resolved_at' => now(),
            ], $validated['reason']);
            $hasOpenSafetyCase = SafetyCase::query()->where('user_id', $record->user_id)->where('status', 'open')->exists();
            $hasRequiredVerification = ProfileVerificationCase::query()->where('user_id', $record->user_id)
                ->where('requirement', 'required')->whereIn('status', ['pending', 'under_review', 'appeal_pending'])->exists();
            if ($validated['decision'] === 'cleared' && ! $hasOpenSafetyCase && ! $hasRequiredVerification) {
                User::query()->find($record->user_id)?->profile()->where('profile_status', 'paused_verification')
                    ->update(['profile_status' => $record->previous_profile_status ?? 'live']);
            }
            if ($validated['decision'] === 'verification_required') {
                User::query()->find($record->user_id)?->profile()->update(['profile_status' => 'paused_verification']);
                $verification = ProfileVerificationCase::query()->where('user_id', $record->user_id)
                    ->where('type', 'identity')->whereIn('status', ['pending', 'under_review'])->first();
                $verification?->update(['requirement' => 'required', 'reason' => $validated['reason']]);
                $verification ??= ProfileVerificationCase::query()->create([
                    'user_id' => $record->user_id, 'type' => 'identity', 'requirement' => 'required',
                    'status' => 'pending', 'reason' => $validated['reason'], 'submitted_at' => now(),
                ]);
            }
        });

        return ApiResponse::success(['id' => $record->public_id, 'status' => $record->status]);
    }

    public function verifications(): JsonResponse
    {
        $p = ProfileVerificationCase::whereIn('status', ['pending', 'under_review', 'appeal_pending'])->latest('id')->cursorPaginate(30);

        return ApiResponse::success(['cases' => collect($p->items())->map(fn ($x) => ['id' => $x->public_id, 'type' => $x->type, 'requirement' => $x->requirement, 'status' => $x->status, 'submitted_at' => $x->submitted_at->toIso8601String()])->values(), 'next_cursor' => $p->nextCursor()?->encode()]);
    }

    public function decideVerification(Request $r, string $case): JsonResponse
    {
        $v = $r->validate(['decision' => ['required', Rule::in(['approved', 'rejected', 'appeal_available'])], 'reason' => ['nullable', 'required_unless:decision,approved', 'string', 'max:1000']]);
        $record = ProfileVerificationCase::where('public_id', $case)->first();
        if (! $record) {
            return ApiResponse::error('VERIFICATION_CASE_NOT_FOUND', 'Verification case not found.', 404);
        } $this->auditUpdate($r, $record, 'verification.'.$v['decision'], ['status' => $v['decision'], 'reason' => $v['reason'] ?? null, 'reviewed_at' => now(), 'verified_at' => $v['decision'] === 'approved' ? now() : null], $v['reason'] ?? null);

        return ApiResponse::success(['id' => $record->public_id, 'status' => $record->status]);
    }

    private function auditUpdate(Request $r, $record, string $action, array $changes, ?string $reason): void
    {
        DB::transaction(function () use ($r, $record, $action, $changes, $reason) {
            $before = $record->only(array_keys($changes));
            $record->update($changes);
            AdminAuditLog::create(['admin_user_id' => $r->user()->id, 'action' => $action, 'subject_type' => $record::class, 'subject_id' => $record->id, 'before' => $before, 'after' => $record->only(array_keys($changes)), 'reason' => $reason, 'ip_address' => $r->ip()]);
        });
    }
}
