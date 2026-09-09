<?php

namespace App\Infrastructure\Notifications;

use App\Contracts\Notifications\NotificationChannelSender;
use App\Models\NotificationDeliveryAttempt;
use App\Support\Providers\EcJwt;
use Google\Auth\Credentials\ServiceAccountCredentials;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Mail;
use RuntimeException;

class ConfiguredNotificationChannelSender implements NotificationChannelSender
{
    public function send(NotificationDeliveryAttempt $attempt): ?string
    {
        $attempt->loadMissing(['notification.user', 'device']);
        return match ($attempt->channel) {
            'email' => $this->email($attempt),
            'push' => $attempt->device?->platform === 'ios' ? $this->apns($attempt) : $this->fcm($attempt),
            default => throw new RuntimeException('Unsupported notification channel.'),
        };
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
        if ($json === '' || $project === '') throw new RuntimeException('FCM is not configured.');
        $credentials = new ServiceAccountCredentials('https://www.googleapis.com/auth/firebase.messaging', json_decode($json, true, flags: JSON_THROW_ON_ERROR));
        $token = $credentials->fetchAuthToken()['access_token'] ?? null;
        if (! is_string($token)) throw new RuntimeException('FCM authorization failed.');
        $data = $attempt->notification->data;
        $response = Http::withToken($token)->timeout(10)->post('https://fcm.googleapis.com/v1/projects/'.rawurlencode($project).'/messages:send', ['message' => ['token' => $attempt->device->push_token, 'notification' => ['title' => (string) ($data['title'] ?? 'SOUL'), 'body' => (string) ($data['body'] ?? $data['message'] ?? '')], 'data' => collect($data)->map(fn ($value) => is_scalar($value) ? (string) $value : json_encode($value, JSON_THROW_ON_ERROR))->all()]]);
        if (str_contains((string) $response->body(), 'UNREGISTERED')) { $attempt->device->update(['revoked_at' => now()]); throw new RuntimeException('Push token is no longer valid.'); }
        if (! $response->successful()) throw new RuntimeException('FCM delivery failed.');
        return $response->json('name');
    }

    private function apns(NotificationDeliveryAttempt $attempt): ?string
    {
        $team = (string) config('services.push.apns.team_id'); $keyId = (string) config('services.push.apns.key_id'); $bundle = (string) config('services.push.apns.bundle_id'); $key = str_replace('\\n', "\n", (string) config('services.push.apns.private_key'));
        if ($team === '' || $keyId === '' || $bundle === '' || $key === '') throw new RuntimeException('APNs is not configured.');
        $jwt = EcJwt::sign(['alg' => 'ES256', 'kid' => $keyId], ['iss' => $team, 'iat' => time()], $key); $data = $attempt->notification->data;
        $host = app()->isProduction() ? 'https://api.push.apple.com' : 'https://api.sandbox.push.apple.com';
        $response = Http::withToken($jwt)->timeout(10)->withHeaders(['apns-topic' => $bundle, 'apns-push-type' => 'alert'])->post($host.'/3/device/'.rawurlencode($attempt->device->push_token), ['aps' => ['alert' => ['title' => (string) ($data['title'] ?? 'SOUL'), 'body' => (string) ($data['body'] ?? $data['message'] ?? '')], 'sound' => 'default'], 'type' => $attempt->notification->type]);
        if (in_array($response->json('reason'), ['BadDeviceToken', 'DeviceTokenNotForTopic', 'Unregistered'], true)) $attempt->device->update(['revoked_at' => now()]);
        if (! $response->successful()) throw new RuntimeException('APNs delivery failed.');
        return $response->header('apns-id');
    }
}
