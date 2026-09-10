<?php

namespace App\Support\Operations;

use Illuminate\Support\Facades\DB;
use Throwable;

final class DatabaseCapacityInspector
{
    /** @return array{status:string,checked_at:string,metrics:array<string,int|float|null>,warnings:array<int,array{code:string,message:string}>} */
    public function snapshot(): array
    {
        $driver = DB::connection()->getDriverName();
        [$sizeBytes, $connections, $maximumConnections] = match ($driver) {
            'mysql' => $this->mysqlMetrics(),
            'pgsql' => $this->postgresMetrics(),
            'sqlite' => [$this->sqliteSize(), null, null],
            default => [null, null, null],
        };
        $utilization = $connections !== null && $maximumConnections > 0
            ? round(($connections / $maximumConnections) * 100, 2)
            : null;
        $warningAt = max(1, min(100, (int) config('soul.operations.database_connection_warning_percent', 80)));
        $warnings = [];
        if (in_array($driver, ['mysql', 'pgsql'], true) && ($connections === null || $maximumConnections === null)) {
            $warnings[] = ['code' => 'DATABASE_CAPACITY_UNAVAILABLE', 'message' => 'Database connection capacity could not be read with the configured role.'];
        }
        if ($utilization !== null && $utilization >= $warningAt) {
            $warnings[] = ['code' => 'DATABASE_CONNECTION_CAPACITY_HIGH', 'message' => 'Database connection utilization reached its warning threshold.'];
        }

        return [
            'status' => $warnings === [] ? 'healthy' : 'warning',
            'checked_at' => now()->toIso8601String(),
            'metrics' => [
                'database_size_bytes' => $sizeBytes,
                'active_connections' => $connections,
                'maximum_connections' => $maximumConnections,
                'connection_utilization_percent' => $utilization,
                'connection_warning_percent' => $warningAt,
            ],
            'warnings' => $warnings,
        ];
    }

    /** @return array{int|null,int|null,int|null} */
    private function mysqlMetrics(): array
    {
        try {
            $size = DB::selectOne('SELECT SUM(data_length + index_length) AS bytes FROM information_schema.tables WHERE table_schema = DATABASE()');
            $connections = DB::selectOne("SHOW STATUS LIKE 'Threads_connected'");
            $maximum = DB::selectOne("SHOW VARIABLES LIKE 'max_connections'");

            return [(int) ($size->bytes ?? 0), (int) ($connections->Value ?? 0), (int) ($maximum->Value ?? 0)];
        } catch (Throwable) {
            return [null, null, null];
        }
    }

    /** @return array{int|null,int|null,int|null} */
    private function postgresMetrics(): array
    {
        try {
            $size = DB::selectOne('SELECT pg_database_size(current_database()) AS bytes');
            $connections = DB::selectOne('SELECT COUNT(*) AS count FROM pg_stat_activity WHERE datname = current_database()');
            $maximum = DB::selectOne("SELECT setting::integer AS count FROM pg_settings WHERE name = 'max_connections'");

            return [(int) ($size->bytes ?? 0), (int) ($connections->count ?? 0), (int) ($maximum->count ?? 0)];
        } catch (Throwable) {
            return [null, null, null];
        }
    }

    private function sqliteSize(): ?int
    {
        $path = DB::connection()->getDatabaseName();
        return is_string($path) && $path !== ':memory:' && is_file($path) ? filesize($path) ?: 0 : null;
    }
}
