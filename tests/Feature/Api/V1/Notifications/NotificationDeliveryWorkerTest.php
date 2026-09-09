<?php

namespace Tests\Feature\Api\V1\Notifications;

use App\Contracts\Notifications\NotificationChannelSender;
use App\Jobs\DeliverNotificationAttempt;
use App\Jobs\PrepareNotificationDeliveries;
use App\Models\NotificationDeliveryAttempt;
use App\Models\User;
use App\Models\UserNotification;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Queue;
use Tests\TestCase;

class NotificationDeliveryWorkerTest extends TestCase
{
    use RefreshDatabase;

    public function test_fanout_creates_one_retry_safe_attempt_per_channel_and_device(): void
    {
        Queue::fake(); $user = User::factory()->create();
        $user->devices()->create(['platform' => 'android', 'push_token' => 'token-one', 'token_hash' => hash('sha256', 'token-one'), 'last_seen_at' => now()]);
        $notification = UserNotification::create(['user_id' => $user->id, 'type' => 'new_match', 'data' => ['title' => 'New match'], 'delivery_channels' => ['in_app', 'push', 'email']]);
        (new PrepareNotificationDeliveries($notification->id))->handle();
        (new PrepareNotificationDeliveries($notification->id))->handle();
        $this->assertDatabaseCount('notification_delivery_attempts', 2);
        Queue::assertPushed(DeliverNotificationAttempt::class, 2);
    }

    public function test_successful_delivery_is_idempotent(): void
    {
        $user = User::factory()->create(); $notification = UserNotification::create(['user_id' => $user->id, 'type' => 'account', 'data' => [], 'delivery_channels' => ['in_app']]);
        $attempt = NotificationDeliveryAttempt::create(['user_notification_id' => $notification->id, 'channel' => 'email', 'provider' => 'mail', 'deduplication_key' => hash('sha256', 'delivery-test')]);
        $sender = new class implements NotificationChannelSender { public int $calls = 0; public function send(NotificationDeliveryAttempt $attempt): ?string { $this->calls++; return 'provider-id'; } };
        $job = new DeliverNotificationAttempt($attempt->id); $job->handle($sender); $job->handle($sender);
        $this->assertSame(1, $sender->calls); $this->assertSame('delivered', $attempt->fresh()->status);
    }
}
