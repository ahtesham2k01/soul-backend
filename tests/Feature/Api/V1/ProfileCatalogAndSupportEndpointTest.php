<?php

namespace Tests\Feature\Api\V1;

use App\Models\User;
use Database\Seeders\ProfileAndSupportCatalogSeeder;
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
    }

    public function test_catalogs_are_localized_with_english_fallback(): void
    {
        $this->getJson('/api/v1/catalogs/profile?locale=ur')->assertOk()
            ->assertJsonFragment(['key' => 'reading', 'label' => 'Kitabein parhna'])
            ->assertJsonFragment(['key' => 'safety', 'name' => 'Safety aur reporting']);
        $this->getJson('/api/v1/catalogs/profile?locale=fr')->assertOk()
            ->assertJsonFragment(['key' => 'reading', 'label' => 'Reading']);
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
