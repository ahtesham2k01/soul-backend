<?php

namespace App\Http\Controllers\Api\V1\Admin;

use App\Http\Controllers\Controller;
use App\Models\AccountAppeal;
use App\Models\AdminAuditLog;
use App\Models\User;
use App\Support\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\Rule;

class AccountAppealController extends Controller
{
    public function index(): JsonResponse
    {
        $page = AccountAppeal::query()->where('status', 'pending')->with('user:id,public_id,email')
            ->latest('id')->cursorPaginate(30);

        return ApiResponse::success([
            'appeals' => collect($page->items())->map(fn (AccountAppeal $appeal): array => [
                'id' => $appeal->public_id,
                'user' => ['id' => $appeal->user->public_id, 'email' => $appeal->user->email],
                'statement' => $appeal->statement, 'status' => $appeal->status,
                'submitted_at' => $appeal->submitted_at->toIso8601String(),
            ])->values(),
            'next_cursor' => $page->nextCursor()?->encode(),
        ]);
    }

    public function update(Request $request, string $appeal): JsonResponse
    {
        $validated = $request->validate([
            'decision' => ['required', Rule::in(['accepted', 'rejected'])],
            'reason' => ['required', 'string', 'min:5', 'max:1000'],
        ]);
        $record = AccountAppeal::query()->where('public_id', $appeal)->where('status', 'pending')->first();
        if ($record === null) {
            return ApiResponse::error('ACCOUNT_APPEAL_NOT_FOUND', 'Pending account appeal not found.', 404);
        }
        DB::transaction(function () use ($request, $record, $validated): void {
            $record->update([
                'status' => $validated['decision'], 'resolved_at' => now(),
                'resolved_by_admin_id' => $request->user()->id, 'resolution_reason' => $validated['reason'],
            ]);
            if ($validated['decision'] === 'accepted') {
                $record->user()->update(['status' => User::STATUS_ACTIVE]);
                $hasOpenSafetyCase = $record->user->safetyCases()->where('status', 'open')->exists();
                $hasRequiredVerification = $record->user->verificationCases()->where('requirement', 'required')
                    ->whereIn('status', ['pending', 'under_review', 'appeal_pending'])->exists();
                if (! $hasOpenSafetyCase && ! $hasRequiredVerification) {
                    $record->user->profile()->where('profile_status', 'paused_verification')->update(['profile_status' => 'live']);
                }
            }
            AdminAuditLog::query()->create([
                'admin_user_id' => $request->user()->id, 'action' => 'account_appeal.'.$validated['decision'],
                'subject_type' => AccountAppeal::class, 'subject_id' => $record->id,
                'before' => ['status' => 'pending'], 'after' => ['status' => $validated['decision']],
                'reason' => $validated['reason'], 'ip_address' => $request->ip(),
            ]);
        });

        return ApiResponse::success(['id' => $record->public_id, 'status' => $record->status]);
    }
}
