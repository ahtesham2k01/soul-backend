<?php

namespace App\Support\Operations;

use App\Models\OperationalIncident;
use App\Models\OperationalIncidentEvent;
use Illuminate\Support\Facades\DB;

class OperationalIncidentManager
{
    public function record(array $snapshot): void
    {
        DB::transaction(function () use ($snapshot): void {
            $activeCodes = collect($snapshot['warnings'])->pluck('code');
            foreach ($snapshot['warnings'] as $warning) {
                $fingerprint = hash('sha256', $warning['code']);
                $incident = OperationalIncident::query()->lockForUpdate()->firstOrNew(['fingerprint' => $fingerprint]);
                $eventType = ! $incident->exists ? 'opened' : ($incident->status === 'resolved' ? 'reopened' : null);
                if ($eventType !== null) {
                    $incident->fill(['first_detected_at' => now(), 'status' => 'open', 'acknowledged_by_admin_id' => null, 'acknowledged_at' => null, 'resolved_by_admin_id' => null, 'resolved_at' => null, 'resolution_reason' => null]);
                }
                $incident->fill(['code' => $warning['code'], 'severity' => $warning['severity'], 'current_value' => $warning['value'], 'threshold' => $warning['threshold'], 'last_detected_at' => now()])->save();
                if ($eventType !== null) {
                    OperationalIncidentEvent::create(['operational_incident_id' => $incident->id, 'type' => $eventType, 'severity' => $incident->severity, 'current_value' => $incident->current_value, 'threshold' => $incident->threshold, 'created_at' => now()]);
                }
            }

            OperationalIncident::query()->whereIn('status', ['open', 'acknowledged'])
                ->when($activeCodes->isNotEmpty(), fn ($query) => $query->whereNotIn('code', $activeCodes))
                ->get()->each(function (OperationalIncident $incident): void {
                    $incident->update(['status' => 'resolved', 'resolved_at' => now(), 'resolution_reason' => 'Automatically resolved after a healthy operational check.']);
                    OperationalIncidentEvent::create(['operational_incident_id' => $incident->id, 'type' => 'auto_resolved', 'severity' => $incident->severity, 'current_value' => $incident->current_value, 'threshold' => $incident->threshold, 'reason' => $incident->resolution_reason, 'created_at' => now()]);
                });
        });
    }
}
