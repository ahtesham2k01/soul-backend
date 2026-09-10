<?php

namespace Tests\Feature\Infrastructure;

use App\Support\Operations\DatabaseCapacityInspector;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Artisan;
use Tests\TestCase;

class DatabaseCapacityInspectorTest extends TestCase
{
    use RefreshDatabase;

    public function test_sqlite_capacity_snapshot_is_safe_and_machine_readable(): void
    {
        $snapshot = app(DatabaseCapacityInspector::class)->snapshot();

        $this->assertSame('healthy', $snapshot['status']);
        $this->assertNull($snapshot['metrics']['active_connections']);
        $this->assertNull($snapshot['metrics']['maximum_connections']);
        $this->assertSame(80, $snapshot['metrics']['connection_warning_percent']);
        $this->assertArrayNotHasKey('database_name', $snapshot['metrics']);
        $this->assertArrayNotHasKey('host', $snapshot['metrics']);
        $this->assertSame(0, Artisan::call('soul:database-capacity'));
    }
}
