<?php

namespace Tests\Feature\Infrastructure\Release;

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
        $this->assertStringContainsString('configuration is not ready', Artisan::output());
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
}
