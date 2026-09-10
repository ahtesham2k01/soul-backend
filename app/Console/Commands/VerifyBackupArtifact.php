<?php

namespace App\Console\Commands;

use App\Support\Release\BackupArtifactVerifier;
use Illuminate\Console\Command;

class VerifyBackupArtifact extends Command
{
    protected $signature = 'soul:backup-verify {--artifact= : Path to the encrypted backup artifact} {--manifest= : Path to its JSON manifest}';

    protected $description = 'Verify backup freshness, encryption metadata, size and checksum without restoring data';

    public function handle(BackupArtifactVerifier $verifier): int
    {
        $result = $verifier->verify((string) $this->option('artifact'), (string) $this->option('manifest'));
        $this->line(json_encode($result, JSON_THROW_ON_ERROR | JSON_UNESCAPED_SLASHES));

        return $result['status'] === 'verified' ? self::SUCCESS : self::FAILURE;
    }
}
