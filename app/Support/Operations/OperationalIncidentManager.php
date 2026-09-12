<?php

namespace App\Support\Operations;

use App\Models\OperationalIncident;

class OperationalIncidentManager
{
    public function record(array $snapshot): void
    {
        foreach ($snapshot['warnings'] as $warning) {
            $fingerprint = hash('sha256', $warning['code']);
            $incident = OperationalIncident::query()->firstOrNew(['fingerprint' => $fingerprint]);
            if (! $incident->exists || $incident->status === 'resolved') {
                $incident->fill(['first_detected_at' => now(), 'status' => 'open', 'acknowledged_by_admin_id' => null, 'acknowledged_at' => null, 'resolved_by_admin_id' => null, 'resolved_at' => null, 'resolution_reason' => null]);
            }
            $incident->fill(['code' => $warning['code'], 'severity' => $warning['severity'], 'current_value' => $warning['value'], 'threshold' => $warning['threshold'], 'last_detected_at' => now()])->save();
        }
    }
}
