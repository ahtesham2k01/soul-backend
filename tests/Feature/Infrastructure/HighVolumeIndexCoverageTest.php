<?php

namespace Tests\Feature\Infrastructure;

use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Schema;
use Tests\TestCase;

class HighVolumeIndexCoverageTest extends TestCase
{
    use RefreshDatabase;

    public function test_critical_feed_and_session_indexes_exist(): void
    {
        $expected = [
            'user_profiles' => ['profile_activity_discovery_index'],
            'profile_decisions' => ['profile_decisions_inbox_index'],
            'user_matches' => ['matches_first_user_feed_index', 'matches_second_user_feed_index'],
            'user_notifications' => ['notifications_user_feed_index'],
            'messages' => ['messages_conversation_id_id_index'],
            'users' => ['users_status_feed_index'],
            'jobs' => ['jobs_created_at_index'],
            'personal_access_tokens' => ['tokens_owner_expiry_activity_index'],
        ];

        foreach ($expected as $table => $names) {
            $actual = collect(Schema::getIndexes($table))->pluck('name')->all();
            foreach ($names as $name) {
                $this->assertContains($name, $actual, "Missing required {$table}.{$name} index.");
            }
        }
    }
}
