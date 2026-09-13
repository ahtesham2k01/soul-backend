<?php

namespace App\Support\Operations;

use Illuminate\Support\Facades\DB;

class OperationalHealth
{
    /** @return array{status:string,checked_at:string,metrics:array<string,int>,warnings:array<int,array{code:string,message:string,value:int,threshold:int,severity:string}>,incident:array{highest_severity:string,notification_required:bool,runbook_code:?string}} */
    public function snapshot(): array
    {
        $now = now();
        $oldestCreatedAt = DB::table('jobs')->min('created_at');
        $metrics = [
            'queued_jobs' => DB::table('jobs')->count(),
            'oldest_queued_job_age_seconds' => $oldestCreatedAt === null ? 0 : max(0, $now->timestamp - (int) $oldestCreatedAt),
            'failed_jobs_24h' => DB::table('failed_jobs')->where('failed_at', '>=', $now->copy()->subDay())->count(),
            'stale_exports' => DB::table('data_export_requests')->where('status', 'processing')->where('processing_started_at', '<=', $now->copy()->subMinutes(30))->count(),
            'stale_notification_deliveries' => DB::table('notification_delivery_attempts')->where('status', 'processing')->where('processing_started_at', '<=', $now->copy()->subMinutes(15))->count(),
            'stale_store_webhooks' => DB::table('store_webhook_events')->where('status', 'processing')->where('processing_started_at', '<=', $now->copy()->subMinutes(15))->count(),
            'store_webhook_backlog' => DB::table('store_webhook_events')->whereIn('status', ['pending', 'processing'])->count(),
            'notification_provider_failures_24h' => DB::table('notification_delivery_attempts')->whereNotNull('failure_code')->where('updated_at', '>=', $now->copy()->subDay())->count(),
            'store_provider_failures_24h' => DB::table('store_webhook_events')->whereNotNull('failure_code')->where('updated_at', '>=', $now->copy()->subDay())->count()
                + DB::table('store_purchase_receipts')->whereNotNull('failure_code')->where('updated_at', '>=', $now->copy()->subDay())->count(),
            'critical_incidents_past_ack_sla' => DB::table('operational_incidents')
                ->where('severity', 'critical')->where('status', 'open')
                ->where('first_detected_at', '<=', $now->copy()->subMinutes(max(1, (int) config('soul.operations.critical_ack_sla_minutes', 15))))
                ->count(),
        ];
        $thresholds = config('soul.operations.warning_thresholds');
        $definitions = [
            'queued_jobs' => ['QUEUE_DEPTH_HIGH', 'Queued job count is above its warning threshold.'],
            'oldest_queued_job_age_seconds' => ['QUEUE_WAIT_HIGH', 'The oldest queued job has waited too long.'],
            'failed_jobs_24h' => ['FAILED_JOBS_PRESENT', 'One or more jobs failed during the last 24 hours.'],
            'stale_exports' => ['STALE_EXPORTS_PRESENT', 'One or more data exports have a stale processing lease.'],
            'stale_notification_deliveries' => ['STALE_NOTIFICATION_DELIVERIES_PRESENT', 'One or more notification deliveries have a stale processing lease.'],
            'stale_store_webhooks' => ['STALE_STORE_WEBHOOKS_PRESENT', 'One or more store webhooks have a stale processing lease.'],
            'store_webhook_backlog' => ['STORE_WEBHOOK_BACKLOG_HIGH', 'The unprocessed store-webhook backlog is above its warning threshold.'],
            'notification_provider_failures_24h' => ['NOTIFICATION_PROVIDER_FAILURES_HIGH', 'Notification-provider failures are above their 24-hour warning threshold.'],
            'store_provider_failures_24h' => ['STORE_PROVIDER_FAILURES_HIGH', 'Store-provider failures are above their 24-hour warning threshold.'],
            'critical_incidents_past_ack_sla' => ['CRITICAL_INCIDENT_ACK_SLA_BREACHED', 'One or more critical incidents have not been acknowledged within the configured SLA.'],
        ];
        $warnings = [];
        foreach ($definitions as $metric => [$code, $message]) {
            $threshold = max(0, (int) ($thresholds[$metric] ?? 0));
            if ($metrics[$metric] > $threshold) {
                $severity = $metrics[$metric] > max(1, $threshold * 5) ? 'critical' : 'warning';
                $warnings[] = compact('code', 'message', 'severity') + ['value' => $metrics[$metric], 'threshold' => $threshold];
            }
        }

        $highestSeverity = collect($warnings)->contains('severity', 'critical') ? 'critical' : ($warnings === [] ? 'healthy' : 'warning');

        return [
            'status' => $highestSeverity,
            'checked_at' => $now->toIso8601String(),
            'metrics' => $metrics,
            'warnings' => $warnings,
            'incident' => [
                'highest_severity' => $highestSeverity,
                'notification_required' => $highestSeverity === 'critical',
                'runbook_code' => $warnings[0]['code'] ?? null,
            ],
        ];
    }
}
