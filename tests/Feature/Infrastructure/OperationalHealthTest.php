<?php

namespace Tests\Feature\Infrastructure;

use App\Support\Operations\OperationalHealth;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\DB;
use Tests\TestCase;

class OperationalHealthTest extends TestCase
{
    use RefreshDatabase;

    public function test_empty_workloads_are_healthy(): void
    {
        $snapshot = app(OperationalHealth::class)->snapshot();

        $this->assertSame('healthy', $snapshot['status']);
        $this->assertSame(0, $snapshot['metrics']['queued_jobs']);
        $this->assertSame([], $snapshot['warnings']);
        $this->artisan('soul:ops-check')->assertSuccessful();
    }

    public function test_backlog_and_recent_failure_produce_machine_readable_warnings(): void
    {
        config()->set('soul.operations.warning_thresholds.queued_jobs', 0);
        config()->set('soul.operations.warning_thresholds.oldest_queued_job_age_seconds', 60);
        config()->set('soul.operations.warning_thresholds.failed_jobs_24h', 0);

        DB::table('jobs')->insert([
            'queue' => 'default',
            'payload' => '{}',
            'attempts' => 0,
            'reserved_at' => null,
            'available_at' => now()->timestamp,
            'created_at' => now()->subMinutes(5)->timestamp,
        ]);
        DB::table('failed_jobs')->insert([
            'uuid' => fake()->uuid(),
            'connection' => 'database',
            'queue' => 'default',
            'payload' => '{}',
            'exception' => 'Redacted test exception',
            'failed_at' => now(),
        ]);

        $snapshot = app(OperationalHealth::class)->snapshot();
        $codes = collect($snapshot['warnings'])->pluck('code')->all();

        $this->assertSame('warning', $snapshot['status']);
        $this->assertSame(1, $snapshot['metrics']['queued_jobs']);
        $this->assertContains('QUEUE_DEPTH_HIGH', $codes);
        $this->assertContains('QUEUE_WAIT_HIGH', $codes);
        $this->assertContains('FAILED_JOBS_PRESENT', $codes);
        $this->artisan('soul:ops-check')->assertFailed();
    }
}
