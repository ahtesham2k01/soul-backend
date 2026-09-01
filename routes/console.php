<?php

use App\Models\DataExportRequest;
use App\Models\EmailVerificationCode;
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

Schedule::command('soul:cleanup')
    ->dailyAt('02:30')
    ->withoutOverlapping();
