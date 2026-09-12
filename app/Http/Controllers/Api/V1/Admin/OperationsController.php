<?php

namespace App\Http\Controllers\Api\V1\Admin;

use App\Http\Controllers\Controller;
use App\Models\AccountDeletionRequest;
use App\Models\AdminAuditLog;
use App\Models\DataExportRequest;
use App\Models\OperationalIncident;
use App\Support\ApiResponse;
use App\Support\Operations\OperationalHealth;
use App\Support\Providers\ProviderCircuitBreaker;
use App\Support\Release\ReleaseConfigurationValidator;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class OperationsController extends Controller
{
    public function __invoke(ReleaseConfigurationValidator $validator, OperationalHealth $health, ProviderCircuitBreaker $breaker): JsonResponse
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
            'provider_circuits' => $breaker->states(['store:ios', 'store:android', 'push:apns', 'push:fcm']),
            'operational_health' => $health->snapshot(),
            'store_processing' => [
                'receipts_pending' => DB::table('store_purchase_receipts')->where('status', 'pending')->count(),
                'receipts_failed' => DB::table('store_purchase_receipts')->where('status', 'failed')->count(),
                'webhooks_pending' => DB::table('store_webhook_events')->where('status', 'pending')->count(),
                'webhooks_failed' => DB::table('store_webhook_events')->where('status', 'failed')->count(),
                'webhooks_discarded' => DB::table('store_webhook_events')->where('status', 'discarded')->count(),
                'raw_purchase_tokens_retained' => DB::table('store_purchase_receipts')->whereNotNull('encrypted_receipt')->count(),
                'raw_webhook_payloads_retained' => DB::table('store_webhook_events')->whereNotNull('encrypted_payload')->count(),
            ],
            'notification_delivery' => [
                'pending' => DB::table('notification_delivery_attempts')->whereIn('status', ['pending', 'retrying'])->count(),
                'failed' => DB::table('notification_delivery_attempts')->where('status', 'failed')->count(),
                'delivered_24h' => DB::table('notification_delivery_attempts')->where('status', 'delivered')->where('delivered_at', '>=', now()->subDay())->count(),
            ],
            'recent_delivery_failures' => DB::table('notification_delivery_attempts')->whereIn('status', ['retrying', 'failed'])->latest()->limit(25)->get(['channel', 'provider', 'status', 'attempts', 'failure_code', 'updated_at']),
            'provider_failure_summary_24h' => [
                'notifications' => DB::table('notification_delivery_attempts')->whereNotNull('failure_code')->where('updated_at', '>=', now()->subDay())->select('failure_code', DB::raw('count(*) as total'))->groupBy('failure_code')->pluck('total', 'failure_code'),
                'store_webhooks' => DB::table('store_webhook_events')->whereNotNull('failure_code')->where('updated_at', '>=', now()->subDay())->select('failure_code', DB::raw('count(*) as total'))->groupBy('failure_code')->pluck('total', 'failure_code'),
                'purchases' => DB::table('store_purchase_receipts')->whereNotNull('failure_code')->where('updated_at', '>=', now()->subDay())->select('failure_code', DB::raw('count(*) as total'))->groupBy('failure_code')->pluck('total', 'failure_code'),
            ],
            'recent_provider_recoveries' => AdminAuditLog::query()->with('adminUser:id,email')
                ->where('action', 'store_webhook.replayed')->latest()->limit(25)->get()
                ->map(fn (AdminAuditLog $log): array => [
                    'id' => $log->public_id, 'action' => $log->action,
                    'admin_email' => $log->adminUser->email, 'reason' => $log->reason,
                    'created_at' => $log->created_at->toIso8601String(),
                ]),
            'operational_incidents' => OperationalIncident::query()->with(['acknowledgedBy:id,email', 'resolvedBy:id,email'])
                ->latest('last_detected_at')->limit(50)->get()->map(fn (OperationalIncident $incident): array => $this->incidentData($incident)),
        ]);
    }

    public function updateIncident(Request $request, OperationalIncident $incident): JsonResponse
    {
        $data = $request->validate(['decision' => ['required', 'in:acknowledge,resolve'], 'reason' => ['required', 'string', 'min:10', 'max:1000']]);
        $updated = DB::transaction(function () use ($request, $incident, $data): OperationalIncident {
            $record = OperationalIncident::query()->lockForUpdate()->findOrFail($incident->id);
            abort_if($record->status === 'resolved', 409, 'Resolved incidents are immutable.');
            $before = $record->only(['status', 'severity']);
            $changes = $data['decision'] === 'acknowledge'
                ? ['status' => 'acknowledged', 'acknowledged_by_admin_id' => $request->user()->id, 'acknowledged_at' => now()]
                : ['status' => 'resolved', 'resolved_by_admin_id' => $request->user()->id, 'resolved_at' => now(), 'resolution_reason' => $data['reason']];
            $record->update($changes);
            AdminAuditLog::create(['admin_user_id' => $request->user()->id, 'action' => 'operational_incident.'.$data['decision'].'d', 'subject_type' => OperationalIncident::class, 'subject_id' => $record->id, 'before' => $before, 'after' => $record->only(['status', 'severity']), 'reason' => $data['reason'], 'ip_address' => $request->ip()]);
            return $record->fresh(['acknowledgedBy:id,email', 'resolvedBy:id,email']);
        });

        return ApiResponse::success(['incident' => $this->incidentData($updated)]);
    }

    private function incidentData(OperationalIncident $incident): array
    {
        return ['id' => $incident->public_id, 'code' => $incident->code, 'severity' => $incident->severity, 'status' => $incident->status, 'current_value' => $incident->current_value, 'threshold' => $incident->threshold, 'first_detected_at' => $incident->first_detected_at->toIso8601String(), 'last_detected_at' => $incident->last_detected_at->toIso8601String(), 'acknowledged_by' => $incident->acknowledgedBy?->email, 'acknowledged_at' => $incident->acknowledged_at?->toIso8601String(), 'resolved_by' => $incident->resolvedBy?->email, 'resolved_at' => $incident->resolved_at?->toIso8601String(), 'resolution_reason' => $incident->resolution_reason];
    }
}
