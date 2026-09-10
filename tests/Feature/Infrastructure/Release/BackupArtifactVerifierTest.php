<?php

namespace Tests\Feature\Infrastructure\Release;

use Illuminate\Support\Facades\Artisan;
use Tests\TestCase;

class BackupArtifactVerifierTest extends TestCase
{
    public function test_valid_encrypted_backup_artifact_is_verified_without_exposing_content(): void
    {
        $artifact = tempnam(sys_get_temp_dir(), 'soul-backup-');
        $manifest = tempnam(sys_get_temp_dir(), 'soul-manifest-');
        file_put_contents($artifact, 'encrypted-private-backup-content');
        file_put_contents($manifest, json_encode([
            'format_version' => 1,
            'created_at' => now()->toIso8601String(),
            'environment' => 'staging',
            'database_driver' => 'mysql',
            'encrypted' => true,
            'size_bytes' => filesize($artifact),
            'sha256' => hash_file('sha256', $artifact),
            'migration_head' => '2026_09_10_070000_optimize_active_device_sessions',
        ], JSON_THROW_ON_ERROR));

        try {
            $this->assertSame(0, Artisan::call('soul:backup-verify', ['--artifact' => $artifact, '--manifest' => $manifest]));
            $this->assertStringContainsString('"status":"verified"', Artisan::output());
            $this->assertStringNotContainsString('encrypted-private-backup-content', Artisan::output());
        } finally {
            @unlink($artifact);
            @unlink($manifest);
        }
    }

    public function test_tampered_or_unencrypted_backup_fails_closed(): void
    {
        $artifact = tempnam(sys_get_temp_dir(), 'soul-backup-');
        $manifest = tempnam(sys_get_temp_dir(), 'soul-manifest-');
        file_put_contents($artifact, 'tampered');
        file_put_contents($manifest, json_encode([
            'format_version' => 1,
            'created_at' => now()->subDays(2)->toIso8601String(),
            'environment' => 'production',
            'database_driver' => 'mysql',
            'encrypted' => false,
            'size_bytes' => 1,
            'sha256' => str_repeat('0', 64),
            'migration_head' => 'migration',
        ], JSON_THROW_ON_ERROR));

        try {
            $this->assertSame(1, Artisan::call('soul:backup-verify', ['--artifact' => $artifact, '--manifest' => $manifest]));
            $this->assertStringContainsString('"status":"failed"', Artisan::output());
        } finally {
            @unlink($artifact);
            @unlink($manifest);
        }
    }
}
