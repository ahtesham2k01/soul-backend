<?php

namespace Tests\Feature\Infrastructure;

use App\Support\Operations\SlowQueryMonitor;
use Illuminate\Database\Events\QueryExecuted;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Tests\TestCase;

class SlowQueryMonitorTest extends TestCase
{
    public function test_slow_query_log_excludes_sql_bindings_and_member_values(): void
    {
        config()->set('soul.performance.slow_query_warning_ms', 100);
        Log::spy();
        $event = new QueryExecuted('select * from users where email = ?', ['private@example.test'], 125.5, DB::connection());

        app(SlowQueryMonitor::class)->record($event);

        Log::shouldHaveReceived('warning')->once()->with('slow_database_query', \Mockery::on(function (array $context): bool {
            $encoded = json_encode($context);

            return $context['operation'] === 'SELECT'
                && $context['duration_ms'] === 125.5
                && ! str_contains($encoded, 'private@example.test')
                && ! array_key_exists('sql', $context)
                && ! array_key_exists('bindings', $context);
        }));
    }

    public function test_monitor_can_be_disabled_and_ignores_queries_below_threshold(): void
    {
        Log::spy();
        $event = new QueryExecuted('select 1', [], 10, DB::connection());
        config()->set('soul.performance.slow_query_warning_ms', 0);
        app(SlowQueryMonitor::class)->record($event);
        Log::shouldNotHaveReceived('warning');
    }
}
