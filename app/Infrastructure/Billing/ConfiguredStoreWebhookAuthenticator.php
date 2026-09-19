<?php

namespace App\Infrastructure\Billing;

use App\Contracts\Billing\StoreWebhookAuthenticator;
use Firebase\JWT\JWK;
use Firebase\JWT\JWT;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Http;
use Throwable;

final class ConfiguredStoreWebhookAuthenticator implements StoreWebhookAuthenticator
{
    private const GOOGLE_ISSUERS = ['accounts.google.com', 'https://accounts.google.com'];

    public function authenticate(string $platform, Request $request): bool
    {
        return match ($platform) {
            'ios' => $this->authenticateApple($request),
            'android' => $this->authenticateGoogle($request),
            default => false,
        };
    }

    private function authenticateGoogle(Request $request): bool
    {
        $audience = trim((string) config('services.stores.google.pubsub_audience'));
        $serviceAccount = trim((string) config('services.stores.google.pubsub_service_account_email'));
        $token = trim((string) preg_replace('/^Bearer\\s+/i', '', (string) $request->header('Authorization')));

        if ($audience === '' || $serviceAccount === '' || $token === '' || ! str_starts_with((string) $request->header('Authorization'), 'Bearer ')) {
            return false;
        }

        try {
            $claims = (array) JWT::decode($token, JWK::parseKeySet($this->googlePublicKeys()));

            return in_array($claims['iss'] ?? null, self::GOOGLE_ISSUERS, true)
                && is_string($claims['aud'] ?? null)
                && hash_equals($audience, $claims['aud'])
                && is_string($claims['email'] ?? null)
                && hash_equals($serviceAccount, $claims['email'])
                && ($claims['email_verified'] ?? false) === true;
        } catch (Throwable) {
            return false;
        }
    }

    private function authenticateApple(Request $request): bool
    {
        $rootCertificate = str_replace('\\n', "\n", trim((string) config('services.stores.apple.notification_root_certificate')));
        $payload = $request->json('signedPayload');

        if ($rootCertificate === '' || ! is_string($payload) || count(explode('.', $payload)) !== 3) {
            return false;
        }

        try {
            [$header, $claims, $signature] = $this->jwsParts($payload);
            if (($header['alg'] ?? null) !== 'ES256' || ! is_array($header['x5c'] ?? null) || count($header['x5c']) < 2) {
                return false;
            }

            $chain = array_map(static fn (string $certificate): string => "-----BEGIN CERTIFICATE-----\n".chunk_split($certificate, 64, "\n")."-----END CERTIFICATE-----\n", array_slice($header['x5c'], 0, 3));
            if (! $this->isTrustedAppleChain($chain, $rootCertificate)) {
                return false;
            }

            $publicKey = openssl_pkey_get_public($chain[0]);
            if ($publicKey === false || openssl_verify($this->signingInput($payload), $this->derEncodeEs256Signature($signature), $publicKey, OPENSSL_ALGO_SHA256) !== 1) {
                return false;
            }

            return hash_equals((string) config('services.stores.apple.bundle_id'), (string) data_get($claims, 'data.bundleId', data_get($claims, 'bundleId', '')));
        } catch (Throwable) {
            return false;
        }
    }

    /** @return array<string, mixed> */
    private function googlePublicKeys(): array
    {
        return Cache::remember('stores.google.pubsub_public_keys', now()->addMinutes(15), static function (): array {
            $keys = Http::acceptJson()->timeout(5)->retry(2, 200)->get('https://www.googleapis.com/oauth2/v3/certs')->json();

            return is_array($keys) ? $keys : [];
        });
    }

    /** @return array{0: array<string,mixed>, 1: array<string,mixed>, 2: string} */
    private function jwsParts(string $jws): array
    {
        [$header, $claims, $signature] = explode('.', $jws);

        return [
            json_decode($this->base64UrlDecode($header), true, flags: JSON_THROW_ON_ERROR),
            json_decode($this->base64UrlDecode($claims), true, flags: JSON_THROW_ON_ERROR),
            $this->base64UrlDecode($signature),
        ];
    }

    /** @param array<int, string> $chain */
    private function isTrustedAppleChain(array $chain, string $rootCertificate): bool
    {
        $configuredRoot = openssl_x509_read($rootCertificate);
        $leaf = openssl_x509_read($chain[0] ?? '');
        $intermediate = openssl_x509_read($chain[1] ?? '');

        if ($configuredRoot === false || $leaf === false || $intermediate === false) {
            return false;
        }

        $rootKey = openssl_pkey_get_public($configuredRoot);
        $intermediateKey = openssl_pkey_get_public($intermediate);

        return $rootKey !== false && $intermediateKey !== false
            && openssl_x509_verify($intermediate, $rootKey) === 1
            && openssl_x509_verify($leaf, $intermediateKey) === 1;
    }

    private function signingInput(string $jws): string
    {
        return implode('.', array_slice(explode('.', $jws), 0, 2));
    }

    private function base64UrlDecode(string $value): string
    {
        $decoded = base64_decode(strtr($value, '-_', '+/'), true);
        if ($decoded === false) {
            throw new \RuntimeException('Invalid base64url value.');
        }

        return $decoded;
    }

    private function derEncodeEs256Signature(string $signature): string
    {
        if (strlen($signature) !== 64) {
            throw new \RuntimeException('Invalid ES256 signature.');
        }

        $r = ltrim(substr($signature, 0, 32), "\0");
        $s = ltrim(substr($signature, 32, 32), "\0");
        $r = (ord($r[0] ?? "\0") & 0x80) !== 0 ? "\0".$r : $r;
        $s = (ord($s[0] ?? "\0") & 0x80) !== 0 ? "\0".$s : $s;

        return "\x30".chr(strlen($r) + strlen($s) + 4)."\x02".chr(strlen($r)).$r."\x02".chr(strlen($s)).$s;
    }
}
