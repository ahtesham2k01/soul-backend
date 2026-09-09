<?php

namespace App\Jobs;

use App\Contracts\Notifications\NotificationChannelSender;
use App\Models\NotificationDeliveryAttempt;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;
use Illuminate\Support\Facades\DB;
use Throwable;

class DeliverNotificationAttempt implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;
    public int $tries = 5;
    public array $backoff = [60, 300, 900, 3600];
    public function __construct(public int $attemptId) {}
    public function handle(NotificationChannelSender $sender): void
    {
        $attempt = DB::transaction(function (): ?NotificationDeliveryAttempt {
            $record = NotificationDeliveryAttempt::query()->lockForUpdate()->find($this->attemptId);
            if (! $record || ! in_array($record->status, ['pending', 'retrying'], true)) return null;
            $record->update(['status' => 'processing', 'processing_started_at' => now(), 'attempts' => $record->attempts + 1]);
            return $record;
        });
        if (! $attempt) return;
        try {
            $messageId = $sender->send($attempt);
            $attempt->update(['status' => 'delivered', 'processing_started_at' => null, 'next_attempt_at' => null, 'delivered_at' => now(), 'provider_message_id' => $messageId, 'failure_code' => null]);
        } catch (Throwable $exception) {
            $attempt->update(['status' => 'retrying', 'processing_started_at' => null, 'failure_code' => 'PROVIDER_DELIVERY_FAILED', 'next_attempt_at' => now()->addMinutes(5)]);
            throw $exception;
        }
    }
    public function failed(): void
    {
        NotificationDeliveryAttempt::whereKey($this->attemptId)->update(['status' => 'failed', 'processing_started_at' => null, 'failure_code' => 'RETRIES_EXHAUSTED']);
    }
}
