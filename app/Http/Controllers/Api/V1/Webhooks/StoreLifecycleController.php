<?php

namespace App\Http\Controllers\Api\V1\Webhooks;

use App\Http\Controllers\Controller;
use App\Jobs\ProcessStoreWebhook;
use App\Models\StoreWebhookEvent;
use App\Support\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Cache;

class StoreLifecycleController extends Controller
{
    public function __invoke(Request $request, string $platform): JsonResponse
    {
        abort_unless(in_array($platform, ['ios', 'android'], true), 404);
        $payload = $request->getContent();
        abort_if($payload === '' || strlen($payload) > 100000, 400, 'Invalid webhook payload.');
        abort_unless($this->hasProviderShape($platform, $payload), 400, 'Invalid webhook payload.');
        $eventHash = hash('sha256', $payload);
        $existing = StoreWebhookEvent::query()->where(['platform' => $platform, 'event_hash' => $eventHash])->first();
        if ($existing !== null) return ApiResponse::success(['accepted' => true], status: 202);

        $event = Cache::lock('store-webhook-admission', 5)->block(2, function () use ($platform, $eventHash, $payload): StoreWebhookEvent {
            $existing = StoreWebhookEvent::query()->where(['platform' => $platform, 'event_hash' => $eventHash])->first();
            if ($existing !== null) return $existing;

            $limit = max(1, (int) config('soul.operations.store_webhook_backlog_limit', 10000));
            abort_if(
                StoreWebhookEvent::query()->whereIn('status', ['pending', 'processing'])->count() >= $limit,
                503,
                'Store webhook processing is temporarily at capacity.',
            );

            return StoreWebhookEvent::query()->create(['platform' => $platform, 'event_hash' => $eventHash, 'encrypted_payload' => $payload]);
        });
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
