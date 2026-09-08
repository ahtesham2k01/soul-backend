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

    public function test_user_can_list_active_device_sessions_with_current_device_marked(): void
    {
        $user = User::factory()->create(['status' => User::STATUS_ACTIVE]);
        $current = $user->createToken('Current Android', ['mobile'], now()->addDays(90));
        $other = $user->createToken('Other iPhone', ['mobile'], now()->addDays(30));
        $expired = $user->createToken('Expired tablet', ['mobile'], now()->subMinute());

        $response = $this->withToken($current->plainTextToken)
            ->getJson('/api/v1/auth/devices')
            ->assertOk()
            ->assertJsonCount(2, 'data.sessions')
            ->assertJsonMissing(['device_name' => 'Expired tablet']);

        $sessions = collect($response->json('data.sessions'));
        $this->assertTrue($sessions->firstWhere('device_name', 'Current Android')['is_current']);
        $this->assertFalse($sessions->firstWhere('device_name', 'Other iPhone')['is_current']);
        $this->assertSame($other->accessToken->public_id, $sessions->firstWhere('device_name', 'Other iPhone')['id']);
        $this->assertNotNull($expired->accessToken->public_id);
        $response->assertJsonMissingPath('data.sessions.0.token');
    }

    public function test_user_can_remotely_sign_out_one_owned_device_only(): void
    {
        $user = User::factory()->create(['status' => User::STATUS_ACTIVE]);
        $otherUser = User::factory()->create(['status' => User::STATUS_ACTIVE]);
        $current = $user->createToken('Current Android', ['mobile'], now()->addDays(90));
        $remote = $user->createToken('Remote iPhone', ['mobile'], now()->addDays(90));
        $foreign = $otherUser->createToken('Foreign device', ['mobile'], now()->addDays(90));

        $this->withToken($current->plainTextToken)
            ->deleteJson('/api/v1/auth/devices/'.$foreign->accessToken->public_id)
            ->assertNotFound()
            ->assertJsonPath('error.code', 'DEVICE_SESSION_NOT_FOUND');

        $this->withToken($current->plainTextToken)
            ->deleteJson('/api/v1/auth/devices/'.$remote->accessToken->public_id)
            ->assertOk()
            ->assertJsonPath('data.revoked', true)
            ->assertJsonPath('data.was_current', false);

        $this->assertDatabaseMissing('personal_access_tokens', ['id' => $remote->accessToken->id]);
        $this->assertDatabaseHas('personal_access_tokens', ['id' => $current->accessToken->id]);
        $this->assertDatabaseHas('personal_access_tokens', ['id' => $foreign->accessToken->id]);
    }

    public function test_deleting_current_device_session_immediately_invalidates_its_token(): void
    {
        $user = User::factory()->create(['status' => User::STATUS_ACTIVE]);
        $current = $user->createToken('Current Android', ['mobile'], now()->addDays(90));

        $this->withToken($current->plainTextToken)
            ->deleteJson('/api/v1/auth/devices/'.$current->accessToken->public_id)
            ->assertOk()
            ->assertJsonPath('data.was_current', true);

        $this->app['auth']->forgetGuards();
        $this->withToken($current->plainTextToken)
            ->getJson('/api/v1/auth/me')
            ->assertUnauthorized();
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
