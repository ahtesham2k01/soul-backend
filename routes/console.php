<?php

use App\Models\DataExportRequest;
use App\Models\EmailVerificationCode;
use App\Jobs\BuildUserDataExport;
use App\Jobs\DeliverNotificationAttempt;
use App\Jobs\ProcessStoreWebhook;
use App\Models\NotificationDeliveryAttempt;
use App\Models\StoreWebhookEvent;
use App\Models\AdminAuditLog;
use App\Models\User;
use App\Support\Operations\OperationalHealth;
use App\Support\Operations\DatabaseCapacityInspector;
use App\Support\Performance\CapacityProbe;
use App\Support\Performance\SyntheticDatasetGenerator;
use Illuminate\Foundation\Inspiring;
use Illuminate\Support\Facades\Artisan;
use Illuminate\Support\Facades\Schedule;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Facades\DB;

Artisan::command('inspire', function () {
    $this->comment(Inspiring::quote());
})->purpose('Display an inspiring quote');

Artisan::command('soul:cleanup', function (): void {
    $expiredExports = 0;

    DataExportRequest::query()
        ->where('status', 'completed')
        ->where('expires_at', '<=', now())
        ->each(function (DataExportRequest $export) use (&$expiredExports): void {
            if ($export->file_path !== null) {
                Storage::disk(config('soul.privacy.export_disk'))->delete($export->file_path);
            }

            $export->forceFill([
                'status' => 'expired',
                'file_path' => null,
            ])->save();

            $expiredExports++;
        });

    $expiredOtpCodes = EmailVerificationCode::query()
        ->where('created_at', '<', now()->subDays(2))
        ->delete();

    $discardedWebhooks = StoreWebhookEvent::query()
        ->where('status', 'failed')
        ->where('attempts', '>=', 6)
        ->where('updated_at', '<=', now()->subDays(config('soul.privacy.retention.failed_store_webhook_days', 30)))
        ->update(['status' => 'discarded', 'encrypted_payload' => null, 'failure_code' => 'RETENTION_EXPIRED']);

    $prunedDeliveries = NotificationDeliveryAttempt::query()
        ->where(fn ($query) => $query->where(fn ($q) => $q->where('status', 'delivered')->where('delivered_at', '<=', now()->subDays(config('soul.privacy.retention.delivered_notification_days', 90))))
            ->orWhere(fn ($q) => $q->where('status', 'failed')->where('updated_at', '<=', now()->subDays(config('soul.privacy.retention.failed_notification_days', 180)))))
        ->delete();

    $this->info("Expired {$expiredExports} data exports, removed {$expiredOtpCodes} stale OTP records, discarded {$discardedWebhooks} exhausted webhooks, and pruned {$prunedDeliveries} delivery records.");
})->purpose('Remove expired private exports and stale OTP records');

Artisan::command('soul:recover-provider-work', function (): void {
    $staleBefore = now()->subMinutes(15);

    $exports = DataExportRequest::query()
        ->where('status', 'processing')
        ->where('processing_started_at', '<=', now()->subMinutes(30))
        ->limit(50)->pluck('id');
    DataExportRequest::query()->whereIn('id', $exports)->where('status', 'processing')
        ->update(['status' => 'failed', 'processing_started_at' => null]);
    foreach ($exports as $id) BuildUserDataExport::dispatch($id);

    NotificationDeliveryAttempt::query()
        ->where('status', 'processing')
        ->where('processing_started_at', '<=', $staleBefore)
        ->update(['status' => 'retrying', 'processing_started_at' => null, 'next_attempt_at' => now(), 'failure_code' => 'STALE_PROCESS_RECOVERED']);

    StoreWebhookEvent::query()
        ->where('status', 'processing')
        ->where('processing_started_at', '<=', $staleBefore)
        ->update(['status' => 'failed', 'processing_started_at' => null, 'failure_code' => 'STALE_PROCESS_RECOVERED']);

    $deliveries = NotificationDeliveryAttempt::query()
        ->where(fn ($query) => $query->where(fn ($q) => $q->where('status', 'pending')->where('created_at', '<=', now()->subMinutes(2)))
            ->orWhere(fn ($q) => $q->where('status', 'retrying')->where('next_attempt_at', '<=', now())))
        ->limit(500)->pluck('id');
    foreach ($deliveries as $id) DeliverNotificationAttempt::dispatch($id);

    $webhooks = StoreWebhookEvent::query()
        ->whereIn('status', ['pending', 'failed'])
        ->whereNotNull('encrypted_payload')
        ->where('attempts', '<', 6)
        ->where(fn ($query) => $query->where('updated_at', '<=', now()->subMinutes(2))->orWhere('failure_code', 'STALE_PROCESS_RECOVERED'))
        ->limit(200)->pluck('id');
    foreach ($webhooks as $id) ProcessStoreWebhook::dispatch($id);

    $this->info("Queued {$exports->count()} data exports, {$deliveries->count()} delivery attempts and {$webhooks->count()} store events for recovery.");
})->purpose('Recover stale or interrupted provider delivery work');

Artisan::command('soul:ops-check', function (): int {
    $snapshot = app(OperationalHealth::class)->snapshot();
    app(\App\Support\Operations\OperationalIncidentManager::class)->record($snapshot);
    $this->line(json_encode($snapshot, JSON_THROW_ON_ERROR | JSON_UNESCAPED_SLASHES));

    return $snapshot['status'] === 'healthy' ? 0 : 1;
})->purpose('Check queue and asynchronous workload health for monitoring');

Artisan::command('soul:replay-store-webhook {event} {--admin=} {--reason=} {--confirm=}', function (): int {
    if ($this->option('confirm') !== 'REPLAY-FAILED-STORE-WEBHOOK') {
        $this->error('Pass --confirm=REPLAY-FAILED-STORE-WEBHOOK after reviewing the event.');
        return 1;
    }
    $reason = trim((string) $this->option('reason'));
    $admin = User::query()->where('email', strtolower(trim((string) $this->option('admin'))))->where('admin_role', 'super_admin')->first();
    if (! $admin || mb_strlen($reason) < 10) {
        $this->error('A valid super-admin email and a reason of at least 10 characters are required.');
        return 1;
    }

    $event = DB::transaction(function () use ($admin, $reason): ?StoreWebhookEvent {
        $record = StoreWebhookEvent::query()->lockForUpdate()->find((int) $this->argument('event'));
        if (! $record || $record->status !== 'failed' || $record->encrypted_payload === null) return null;
        $before = $record->only(['status', 'attempts', 'failure_code']);
        $record->update(['status' => 'pending', 'attempts' => 0, 'failure_code' => null, 'processing_started_at' => null]);
        AdminAuditLog::create([
            'admin_user_id' => $admin->id, 'action' => 'store_webhook.replayed',
            'subject_type' => StoreWebhookEvent::class, 'subject_id' => $record->id,
            'before' => $before, 'after' => $record->only(['status', 'attempts', 'failure_code']),
            'reason' => $reason, 'ip_address' => null,
        ]);
        return $record;
    });
    if (! $event) {
        $this->error('Only a failed event with a retained payload can be replayed.');
        return 1;
    }
    ProcessStoreWebhook::dispatch($event->id);
    $this->info('Store webhook queued for one audited replay cycle.');
    return 0;
})->purpose('Replay one retained failed store webhook with super-admin attribution');

Artisan::command('soul:seed-performance {--users=10000} {--matches=5000} {--messages=10} {--confirm=}', function (): int {
    if (! app()->environment(['local', 'testing'])) {
        $this->error('Synthetic data generation is allowed only in local or testing environments.');
        return 1;
    }
    if ($this->option('confirm') !== 'GENERATE-SYNTHETIC-DATA') {
        $this->error('Pass --confirm=GENERATE-SYNTHETIC-DATA and use a disposable database.');
        return 1;
    }

    try {
        $result = app(SyntheticDatasetGenerator::class)->generate(
            (int) $this->option('users'),
            (int) $this->option('matches'),
            (int) $this->option('messages'),
        );
    } catch (\InvalidArgumentException $exception) {
        $this->error($exception->getMessage());
        return 1;
    }

    $this->line(json_encode($result, JSON_THROW_ON_ERROR | JSON_UNESCAPED_SLASHES));
    return 0;
})->purpose('Generate bounded synthetic load data in a disposable local database');

Artisan::command('soul:performance-check {--max-ms=250}', function (): int {
    $result = app(CapacityProbe::class)->run((int) $this->option('max-ms'));
    $this->line(json_encode($result, JSON_THROW_ON_ERROR | JSON_UNESCAPED_SLASHES));

    return $result['status'] === 'healthy' ? 0 : 1;
})->purpose('Run repeatable read-only capacity probes against representative feeds');

Artisan::command('soul:database-capacity', function (): int {
    $result = app(DatabaseCapacityInspector::class)->snapshot();
    $this->line(json_encode($result, JSON_THROW_ON_ERROR | JSON_UNESCAPED_SLASHES));

    return $result['status'] === 'healthy' ? 0 : 1;
})->purpose('Inspect database size and connection capacity without exposing database names');

Schedule::command('soul:cleanup')
    ->dailyAt('02:30')
    ->withoutOverlapping();

Schedule::command('soul:recover-provider-work')
    ->everyFiveMinutes()
    ->withoutOverlapping();
