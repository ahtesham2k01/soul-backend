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
        $event = StoreWebhookEvent::query()->firstOrCreate(['platform' => $platform, 'event_hash' => hash('sha256', $payload)], ['encrypted_payload' => $payload]);
        if ($event->wasRecentlyCreated) ProcessStoreWebhook::dispatch($event->id);
        return ApiResponse::success(['accepted' => true], status: 202);
    }
}
