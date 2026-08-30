<?php

namespace Tests\Feature\Api\V1\Auth;

use App\Contracts\Auth\AppleTokenVerifier;
use App\Data\Auth\VerifiedAppleIdentity;
use App\Enums\Auth\SocialProvider;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class AppleSignInEndpointTest extends TestCase
{
    use RefreshDatabase;

    private const RAW_NONCE =
        '0123456789abcdef0123456789abcdef';

    public function test_apple_sign_in_creates_new_user_with_name(): void
    {
        $this->bindAppleIdentity(
            new VerifiedAppleIdentity(
                subject: 'apple-user-123',
                email: 'private@privaterelay.appleid.com',
                emailVerified: true,
                isPrivateEmail: true,
            ),
        );

        $response = $this->postJson(
            '/api/v1/auth/apple',
            [
                'identity_token' => 'valid-apple-token',
                'raw_nonce' => self::RAW_NONCE,
                'device_name' => 'iPhone 16 Pro',
                'given_name' => 'Syed Ahtesham',
                'family_name' => 'Shah',
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
                'Syed Ahtesham Shah',
            )
            ->assertJsonPath(
                'data.user.email',
                'private@privaterelay.appleid.com',
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
                'name' => 'Syed Ahtesham Shah',
                'email' =>
                    'private@privaterelay.appleid.com',
                'status' => User::STATUS_ACTIVE,
            ],
        );

        $this->assertDatabaseHas(
            'social_accounts',
            [
                'provider' => SocialProvider::Apple->value,
                'provider_user_id' => 'apple-user-123',
                'provider_email' =>
                    'private@privaterelay.appleid.com',
                'provider_email_verified' => true,
            ],
        );

        $this->assertDatabaseCount(
            'personal_access_tokens',
            1,
        );
    }

    public function test_returning_apple_user_can_sign_in_without_email(): void
    {
        $user = User::factory()->create([
            'name' => 'Existing Apple User',
            'email' => 'apple@example.com',
            'email_verified_at' => now(),
        ]);

        $user->socialAccounts()->create([
            'provider' => SocialProvider::Apple,
            'provider_user_id' => 'returning-apple-user',
            'provider_email' => 'apple@example.com',
            'provider_email_verified' => true,
        ]);

        $this->bindAppleIdentity(
            new VerifiedAppleIdentity(
                subject: 'returning-apple-user',
                email: null,
                emailVerified: false,
                isPrivateEmail: false,
            ),
        );

        $response = $this->postJson(
            '/api/v1/auth/apple',
            [
                'identity_token' =>
                    'returning-apple-token',
                'raw_nonce' => self::RAW_NONCE,
                'device_name' => 'iPhone',
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
            )
            ->assertJsonPath(
                'data.user.name',
                'Existing Apple User',
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

    public function test_verified_apple_email_links_to_existing_user(): void
    {
        $user = User::factory()->create([
            'name' => 'Existing User',
            'email' => 'existing@example.com',
            'email_verified_at' => now(),
        ]);

        $this->bindAppleIdentity(
            new VerifiedAppleIdentity(
                subject: 'new-apple-link',
                email: 'existing@example.com',
                emailVerified: true,
                isPrivateEmail: false,
            ),
        );

        $response = $this->postJson(
            '/api/v1/auth/apple',
            [
                'identity_token' => 'apple-link-token',
                'raw_nonce' => self::RAW_NONCE,
                'device_name' => 'iPhone',
                'given_name' => 'Different',
                'family_name' => 'Name',
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
                'provider' => SocialProvider::Apple->value,
                'provider_user_id' => 'new-apple-link',
            ],
        );
    }

    public function test_new_apple_identity_requires_verified_email(): void
    {
        $this->bindAppleIdentity(
            new VerifiedAppleIdentity(
                subject: 'apple-user-without-email',
                email: null,
                emailVerified: false,
                isPrivateEmail: false,
            ),
        );

        $response = $this->postJson(
            '/api/v1/auth/apple',
            [
                'identity_token' =>
                    'apple-token-without-email',
                'raw_nonce' => self::RAW_NONCE,
                'device_name' => 'iPhone',
            ],
        );

        $response
            ->assertUnprocessable()
            ->assertJsonPath(
                'error.code',
                'APPLE_EMAIL_REQUIRED',
            )
            ->assertJsonPath(
                'error.details.suggested_action',
                'restart_apple_authorization',
            );

        $this->assertDatabaseCount(
            'users',
            0,
        );
    }

    public function test_invalid_apple_token_is_rejected(): void
    {
        $this->bindAppleIdentity(
            null,
        );

        $response = $this->postJson(
            '/api/v1/auth/apple',
            [
                'identity_token' => 'invalid-apple-token',
                'raw_nonce' => self::RAW_NONCE,
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
                'INVALID_APPLE_TOKEN',
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

    public function test_suspended_apple_user_cannot_sign_in(): void
    {
        $user = User::factory()->create([
            'email' => 'suspended@example.com',
            'status' => User::STATUS_SUSPENDED,
        ]);

        $user->socialAccounts()->create([
            'provider' => SocialProvider::Apple,
            'provider_user_id' => 'suspended-apple-user',
            'provider_email' => 'suspended@example.com',
            'provider_email_verified' => true,
        ]);

        $this->bindAppleIdentity(
            new VerifiedAppleIdentity(
                subject: 'suspended-apple-user',
                email: null,
                emailVerified: false,
                isPrivateEmail: false,
            ),
        );

        $response = $this->postJson(
            '/api/v1/auth/apple',
            [
                'identity_token' =>
                    'suspended-apple-token',
                'raw_nonce' => self::RAW_NONCE,
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

    public function test_apple_sign_in_payload_is_validated(): void
    {
        $response = $this->postJson(
            '/api/v1/auth/apple',
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
                            'identity_token',
                            'raw_nonce',
                            'device_name',
                        ],
                    ],
                ],
            ]);
    }

    public function test_apple_sign_in_is_rate_limited(): void
    {
        $this->bindAppleIdentity(
            null,
        );

        for ($attempt = 1; $attempt <= 10; $attempt++) {
            $this->postJson(
                '/api/v1/auth/apple',
                [
                    'identity_token' =>
                        'invalid-apple-token-'.$attempt,
                    'raw_nonce' => self::RAW_NONCE,
                    'device_name' => 'Test iPhone',
                ],
            )->assertUnauthorized();
        }

        $this->postJson(
            '/api/v1/auth/apple',
            [
                'identity_token' =>
                    'rate-limited-apple-token',
                'raw_nonce' => self::RAW_NONCE,
                'device_name' => 'Test iPhone',
            ],
        )
            ->assertTooManyRequests()
            ->assertJsonPath(
                'error.code',
                'RATE_LIMIT_EXCEEDED',
            );
    }

    private function bindAppleIdentity(
        ?VerifiedAppleIdentity $identity,
    ): void {
        $this->app->instance(
            AppleTokenVerifier::class,
            new class($identity) implements AppleTokenVerifier
            {
                public function __construct(
                    private readonly ?VerifiedAppleIdentity $identity,
                ) {
                }

                public function verify(
                    string $identityToken,
                    string $rawNonce,
                ): ?VerifiedAppleIdentity {
                    return $this->identity;
                }
            },
        );
    }
}
