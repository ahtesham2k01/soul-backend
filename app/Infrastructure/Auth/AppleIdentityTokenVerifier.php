<?php

namespace App\Infrastructure\Auth;

use App\Contracts\Auth\AppleTokenVerifier;
use App\Data\Auth\VerifiedAppleIdentity;
use Firebase\JWT\JWK;
use Firebase\JWT\JWT;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Http;
use Throwable;

final class AppleIdentityTokenVerifier implements AppleTokenVerifier
{
    private const ISSUER = 'https://appleid.apple.com';

    private const PUBLIC_KEYS_URL =
        'https://appleid.apple.com/auth/keys';

    private const PUBLIC_KEYS_CACHE_KEY =
        'auth.apple.public_keys';

    public function verify(
        string $identityToken,
        string $rawNonce,
    ): ?VerifiedAppleIdentity {
        $clientIds = config(
            'services.apple.client_ids',
            [],
        );

        if (
            trim($identityToken) === ''
            || trim($rawNonce) === ''
            || ! is_array($clientIds)
            || $clientIds === []
        ) {
            return null;
        }

        try {
            $claims = (array) JWT::decode(
                $identityToken,
                JWK::parseKeySet(
                    $this->publicKeys(),
                ),
            );
        } catch (Throwable) {
            return null;
        }

        $issuer = $claims['iss'] ?? null;
        $audience = $claims['aud'] ?? null;
        $subject = $claims['sub'] ?? null;
        $nonce = $claims['nonce'] ?? null;

        $expectedNonce = hash(
            'sha256',
            $rawNonce,
        );

        if (
            ! is_string($issuer)
            || ! hash_equals(
                self::ISSUER,
                $issuer,
            )
            || ! is_string($audience)
            || ! $this->hasAllowedAudience(
                $audience,
                $clientIds,
            )
            || ! is_string($subject)
            || trim($subject) === ''
            || ! is_string($nonce)
            || ! hash_equals(
                $expectedNonce,
                $nonce,
            )
        ) {
            return null;
        }

        $email = $this->nullableString(
            $claims['email'] ?? null,
        );

        return new VerifiedAppleIdentity(
            subject: trim($subject),
            email: $email === null
                ? null
                : mb_strtolower($email),
            emailVerified: filter_var(
                $claims['email_verified'] ?? false,
                FILTER_VALIDATE_BOOL,
            ),
            isPrivateEmail: filter_var(
                $claims['is_private_email'] ?? false,
                FILTER_VALIDATE_BOOL,
            ),
        );
    }

    /**
     * @return array<string, mixed>
     */
    private function publicKeys(): array
    {
        $keys = Cache::remember(
            self::PUBLIC_KEYS_CACHE_KEY,
            now()->addMinutes(15),
            static function (): array {
                $response = Http::acceptJson()
                    ->timeout(5)
                    ->retry(
                        2,
                        200,
                    )
                    ->get(
                        self::PUBLIC_KEYS_URL,
                    )
                    ->throw();

                $keys = $response->json();

                if (! is_array($keys)) {
                    return [];
                }

                return $keys;
            },
        );

        return is_array($keys)
            ? $keys
            : [];
    }

    /**
     * @param array<int, mixed> $clientIds
     */
    private function hasAllowedAudience(
        string $audience,
        array $clientIds,
    ): bool {
        foreach ($clientIds as $clientId) {
            if (
                is_string($clientId)
                && hash_equals(
                    trim($clientId),
                    $audience,
                )
            ) {
                return true;
            }
        }

        return false;
    }

    private function nullableString(
        mixed $value,
    ): ?string {
        if (! is_string($value)) {
            return null;
        }

        $value = trim($value);

        return $value === ''
            ? null
            : $value;
    }
}
