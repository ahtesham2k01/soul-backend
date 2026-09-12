<?php

namespace Tests\Feature\Infrastructure;

use App\Support\Operations\OperationalHealth;
use App\Support\Operations\OperationalIncidentManager;
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
        $this->assertFalse($snapshot['incident']['notification_required']);
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

    public function test_severe_threshold_breach_requests_incident_escalation(): void
    {
        config()->set('soul.operations.warning_thresholds.queued_jobs', 1);
        foreach (range(1, 6) as $index) {
            DB::table('jobs')->insert(['queue' => 'default', 'payload' => '{}', 'attempts' => 0, 'reserved_at' => null, 'available_at' => now()->timestamp, 'created_at' => now()->timestamp + $index]);
        }

        $snapshot = app(OperationalHealth::class)->snapshot();
        $this->assertSame('critical', $snapshot['status']);
        $this->assertTrue($snapshot['incident']['notification_required']);
        $this->assertSame('QUEUE_DEPTH_HIGH', $snapshot['incident']['runbook_code']);
        $this->assertSame('critical', collect($snapshot['warnings'])->firstWhere('code', 'QUEUE_DEPTH_HIGH')['severity']);
        app(OperationalIncidentManager::class)->record($snapshot);
        $this->assertDatabaseHas('operational_incidents', ['code' => 'QUEUE_DEPTH_HIGH', 'severity' => 'critical', 'status' => 'open']);
    }

    public function test_provider_backlog_and_failure_thresholds_are_reported(): void
    {
        config()->set('soul.operations.warning_thresholds.store_webhook_backlog', 0);
        config()->set('soul.operations.warning_thresholds.store_provider_failures_24h', 0);

        DB::table('store_webhook_events')->insert([
            'platform' => 'ios', 'event_hash' => hash('sha256', 'event'), 'status' => 'pending',
            'attempts' => 1, 'failure_code' => 'PROVIDER_TEMPORARILY_UNAVAILABLE',
            'created_at' => now(), 'updated_at' => now(),
        ]);

        $snapshot = app(OperationalHealth::class)->snapshot();
        $codes = collect($snapshot['warnings'])->pluck('code')->all();
        $this->assertSame(1, $snapshot['metrics']['store_webhook_backlog']);
        $this->assertContains('STORE_WEBHOOK_BACKLOG_HIGH', $codes);
        $this->assertContains('STORE_PROVIDER_FAILURES_HIGH', $codes);
    }
}
