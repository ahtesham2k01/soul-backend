<?php

namespace App\Jobs;

use App\Models\NotificationDeliveryAttempt;
use App\Models\UserNotification;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;

class PrepareNotificationDeliveries implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;
    public function __construct(public int $notificationId) {}
    public function handle(): void
    {
        $notification = UserNotification::with('user.devices')->find($this->notificationId);
        if (! $notification) return;
        foreach ($notification->delivery_channels ?? ['in_app'] as $channel) {
            if ($channel === 'in_app') continue;
            $devices = $channel === 'push' ? $notification->user->devices->whereNull('revoked_at') : collect([null]);
            foreach ($devices as $device) {
                $key = hash('sha256', $notification->id.'|'.$channel.'|'.($device?->id ?? 'account'));
                $attempt = NotificationDeliveryAttempt::firstOrCreate(['deduplication_key' => $key], ['user_notification_id' => $notification->id, 'user_device_id' => $device?->id, 'channel' => $channel, 'provider' => $channel === 'email' ? 'mail' : ($device?->platform === 'ios' ? 'apns' : 'fcm')]);
                if ($attempt->wasRecentlyCreated) DeliverNotificationAttempt::dispatch($attempt->id);
            }
        }
    }
}
