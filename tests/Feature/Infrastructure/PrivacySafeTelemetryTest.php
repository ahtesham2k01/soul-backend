<?php

namespace Tests\Feature\Infrastructure;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Log;
use Tests\TestCase;

class PrivacySafeTelemetryTest extends TestCase
{
    use RefreshDatabase;

    public function test_request_log_uses_public_identity_instead_of_database_id(): void
    {
        $user = User::factory()->create();
        $user->forceFill(['status' => User::STATUS_ACTIVE])->save();
        Log::spy();

        $this->actingAs($user, 'sanctum')->getJson('/api/v1/auth/me')->assertOk();

        Log::shouldHaveReceived('info')->with('http_request', \Mockery::on(function (array $context) use ($user): bool {
            return $context['user_public_id'] === $user->public_id
                && ! array_key_exists('user_id', $context);
        }));
    }
}
