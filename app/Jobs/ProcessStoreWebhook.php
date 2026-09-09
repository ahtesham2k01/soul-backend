<?php

namespace App\Jobs;

use App\Contracts\Billing\StorePurchaseVerifier;
use App\Models\StorePurchaseReceipt;
use App\Models\StoreWebhookEvent;
use App\Support\Billing\SubscriptionLifecycle;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;
use Throwable;

class ProcessStoreWebhook implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;
    public int $tries = 6;
    public array $backoff = [60, 300, 900, 3600, 10800];
    public function __construct(public int $eventId) {}
    public function handle(StorePurchaseVerifier $verifier, SubscriptionLifecycle $lifecycle): void
    {
        $event = StoreWebhookEvent::findOrFail($this->eventId);
        if ($event->status === 'processed') return;
        $event->increment('attempts');
        try {
            foreach ($verifier->verifyWebhook($event->platform, $event->encrypted_payload) as $purchase) {
                $receipt = StorePurchaseReceipt::query()->where('platform', $event->platform)->where(function ($q) use ($purchase) { $q->where('provider_transaction_id', $purchase->transactionId)->when($purchase->originalTransactionId, fn ($q) => $q->orWhere('provider_original_transaction_id', $purchase->originalTransactionId)); })->latest()->first();
                if ($receipt) $lifecycle->apply($receipt, $purchase);
            }
            $event->update(['status' => 'processed', 'processed_at' => now(), 'failure_code' => null]);
        } catch (Throwable $exception) {
            $event->update(['status' => 'failed', 'failure_code' => 'PROVIDER_VERIFICATION_FAILED']);
            throw $exception;
        }
    }
}
