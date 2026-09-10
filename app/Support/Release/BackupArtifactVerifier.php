<?php

namespace App\Support\Release;

use Carbon\CarbonImmutable;
use JsonException;
use Throwable;

final class BackupArtifactVerifier
{
    /** @return array{status:string,checks:array<int,array{name:string,status:string,message:string}>} */
    public function verify(string $artifactPath, string $manifestPath): array
    {
        $artifact = realpath($artifactPath);
        $manifest = realpath($manifestPath);
        $checks = [
            $this->check('Backup artifact', $artifact !== false && is_file($artifact), 'Backup artifact is missing or is not a regular file.'),
            $this->check('Backup manifest', $manifest !== false && is_file($manifest), 'Backup manifest is missing or is not a regular file.'),
        ];

        if (! $this->passes($checks)) {
            return $this->result($checks);
        }

        try {
            $metadata = json_decode((string) file_get_contents($manifest), true, flags: JSON_THROW_ON_ERROR);
        } catch (JsonException) {
            return $this->result([...$checks, $this->check('Manifest JSON', false, 'Manifest must contain valid JSON.')]);
        }

        if (! is_array($metadata)) {
            return $this->result([...$checks, $this->check('Manifest JSON', false, 'Manifest must contain a JSON object.')]);
        }

        $required = ['format_version', 'created_at', 'environment', 'database_driver', 'encrypted', 'size_bytes', 'sha256', 'migration_head'];
        $missing = array_values(array_filter($required, fn (string $key): bool => ! array_key_exists($key, $metadata)));
        $checks[] = $this->check('Manifest fields', $missing === [], $missing === [] ? '' : 'Missing fields: '.implode(', ', $missing).'.');
        if ($missing !== []) {
            return $this->result($checks);
        }

        $maximumAgeHours = max(1, (int) config('soul.release.backup.maximum_age_hours', 24));
        try {
            $createdAt = CarbonImmutable::parse((string) $metadata['created_at']);
            $fresh = $createdAt->lessThanOrEqualTo(now()) && $createdAt->greaterThanOrEqualTo(now()->subHours($maximumAgeHours));
        } catch (Throwable) {
            $fresh = false;
        }

        $actualSize = filesize($artifact);
        $actualHash = hash_file('sha256', $artifact);
        $allowedEnvironments = ['local', 'testing', 'staging', 'production'];
        $allowedDrivers = ['mysql', 'pgsql'];

        $checks[] = $this->check('Manifest version', $metadata['format_version'] === 1, 'format_version must be 1.');
        $checks[] = $this->check('Backup freshness', $fresh, "Backup must be no older than {$maximumAgeHours} hours and cannot be future-dated.");
        $checks[] = $this->check('Source environment', in_array($metadata['environment'], $allowedEnvironments, true), 'Environment must be local, testing, staging or production.');
        $checks[] = $this->check('Database driver', in_array($metadata['database_driver'], $allowedDrivers, true), 'Database driver must be mysql or pgsql.');
        $checks[] = $this->check('Encrypted artifact', $metadata['encrypted'] === true, 'Backup artifacts must be encrypted before storage.');
        $checks[] = $this->check('Artifact size', is_int($metadata['size_bytes']) && $metadata['size_bytes'] > 0 && $actualSize === $metadata['size_bytes'], 'Artifact size does not match the manifest.');
        $checks[] = $this->check('SHA-256 checksum', is_string($metadata['sha256']) && preg_match('/^[a-f0-9]{64}$/', $metadata['sha256']) === 1 && is_string($actualHash) && hash_equals($metadata['sha256'], $actualHash), 'Artifact checksum does not match the manifest.');
        $checks[] = $this->check('Migration head', is_string($metadata['migration_head']) && preg_match('/^[A-Za-z0-9_\-.]{1,190}$/', $metadata['migration_head']) === 1, 'migration_head must be a safe migration identifier.');

        return $this->result($checks);
    }

    /** @param array<int,array{name:string,status:string,message:string}> $checks */
    private function passes(array $checks): bool
    {
        return collect($checks)->every(fn (array $check): bool => $check['status'] === 'pass');
    }

    /** @param array<int,array{name:string,status:string,message:string}> $checks
     * @return array{status:string,checks:array<int,array{name:string,status:string,message:string}>}
     */
    private function result(array $checks): array
    {
        return ['status' => $this->passes($checks) ? 'verified' : 'failed', 'checks' => $checks];
    }

    /** @return array{name:string,status:string,message:string} */
    private function check(string $name, bool $passes, string $failure): array
    {
        return ['name' => $name, 'status' => $passes ? 'pass' : 'fail', 'message' => $passes ? 'Verified' : $failure];
    }
}
