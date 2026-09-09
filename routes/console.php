<?php

use App\Models\DataExportRequest;
use App\Models\EmailVerificationCode;
use App\Jobs\DeliverNotificationAttempt;
use App\Jobs\ProcessStoreWebhook;
use App\Models\NotificationDeliveryAttempt;
use App\Models\StoreWebhookEvent;
use Illuminate\Foundation\Inspiring;
use Illuminate\Support\Facades\Artisan;
use Illuminate\Support\Facades\Schedule;
use Illuminate\Support\Facades\Storage;

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

    $this->info("Expired {$expiredExports} data exports and removed {$expiredOtpCodes} stale OTP records.");
})->purpose('Remove expired private exports and stale OTP records');

Artisan::command('soul:recover-provider-work', function (): void {
    $staleBefore = now()->subMinutes(15);

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
        ->where('attempts', '<', 6)
        ->where(fn ($query) => $query->where('updated_at', '<=', now()->subMinutes(2))->orWhere('failure_code', 'STALE_PROCESS_RECOVERED'))
        ->limit(200)->pluck('id');
    foreach ($webhooks as $id) ProcessStoreWebhook::dispatch($id);

    $this->info("Queued {$deliveries->count()} delivery attempts and {$webhooks->count()} store events for recovery.");
})->purpose('Recover stale or interrupted provider delivery work');

Schedule::command('soul:cleanup')
    ->dailyAt('02:30')
    ->withoutOverlapping();

Schedule::command('soul:recover-provider-work')
    ->everyFiveMinutes()
    ->withoutOverlapping();
