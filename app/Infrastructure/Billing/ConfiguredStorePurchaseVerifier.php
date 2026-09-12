<?php

namespace App\Infrastructure\Billing;

use App\Contracts\Billing\StorePurchaseVerifier;
use App\Support\Billing\VerifiedStorePurchase;
use App\Support\Billing\StoreProviderException;
use App\Support\Providers\EcJwt;
use App\Support\Providers\ProviderCircuitBreaker;
use Carbon\CarbonImmutable;
use Google\Auth\Credentials\ServiceAccountCredentials;
use Illuminate\Support\Facades\Http;
use Throwable;

class ConfiguredStorePurchaseVerifier implements StorePurchaseVerifier
{
    public function __construct(private readonly ProviderCircuitBreaker $breaker) {}

    public function verify(string $platform, string $productId, string $receipt): VerifiedStorePurchase
    {
        return $this->guarded($platform, fn (): VerifiedStorePurchase => match ($platform) {
            'android' => $this->verifyGoogle($productId, $receipt), 'ios' => $this->verifyApple($productId, $receipt),
            default => throw StoreProviderException::permanent('UNSUPPORTED_STORE_PLATFORM'),
        });
    }

    public function verifyWebhook(string $platform, string $payload): array
    {
        return $this->guarded($platform, fn (): array => $this->verifyWebhookPayload($platform, $payload));
    }

    private function verifyWebhookPayload(string $platform, string $payload): array
    {
        // Webhooks are provider notifications, never proof of ownership by themselves.
        // Decode only the provider reference, then re-query the signed provider API.
        $decoded = json_decode($payload, true, flags: JSON_THROW_ON_ERROR);
        if ($platform === 'android') {
            $message = json_decode(base64_decode((string) data_get($decoded, 'message.data'), true) ?: '', true, flags: JSON_THROW_ON_ERROR);
            $notice = $message['subscriptionNotification'] ?? null;
            if (! is_array($notice) || empty($notice['purchaseToken']) || empty($notice['subscriptionId'])) {
                throw StoreProviderException::permanent('MALFORMED_PROVIDER_NOTIFICATION');
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
            throw StoreProviderException::permanent('MALFORMED_PROVIDER_NOTIFICATION');
        }
        return [$this->verifyApple($productId, $transactionId)];
    }

    private function guarded(string $platform, callable $operation): mixed
    {
        $provider = 'store:'.$platform;
        if ($this->breaker->isOpen($provider)) throw StoreProviderException::transient('PROVIDER_CIRCUIT_OPEN');
        try {
            $result = $operation();
            $this->breaker->recordSuccess($provider);
            return $result;
        } catch (StoreProviderException $exception) {
            if ($exception->retryable) $this->breaker->recordTransientFailure($provider);
            throw $exception;
        }
    }

    private function verifyGoogle(string $productId, string $purchaseToken): VerifiedStorePurchase
    {
        $json = config('services.stores.google.service_account_json');
        $package = config('services.stores.google.package_name');
        if (! is_string($json) || ! is_string($package) || $json === '' || $package === '') {
            throw StoreProviderException::permanent('PROVIDER_NOT_CONFIGURED');
        }
        $credentials = new ServiceAccountCredentials('https://www.googleapis.com/auth/androidpublisher', json_decode($json, true, flags: JSON_THROW_ON_ERROR));
        $token = $credentials->fetchAuthToken()['access_token'] ?? null;
        if (! is_string($token)) throw StoreProviderException::transient('PROVIDER_AUTHORIZATION_FAILED');
        $response = Http::withToken($token)->acceptJson()->timeout(10)->get('https://androidpublisher.googleapis.com/androidpublisher/v3/applications/'.rawurlencode($package).'/purchases/subscriptionsv2/tokens/'.rawurlencode($purchaseToken));
        $this->guardResponse($response->status(), $response->serverError());
        $data = $response->json();
        $line = collect($data['lineItems'] ?? [])->first(fn ($item) => ($item['productId'] ?? null) === $productId);
        if (! is_array($line)) throw StoreProviderException::permanent('STORE_PRODUCT_MISMATCH');
        $state = (string) ($data['subscriptionState'] ?? '');
        $expires = isset($line['expiryTime']) ? CarbonImmutable::parse($line['expiryTime']) : null;
        $status = in_array($state, ['SUBSCRIPTION_STATE_ACTIVE', 'SUBSCRIPTION_STATE_IN_GRACE_PERIOD', 'SUBSCRIPTION_STATE_CANCELED'], true) && ($expires === null || $expires->isFuture()) ? 'active' : 'inactive';
        return new VerifiedStorePurchase($productId, hash('sha256', $purchaseToken), null, $status, CarbonImmutable::parse($data['startTime'] ?? now()), $expires);
    }

    private function verifyApple(string $productId, string $transactionId): VerifiedStorePurchase
    {
        $token = $this->appleApiToken();
        $base = app()->isProduction() ? 'https://api.storekit.itunes.apple.com' : 'https://api.storekit-sandbox.itunes.apple.com';
        $response = Http::withToken($token)->acceptJson()->timeout(10)->get($base.'/inApps/v1/transactions/'.rawurlencode($transactionId));
        $this->guardResponse($response->status(), $response->serverError());
        $claims = $this->decodeJwtPayload((string) $response->json('signedTransactionInfo'));
        if (($claims['bundleId'] ?? null) !== config('services.stores.apple.bundle_id') || ($claims['productId'] ?? null) !== $productId) {
            throw StoreProviderException::permanent('STORE_PRODUCT_MISMATCH');
        }
        $expires = isset($claims['expiresDate']) ? CarbonImmutable::createFromTimestampMs((int) $claims['expiresDate']) : null;
        $active = ! isset($claims['revocationDate']) && ($expires === null || $expires->isFuture());
        return new VerifiedStorePurchase($productId, (string) $claims['transactionId'], $claims['originalTransactionId'] ?? null, $active ? 'active' : 'expired', CarbonImmutable::createFromTimestampMs((int) ($claims['purchaseDate'] ?? now()->getTimestampMs())), $expires);
    }

    private function appleApiToken(): string
    {
        $issuer = (string) config('services.stores.apple.issuer_id'); $keyId = (string) config('services.stores.apple.key_id');
        $bundle = (string) config('services.stores.apple.bundle_id'); $key = str_replace('\\n', "\n", (string) config('services.stores.apple.private_key'));
        if ($issuer === '' || $keyId === '' || $bundle === '' || $key === '') throw StoreProviderException::permanent('PROVIDER_NOT_CONFIGURED');
        $now = time();
        return EcJwt::sign(['alg' => 'ES256', 'kid' => $keyId, 'typ' => 'JWT'], ['iss' => $issuer, 'iat' => $now, 'exp' => $now + 300, 'aud' => 'appstoreconnect-v1', 'bid' => $bundle], $key);
    }

    /** @return array<string,mixed> */
    private function decodeJwtPayload(string $jwt): array
    {
        $parts = explode('.', $jwt);
        if (count($parts) !== 3) throw StoreProviderException::permanent('MALFORMED_PROVIDER_NOTIFICATION');
        $json = base64_decode(strtr($parts[1], '-_', '+/'), true);
        if ($json === false) throw StoreProviderException::permanent('MALFORMED_PROVIDER_NOTIFICATION');
        try {
            return json_decode($json, true, flags: JSON_THROW_ON_ERROR);
        } catch (Throwable) {
            throw StoreProviderException::permanent('MALFORMED_PROVIDER_NOTIFICATION');
        }
    }

    private function guardResponse(int $status, bool $serverError): void
    {
        if ($status >= 200 && $status < 300) return;

        throw $status === 429 || $serverError
            ? StoreProviderException::transient('PROVIDER_TEMPORARILY_UNAVAILABLE')
            : StoreProviderException::permanent('PROVIDER_REQUEST_REJECTED');
    }
}
