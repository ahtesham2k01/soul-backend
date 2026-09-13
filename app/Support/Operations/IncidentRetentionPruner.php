<?php

namespace App\Support\Operations;

use App\Models\OperationalIncident;
use Illuminate\Support\Facades\DB;

class IncidentRetentionPruner
{
    public function preview(int $limit): array
    {
        $retentionDays = max(30, (int) config('soul.operations.incident_history_retention_days', 365));
        $cutoff = now()->subDays($retentionDays);
        $eligible = OperationalIncident::query()
            ->where('status', 'resolved')
            ->whereNotNull('resolved_at')
            ->where('resolved_at', '<=', $cutoff)
            ->count();

        return [
            'retention_days' => $retentionDays,
            'eligible_incidents' => $eligible,
            'batch_limit' => $limit,
            'would_delete' => min($eligible, $limit),
            'deleted_incidents' => 0,
            'executed' => false,
        ];
    }

    public function prune(int $limit): array
    {
        $preview = $this->preview($limit);

        $deleted = DB::transaction(function () use ($preview, $limit): int {
            $ids = OperationalIncident::query()
                ->where('status', 'resolved')
                ->whereNotNull('resolved_at')
                ->where('resolved_at', '<=', now()->subDays($preview['retention_days']))
                ->orderBy('resolved_at')
                ->limit($limit)
                ->lockForUpdate()
                ->pluck('id');

            return $ids->isEmpty()
                ? 0
                : OperationalIncident::query()->whereKey($ids)->delete();
        });

        return [
            ...$preview,
            'deleted_incidents' => $deleted,
            'executed' => true,
        ];
    }
}
