<?php

namespace App\Support\Performance;

use Closure;
use Illuminate\Support\Facades\DB;

class CapacityProbe
{
    /** @return array{status: string, target_ms: int, probes: array<int, array<string, int|float|string|bool>>} */
    public function run(int $targetMilliseconds): array
    {
        $targetMilliseconds = max(1, min($targetMilliseconds, 60000));
        $userId = (int) (DB::table('users')->where('status', 'active')->value('id') ?? 0);
        $conversationId = (int) (DB::table('conversations')->value('id') ?? 0);

        $probes = [
            $this->measure('discovery_candidates', fn () => DB::table('user_profiles')->where('profile_status', 'live')->orderByDesc('last_active_at')->orderByDesc('id')->limit(50)->get()),
            $this->measure('first_side_matches', fn () => DB::table('user_matches')->where('first_user_id', $userId)->where('status', 'active')->orderByDesc('matched_at')->orderByDesc('id')->limit(50)->get()),
            $this->measure('second_side_matches', fn () => DB::table('user_matches')->where('second_user_id', $userId)->where('status', 'active')->orderByDesc('matched_at')->orderByDesc('id')->limit(50)->get()),
            $this->measure('notification_feed', fn () => DB::table('user_notifications')->where('user_id', $userId)->orderByDesc('id')->limit(50)->get()),
            $this->measure('conversation_messages', fn () => DB::table('messages')->where('conversation_id', $conversationId)->orderByDesc('id')->limit(50)->get()),
            $this->measure('admin_active_members', fn () => DB::table('users')->where('status', 'active')->orderByDesc('id')->limit(50)->get()),
        ];

        $probes = array_map(function (array $probe) use ($targetMilliseconds): array {
            $probe['within_target'] = $probe['duration_ms'] <= $targetMilliseconds;
            return $probe;
        }, $probes);

        return [
            'status' => collect($probes)->every(fn (array $probe): bool => $probe['within_target']) ? 'healthy' : 'warning',
            'target_ms' => $targetMilliseconds,
            'probes' => $probes,
        ];
    }

    /** @return array{name: string, duration_ms: float, rows: int} */
    private function measure(string $name, Closure $query): array
    {
        $started = hrtime(true);
        $rows = $query();

        return [
            'name' => $name,
            'duration_ms' => round((hrtime(true) - $started) / 1_000_000, 2),
            'rows' => count($rows),
        ];
    }
}
