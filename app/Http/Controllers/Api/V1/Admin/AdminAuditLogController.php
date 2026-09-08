<?php

namespace App\Http\Controllers\Api\V1\Admin;

use App\Http\Controllers\Controller;
use App\Models\AdminAuditLog;
use App\Support\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class AdminAuditLogController extends Controller
{
    public function __invoke(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'action' => ['nullable', 'string', 'max:80'],
            'admin' => ['nullable', 'string', 'max:26'],
        ]);
        $page = AdminAuditLog::query()
            ->when(isset($validated['action']), fn ($query) => $query->where('action', 'like', $validated['action'].'%'))
            ->when(isset($validated['admin']), fn ($query) => $query->whereHas('adminUser', fn ($admin) => $admin->where('public_id', $validated['admin'])))
            ->with('adminUser:id,public_id,email')
            ->latest('id')
            ->cursorPaginate(50);

        return ApiResponse::success([
            'audit_logs' => collect($page->items())->map(fn (AdminAuditLog $log): array => [
                'id' => $log->public_id,
                'action' => $log->action,
                'admin' => [
                    'id' => $log->adminUser->public_id,
                    'email' => $log->adminUser->email,
                ],
                'subject_type' => class_basename($log->subject_type),
                'before' => $log->before,
                'after' => $log->after,
                'reason' => $log->reason,
                'created_at' => $log->created_at->toIso8601String(),
            ])->values(),
            'next_cursor' => $page->nextCursor()?->encode(),
        ]);
    }
}
