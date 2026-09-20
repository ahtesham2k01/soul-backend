<?php

namespace Tests\Feature\Infrastructure;

use App\Support\Operations\DatabaseCapacityInspector;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Artisan;
use Illuminate\Support\Facades\DB;
use Tests\TestCase;

class DatabaseCapacityInspectorTest extends TestCase
{
    use RefreshDatabase;

    public function test_capacity_snapshot_is_safe_and_machine_readable_for_the_active_database(): void
    {
        $snapshot = app(DatabaseCapacityInspector::class)->snapshot();

        $this->assertSame('healthy', $snapshot['status']);
        if (DB::connection()->getDriverName() === 'sqlite') {
            $this->assertNull($snapshot['metrics']['active_connections']);
            $this->assertNull($snapshot['metrics']['maximum_connections']);
        } else {
            $this->assertGreaterThanOrEqual(1, $snapshot['metrics']['active_connections']);
            $this->assertGreaterThan(0, $snapshot['metrics']['maximum_connections']);
            $this->assertIsFloat($snapshot['metrics']['connection_utilization_percent']);
        }
        $this->assertSame(80, $snapshot['metrics']['connection_warning_percent']);
        $this->assertArrayNotHasKey('database_name', $snapshot['metrics']);
        $this->assertArrayNotHasKey('host', $snapshot['metrics']);
        $this->assertSame(0, Artisan::call('soul:database-capacity'));
    }
}
