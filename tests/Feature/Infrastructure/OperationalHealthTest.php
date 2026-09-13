<?php

namespace Tests\Feature\Infrastructure;

use App\Support\Operations\OperationalHealth;
use App\Support\Operations\OperationalIncidentManager;
use App\Models\OperationalIncident;
use App\Support\Operations\PrometheusHealthFormatter;
use App\Support\Operations\IncidentOperationsReport;
use App\Models\OperationalIncidentEvent;
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

    public function test_incident_is_auto_resolved_and_recurrence_is_preserved(): void
    {
        $manager = app(OperationalIncidentManager::class);
        $warning = ['warnings' => [['code' => 'QUEUE_DEPTH_HIGH', 'severity' => 'warning', 'value' => 2, 'threshold' => 1]]];

        $manager->record($warning);
        $manager->record(['warnings' => []]);
        $this->assertDatabaseHas('operational_incidents', ['code' => 'QUEUE_DEPTH_HIGH', 'status' => 'resolved']);
        $this->assertDatabaseHas('operational_incident_events', ['type' => 'auto_resolved']);

        $manager->record($warning);
        $incident = OperationalIncident::firstOrFail();
        $this->assertSame('open', $incident->status);
        $this->assertSame(['opened', 'auto_resolved', 'reopened'], $incident->events()->orderBy('id')->pluck('type')->all());
    }

    public function test_critical_acknowledgement_sla_and_prometheus_export_are_machine_readable(): void
    {
        config()->set('soul.operations.critical_ack_sla_minutes', 10);
        OperationalIncident::create(['fingerprint' => hash('sha256', 'SLA'), 'code' => 'QUEUE_DEPTH_HIGH', 'severity' => 'critical', 'status' => 'open', 'current_value' => 50, 'threshold' => 5, 'first_detected_at' => now()->subMinutes(11), 'last_detected_at' => now()]);

        $snapshot = app(OperationalHealth::class)->snapshot();
        $this->assertSame(1, $snapshot['metrics']['critical_incidents_past_ack_sla']);
        $this->assertContains('CRITICAL_INCIDENT_ACK_SLA_BREACHED', collect($snapshot['warnings'])->pluck('code')->all());

        $output = app(PrometheusHealthFormatter::class)->format($snapshot);
        $this->assertStringContainsString('soul_critical_incidents_past_ack_sla 1', $output);
        $this->assertStringContainsString('code="CRITICAL_INCIDENT_ACK_SLA_BREACHED"', $output);
        $this->assertStringNotContainsString('QUEUE_DEPTH_HIGH', $output);
    }

    public function test_incident_report_is_non_destructive_and_calculates_acknowledgement_sla(): void
    {
        config()->set('soul.operations.critical_ack_sla_minutes', 15);
        config()->set('soul.operations.incident_history_retention_days', 30);
        $incident = OperationalIncident::create(['fingerprint' => hash('sha256', 'REPORT'), 'code' => 'REPORT', 'severity' => 'critical', 'status' => 'resolved', 'current_value' => 5, 'threshold' => 1, 'first_detected_at' => now()->subDays(40), 'last_detected_at' => now()->subDays(40), 'resolved_at' => now()->subDays(31)]);
        OperationalIncidentEvent::create(['operational_incident_id' => $incident->id, 'type' => 'opened', 'severity' => 'critical', 'current_value' => 5, 'threshold' => 1, 'created_at' => now()->subMinutes(10)]);
        OperationalIncidentEvent::create(['operational_incident_id' => $incident->id, 'type' => 'acknowledged', 'severity' => 'critical', 'current_value' => 5, 'threshold' => 1, 'created_at' => now()]);

        $report = app(IncidentOperationsReport::class)->build();
        $this->assertSame(1, $report['retention_preview']['resolved_incidents_eligible']);
        $this->assertFalse($report['retention_preview']['deletion_performed']);
        $this->assertSame(1, $report['acknowledgement_sla_30d']['sample_count']);
        $this->assertSame(1, $report['acknowledgement_sla_30d']['within_target_count']);
        $this->assertDatabaseCount('operational_incidents', 1);
        $this->assertDatabaseCount('operational_incident_events', 2);
    }
}
