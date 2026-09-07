<?php

namespace App\Http\Controllers\Api\V1\Admin;

use App\Http\Controllers\Controller;
use App\Models\AccountDeletionRequest;
use App\Models\DataExportRequest;
use App\Support\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\DB;

class OperationsController extends Controller
{
    public function __invoke(): JsonResponse
    {
        return ApiResponse::success([
            'social_accounts' => DB::table('social_accounts')->select('provider', DB::raw('count(*) as total'))->groupBy('provider')->pluck('total', 'provider'),
            'privacy' => [
                'paused_profiles' => DB::table('account_privacy_settings')->where('profile_paused', true)->count(),
                'incognito_members' => DB::table('account_privacy_settings')->where('incognito', true)->count(),
                'contact_hiding_members' => DB::table('account_privacy_settings')->where('hide_contacts', true)->count(),
            ],
            'exports' => DB::table('data_export_requests')->select('status', DB::raw('count(*) as total'))->groupBy('status')->pluck('total', 'status'),
            'deletions' => DB::table('account_deletion_requests')->select('status', DB::raw('count(*) as total'))->groupBy('status')->pluck('total', 'status'),
            'recent_exports' => DataExportRequest::with('user:id,public_id,email')->latest()->limit(25)->get()->map(fn ($item): array => ['id' => $item->public_id, 'user' => ['id' => $item->user->public_id, 'email' => $item->user->email], 'status' => $item->status, 'created_at' => $item->created_at->toIso8601String(), 'expires_at' => $item->expires_at?->toIso8601String()]),
            'scheduled_deletions' => AccountDeletionRequest::with('user:id,public_id,email')->where('status', 'scheduled')->orderBy('scheduled_for')->limit(25)->get()->map(fn ($item): array => ['id' => $item->public_id, 'user' => ['id' => $item->user->public_id, 'email' => $item->user->email], 'scheduled_for' => $item->scheduled_for->toIso8601String()]),
        ]);
    }
}
