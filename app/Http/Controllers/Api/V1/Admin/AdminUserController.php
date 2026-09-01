<?php

namespace App\Http\Controllers\Api\V1\Admin;

use App\Enums\Profile\ProfileStatus;
use App\Http\Controllers\Controller;
use App\Models\AdminAuditLog;
use App\Models\User;
use App\Support\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\Rule;

class AdminUserController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'search' => ['nullable', 'string', 'max:120'],
            'status' => ['nullable', Rule::in($this->statuses())],
        ]);
        $search = trim((string) ($validated['search'] ?? ''));
        $page = User::query()
            ->when($search !== '', fn ($query) => $query->where(function ($query) use ($search): void {
                $query->where('email', 'like', '%'.$search.'%')
                    ->orWhere('name', 'like', '%'.$search.'%')
                    ->orWhere('public_id', $search)
                    ->orWhereHas('profile', fn ($profile) => $profile->where('first_name', 'like', '%'.$search.'%'));
            }))
            ->when(isset($validated['status']), fn ($query) => $query->where('status', $validated['status']))
            ->with('profile:id,user_id,public_id,first_name,profile_status,country_code')
            ->latest('id')
            ->cursorPaginate(30);

        return ApiResponse::success([
            'users' => collect($page->items())->map(fn (User $user): array => $this->summary($user))->values(),
            'next_cursor' => $page->nextCursor()?->encode(),
        ]);
    }

    public function show(string $user): JsonResponse
    {
        $record = User::query()->where('public_id', $user)->with([
            'profile.photos',
            'privacySetting',
        ])->first();

        if ($record === null) {
            return ApiResponse::error('ADMIN_USER_NOT_FOUND', 'User not found.', 404);
        }

        return ApiResponse::success(['user' => [
            ...$this->summary($record),
            'preferred_locale' => $record->preferred_locale,
            'created_at' => $record->created_at->toIso8601String(),
            'last_login_at' => $record->last_login_at?->toIso8601String(),
            'profile' => $record->profile ? [
                'id' => $record->profile->public_id,
                'first_name' => $record->profile->first_name,
                'status' => $record->profile->profile_status->value,
                'country_code' => $record->profile->country_code,
                'city_name' => $record->profile->city_name,
                'photos' => $record->profile->photos->map(fn ($photo): array => [
                    'id' => $photo->public_id,
                    'position' => $photo->position,
                    'moderation_status' => $photo->moderation_status->value,
                    'visibility' => $photo->visibility->value,
                ])->values(),
            ] : null,
            'counts' => [
                'reports_received' => DB::table('user_reports')->where('reported_user_id', $record->id)->count(),
                'reports_submitted' => DB::table('user_reports')->where('reporter_user_id', $record->id)->count(),
                'active_matches' => DB::table('user_matches')->where('status', 'active')
                    ->where(fn ($query) => $query->where('first_user_id', $record->id)->orWhere('second_user_id', $record->id))->count(),
            ],
        ]]);
    }

    public function updateStatus(Request $request, string $user): JsonResponse
    {
        $validated = $request->validate([
            'status' => ['required', Rule::in($this->statuses())],
            'reason' => ['required', 'string', 'min:5', 'max:1000'],
        ]);
        $record = User::query()->where('public_id', $user)->first();

        if ($record === null) {
            return ApiResponse::error('ADMIN_USER_NOT_FOUND', 'User not found.', 404);
        }
        if ($record->is($request->user())) {
            return ApiResponse::error('ADMIN_SELF_STATUS_CHANGE', 'You cannot change your own account status.', 409);
        }
        if ($record->admin_role !== null) {
            return ApiResponse::error('ADMIN_ACCOUNT_PROTECTED', 'Admin accounts require the dedicated role-management flow.', 409);
        }

        DB::transaction(function () use ($request, $record, $validated): void {
            $before = ['status' => $record->status];
            $record->forceFill(['status' => $validated['status']])->save();

            if ($validated['status'] !== User::STATUS_ACTIVE) {
                $record->tokens()->delete();
                $record->devices()->update(['revoked_at' => now()]);
                $record->profile()->where('profile_status', ProfileStatus::Live->value)
                    ->update(['profile_status' => ProfileStatus::PausedVerification->value]);
            }

            AdminAuditLog::query()->create([
                'admin_user_id' => $request->user()->id,
                'action' => 'user.status.'.$validated['status'],
                'subject_type' => User::class,
                'subject_id' => $record->id,
                'before' => $before,
                'after' => ['status' => $validated['status']],
                'reason' => $validated['reason'],
                'ip_address' => $request->ip(),
            ]);
        });

        return ApiResponse::success([
            'user' => $this->summary($record->refresh()->load('profile')),
        ], 'User status updated successfully.');
    }

    private function summary(User $user): array
    {
        return [
            'id' => $user->public_id,
            'name' => $user->profile?->first_name ?? $user->name,
            'email' => $user->email,
            'status' => $user->status,
            'admin_role' => $user->admin_role,
            'profile_status' => $user->profile?->profile_status?->value,
            'country_code' => $user->profile?->country_code,
        ];
    }

    private function statuses(): array
    {
        return [User::STATUS_ACTIVE, User::STATUS_SUSPENDED, User::STATUS_BLOCKED];
    }
}
