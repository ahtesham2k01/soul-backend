<?php

namespace App\Jobs;

use App\Contracts\Billing\StorePurchaseVerifier;
use App\Models\StorePurchaseReceipt;
use App\Models\StoreWebhookEvent;
use App\Support\Billing\SubscriptionLifecycle;
use App\Support\Billing\StoreProviderException;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;
use Illuminate\Support\Facades\DB;
use Throwable;

class ProcessStoreWebhook implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;
    public int $tries = 6;
    public int $timeout = 45;
    public bool $failOnTimeout = true;
    public array $backoff = [60, 300, 900, 3600, 10800];
    public function __construct(public int $eventId) {}
    public function handle(StorePurchaseVerifier $verifier, SubscriptionLifecycle $lifecycle): void
    {
        $event = DB::transaction(function (): ?StoreWebhookEvent {
            $record = StoreWebhookEvent::query()->lockForUpdate()->find($this->eventId);
            if (! $record || ! in_array($record->status, ['pending', 'failed'], true)) return null;
            $record->update(['status' => 'processing', 'processing_started_at' => now(), 'attempts' => $record->attempts + 1]);
            return $record;
        });
        if (! $event) return;
        try {
            foreach ($verifier->verifyWebhook($event->platform, $event->encrypted_payload) as $purchase) {
                $receipt = StorePurchaseReceipt::query()->where('platform', $event->platform)->where(function ($q) use ($purchase) { $q->where('provider_transaction_id', $purchase->transactionId)->when($purchase->originalTransactionId, fn ($q) => $q->orWhere('provider_original_transaction_id', $purchase->originalTransactionId)); })->latest()->first();
                if ($receipt) $lifecycle->apply($receipt, $purchase);
            }
            $event->update(['status' => 'processed', 'encrypted_payload' => null, 'processing_started_at' => null, 'processed_at' => now(), 'failure_code' => null]);
        } catch (StoreProviderException $exception) {
            $event->update([
                'status' => 'failed',
                'processing_started_at' => null,
                'failure_code' => $exception->failureCode,
            ]);
            if ($exception->retryable) throw $exception;
            $event->update(['encrypted_payload' => null]);
        } catch (Throwable $exception) {
            $event->update(['status' => 'failed', 'processing_started_at' => null, 'failure_code' => 'PROVIDER_VERIFICATION_FAILED']);
            throw $exception;
        }
    }
}
