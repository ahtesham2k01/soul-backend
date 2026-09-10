<?php

namespace App\Support\Operations;

use Illuminate\Database\Events\QueryExecuted;
use Illuminate\Support\Facades\Log;

class SlowQueryMonitor
{
    public function record(QueryExecuted $query): void
    {
        $threshold = max(0, (int) config('soul.performance.slow_query_warning_ms', 500));
        if ($threshold === 0 || $query->time < $threshold) {
            return;
        }

        $operation = strtok(ltrim($query->sql), " \t\n\r");

        Log::warning('slow_database_query', [
            'request_id' => app()->bound('request_id') ? app('request_id') : null,
            'route' => app()->runningInConsole() ? null : request()->route()?->getName(),
            'connection' => $query->connectionName,
            'duration_ms' => round($query->time, 2),
            'operation' => is_string($operation) ? strtoupper($operation) : 'UNKNOWN',
            'in_transaction' => $query->connection->transactionLevel() > 0,
        ]);
    }
}
