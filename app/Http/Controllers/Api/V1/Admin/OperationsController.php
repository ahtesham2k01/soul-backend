<?php

namespace App\Http\Controllers\Api\V1\Admin;

use App\Http\Controllers\Controller;
use App\Models\AccountDeletionRequest;
use App\Models\DataExportRequest;
use App\Support\ApiResponse;
use App\Support\Release\ReleaseConfigurationValidator;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\DB;

class OperationsController extends Controller
{
    public function __invoke(ReleaseConfigurationValidator $validator): JsonResponse
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
            'provider_readiness' => $validator->providerReadiness(),
            'store_processing' => [
                'receipts_pending' => DB::table('store_purchase_receipts')->where('status', 'pending')->count(),
                'receipts_failed' => DB::table('store_purchase_receipts')->where('status', 'failed')->count(),
                'webhooks_pending' => DB::table('store_webhook_events')->where('status', 'pending')->count(),
                'webhooks_failed' => DB::table('store_webhook_events')->where('status', 'failed')->count(),
            ],
            'notification_delivery' => [
                'pending' => DB::table('notification_delivery_attempts')->whereIn('status', ['pending', 'retrying'])->count(),
                'failed' => DB::table('notification_delivery_attempts')->where('status', 'failed')->count(),
                'delivered_24h' => DB::table('notification_delivery_attempts')->where('status', 'delivered')->where('delivered_at', '>=', now()->subDay())->count(),
            ],
            'recent_delivery_failures' => DB::table('notification_delivery_attempts')->whereIn('status', ['retrying', 'failed'])->latest()->limit(25)->get(['channel', 'provider', 'status', 'attempts', 'failure_code', 'updated_at']),
        ]);
    }
}
