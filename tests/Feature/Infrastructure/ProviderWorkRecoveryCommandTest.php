<?php

namespace Tests\Feature\Infrastructure;

use App\Jobs\DeliverNotificationAttempt;
use App\Jobs\BuildUserDataExport;
use App\Jobs\ProcessStoreWebhook;
use App\Models\DataExportRequest;
use App\Models\NotificationDeliveryAttempt;
use App\Models\StoreWebhookEvent;
use App\Models\User;
use App\Models\UserNotification;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Queue;
use Tests\TestCase;

class ProviderWorkRecoveryCommandTest extends TestCase
{
    use RefreshDatabase;

    public function test_command_recovers_only_due_or_stale_provider_work(): void
    {
        Queue::fake();
        $user = User::factory()->create();
        $notification = UserNotification::create(['user_id' => $user->id, 'type' => 'account', 'data' => [], 'delivery_channels' => ['in_app']]);
        $due = NotificationDeliveryAttempt::create(['user_notification_id' => $notification->id, 'channel' => 'email', 'provider' => 'mail', 'deduplication_key' => hash('sha256', 'due'), 'status' => 'retrying', 'next_attempt_at' => now()->subMinute()]);
        $future = NotificationDeliveryAttempt::create(['user_notification_id' => $notification->id, 'channel' => 'email', 'provider' => 'mail', 'deduplication_key' => hash('sha256', 'future'), 'status' => 'retrying', 'next_attempt_at' => now()->addHour()]);
        $stale = NotificationDeliveryAttempt::create(['user_notification_id' => $notification->id, 'channel' => 'email', 'provider' => 'mail', 'deduplication_key' => hash('sha256', 'stale'), 'status' => 'processing', 'processing_started_at' => now()->subMinutes(20)]);
        $event = StoreWebhookEvent::create(['platform' => 'ios', 'event_hash' => hash('sha256', 'event'), 'encrypted_payload' => '{}', 'status' => 'processing', 'processing_started_at' => now()->subMinutes(20)]);
        $export = DataExportRequest::create(['user_id' => $user->id, 'status' => 'processing', 'processing_started_at' => now()->subMinutes(31)]);

        $this->artisan('soul:recover-provider-work')->assertSuccessful();

        Queue::assertPushed(DeliverNotificationAttempt::class, fn ($job) => in_array($job->attemptId, [$due->id, $stale->id], true));
        Queue::assertNotPushed(DeliverNotificationAttempt::class, fn ($job) => $job->attemptId === $future->id);
        Queue::assertPushed(ProcessStoreWebhook::class, fn ($job) => $job->eventId === $event->id);
        Queue::assertPushed(BuildUserDataExport::class, fn ($job) => $job->requestId === $export->id);
        $this->assertSame('retrying', $stale->fresh()->status);
        $this->assertSame('failed', $event->fresh()->status);
        $this->assertSame('failed', $export->fresh()->status);
    }
}
