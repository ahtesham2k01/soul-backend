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
            ->assertHeader('Cross-Origin-Opener-Policy', 'same-origin')
            ->assertHeader('Cross-Origin-Resource-Policy', 'cross-origin')
            ->assertHeader('Server-Timing');
    }

    public function test_oversized_json_request_is_rejected_before_controller_work(): void
    {
        config()->set('soul.security.maximum_json_request_kilobytes', 64);

        $this->withHeader('Content-Length', (string) (65 * 1024))
            ->postJson('/api/v1/auth/email/request-code', [])
            ->assertStatus(413)
            ->assertJsonPath('error.code', 'REQUEST_TOO_LARGE');
    }

    public function test_authenticated_responses_cannot_be_stored_by_shared_caches(): void
    {
        $user = User::factory()->create();

        $response = $this->actingAs($user, 'sanctum')
            ->getJson('/api/v1/auth/me')
            ->assertOk();

        $this->assertStringContainsString('private', (string) $response->headers->get('Cache-Control'));
        $this->assertStringContainsString('no-store', (string) $response->headers->get('Cache-Control'));
        $response->assertHeader('Pragma', 'no-cache');
    }

    public function test_cors_allows_only_explicitly_configured_member_web_origin(): void
    {
        config()->set('cors.allowed_origins', ['https://app.soul.test']);

        $this->withHeader('Origin', 'https://app.soul.test')
            ->getJson('/api/v1/health')
            ->assertOk()
            ->assertHeader('Access-Control-Allow-Origin', 'https://app.soul.test');

        $this->withHeader('Origin', 'https://evil.test')
            ->getJson('/api/v1/health')
            ->assertOk()
            ->assertHeaderMissing('Access-Control-Allow-Origin');
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
