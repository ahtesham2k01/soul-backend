<?php

namespace Tests\Feature\Api\V1\Infrastructure;

use App\Enums\Auth\EmailVerificationPurpose;
use App\Models\DataExportRequest;
use App\Models\EmailVerificationCode;
use App\Models\NotificationDeliveryAttempt;
use App\Models\StoreWebhookEvent;
use App\Models\User;
use App\Models\UserNotification;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Artisan;
use Illuminate\Support\Facades\Storage;
use Tests\TestCase;

class ReleaseReadinessTest extends TestCase
{
    use RefreshDatabase;

    public function test_readiness_endpoint_checks_database_and_cache(): void
    {
        $this->getJson('/api/v1/health/ready')
            ->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.status', 'ready')
            ->assertJsonPath('data.checks.database', 'ok')
            ->assertJsonPath('data.checks.cache', 'ok');
    }

    public function test_api_responses_include_security_and_timing_headers(): void
    {
        $this->getJson('/api/v1/health')
            ->assertOk()
            ->assertHeader('X-Content-Type-Options', 'nosniff')
            ->assertHeader('X-Frame-Options', 'DENY')
            ->assertHeader('Referrer-Policy', 'strict-origin-when-cross-origin')
            ->assertHeader('Server-Timing');
    }

    public function test_cleanup_expires_private_exports_and_removes_stale_otps(): void
    {
        Storage::fake('local');
        $user = User::factory()->create();
        $path = 'exports/expired.json';
        Storage::disk('local')->put($path, '{}');

        $export = DataExportRequest::query()->create([
            'user_id' => $user->id,
            'status' => 'completed',
            'file_path' => $path,
            'completed_at' => now()->subDays(8),
            'expires_at' => now()->subMinute(),
        ]);

        $otp = EmailVerificationCode::query()->create([
            'email_hash' => hash('sha256', 'expired@example.com'),
            'purpose' => EmailVerificationPurpose::Login,
            'code_hash' => hash('sha256', '123456'),
            'expires_at' => now()->subDays(3),
        ]);
        $otp->forceFill(['created_at' => now()->subDays(3)])->save();

        $notification = UserNotification::create(['user_id' => $user->id, 'type' => 'account', 'data' => [], 'delivery_channels' => ['in_app']]);
        $delivery = NotificationDeliveryAttempt::create(['user_notification_id' => $notification->id, 'channel' => 'email', 'provider' => 'mail', 'deduplication_key' => hash('sha256', 'old-delivery'), 'status' => 'delivered', 'delivered_at' => now()->subDays(91)]);
        $webhook = StoreWebhookEvent::create(['platform' => 'ios', 'event_hash' => hash('sha256', 'old-webhook'), 'encrypted_payload' => 'sensitive', 'status' => 'failed', 'attempts' => 6]);
        $webhook->timestamps = false;
        $webhook->forceFill(['updated_at' => now()->subDays(31)])->save();

        Artisan::call('soul:cleanup');

        Storage::disk('local')->assertMissing($path);
        $this->assertSame('expired', $export->refresh()->status);
        $this->assertNull($export->file_path);
        $this->assertModelMissing($otp);
        $this->assertModelMissing($delivery);
        $this->assertSame('discarded', $webhook->refresh()->status);
        $this->assertNull($webhook->encrypted_payload);
    }
}
