<?php

namespace Tests\Feature\Api\V1;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class LocalizedValidationEndpointTest extends TestCase
{
    use RefreshDatabase;

    public function test_api_validation_uses_requested_roman_urdu_locale(): void
    {
        Sanctum::actingAs(User::factory()->create(['status' => User::STATUS_ACTIVE]));

        $this->withHeader('Accept-Language', 'ur-PK')
            ->putJson('/api/v1/privacy/settings', ['show_age' => false])
            ->assertUnprocessable()
            ->assertJsonPath('error.message', 'Di hui information sahi nahi hai.')
            ->assertJsonPath('error.details.fields.show_age.0', 'show age ko accept karna zaroori hai.');
    }

    public function test_unsupported_locale_safely_uses_english_validation(): void
    {
        Sanctum::actingAs(User::factory()->create(['status' => User::STATUS_ACTIVE]));

        $this->withHeader('Accept-Language', 'xx-YY')
            ->putJson('/api/v1/privacy/settings', ['show_age' => false])
            ->assertUnprocessable()
            ->assertJsonPath('error.message', 'The submitted data is invalid.')
            ->assertJsonPath('error.details.fields.show_age.0', 'The show age field must be accepted.');
    }
}
