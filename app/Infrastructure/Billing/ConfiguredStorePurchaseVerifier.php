<?php

namespace App\Infrastructure\Billing;

use App\Contracts\Billing\StorePurchaseVerifier;
use App\Support\Billing\VerifiedStorePurchase;
use App\Support\Providers\EcJwt;
use Carbon\CarbonImmutable;
use Google\Auth\Credentials\ServiceAccountCredentials;
use Illuminate\Support\Facades\Http;
use RuntimeException;

class ConfiguredStorePurchaseVerifier implements StorePurchaseVerifier
{
    public function verify(string $platform, string $productId, string $receipt): VerifiedStorePurchase
    {
        return match ($platform) {
            'android' => $this->verifyGoogle($productId, $receipt),
            'ios' => $this->verifyApple($productId, $receipt),
            default => throw new RuntimeException('Unsupported store platform.'),
        };
    }

    public function verifyWebhook(string $platform, string $payload): array
    {
        // Webhooks are provider notifications, never proof of ownership by themselves.
        // Decode only the provider reference, then re-query the signed provider API.
        $decoded = json_decode($payload, true, flags: JSON_THROW_ON_ERROR);
        if ($platform === 'android') {
            $message = json_decode(base64_decode((string) data_get($decoded, 'message.data'), true) ?: '', true, flags: JSON_THROW_ON_ERROR);
            $notice = $message['subscriptionNotification'] ?? null;
            if (! is_array($notice) || empty($notice['purchaseToken']) || empty($notice['subscriptionId'])) {
                throw new RuntimeException('Invalid Google subscription notification.');
            }
            return [$this->verifyGoogle($notice['subscriptionId'], $notice['purchaseToken'])];
        }

        // Apple Server Notifications V2 contains a signed transaction. We deliberately
        // require the transaction ID and verify it again against App Store Server API.
        $signedPayload = (string) ($decoded['signedPayload'] ?? '');
        $claims = $this->decodeJwtPayload($signedPayload);
        $signedTransaction = (string) data_get($claims, 'data.signedTransactionInfo', '');
        $transaction = $this->decodeJwtPayload($signedTransaction);
        $transactionId = (string) ($transaction['transactionId'] ?? '');
        $productId = (string) ($transaction['productId'] ?? '');
        if ($transactionId === '' || $productId === '') {
            throw new RuntimeException('Invalid Apple subscription notification.');
        }
        return [$this->verifyApple($productId, $transactionId)];
    }

    private function verifyGoogle(string $productId, string $purchaseToken): VerifiedStorePurchase
    {
        $json = config('services.stores.google.service_account_json');
        $package = config('services.stores.google.package_name');
        if (! is_string($json) || ! is_string($package) || $json === '' || $package === '') {
            throw new RuntimeException('Google Play verification is not configured.');
        }
        $credentials = new ServiceAccountCredentials('https://www.googleapis.com/auth/androidpublisher', json_decode($json, true, flags: JSON_THROW_ON_ERROR));
        $token = $credentials->fetchAuthToken()['access_token'] ?? null;
        if (! is_string($token)) throw new RuntimeException('Google Play authorization failed.');
        $response = Http::withToken($token)->acceptJson()->get('https://androidpublisher.googleapis.com/androidpublisher/v3/applications/'.rawurlencode($package).'/purchases/subscriptionsv2/tokens/'.rawurlencode($purchaseToken));
        if (! $response->successful()) throw new RuntimeException('Google Play receipt verification failed.');
        $data = $response->json();
        $line = collect($data['lineItems'] ?? [])->first(fn ($item) => ($item['productId'] ?? null) === $productId);
        if (! is_array($line)) throw new RuntimeException('Google Play product mismatch.');
        $state = (string) ($data['subscriptionState'] ?? '');
        $status = in_array($state, ['SUBSCRIPTION_STATE_ACTIVE', 'SUBSCRIPTION_STATE_IN_GRACE_PERIOD'], true) ? 'active' : 'inactive';
        return new VerifiedStorePurchase($productId, hash('sha256', $purchaseToken), null, $status, CarbonImmutable::parse($data['startTime'] ?? now()), isset($line['expiryTime']) ? CarbonImmutable::parse($line['expiryTime']) : null);
    }

    private function verifyApple(string $productId, string $transactionId): VerifiedStorePurchase
    {
        $token = $this->appleApiToken();
        $base = app()->isProduction() ? 'https://api.storekit.itunes.apple.com' : 'https://api.storekit-sandbox.itunes.apple.com';
        $response = Http::withToken($token)->acceptJson()->get($base.'/inApps/v1/transactions/'.rawurlencode($transactionId));
        if (! $response->successful()) throw new RuntimeException('Apple receipt verification failed.');
        $claims = $this->decodeJwtPayload((string) $response->json('signedTransactionInfo'));
        if (($claims['bundleId'] ?? null) !== config('services.stores.apple.bundle_id') || ($claims['productId'] ?? null) !== $productId) {
            throw new RuntimeException('Apple receipt product or application mismatch.');
        }
        $expires = isset($claims['expiresDate']) ? CarbonImmutable::createFromTimestampMs((int) $claims['expiresDate']) : null;
        return new VerifiedStorePurchase($productId, (string) $claims['transactionId'], $claims['originalTransactionId'] ?? null, $expires === null || $expires->isFuture() ? 'active' : 'expired', CarbonImmutable::createFromTimestampMs((int) ($claims['purchaseDate'] ?? now()->getTimestampMs())), $expires);
    }

    private function appleApiToken(): string
    {
        $issuer = (string) config('services.stores.apple.issuer_id'); $keyId = (string) config('services.stores.apple.key_id');
        $bundle = (string) config('services.stores.apple.bundle_id'); $key = str_replace('\\n', "\n", (string) config('services.stores.apple.private_key'));
        if ($issuer === '' || $keyId === '' || $bundle === '' || $key === '') throw new RuntimeException('Apple Store verification is not configured.');
        $now = time();
        return EcJwt::sign(['alg' => 'ES256', 'kid' => $keyId, 'typ' => 'JWT'], ['iss' => $issuer, 'iat' => $now, 'exp' => $now + 300, 'aud' => 'appstoreconnect-v1', 'bid' => $bundle], $key);
    }

    /** @return array<string,mixed> */
    private function decodeJwtPayload(string $jwt): array
    {
        $parts = explode('.', $jwt);
        if (count($parts) !== 3) throw new RuntimeException('Malformed signed provider payload.');
        $json = base64_decode(strtr($parts[1], '-_', '+/'), true);
        if ($json === false) throw new RuntimeException('Malformed signed provider payload.');
        return json_decode($json, true, flags: JSON_THROW_ON_ERROR);
    }
}
