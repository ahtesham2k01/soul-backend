<?php

namespace Tests\Feature\Api\V1;

use App\Models\ProfileCatalogItem;
use App\Models\User;
use App\Models\UserProfile;
use Database\Seeders\ProfileAndSupportCatalogSeeder;
use Database\Seeders\SpokenLanguageSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class ProfileCatalogAndSupportEndpointTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        $this->seed(ProfileAndSupportCatalogSeeder::class);
        $this->seed(SpokenLanguageSeeder::class);
    }

    public function test_catalogs_are_localized_with_english_fallback(): void
    {
        $this->getJson('/api/v1/catalogs/profile?locale=ur')->assertOk()
            ->assertJsonFragment(['key' => 'reading', 'label' => 'Kitabein parhna'])
            ->assertJsonFragment(['key' => 'safety', 'name' => 'Safety aur reporting']);
        $this->getJson('/api/v1/catalogs/profile?locale=fr')->assertOk()
            ->assertJsonFragment(['key' => 'reading', 'label' => 'Reading']);

        $this->getJson('/api/v1/catalogs/profile')->assertOk()
            ->assertJsonStructure(['data' => ['spoken_languages' => [['code', 'name', 'native_name']]]]);
    }

    public function test_catalog_keys_round_trip_and_persist_catalog_relationships(): void
    {
        $member = User::factory()->create(['status' => User::STATUS_ACTIVE]);
        Sanctum::actingAs($member);

        $this->putJson('/api/v1/onboarding/profile', [
            'interests' => ['reading', 'travel'],
            'personality_traits' => ['kind'],
        ])->assertOk()
            ->assertJsonPath('data.profile.interests', ['reading', 'travel'])
            ->assertJsonPath('data.profile.personality_traits', ['kind']);

        $profile = $member->profile()->firstOrFail();
        $reading = ProfileCatalogItem::query()
            ->where('type', 'interest')
            ->where('key', 'reading')
            ->firstOrFail();
        $kind = ProfileCatalogItem::query()
            ->where('type', 'trait')
            ->where('key', 'kind')
            ->firstOrFail();

        $this->assertDatabaseHas('user_profile_interests', [
            'user_profile_id' => $profile->id,
            'profile_catalog_item_id' => $reading->id,
            'value' => 'Reading',
        ]);
        $this->assertDatabaseHas('user_profile_traits', [
            'user_profile_id' => $profile->id,
            'profile_catalog_item_id' => $kind->id,
            'value' => 'Kind',
        ]);

        $this->getJson('/api/v1/onboarding/profile')->assertOk()
            ->assertJsonPath('data.profile.interests', ['reading', 'travel'])
            ->assertJsonPath('data.profile.personality_traits', ['kind']);
    }

    public function test_public_profile_localizes_catalog_backed_values(): void
    {
        $viewer = User::factory()->create(['status' => User::STATUS_ACTIVE]);
        $candidate = User::factory()->create(['status' => User::STATUS_ACTIVE]);
        $profile = UserProfile::factory()->for($candidate)->create([
            'profile_status' => 'draft',
            'gender' => 'woman',
            'date_of_birth' => now()->subYears(30),
        ]);

        Sanctum::actingAs($candidate);
        $this->putJson('/api/v1/onboarding/profile', [
            'interests' => ['reading'],
            'personality_traits' => ['kind'],
        ])->assertOk();

        $profile->refresh()->update(['profile_status' => 'live']);

        Sanctum::actingAs($viewer);
        $this->withHeader('Accept-Language', 'ur')
            ->getJson('/api/v1/profiles/'.$profile->public_id)
            ->assertOk()
            ->assertJsonPath('data.profile.interests.0', 'Kitabein parhna')
            ->assertJsonPath('data.profile.personality_traits.0', 'Meharban');
    }

    public function test_member_can_open_reply_to_and_privately_read_own_ticket(): void
    {
        $member = User::factory()->create(['status' => User::STATUS_ACTIVE]);
        $other = User::factory()->create(['status' => User::STATUS_ACTIVE]);
        Sanctum::actingAs($member);
        $category = $this->getJson('/api/v1/catalogs/profile')->json('data.help_categories.0.id');
        $id = $this->postJson('/api/v1/support/tickets', ['category_id' => $category, 'subject' => 'Cannot update profile', 'message' => 'Please help me update my profile.'])
            ->assertCreated()->assertJsonPath('data.ticket.status', 'open')->json('data.ticket.id');
        $this->postJson("/api/v1/support/tickets/{$id}/replies", ['message' => 'Here is more context.'])->assertCreated();
        $this->getJson("/api/v1/support/tickets/{$id}")->assertOk()->assertJsonCount(2, 'data.ticket.messages');
        Sanctum::actingAs($other);
        $this->getJson("/api/v1/support/tickets/{$id}")->assertNotFound();
    }

    public function test_support_attachment_is_private_and_owner_authorized(): void
    {
        Storage::fake('local');
        $member = User::factory()->create(['status' => User::STATUS_ACTIVE]);
        $other = User::factory()->create(['status' => User::STATUS_ACTIVE]);
        Sanctum::actingAs($member);
        $category = $this->getJson('/api/v1/catalogs/profile')->json('data.help_categories.0.id');
        $id = $this->postJson('/api/v1/support/tickets', ['category_id' => $category, 'subject' => 'Screenshot attached', 'message' => 'The error is visible in my screenshot.'])->json('data.ticket.id');
        $attachment = $this->post('/api/v1/support/tickets/'.$id.'/attachments', ['file' => UploadedFile::fake()->createWithContent('error.pdf', '%PDF-1.4 safe test file')], ['Accept' => 'application/json'])
            ->assertCreated()->json('data.attachment.id');
        $this->get('/api/v1/support/attachments/'.$attachment)->assertOk();
        Sanctum::actingAs($other);
        $this->getJson('/api/v1/support/attachments/'.$attachment)->assertNotFound();
    }
}
