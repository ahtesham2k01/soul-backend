<?php

namespace App\Http\Controllers\Api\V1\Admin;

use App\Http\Controllers\Controller;
use App\Models\AdminAuditLog;
use App\Models\User;
use App\Support\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\Rule;
use Illuminate\Validation\Rules\Password;

class AdminAccountController extends Controller
{
    public function index(): JsonResponse
    {
        $admins = User::query()->whereNotNull('admin_role')->orderBy('email')->get();

        return ApiResponse::success([
            'admins' => $admins->map(fn (User $admin): array => $this->serialize($admin))->values(),
        ]);
    }

    public function store(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'name' => ['required', 'string', 'max:120'],
            'email' => ['required', 'email:rfc', 'max:255', Rule::unique('users', 'email')],
            'password' => ['required', 'confirmed', Password::min(12)->mixedCase()->numbers()],
            'role' => ['required', Rule::in($this->roles())],
            'reason' => ['required', 'string', 'min:5', 'max:1000'],
        ]);

        $admin = DB::transaction(function () use ($request, $validated): User {
            $admin = User::query()->create([
                'name' => $validated['name'],
                'email' => mb_strtolower($validated['email']),
                'password' => $validated['password'],
            ]);
            $admin->forceFill([
                'status' => User::STATUS_ACTIVE,
                'admin_role' => $validated['role'],
                'email_verified_at' => now(),
            ])->save();
            $this->audit($request, $admin, 'admin.created', null, $validated['role'], $validated['reason']);

            return $admin;
        });

        return ApiResponse::success(['admin' => $this->serialize($admin)], 'Admin account created.', 201);
    }

    public function updateRole(Request $request, string $admin): JsonResponse
    {
        $validated = $request->validate([
            'role' => ['required', Rule::in($this->roles())],
            'reason' => ['required', 'string', 'min:5', 'max:1000'],
        ]);
        $record = $this->findAdmin($admin);
        if ($record === null) {
            return ApiResponse::error('ADMIN_ACCOUNT_NOT_FOUND', 'Admin account not found.', 404);
        }
        if ($record->is($request->user())) {
            return ApiResponse::error('ADMIN_SELF_ROLE_CHANGE', 'You cannot change your own admin role.', 409);
        }

        $result = DB::transaction(function () use ($request, $record, $validated): ?User {
            $locked = User::query()->lockForUpdate()->findOrFail($record->id);
            if ($this->removesLastSuperAdmin($locked, $validated['role'])) {
                return null;
            }
            $before = $locked->admin_role;
            $locked->forceFill(['admin_role' => $validated['role']])->save();
            $this->revokeAdminSessions($locked);
            $this->audit($request, $locked, 'admin.role.updated', $before, $validated['role'], $validated['reason']);

            return $locked;
        });

        if ($result === null) {
            return ApiResponse::error('LAST_SUPER_ADMIN_REQUIRED', 'At least one super admin must remain.', 409);
        }

        return ApiResponse::success(['admin' => $this->serialize($result)], 'Admin role updated.');
    }

    public function destroy(Request $request, string $admin): JsonResponse
    {
        $validated = $request->validate(['reason' => ['required', 'string', 'min:5', 'max:1000']]);
        $record = $this->findAdmin($admin);
        if ($record === null) {
            return ApiResponse::error('ADMIN_ACCOUNT_NOT_FOUND', 'Admin account not found.', 404);
        }
        if ($record->is($request->user())) {
            return ApiResponse::error('ADMIN_SELF_ACCESS_REMOVAL', 'You cannot remove your own admin access.', 409);
        }

        $removed = DB::transaction(function () use ($request, $record, $validated): bool {
            $locked = User::query()->lockForUpdate()->findOrFail($record->id);
            if ($this->removesLastSuperAdmin($locked, null)) {
                return false;
            }
            $before = $locked->admin_role;
            $locked->forceFill(['admin_role' => null])->save();
            $this->revokeAdminSessions($locked);
            $this->audit($request, $locked, 'admin.access.removed', $before, null, $validated['reason']);

            return true;
        });

        if (! $removed) {
            return ApiResponse::error('LAST_SUPER_ADMIN_REQUIRED', 'At least one super admin must remain.', 409);
        }

        return ApiResponse::success(['removed' => true], 'Admin access removed.');
    }

    private function findAdmin(string $publicId): ?User
    {
        return User::query()->where('public_id', $publicId)->whereNotNull('admin_role')->first();
    }

    private function removesLastSuperAdmin(User $admin, ?string $nextRole): bool
    {
        return $admin->admin_role === 'super_admin'
            && $nextRole !== 'super_admin'
            && User::query()->where('admin_role', 'super_admin')->lockForUpdate()->get(['id'])->count() <= 1;
    }

    private function revokeAdminSessions(User $admin): void
    {
        $admin->tokens()->delete();
        DB::table('sessions')->where('user_id', $admin->id)->delete();
    }

    private function audit(Request $request, User $admin, string $action, ?string $before, ?string $after, string $reason): void
    {
        AdminAuditLog::query()->create([
            'admin_user_id' => $request->user()->id,
            'action' => $action,
            'subject_type' => User::class,
            'subject_id' => $admin->id,
            'before' => ['admin_role' => $before],
            'after' => ['admin_role' => $after],
            'reason' => $reason,
            'ip_address' => $request->ip(),
        ]);
    }

    private function serialize(User $admin): array
    {
        return [
            'id' => $admin->public_id,
            'name' => $admin->name,
            'email' => $admin->email,
            'role' => $admin->admin_role,
            'status' => $admin->status,
            'created_at' => $admin->created_at->toIso8601String(),
        ];
    }

    private function roles(): array
    {
        return ['moderator', 'super_admin'];
    }
}
