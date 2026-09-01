<?php

namespace Tests\Feature\Api\V1\Matching;

use App\Models\User;
use App\Models\UserProfile;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class ProfileMatchingEndpointTest extends TestCase
{
    use RefreshDatabase;

    public function test_matching_endpoints_require_authentication(): void
    {
        $this->postJson('/api/v1/profiles/test/decision')->assertUnauthorized();
        $this->getJson('/api/v1/matches')->assertUnauthorized();
        $this->deleteJson('/api/v1/matches/test')->assertUnauthorized();
    }

    public function test_decisions_are_validated_and_idempotently_updated(): void
    {
        [$actor, $target] = $this->liveUsers();
        Sanctum::actingAs($actor);

        $this->postJson("/api/v1/profiles/{$target->profile->public_id}/decision", ['decision' => 'like'])
            ->assertOk()->assertJsonPath('data.matched', false);
        $this->postJson("/api/v1/profiles/{$target->profile->public_id}/decision", ['decision' => 'pass'])
            ->assertOk()->assertJsonPath('data.decision', 'pass');
        $this->assertDatabaseCount('profile_decisions', 1);

        $this->postJson("/api/v1/profiles/{$target->profile->public_id}/decision", ['decision' => 'skip'])
            ->assertUnprocessable();
    }

    public function test_reciprocal_likes_create_one_match_and_list_it(): void
    {
        [$first, $second] = $this->liveUsers();
        Sanctum::actingAs($first);
        $this->postJson("/api/v1/profiles/{$second->profile->public_id}/decision", ['decision' => 'like'])
            ->assertJsonPath('data.matched', false);

        Sanctum::actingAs($second);
        $response = $this->postJson("/api/v1/profiles/{$first->profile->public_id}/decision", ['decision' => 'like'])
            ->assertOk()->assertJsonPath('data.matched', true);
        $matchId = $response->json('data.match_id');
        $this->assertDatabaseCount('user_matches', 1);

        $this->postJson("/api/v1/profiles/{$first->profile->public_id}/decision", ['decision' => 'like'])
            ->assertJsonPath('data.match_id', $matchId);
        $this->getJson('/api/v1/matches')->assertOk()
            ->assertJsonCount(1, 'data.matches')
            ->assertJsonPath('data.matches.0.profile.id', $first->profile->public_id);
    }

    public function test_participant_can_unmatch_idempotently_but_outsider_cannot(): void
    {
        [$first, $second] = $this->liveUsers();
        $ids = [$first->id, $second->id]; sort($ids);
        $match = \App\Models\UserMatch::query()->create([
            'first_user_id' => $ids[0], 'second_user_id' => $ids[1],
            'status' => 'active', 'matched_at' => now(),
        ]);
        $outsider = User::factory()->create(['status' => User::STATUS_ACTIVE]);
        Sanctum::actingAs($outsider);
        $this->deleteJson("/api/v1/matches/{$match->public_id}")->assertNotFound();

        Sanctum::actingAs($first);
        $this->deleteJson("/api/v1/matches/{$match->public_id}")
            ->assertOk()->assertJsonPath('data.status', 'unmatched');
        $this->deleteJson("/api/v1/matches/{$match->public_id}")->assertOk();
        $this->getJson('/api/v1/matches')->assertJsonCount(0, 'data.matches');
    }

    private function liveUsers(): array
    {
        $first = User::factory()->create(['status' => User::STATUS_ACTIVE]);
        $second = User::factory()->create(['status' => User::STATUS_ACTIVE]);
        UserProfile::factory()->for($first)->create(['profile_status' => 'live']);
        UserProfile::factory()->for($second)->create(['profile_status' => 'live']);
        return [$first->load('profile'), $second->load('profile')];
    }
}
