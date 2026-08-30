<?php

namespace App\Infrastructure\Auth;

use App\Contracts\Auth\GoogleTokenVerifier;
use App\Data\Auth\VerifiedGoogleIdentity;
use Google\Auth\AccessToken;
use Throwable;

final class GoogleAuthTokenVerifier implements GoogleTokenVerifier
{
    public function __construct(
        private readonly AccessToken $accessToken,
    ) {
    }

    public function verify(
        string $idToken,
    ): ?VerifiedGoogleIdentity {
        $clientIds = config(
            'services.google.client_ids',
            [],
        );

        if (
            trim($idToken) === ''
            || ! is_array($clientIds)
            || $clientIds === []
        ) {
            return null;
        }

        try {
            $payload = $this->accessToken->verify(
                $idToken,
                [
                    'throwException' => true,
                ],
            );
        } catch (Throwable) {
            return null;
        }

        if (! is_array($payload)) {
            return null;
        }

        $audience = $payload['aud'] ?? null;
        $subject = $payload['sub'] ?? null;

        if (
            ! is_string($audience)
            || ! $this->hasAllowedAudience(
                $audience,
                $clientIds,
            )
            || ! is_string($subject)
            || trim($subject) === ''
        ) {
            return null;
        }

        $email = $this->nullableString(
            $payload['email'] ?? null,
        );

        return new VerifiedGoogleIdentity(
            subject: trim($subject),
            email: $email === null
                ? null
                : mb_strtolower($email),
            emailVerified: filter_var(
                $payload['email_verified'] ?? false,
                FILTER_VALIDATE_BOOL,
            ),
            name: $this->nullableString(
                $payload['name'] ?? null,
            ),
            avatarUrl: $this->nullableString(
                $payload['picture'] ?? null,
            ),
        );
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
