<?php

namespace Tests\Feature\Infrastructure\Auth;

use App\Infrastructure\Auth\AppleIdentityTokenVerifier;
use Firebase\JWT\JWT;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Http;
use RuntimeException;
use Tests\TestCase;

class AppleIdentityTokenVerifierTest extends TestCase
{
    private const RAW_NONCE = 'test-raw-nonce';

    private string $privateKey;

    /**
     * @var array<string, string>
     */
    private array $publicJwk;

    protected function setUp(): void
    {
        parent::setUp();

        Cache::forget(
            'auth.apple.public_keys',
        );

        $key = openssl_pkey_new([
            'digest_alg' => 'sha256',
            'private_key_bits' => 2048,
            'private_key_type' => OPENSSL_KEYTYPE_RSA,
        ]);

        if ($key === false) {
            throw new RuntimeException(
                'Unable to create test RSA key.',
            );
        }

        $exported = openssl_pkey_export(
            $key,
            $privateKey,
        );

        if (! $exported) {
            throw new RuntimeException(
                'Unable to export test RSA key.',
            );
        }

        $details = openssl_pkey_get_details(
            $key,
        );

        if (
            $details === false
            || ! isset(
                $details['rsa']['n'],
                $details['rsa']['e'],
            )
        ) {
            throw new RuntimeException(
                'Unable to read test RSA public key.',
            );
        }

        $this->privateKey = $privateKey;

        $this->publicJwk = [
            'kty' => 'RSA',
            'kid' => 'test-apple-key',
            'use' => 'sig',
            'alg' => 'RS256',
            'n' => $this->base64UrlEncode(
                $details['rsa']['n'],
            ),
            'e' => $this->base64UrlEncode(
                $details['rsa']['e'],
            ),
        ];
    }

    public function test_valid_apple_token_returns_trusted_identity(): void
    {
        $this->configureAppleVerification();

        $identityToken = $this->createIdentityToken([
            'email' => 'USER@PRIVATERELAY.APPLEID.COM',
            'email_verified' => 'true',
            'is_private_email' => 'true',
        ]);

        $identity = (
            new AppleIdentityTokenVerifier()
        )->verify(
            $identityToken,
            self::RAW_NONCE,
        );

        $this->assertNotNull($identity);

        $this->assertSame(
            'apple-user-123',
            $identity->subject,
        );

        $this->assertSame(
            'user@privaterelay.appleid.com',
            $identity->email,
        );

        $this->assertTrue(
            $identity->emailVerified,
        );

        $this->assertTrue(
            $identity->isPrivateEmail,
        );

        Http::assertSentCount(1);
    }

    public function test_token_for_unapproved_apple_client_is_rejected(): void
    {
        $this->configureAppleVerification();

        $identityToken = $this->createIdentityToken([
            'aud' => 'com.example.different-app',
        ]);

        $this->assertNull(
            (
                new AppleIdentityTokenVerifier()
            )->verify(
                $identityToken,
                self::RAW_NONCE,
            ),
        );
    }

    public function test_token_with_invalid_issuer_is_rejected(): void
    {
        $this->configureAppleVerification();

        $identityToken = $this->createIdentityToken([
            'iss' => 'https://attacker.example.com',
        ]);

        $this->assertNull(
            (
                new AppleIdentityTokenVerifier()
            )->verify(
                $identityToken,
                self::RAW_NONCE,
            ),
        );
    }

    public function test_expired_apple_token_is_rejected(): void
    {
        $this->configureAppleVerification();

        $identityToken = $this->createIdentityToken([
            'iat' => now()
                ->subMinutes(10)
                ->timestamp,
            'exp' => now()
                ->subMinutes(5)
                ->timestamp,
        ]);

        $this->assertNull(
            (
                new AppleIdentityTokenVerifier()
            )->verify(
                $identityToken,
                self::RAW_NONCE,
            ),
        );
    }

    public function test_token_with_wrong_nonce_is_rejected(): void
    {
        $this->configureAppleVerification();

        $identityToken = $this->createIdentityToken();

        $this->assertNull(
            (
                new AppleIdentityTokenVerifier()
            )->verify(
                $identityToken,
                'different-raw-nonce',
            ),
        );
    }

    public function test_token_is_rejected_when_no_apple_client_ids_are_configured(): void
    {
        config()->set(
            'services.apple.client_ids',
            [],
        );

        Http::fake();

        $identityToken = $this->createIdentityToken();

        $this->assertNull(
            (
                new AppleIdentityTokenVerifier()
            )->verify(
                $identityToken,
                self::RAW_NONCE,
            ),
        );

        Http::assertNothingSent();
    }

    private function configureAppleVerification(): void
    {
        config()->set(
            'services.apple.client_ids',
            [
                'com.soul.app',
            ],
        );

        Http::fake([
            'https://appleid.apple.com/auth/keys' =>
                Http::response(
                    [
                        'keys' => [
                            $this->publicJwk,
                        ],
                    ],
                    200,
                ),
        ]);
    }

    /**
     * @param array<string, mixed> $overrides
     */
    private function createIdentityToken(
        array $overrides = [],
    ): string {
        $claims = array_merge(
            [
                'iss' => 'https://appleid.apple.com',
                'aud' => 'com.soul.app',
                'sub' => 'apple-user-123',
                'nonce' => hash(
                    'sha256',
                    self::RAW_NONCE,
                ),
                'iat' => now()->timestamp,
                'exp' => now()
                    ->addMinutes(5)
                    ->timestamp,
                'email' => 'user@example.com',
                'email_verified' => true,
                'is_private_email' => false,
            ],
            $overrides,
        );

        return JWT::encode(
            $claims,
            $this->privateKey,
            'RS256',
            'test-apple-key',
        );
    }

    private function base64UrlEncode(
        string $value,
    ): string {
        return rtrim(
            strtr(
                base64_encode($value),
                '+/',
                '-_',
            ),
            '=',
        );
    }
}
