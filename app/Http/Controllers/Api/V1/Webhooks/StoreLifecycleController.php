<?php

namespace App\Http\Controllers\Api\V1\Webhooks;

use App\Http\Controllers\Controller;
use App\Jobs\ProcessStoreWebhook;
use App\Models\StoreWebhookEvent;
use App\Support\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class StoreLifecycleController extends Controller
{
    public function __invoke(Request $request, string $platform): JsonResponse
    {
        abort_unless(in_array($platform, ['ios', 'android'], true), 404);
        $payload = $request->getContent();
        abort_if($payload === '' || strlen($payload) > 100000, 400, 'Invalid webhook payload.');
        abort_unless($this->hasProviderShape($platform, $payload), 400, 'Invalid webhook payload.');
        $event = StoreWebhookEvent::query()->firstOrCreate(['platform' => $platform, 'event_hash' => hash('sha256', $payload)], ['encrypted_payload' => $payload]);
        if ($event->wasRecentlyCreated) ProcessStoreWebhook::dispatch($event->id);
        return ApiResponse::success(['accepted' => true], status: 202);
    }

    private function hasProviderShape(string $platform, string $payload): bool
    {
        try {
            $data = json_decode($payload, true, flags: JSON_THROW_ON_ERROR);
            if ($platform === 'ios') {
                $signedPayload = $data['signedPayload'] ?? null;
                return is_string($signedPayload) && strlen($signedPayload) <= 50000 && count(explode('.', $signedPayload)) === 3;
            }
            $encoded = data_get($data, 'message.data');
            if (! is_string($encoded) || strlen($encoded) > 50000) return false;
            $decoded = base64_decode($encoded, true);
            if ($decoded === false) return false;
            $message = json_decode($decoded, true, flags: JSON_THROW_ON_ERROR);
            return filled(data_get($message, 'subscriptionNotification.purchaseToken'))
                && filled(data_get($message, 'subscriptionNotification.subscriptionId'));
        } catch (\Throwable) {
            return false;
        }
    }
}
