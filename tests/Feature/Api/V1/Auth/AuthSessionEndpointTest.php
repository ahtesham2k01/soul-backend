<?php

namespace Tests\Feature\Api\V1\Auth;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class AuthSessionEndpointTest extends TestCase
{
    use RefreshDatabase;

    public function test_unauthenticated_user_cannot_access_current_user(): void
    {
        $response = $this->getJson(
            '/api/v1/auth/me',
        );

        $response
            ->assertUnauthorized()
            ->assertHeader('X-Request-ID')
            ->assertJsonPath(
                'success',
                false,
            )
            ->assertJsonPath(
                'error.code',
                'UNAUTHENTICATED',
            )
            ->assertJsonStructure([
                'meta' => [
                    'request_id',
                ],
            ]);
    }

    public function test_authenticated_user_can_load_current_session(): void
    {
        $user = User::factory()->create([
            'email' => 'current@example.com',
            'email_verified_at' => now(),
            'preferred_locale' => 'en',
            'status' => User::STATUS_ACTIVE,
            'onboarding_completed_at' => null,
        ]);

        $token = $user->createToken(
            name: 'Current Android',
            abilities: [
                'mobile',
            ],
            expiresAt: now()->addDays(90),
        )->plainTextToken;

        $response = $this
            ->withToken($token)
            ->getJson(
                '/api/v1/auth/me',
            );

        $response
            ->assertOk()
            ->assertJsonPath(
                'success',
                true,
            )
            ->assertJsonPath(
                'data.user.id',
                $user->public_id,
            )
            ->assertJsonPath(
                'data.user.email',
                'current@example.com',
            )
            ->assertJsonPath(
                'data.user.email_verified',
                true,
            )
            ->assertJsonPath(
                'data.user.status',
                User::STATUS_ACTIVE,
            )
            ->assertJsonPath(
                'data.user.onboarding_completed',
                false,
            )
            ->assertJsonPath(
                'data.next_step',
                'onboarding',
            );
    }

    public function test_completed_user_is_sent_to_home(): void
    {
        $user = User::factory()->create([
            'status' => User::STATUS_ACTIVE,
            'onboarding_completed_at' => now(),
        ]);

        $token = $user->createToken(
            name: 'Completed iPhone',
            abilities: [
                'mobile',
            ],
            expiresAt: now()->addDays(90),
        )->plainTextToken;

        $this
            ->withToken($token)
            ->getJson('/api/v1/auth/me')
            ->assertOk()
            ->assertJsonPath(
                'data.user.onboarding_completed',
                true,
            )
            ->assertJsonPath(
                'data.next_step',
                'home',
            );
    }

    public function test_logout_revokes_only_current_device_token(): void
    {
        $user = User::factory()->create([
            'status' => User::STATUS_ACTIVE,
        ]);

        $currentToken = $user->createToken(
            name: 'Current Device',
            abilities: [
                'mobile',
            ],
            expiresAt: now()->addDays(90),
        );

        $otherToken = $user->createToken(
            name: 'Other Device',
            abilities: [
                'mobile',
            ],
            expiresAt: now()->addDays(90),
        );

        $this->assertDatabaseCount(
            'personal_access_tokens',
            2,
        );

        $this
            ->withToken($currentToken->plainTextToken)
            ->postJson('/api/v1/auth/logout')
            ->assertOk()
            ->assertJsonPath(
                'success',
                true,
            )
            ->assertJsonPath(
                'message',
                'Logged out successfully.',
            );

        $this->assertDatabaseMissing(
            'personal_access_tokens',
            [
                'id' => $currentToken
                    ->accessToken
                    ->id,
            ],
        );

        $this->assertDatabaseHas(
            'personal_access_tokens',
            [
                'id' => $otherToken
                    ->accessToken
                    ->id,
            ],
        );

        $this->app['auth']->forgetGuards();

        $this
            ->withToken($currentToken->plainTextToken)
            ->getJson('/api/v1/auth/me')
            ->assertUnauthorized()
            ->assertJsonPath(
                'error.code',
                'UNAUTHENTICATED',
            );

        $this->app['auth']->forgetGuards();

        $this
            ->withToken($otherToken->plainTextToken)
            ->getJson('/api/v1/auth/me')
            ->assertOk()
            ->assertJsonPath(
                'data.user.id',
                $user->public_id,
            );
    }

    public function test_logout_all_revokes_every_device_token(): void
    {
        $user = User::factory()->create([
            'status' => User::STATUS_ACTIVE,
        ]);

        $currentToken = $user->createToken(
            name: 'Current Device',
            abilities: [
                'mobile',
            ],
            expiresAt: now()->addDays(90),
        );

        $user->createToken(
            name: 'Second Device',
            abilities: [
                'mobile',
            ],
            expiresAt: now()->addDays(90),
        );

        $user->createToken(
            name: 'Third Device',
            abilities: [
                'mobile',
            ],
            expiresAt: now()->addDays(90),
        );

        $this->assertDatabaseCount(
            'personal_access_tokens',
            3,
        );

        $this
            ->withToken($currentToken->plainTextToken)
            ->postJson('/api/v1/auth/logout-all')
            ->assertOk()
            ->assertJsonPath(
                'success',
                true,
            )
            ->assertJsonPath(
                'message',
                'Logged out from all devices successfully.',
            );

        $this->assertDatabaseCount(
            'personal_access_tokens',
            0,
        );
    }

    public function test_suspended_user_is_denied_with_valid_token(): void
    {
        $user = User::factory()->create([
            'status' => User::STATUS_SUSPENDED,
        ]);

        $token = $user->createToken(
            name: 'Suspended Device',
            abilities: [
                'mobile',
            ],
            expiresAt: now()->addDays(90),
        )->plainTextToken;

        $this
            ->withToken($token)
            ->getJson('/api/v1/auth/me')
            ->assertForbidden()
            ->assertJsonPath(
                'success',
                false,
            )
            ->assertJsonPath(
                'error.code',
                'ACCOUNT_UNAVAILABLE',
            );
    }

    public function test_expired_token_is_rejected(): void
    {
        $user = User::factory()->create([
            'status' => User::STATUS_ACTIVE,
        ]);

        $token = $user->createToken(
            name: 'Expired Device',
            abilities: [
                'mobile',
            ],
            expiresAt: now()->subMinute(),
        )->plainTextToken;

        $this
            ->withToken($token)
            ->getJson('/api/v1/auth/me')
            ->assertUnauthorized()
            ->assertJsonPath(
                'error.code',
                'UNAUTHENTICATED',
            );
    }
}
