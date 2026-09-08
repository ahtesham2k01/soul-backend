<?php

namespace App\Http\Controllers\Api\V1\Admin;

use App\Http\Controllers\Controller;
use App\Models\AdminAuditLog;
use App\Models\DuplicateAccountCase;
use App\Models\User;
use App\Support\Accounts\SafeAccountMerger;
use App\Support\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\Rule;

class DuplicateAccountController extends Controller
{
    public function index(SafeAccountMerger $merger): JsonResponse
    {
        $cases = DuplicateAccountCase::with(['primaryUser', 'duplicateUser'])->latest('id')->limit(100)->get();

        return ApiResponse::success(['cases' => $cases->map(fn ($case) => $this->serialize($case, $merger))]);
    }

    public function store(Request $request, SafeAccountMerger $merger): JsonResponse
    {
        $data = $request->validate(['primary_user_id' => ['required', 'string', 'different:duplicate_user_id'], 'duplicate_user_id' => ['required', 'string'], 'reason' => ['required', 'string', 'min:5', 'max:1000']]);
        $primary = User::where('public_id', $data['primary_user_id'])->first();
        $duplicate = User::where('public_id', $data['duplicate_user_id'])->first();
        if (! $primary || ! $duplicate) {
            return ApiResponse::error('ACCOUNT_NOT_FOUND', 'One or both accounts were not found.', 404);
        }
        [$first, $second] = $primary->id < $duplicate->id ? [$primary, $duplicate] : [$duplicate, $primary];
        $signals = $this->signals($primary, $duplicate);
        $case = DuplicateAccountCase::updateOrCreate(['primary_user_id' => $first->id, 'duplicate_user_id' => $second->id], ['signals' => $signals, 'status' => 'open']);
        AdminAuditLog::create(['admin_user_id' => $request->user()->id, 'action' => 'duplicate_account.case_created', 'subject_type' => DuplicateAccountCase::class, 'subject_id' => $case->id, 'before' => null, 'after' => ['signals' => array_keys(array_filter($signals))], 'reason' => $data['reason'], 'ip_address' => $request->ip()]);

        return ApiResponse::success(['case' => $this->serialize($case->load(['primaryUser', 'duplicateUser']), $merger)], 'Duplicate case created.', 201);
    }

    public function resolve(Request $request, string $case, SafeAccountMerger $merger): JsonResponse
    {
        $record = DuplicateAccountCase::where('public_id', $case)->with(['primaryUser', 'duplicateUser'])->first();
        if (! $record) {
            return ApiResponse::error('DUPLICATE_CASE_NOT_FOUND', 'Duplicate account case not found.', 404);
        }
        $data = $request->validate(['decision' => ['required', Rule::in(['merge', 'not_duplicate'])], 'keep_user_id' => ['required_if:decision,merge', 'nullable', 'string'], 'confirmation' => ['required_if:decision,merge', Rule::in(['MERGE ACCOUNTS'])], 'reason' => ['required', 'string', 'min:10', 'max:1000']]);
        if ($record->status !== 'open') {
            return ApiResponse::error('DUPLICATE_CASE_CLOSED', 'Duplicate account case is already resolved.', 409);
        }
        $primary = $record->primaryUser;
        $duplicate = $record->duplicateUser;
        if ($data['decision'] === 'merge') {
            if ($data['keep_user_id'] === $duplicate->public_id) {
                [$primary, $duplicate] = [$duplicate, $primary];
            } elseif ($data['keep_user_id'] !== $primary->public_id) {
                return ApiResponse::error('INVALID_PRIMARY_ACCOUNT', 'The retained account must belong to this case.', 422);
            }
            $assessment = $merger->assessment($primary, $duplicate);
            if (! $assessment['safe_to_merge']) {
                return ApiResponse::error('UNSAFE_ACCOUNT_MERGE', 'This case requires manual data resolution before merge.', 409, ['blockers' => $assessment['blockers']]);
            }
        }
        DB::transaction(function () use ($request, $record, $data, $merger, $primary, $duplicate): void {
            if ($data['decision'] === 'merge') {
                $merger->merge($primary, $duplicate);
            }
            $record->update(['status' => $data['decision'] === 'merge' ? 'merged' : 'not_duplicate', 'resolution_note' => $data['reason'], 'resolved_by_admin_id' => $request->user()->id, 'resolved_at' => now()]);
            AdminAuditLog::create(['admin_user_id' => $request->user()->id, 'action' => 'duplicate_account.'.$record->status, 'subject_type' => DuplicateAccountCase::class, 'subject_id' => $record->id, 'before' => ['status' => 'open'], 'after' => ['status' => $record->status, 'retained_user_id' => $data['decision'] === 'merge' ? $primary->public_id : null], 'reason' => $data['reason'], 'ip_address' => $request->ip()]);
        });

        return ApiResponse::success(['case' => $this->serialize($record->refresh()->load(['primaryUser', 'duplicateUser']), $merger)]);
    }

    private function signals(User $a, User $b): array
    {
        return ['same_verified_email' => $a->email && $b->email && strtolower($a->email) === strtolower($b->email) && $a->email_verified_at && $b->email_verified_at, 'same_verified_phone' => $a->phone && $a->phone === $b->phone && $a->phone_verified_at && $b->phone_verified_at, 'matching_social_email' => $a->socialAccounts()->whereNotNull('provider_email')->pluck('provider_email')->map(fn ($x) => strtolower($x))->intersect($b->socialAccounts()->whereNotNull('provider_email')->pluck('provider_email')->map(fn ($x) => strtolower($x)))->isNotEmpty()];
    }

    private function serialize($case, SafeAccountMerger $merger): array
    {
        return ['id' => $case->public_id, 'status' => $case->status, 'signals' => $case->signals, 'primary' => ['id' => $case->primaryUser->public_id, 'email' => $case->primaryUser->email], 'duplicate' => ['id' => $case->duplicateUser->public_id, 'email' => $case->duplicateUser->email], 'merge_assessment' => $case->status === 'open' ? $merger->assessment($case->primaryUser, $case->duplicateUser) : null];
    }
}
