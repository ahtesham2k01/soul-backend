<?php

namespace Tests\Feature\Infrastructure\Auth;

use App\Infrastructure\Auth\GoogleAuthTokenVerifier;
use Google\Auth\AccessToken;
use Mockery;
use RuntimeException;
use Tests\TestCase;

class GoogleAuthTokenVerifierTest extends TestCase
{
    public function test_valid_google_token_returns_trusted_identity(): void
    {
        config()->set(
            'services.google.client_ids',
            [
                'android-client-id',
                'web-client-id',
            ],
        );

        $accessToken = Mockery::mock(
            AccessToken::class,
        );

        $accessToken
            ->shouldReceive('verify')
            ->once()
            ->with(
                'valid-google-token',
                [
                    'throwException' => true,
                ],
            )
            ->andReturn([
                'aud' => 'web-client-id',
                'sub' => 'google-user-123',
                'email' => 'USER@GMAIL.COM',
                'email_verified' => true,
                'name' => 'Test User',
                'picture' => 'https://example.com/avatar.jpg',
            ]);

        $verifier = new GoogleAuthTokenVerifier(
            $accessToken,
        );

        $identity = $verifier->verify(
            'valid-google-token',
        );

        $this->assertNotNull($identity);
        $this->assertSame(
            'google-user-123',
            $identity->subject,
        );
        $this->assertSame(
            'user@gmail.com',
            $identity->email,
        );
        $this->assertTrue(
            $identity->emailVerified,
        );
        $this->assertSame(
            'Test User',
            $identity->name,
        );
        $this->assertSame(
            'https://example.com/avatar.jpg',
            $identity->avatarUrl,
        );
    }

    public function test_token_for_unapproved_client_is_rejected(): void
    {
        config()->set(
            'services.google.client_ids',
            [
                'approved-client-id',
            ],
        );

        $accessToken = Mockery::mock(
            AccessToken::class,
        );

        $accessToken
            ->shouldReceive('verify')
            ->once()
            ->andReturn([
                'aud' => 'different-client-id',
                'sub' => 'google-user-123',
            ]);

        $verifier = new GoogleAuthTokenVerifier(
            $accessToken,
        );

        $this->assertNull(
            $verifier->verify(
                'wrong-audience-token',
            ),
        );
    }

    public function test_invalid_google_token_is_rejected(): void
    {
        config()->set(
            'services.google.client_ids',
            [
                'approved-client-id',
            ],
        );

        $accessToken = Mockery::mock(
            AccessToken::class,
        );

        $accessToken
            ->shouldReceive('verify')
            ->once()
            ->andThrow(
                new RuntimeException(
                    'Invalid token.',
                ),
            );

        $verifier = new GoogleAuthTokenVerifier(
            $accessToken,
        );

        $this->assertNull(
            $verifier->verify(
                'invalid-google-token',
            ),
        );
    }

    public function test_token_is_rejected_when_no_client_ids_are_configured(): void
    {
        config()->set(
            'services.google.client_ids',
            [],
        );

        $accessToken = Mockery::mock(
            AccessToken::class,
        );

        $accessToken
            ->shouldNotReceive('verify');

        $verifier = new GoogleAuthTokenVerifier(
            $accessToken,
        );

        $this->assertNull(
            $verifier->verify(
                'google-token',
            ),
        );
    }
}
