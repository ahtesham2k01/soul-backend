<?php

namespace App\Support\Performance;

use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;
use InvalidArgumentException;

class SyntheticDatasetGenerator
{
    private const INSERT_BATCH_SIZE = 50;

    /** @return array<string, int|string> */
    public function generate(int $users, int $matches, int $messagesPerMatch): array
    {
        if (! app()->environment(['local', 'testing'])) {
            throw new InvalidArgumentException('Synthetic data generation is allowed only in local or testing environments.');
        }

        $maximumUsers = max(2, (int) config('soul.performance.synthetic.maximum_users', 50000));
        $maximumMatches = max(1, (int) config('soul.performance.synthetic.maximum_matches', 50000));
        $maximumMessages = max(0, (int) config('soul.performance.synthetic.maximum_messages_per_match', 100));

        if ($users < 2 || $users > $maximumUsers) {
            throw new InvalidArgumentException("Users must be between 2 and {$maximumUsers}.");
        }
        if ($matches < 0 || $matches > min($maximumMatches, $users - 1)) {
            throw new InvalidArgumentException('Matches must be between 0 and users minus one.');
        }
        if ($messagesPerMatch < 0 || $messagesPerMatch > $maximumMessages) {
            throw new InvalidArgumentException("Messages per match must be between 0 and {$maximumMessages}.");
        }

        $batch = strtolower((string) Str::ulid());
        $now = now()->startOfSecond();

        DB::transaction(function () use ($users, $matches, $messagesPerMatch, $batch, $now): void {
            foreach (array_chunk(range(1, $users), self::INSERT_BATCH_SIZE) as $positions) {
                $rows = [];
                foreach ($positions as $position) {
                    $rows[] = [
                        'public_id' => (string) Str::ulid(),
                        'name' => "Load Test Member {$position}",
                        'email' => "loadtest-{$batch}-{$position}@example.invalid",
                        'email_verified_at' => $now,
                        'preferred_locale' => 'en',
                        'status' => 'active',
                        'onboarding_completed_at' => $now,
                        'created_at' => $now,
                        'updated_at' => $now,
                    ];
                }
                DB::table('users')->insert($rows);
            }

            $userIds = DB::table('users')
                ->where('email', 'like', "loadtest-{$batch}-%")
                ->orderBy('id')
                ->pluck('id')
                ->map(fn ($id): int => (int) $id)
                ->all();

            foreach (array_chunk($userIds, self::INSERT_BATCH_SIZE, true) as $offset => $ids) {
                $profileRows = [];
                $preferenceRows = [];
                foreach (array_values($ids) as $index => $userId) {
                    $position = ($offset * self::INSERT_BATCH_SIZE) + $index + 1;
                    $gender = $position % 2 === 0 ? 'woman' : 'man';
                    $profileRows[] = [
                        'public_id' => (string) Str::ulid(),
                        'user_id' => $userId,
                        'profile_status' => 'live',
                        'first_name' => "Member {$position}",
                        'date_of_birth' => $now->copy()->subYears(18 + ($position % 43))->toDateString(),
                        'gender' => $gender,
                        'city_name' => $position % 3 === 0 ? 'Lahore' : 'Karachi',
                        'country_code' => 'PK',
                        'latitude' => 24.8607 + (($position % 25) / 1000),
                        'longitude' => 67.0011 + (($position % 25) / 1000),
                        'nationality_country_code' => 'PK',
                        'marital_status' => 'never_married',
                        'profession_status' => 'employed',
                        'smoking' => 'no',
                        'alcohol' => 'no',
                        'current_children' => 'no',
                        'future_children' => 'open_to_children',
                        'bio' => 'Synthetic performance-test profile. Not a real member.',
                        'live_at' => $now,
                        'last_active_at' => $now->copy()->subSeconds($position % 86400),
                        'created_at' => $now,
                        'updated_at' => $now,
                    ];
                    $preferenceRows[] = [
                        'user_id' => $userId,
                        'preferred_gender' => $gender === 'man' ? 'woman' : 'man',
                        'minimum_age' => 18,
                        'maximum_age' => 65,
                        'same_country_only' => true,
                        'religion_mode' => 'all_religions',
                        'location_mode' => 'current',
                        'radius_km' => 100,
                        'created_at' => $now,
                        'updated_at' => $now,
                    ];
                }
                DB::table('user_profiles')->insert($profileRows);
                DB::table('discovery_preferences')->insert($preferenceRows);
            }

            $matchRows = [];
            for ($index = 0; $index < $matches; $index++) {
                $matchRows[] = [
                    'public_id' => (string) Str::ulid(),
                    'first_user_id' => $userIds[0],
                    'second_user_id' => $userIds[$index + 1],
                    'status' => 'active',
                    'matched_at' => $now->copy()->subMinutes($matches - $index),
                    'created_at' => $now,
                    'updated_at' => $now,
                ];
            }
            foreach (array_chunk($matchRows, self::INSERT_BATCH_SIZE) as $rows) {
                DB::table('user_matches')->insert($rows);
            }

            $matchIds = DB::table('user_matches')
                ->where('first_user_id', $userIds[0])
                ->orderBy('id')
                ->pluck('id')
                ->map(fn ($id): int => (int) $id)
                ->all();
            $conversationRows = array_map(fn (int $matchId): array => [
                'public_id' => (string) Str::ulid(),
                'user_match_id' => $matchId,
                'last_message_at' => $messagesPerMatch > 0 ? $now : null,
                'created_at' => $now,
                'updated_at' => $now,
            ], $matchIds);
            foreach (array_chunk($conversationRows, self::INSERT_BATCH_SIZE) as $rows) {
                DB::table('conversations')->insert($rows);
            }

            if ($messagesPerMatch === 0) {
                return;
            }
            $conversationIds = DB::table('conversations')
                ->join('user_matches', 'user_matches.id', '=', 'conversations.user_match_id')
                ->where('user_matches.first_user_id', $userIds[0])
                ->orderBy('conversations.id')
                ->pluck('conversations.id')
                ->map(fn ($id): int => (int) $id)
                ->all();
            $messageRows = [];
            foreach ($conversationIds as $matchIndex => $conversationId) {
                for ($messageIndex = 1; $messageIndex <= $messagesPerMatch; $messageIndex++) {
                    $messageRows[] = [
                        'public_id' => (string) Str::ulid(),
                        'conversation_id' => $conversationId,
                        'sender_user_id' => $messageIndex % 2 === 0 ? $userIds[$matchIndex + 1] : $userIds[0],
                        'body' => "Synthetic message {$messageIndex}; no real member content.",
                        'read_at' => $messageIndex < $messagesPerMatch ? $now : null,
                        'created_at' => $now->copy()->subSeconds($messagesPerMatch - $messageIndex),
                        'updated_at' => $now,
                    ];
                    if (count($messageRows) === 1000) {
                        DB::table('messages')->insert($messageRows);
                        $messageRows = [];
                    }
                }
            }
            if ($messageRows !== []) {
                DB::table('messages')->insert($messageRows);
            }
        });

        return [
            'batch' => $batch,
            'users' => $users,
            'matches' => $matches,
            'conversations' => $matches,
            'messages' => $matches * $messagesPerMatch,
        ];
    }
}
