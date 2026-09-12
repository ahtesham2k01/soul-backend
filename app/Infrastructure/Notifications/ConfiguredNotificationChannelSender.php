<?php

namespace App\Infrastructure\Notifications;

use App\Contracts\Notifications\NotificationChannelSender;
use App\Models\NotificationDeliveryAttempt;
use App\Support\Notifications\NotificationProviderException;
use App\Support\Providers\EcJwt;
use App\Support\Providers\ProviderCircuitBreaker;
use Google\Auth\Credentials\ServiceAccountCredentials;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Mail;
use RuntimeException;

class ConfiguredNotificationChannelSender implements NotificationChannelSender
{
    public function __construct(private readonly ProviderCircuitBreaker $breaker) {}

    public function send(NotificationDeliveryAttempt $attempt): ?string
    {
        $attempt->loadMissing(['notification.user', 'device']);
        if ($attempt->channel === 'email') return $this->email($attempt);
        if ($attempt->channel !== 'push') throw new RuntimeException('Unsupported notification channel.');
        $provider = $attempt->device?->platform === 'ios' ? 'push:apns' : 'push:fcm';
        if (! $this->breaker->allowsRequest($provider)) throw NotificationProviderException::transient('PROVIDER_CIRCUIT_OPEN');
        try {
            $result = $attempt->device?->platform === 'ios' ? $this->apns($attempt) : $this->fcm($attempt);
            $this->breaker->recordSuccess($provider);
            return $result;
        } catch (NotificationProviderException $exception) {
            if ($exception->retryable) $this->breaker->recordTransientFailure($provider);
            else $this->breaker->recordSuccess($provider);
            throw $exception;
        }
    }

    private function email(NotificationDeliveryAttempt $attempt): ?string
    {
        $notification = $attempt->notification; $data = $notification->data;
        Mail::raw((string) ($data['body'] ?? $data['message'] ?? 'You have a new SOUL notification.'), fn ($message) => $message->to($notification->user->email)->subject((string) ($data['title'] ?? 'SOUL notification')));
        return null;
    }

    private function fcm(NotificationDeliveryAttempt $attempt): ?string
    {
        $json = (string) config('services.push.fcm.service_account_json'); $project = (string) config('services.push.fcm.project_id');
        if ($json === '' || $project === '') throw NotificationProviderException::permanent('PROVIDER_NOT_CONFIGURED');
        $credentials = new ServiceAccountCredentials('https://www.googleapis.com/auth/firebase.messaging', json_decode($json, true, flags: JSON_THROW_ON_ERROR));
        $token = $credentials->fetchAuthToken()['access_token'] ?? null;
        if (! is_string($token)) throw NotificationProviderException::transient('PROVIDER_AUTHORIZATION_FAILED');
        $data = $attempt->notification->data;
        $response = Http::withToken($token)->timeout(10)->post('https://fcm.googleapis.com/v1/projects/'.rawurlencode($project).'/messages:send', ['message' => ['token' => $attempt->device->push_token, 'notification' => ['title' => (string) ($data['title'] ?? 'SOUL'), 'body' => (string) ($data['body'] ?? $data['message'] ?? '')], 'data' => collect($data)->map(fn ($value) => is_scalar($value) ? (string) $value : json_encode($value, JSON_THROW_ON_ERROR))->all()]]);
        if (str_contains((string) $response->body(), 'UNREGISTERED')) {
            $attempt->device->update(['revoked_at' => now()]);
            throw NotificationProviderException::permanent('INVALID_DEVICE_TOKEN');
        }
        if (! $response->successful()) {
            throw $response->status() === 429 || $response->serverError()
                ? NotificationProviderException::transient('PROVIDER_TEMPORARILY_UNAVAILABLE')
                : NotificationProviderException::permanent('PROVIDER_REQUEST_REJECTED');
        }
        return $response->json('name');
    }

    private function apns(NotificationDeliveryAttempt $attempt): ?string
    {
        $team = (string) config('services.push.apns.team_id'); $keyId = (string) config('services.push.apns.key_id'); $bundle = (string) config('services.push.apns.bundle_id'); $key = str_replace('\\n', "\n", (string) config('services.push.apns.private_key'));
        if ($team === '' || $keyId === '' || $bundle === '' || $key === '') throw NotificationProviderException::permanent('PROVIDER_NOT_CONFIGURED');
        $jwt = EcJwt::sign(['alg' => 'ES256', 'kid' => $keyId], ['iss' => $team, 'iat' => time()], $key); $data = $attempt->notification->data;
        $host = app()->isProduction() ? 'https://api.push.apple.com' : 'https://api.sandbox.push.apple.com';
        $response = Http::withToken($jwt)->timeout(10)->withHeaders(['apns-topic' => $bundle, 'apns-push-type' => 'alert'])->post($host.'/3/device/'.rawurlencode($attempt->device->push_token), ['aps' => ['alert' => ['title' => (string) ($data['title'] ?? 'SOUL'), 'body' => (string) ($data['body'] ?? $data['message'] ?? '')], 'sound' => 'default'], 'type' => $attempt->notification->type]);
        if (in_array($response->json('reason'), ['BadDeviceToken', 'DeviceTokenNotForTopic', 'Unregistered'], true)) {
            $attempt->device->update(['revoked_at' => now()]);
            throw NotificationProviderException::permanent('INVALID_DEVICE_TOKEN');
        }
        if (! $response->successful()) {
            throw $response->status() === 429 || $response->serverError()
                ? NotificationProviderException::transient('PROVIDER_TEMPORARILY_UNAVAILABLE')
                : NotificationProviderException::permanent('PROVIDER_REQUEST_REJECTED');
        }
        return $response->header('apns-id');
    }
}
