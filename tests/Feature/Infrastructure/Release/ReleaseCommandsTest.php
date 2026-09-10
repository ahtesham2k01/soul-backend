<?php

namespace Tests\Feature\Infrastructure\Release;

use App\Support\Release\ReleaseConfigurationValidator;
use Illuminate\Support\Facades\Artisan;
use Illuminate\Support\Facades\Http;
use Tests\TestCase;

class ReleaseCommandsTest extends TestCase
{
    public function test_basic_configuration_check_passes_without_printing_secrets(): void
    {
        config([
            'app.key' => 'base64:test-key-that-must-not-be-printed',
            'app.url' => 'http://localhost',
            'soul.privacy.export_disk' => 'local',
            'soul.media.cloudinary.upload_session_ttl_minutes' => 10,
        ]);

        $exit = Artisan::call('soul:config-check');
        $output = Artisan::output();

        $this->assertSame(0, $exit);
        $this->assertStringContainsString('configuration is ready', $output);
        $this->assertStringNotContainsString('test-key-that-must-not-be-printed', $output);
    }

    public function test_production_configuration_check_fails_closed_for_unsafe_defaults(): void
    {
        config([
            'app.key' => 'base64:test',
            'app.env' => 'local',
            'app.debug' => true,
            'app.url' => 'http://localhost',
            'database.default' => 'sqlite',
            'cache.default' => 'array',
            'queue.default' => 'sync',
            'mail.default' => 'log',
            'session.secure' => false,
            'soul.privacy.export_disk' => 'local',
            'soul.media.cloudinary.upload_session_ttl_minutes' => 10,
            'soul.media.cloudinary.cloud_name' => null,
            'services.google.client_ids' => [],
            'services.apple.client_ids' => [],
        ]);

        $this->assertSame(1, Artisan::call('soul:config-check', ['--production' => true]));
        $output = Artisan::output();
        $this->assertStringContainsString('configuration is not ready', $output);
        $this->assertStringContainsString('Redis cache', $output);
        $this->assertStringContainsString('Redis queue', $output);
        $this->assertStringContainsString('Encrypted sessions', $output);
        $this->assertStringContainsString('Backup freshness policy', $output);
        $this->assertStringContainsString('Trusted proxies', $output);
        $this->assertStringContainsString('CORS origins', $output);
        $this->assertStringNotContainsString('DB_PASSWORD', $output);
    }

    public function test_smoke_command_checks_only_public_non_destructive_endpoints(): void
    {
        Http::fake([
            'https://staging.soul.test/api/v1/health' => Http::response([
                'success' => true, 'data' => ['status' => 'ok'],
            ], 200, ['X-Request-ID' => 'health-id']),
            'https://staging.soul.test/api/v1/health/ready' => Http::response([
                'success' => true, 'data' => ['status' => 'ready'],
            ], 200, ['X-Request-ID' => 'ready-id']),
            'https://staging.soul.test/api/v1/bootstrap' => Http::response([
                'success' => true, 'data' => ['brand' => ['name' => 'SOUL']],
            ], 200, ['X-Request-ID' => 'bootstrap-id']),
        ]);

        $exit = Artisan::call('soul:smoke', ['--base-url' => 'https://staging.soul.test']);

        $this->assertSame(0, $exit);
        $this->assertStringContainsString('smoke tests passed', Artisan::output());
        Http::assertSentCount(3);
        Http::assertSent(fn ($request): bool => $request->method() === 'GET');
    }

    public function test_provider_readiness_reports_only_names_and_missing_fields(): void
    {
        config([
            'services.stores.apple' => ['issuer_id' => 'issuer-secret', 'key_id' => null, 'bundle_id' => 'app.soul', 'private_key' => 'private-secret'],
            'services.push.fcm' => ['project_id' => null, 'service_account_json' => null],
        ]);

        $readiness = app(ReleaseConfigurationValidator::class)->providerReadiness();

        $this->assertFalse($readiness['apple_store']['ready']);
        $this->assertSame(['key_id'], $readiness['apple_store']['missing']);
        $this->assertSame(['private_key'], $readiness['apple_store']['invalid']);
        $this->assertFalse($readiness['fcm']['ready']);
        $this->assertSame(['project_id', 'service_account_json'], $readiness['fcm']['missing']);
        $this->assertSame([], $readiness['fcm']['invalid']);
        $this->assertStringNotContainsString('issuer-secret', json_encode($readiness));
        $this->assertStringNotContainsString('private-secret', json_encode($readiness));
    }

    public function test_provider_check_is_machine_readable_and_never_prints_credentials(): void
    {
        config([
            'services.stores.google' => [
                'package_name' => 'app.soul',
                'service_account_json' => 'definitely-not-json-secret',
            ],
        ]);

        $this->assertSame(1, Artisan::call('soul:provider-check', ['--json' => true]));
        $output = Artisan::output();

        $this->assertJson($output);
        $this->assertStringContainsString('service_account_json', $output);
        $this->assertStringContainsString('invalid', $output);
        $this->assertStringNotContainsString('definitely-not-json-secret', $output);
    }
}
