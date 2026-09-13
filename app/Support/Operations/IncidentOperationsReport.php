<?php

namespace App\Support\Operations;

use App\Models\OperationalIncident;
use App\Models\OperationalIncidentEvent;

class IncidentOperationsReport
{
    public function build(): array
    {
        $retentionDays = max(30, (int) config('soul.operations.incident_history_retention_days', 365));
        $cutoff = now()->subDays($retentionDays);
        $events = OperationalIncidentEvent::query()
            ->where('created_at', '>=', now()->subDays(30))->latest('id')->limit(10000)->get()->reverse()->values();
        $startedAt = [];
        $acknowledgementSeconds = [];

        foreach ($events as $event) {
            if (in_array($event->type, ['opened', 'reopened'], true)) {
                $startedAt[$event->operational_incident_id] = $event->created_at;
            } elseif ($event->type === 'acknowledged' && $event->severity === 'critical' && isset($startedAt[$event->operational_incident_id])) {
                $acknowledgementSeconds[] = max(0, (int) $startedAt[$event->operational_incident_id]->diffInSeconds($event->created_at));
            }
        }

        sort($acknowledgementSeconds);
        $sampleCount = count($acknowledgementSeconds);
        $slaSeconds = max(1, (int) config('soul.operations.critical_ack_sla_minutes', 15)) * 60;

        return [
            'retention_preview' => [
                'retention_days' => $retentionDays,
                'resolved_incidents_eligible' => OperationalIncident::query()->where('status', 'resolved')->where('resolved_at', '<=', $cutoff)->count(),
                'events_eligible' => OperationalIncidentEvent::query()->whereHas('incident', fn ($query) => $query->where('status', 'resolved')->where('resolved_at', '<=', $cutoff))->where('created_at', '<=', $cutoff)->count(),
                'deletion_performed' => false,
            ],
            'acknowledgement_sla_30d' => [
                'target_seconds' => $slaSeconds,
                'sample_count' => $sampleCount,
                'within_target_count' => collect($acknowledgementSeconds)->filter(fn (int $seconds): bool => $seconds <= $slaSeconds)->count(),
                'average_seconds' => $sampleCount === 0 ? null : (int) round(array_sum($acknowledgementSeconds) / $sampleCount),
                'p95_seconds' => $sampleCount === 0 ? null : $acknowledgementSeconds[(int) ceil($sampleCount * 0.95) - 1],
                'truncated' => $events->count() === 10000,
            ],
        ];
    }
}
