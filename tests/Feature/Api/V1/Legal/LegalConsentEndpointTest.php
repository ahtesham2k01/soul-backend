<?php

namespace Tests\Feature\Api\V1\Legal;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class LegalConsentEndpointTest extends TestCase
{
    use RefreshDatabase;

    public function test_member_can_accept_all_current_documents_with_private_evidence(): void
    {
        $user = User::factory()->create(['status' => User::STATUS_ACTIVE, 'preferred_locale' => 'ur']);
        Sanctum::actingAs($user);

        $this->getJson('/api/v1/legal/consent')->assertOk()
            ->assertJsonPath('data.legal.requires_acceptance', true)
            ->assertJsonCount(5, 'data.legal.commitment_keys');

        $this->withHeader('User-Agent', 'SOUL Flutter Test')->postJson('/api/v1/legal/consent', $this->payload())
            ->assertOk()->assertJsonPath('data.legal.requires_acceptance', false);

        $this->assertDatabaseCount('legal_acceptances', 4);
        $this->assertDatabaseHas('legal_acceptances', ['user_id' => $user->id, 'document_type' => 'community_guidelines', 'document_version' => '1.0', 'accepted_via' => 'settings_reconsent', 'locale' => 'ur']);
        $record = $user->legalAcceptances()->firstOrFail();
        $this->assertNotNull($record->ip_address);
        $this->assertSame(64, strlen((string) $record->device_context_hash));
        $this->getJson('/api/v1/legal/consent')->assertJsonMissingPath('data.legal.documents.0.ip_address')->assertJsonMissingPath('data.legal.documents.0.device_context_hash');
    }

    public function test_outdated_or_partial_acceptance_is_rejected_and_reconsent_is_idempotent(): void
    {
        $user = User::factory()->create(['status' => User::STATUS_ACTIVE]);
        Sanctum::actingAs($user);
        $payload = $this->payload();
        $payload['terms_version'] = '0.9';
        $this->postJson('/api/v1/legal/consent', $payload)->assertUnprocessable();
        $this->assertDatabaseCount('legal_acceptances', 0);

        $this->postJson('/api/v1/legal/consent', $this->payload())->assertOk();
        $this->postJson('/api/v1/legal/consent', $this->payload())->assertOk();
        $this->assertDatabaseCount('legal_acceptances', 4);
    }

    public function test_bootstrap_exposes_public_versions_and_authenticated_status(): void
    {
        $this->getJson('/api/v1/bootstrap')->assertOk()
            ->assertJsonPath('data.legal.versions.community_guidelines', '1.0')
            ->assertJsonCount(5, 'data.legal.commitment_keys');

        $user = User::factory()->create(['status' => User::STATUS_ACTIVE]);
        Sanctum::actingAs($user);
        $this->getJson('/api/v1/bootstrap')->assertJsonPath('data.legal.requires_acceptance', true);
    }

    private function payload(): array
    {
        return [
            'terms_accepted' => true, 'terms_version' => '1.0',
            'privacy_accepted' => true, 'privacy_version' => '1.0',
            'community_guidelines_accepted' => true, 'community_guidelines_version' => '1.0',
            'community_commitment_accepted' => true, 'community_commitment_version' => '1.0',
            'device_id' => 'test-device-id',
        ];
    }
}
