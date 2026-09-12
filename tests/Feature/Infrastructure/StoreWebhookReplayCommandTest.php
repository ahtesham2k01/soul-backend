<?php

namespace Tests\Feature\Infrastructure;

use App\Jobs\ProcessStoreWebhook;
use App\Models\StoreWebhookEvent;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Queue;
use Tests\TestCase;

class StoreWebhookReplayCommandTest extends TestCase
{
    use RefreshDatabase;

    public function test_failed_retained_event_requires_confirmed_super_admin_and_is_audited(): void
    {
        Queue::fake();
        $admin = User::factory()->create(['admin_role' => 'super_admin']);
        $event = StoreWebhookEvent::create(['platform' => 'ios', 'event_hash' => hash('sha256', 'retry'), 'encrypted_payload' => '{}', 'status' => 'failed', 'attempts' => 6, 'failure_code' => 'PROVIDER_TEMPORARILY_UNAVAILABLE']);

        $this->artisan('soul:replay-store-webhook', ['event' => $event->id, '--admin' => $admin->email, '--reason' => 'Provider incident resolved', '--confirm' => 'REPLAY-FAILED-STORE-WEBHOOK'])->assertSuccessful();

        $this->assertDatabaseHas('store_webhook_events', ['id' => $event->id, 'status' => 'pending', 'attempts' => 0, 'failure_code' => null]);
        $this->assertDatabaseHas('admin_audit_logs', ['admin_user_id' => $admin->id, 'action' => 'store_webhook.replayed', 'subject_id' => $event->id]);
        Queue::assertPushed(ProcessStoreWebhook::class, fn ($job) => $job->eventId === $event->id);
    }

    public function test_erased_or_unconfirmed_event_cannot_be_replayed(): void
    {
        Queue::fake();
        $admin = User::factory()->create(['admin_role' => 'super_admin']);
        $event = StoreWebhookEvent::create(['platform' => 'ios', 'event_hash' => hash('sha256', 'erased'), 'encrypted_payload' => null, 'status' => 'failed']);
        $arguments = ['event' => $event->id, '--admin' => $admin->email, '--reason' => 'Manual replay request'];

        $this->artisan('soul:replay-store-webhook', $arguments)->assertFailed();
        $this->artisan('soul:replay-store-webhook', $arguments + ['--confirm' => 'REPLAY-FAILED-STORE-WEBHOOK'])->assertFailed();
        Queue::assertNothingPushed();
    }
}
