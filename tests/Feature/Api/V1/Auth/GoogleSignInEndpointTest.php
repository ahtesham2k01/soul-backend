<?php

namespace Tests\Feature\Api\V1\Auth;

use App\Contracts\Auth\GoogleTokenVerifier;
use App\Data\Auth\VerifiedGoogleIdentity;
use App\Enums\Auth\SocialProvider;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class GoogleSignInEndpointTest extends TestCase
{
    use RefreshDatabase;

    public function test_google_sign_in_creates_a_new_user(): void
    {
        $this->bindGoogleIdentity(
            new VerifiedGoogleIdentity(
                subject: 'google-user-123',
                email: 'new-user@gmail.com',
                emailVerified: true,
                name: 'New Google User',
                avatarUrl: 'https://example.com/avatar.jpg',
            ),
        );

        $response = $this->postJson(
            '/api/v1/auth/google',
            [
                'id_token' => 'valid-google-token',
                'device_name' => 'iPhone 16 Pro',
                'locale' => 'en',
            ],
        );

        $response
            ->assertOk()
            ->assertHeader('X-Request-ID')
            ->assertJsonPath('success', true)
            ->assertJsonPath(
                'message',
                'Account created successfully.',
            )
            ->assertJsonPath(
                'data.user.name',
                'New Google User',
            )
            ->assertJsonPath(
                'data.user.email',
                'new-user@gmail.com',
            )
            ->assertJsonPath(
                'data.is_new_user',
                true,
            )
            ->assertJsonPath(
                'data.next_step',
                'onboarding',
            )
            ->assertJsonPath(
                'data.authentication.token_type',
                'Bearer',
            );

        $accessToken = $response->json(
            'data.authentication.access_token',
        );

        $this->assertIsString($accessToken);
        $this->assertStringContainsString(
            '|',
            $accessToken,
        );

        $this->assertDatabaseHas(
            'users',
            [
                'email' => 'new-user@gmail.com',
                'name' => 'New Google User',
                'status' => User::STATUS_ACTIVE,
            ],
        );

        $this->assertDatabaseHas(
            'social_accounts',
            [
                'provider' => SocialProvider::Google->value,
                'provider_user_id' => 'google-user-123',
                'provider_email' => 'new-user@gmail.com',
                'provider_email_verified' => true,
            ],
        );

        $this->assertDatabaseCount(
            'personal_access_tokens',
            1,
        );
    }

    public function test_returning_google_user_is_signed_in_without_duplication(): void
    {
        $user = User::factory()->create([
            'email' => 'returning@gmail.com',
            'email_verified_at' => now(),
        ]);

        $user->socialAccounts()->create([
            'provider' => SocialProvider::Google,
            'provider_user_id' => 'returning-google-user',
            'provider_email' => 'returning@gmail.com',
            'provider_email_verified' => true,
        ]);

        $this->bindGoogleIdentity(
            new VerifiedGoogleIdentity(
                subject: 'returning-google-user',
                email: 'returning@gmail.com',
                emailVerified: true,
                name: 'Returning User',
                avatarUrl: null,
            ),
        );

        $response = $this->postJson(
            '/api/v1/auth/google',
            [
                'id_token' => 'valid-returning-token',
                'device_name' => 'Pixel 10',
            ],
        );

        $response
            ->assertOk()
            ->assertJsonPath(
                'message',
                'Signed in successfully.',
            )
            ->assertJsonPath(
                'data.is_new_user',
                false,
            );

        $this->assertDatabaseCount(
            'users',
            1,
        );

        $this->assertDatabaseCount(
            'social_accounts',
            1,
        );

        $this->assertDatabaseCount(
            'personal_access_tokens',
            1,
        );
    }

    public function test_verified_google_email_links_to_existing_user(): void
    {
        $user = User::factory()->create([
            'name' => 'Existing User',
            'email' => 'existing@gmail.com',
            'email_verified_at' => now(),
        ]);

        $this->bindGoogleIdentity(
            new VerifiedGoogleIdentity(
                subject: 'new-google-link',
                email: 'existing@gmail.com',
                emailVerified: true,
                name: 'Google Name',
                avatarUrl: null,
            ),
        );

        $response = $this->postJson(
            '/api/v1/auth/google',
            [
                'id_token' => 'valid-link-token',
                'device_name' => 'Samsung Galaxy',
            ],
        );

        $response
            ->assertOk()
            ->assertJsonPath(
                'data.is_new_user',
                false,
            )
            ->assertJsonPath(
                'data.user.name',
                'Existing User',
            );

        $this->assertDatabaseCount(
            'users',
            1,
        );

        $this->assertDatabaseHas(
            'social_accounts',
            [
                'user_id' => $user->getKey(),
                'provider' => SocialProvider::Google->value,
                'provider_user_id' => 'new-google-link',
            ],
        );
    }

    public function test_invalid_google_token_is_rejected(): void
    {
        $this->bindGoogleIdentity(
            null,
        );

        $response = $this->postJson(
            '/api/v1/auth/google',
            [
                'id_token' => 'invalid-google-token',
                'device_name' => 'iPhone',
            ],
        );

        $response
            ->assertUnauthorized()
            ->assertJsonPath(
                'success',
                false,
            )
            ->assertJsonPath(
                'error.code',
                'INVALID_GOOGLE_TOKEN',
            );

        $this->assertDatabaseCount(
            'users',
            0,
        );

        $this->assertDatabaseCount(
            'personal_access_tokens',
            0,
        );
    }

    public function test_unverified_google_email_is_rejected(): void
    {
        $this->bindGoogleIdentity(
            new VerifiedGoogleIdentity(
                subject: 'unverified-google-user',
                email: 'unverified@gmail.com',
                emailVerified: false,
                name: 'Unverified User',
                avatarUrl: null,
            ),
        );

        $response = $this->postJson(
            '/api/v1/auth/google',
            [
                'id_token' => 'unverified-email-token',
                'device_name' => 'Android Phone',
            ],
        );

        $response
            ->assertUnprocessable()
            ->assertJsonPath(
                'error.code',
                'GOOGLE_EMAIL_NOT_VERIFIED',
            );

        $this->assertDatabaseCount(
            'users',
            0,
        );
    }

    public function test_suspended_google_user_cannot_sign_in(): void
    {
        $user = User::factory()->create([
            'email' => 'suspended@gmail.com',
            'status' => User::STATUS_SUSPENDED,
        ]);

        $user->socialAccounts()->create([
            'provider' => SocialProvider::Google,
            'provider_user_id' => 'suspended-google-user',
            'provider_email' => 'suspended@gmail.com',
            'provider_email_verified' => true,
        ]);

        $this->bindGoogleIdentity(
            new VerifiedGoogleIdentity(
                subject: 'suspended-google-user',
                email: 'suspended@gmail.com',
                emailVerified: true,
                name: 'Suspended User',
                avatarUrl: null,
            ),
        );

        $response = $this->postJson(
            '/api/v1/auth/google',
            [
                'id_token' => 'suspended-user-token',
                'device_name' => 'iPhone',
            ],
        );

        $response
            ->assertForbidden()
            ->assertJsonPath(
                'error.code',
                'ACCOUNT_UNAVAILABLE',
            );

        $this->assertDatabaseCount(
            'personal_access_tokens',
            0,
        );
    }

    public function test_google_sign_in_payload_is_validated(): void
    {
        $response = $this->postJson(
            '/api/v1/auth/google',
            [],
        );

        $response
            ->assertUnprocessable()
            ->assertJsonPath(
                'error.code',
                'VALIDATION_ERROR',
            )
            ->assertJsonStructure([
                'error' => [
                    'details' => [
                        'fields' => [
                            'id_token',
                            'device_name',
                        ],
                    ],
                ],
            ]);
    }

    public function test_google_sign_in_is_rate_limited(): void
    {
        $this->bindGoogleIdentity(
            null,
        );

        for ($attempt = 1; $attempt <= 10; $attempt++) {
            $this->postJson(
                '/api/v1/auth/google',
                [
                    'id_token' => 'invalid-token-' . $attempt,
                    'device_name' => 'Test Device',
                ],
            )->assertUnauthorized();
        }

        $this->postJson(
            '/api/v1/auth/google',
            [
                'id_token' => 'rate-limited-token',
                'device_name' => 'Test Device',
            ],
        )
            ->assertTooManyRequests()
            ->assertJsonPath(
                'error.code',
                'RATE_LIMIT_EXCEEDED',
            );
    }

    private function bindGoogleIdentity(
        ?VerifiedGoogleIdentity $identity,
    ): void {
        $this->app->instance(
            GoogleTokenVerifier::class,
            new class($identity) implements GoogleTokenVerifier
            {
                public function __construct(
                    private readonly ?VerifiedGoogleIdentity $identity,
                ) {}

                public function verify(
                    string $idToken,
                ): ?VerifiedGoogleIdentity {
                    return $this->identity;
                }
            },
        );
    }
}
