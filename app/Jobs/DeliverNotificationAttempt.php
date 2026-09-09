<?php

namespace App\Jobs;

use App\Contracts\Notifications\NotificationChannelSender;
use App\Models\NotificationDeliveryAttempt;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;
use Throwable;

class DeliverNotificationAttempt implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;
    public int $tries = 5;
    public array $backoff = [60, 300, 900, 3600];
    public function __construct(public int $attemptId) {}
    public function handle(NotificationChannelSender $sender): void
    {
        $attempt = NotificationDeliveryAttempt::findOrFail($this->attemptId);
        if ($attempt->status === 'delivered') return;
        $attempt->increment('attempts');
        try {
            $messageId = $sender->send($attempt);
            $attempt->update(['status' => 'delivered', 'delivered_at' => now(), 'provider_message_id' => $messageId, 'failure_code' => null]);
        } catch (Throwable $exception) {
            $attempt->update(['status' => 'retrying', 'failure_code' => 'PROVIDER_DELIVERY_FAILED', 'next_attempt_at' => now()->addMinutes(5)]);
            throw $exception;
        }
    }
    public function failed(): void
    {
        NotificationDeliveryAttempt::whereKey($this->attemptId)->update(['status' => 'failed', 'failure_code' => 'RETRIES_EXHAUSTED']);
    }
}
