<?php

namespace App\Support\Operations;

use Illuminate\Support\Facades\DB;

class OperationalHealth
{
    /** @return array{status:string,checked_at:string,metrics:array<string,int>,warnings:array<int,array{code:string,message:string,value:int,threshold:int}>} */
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
        ];
        $thresholds = config('soul.operations.warning_thresholds');
        $definitions = [
            'queued_jobs' => ['QUEUE_DEPTH_HIGH', 'Queued job count is above its warning threshold.'],
            'oldest_queued_job_age_seconds' => ['QUEUE_WAIT_HIGH', 'The oldest queued job has waited too long.'],
            'failed_jobs_24h' => ['FAILED_JOBS_PRESENT', 'One or more jobs failed during the last 24 hours.'],
            'stale_exports' => ['STALE_EXPORTS_PRESENT', 'One or more data exports have a stale processing lease.'],
            'stale_notification_deliveries' => ['STALE_NOTIFICATION_DELIVERIES_PRESENT', 'One or more notification deliveries have a stale processing lease.'],
            'stale_store_webhooks' => ['STALE_STORE_WEBHOOKS_PRESENT', 'One or more store webhooks have a stale processing lease.'],
        ];
        $warnings = [];
        foreach ($definitions as $metric => [$code, $message]) {
            $threshold = max(0, (int) ($thresholds[$metric] ?? 0));
            if ($metrics[$metric] > $threshold) {
                $warnings[] = compact('code', 'message') + ['value' => $metrics[$metric], 'threshold' => $threshold];
            }
        }

        return ['status' => $warnings === [] ? 'healthy' : 'warning', 'checked_at' => $now->toIso8601String(), 'metrics' => $metrics, 'warnings' => $warnings];
    }
}
