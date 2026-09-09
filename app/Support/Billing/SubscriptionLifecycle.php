<?php

namespace App\Support\Billing;

use App\Models\StoreProduct;
use App\Models\StorePurchaseReceipt;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;
use RuntimeException;

class SubscriptionLifecycle
{
    public function apply(StorePurchaseReceipt $receipt, VerifiedStorePurchase $purchase): void
    {
        $product = StoreProduct::query()->findOrFail($receipt->store_product_id);
        if ($product->product_id !== $purchase->productId || $product->platform !== $receipt->platform) {
            throw new RuntimeException('Verified purchase does not match the selected product.');
        }

        DB::transaction(function () use ($receipt, $product, $purchase): void {
            $status = $purchase->status === 'active' ? 'active' : 'expired';
            $identity = ['platform' => $receipt->platform, 'provider_transaction_id' => $purchase->originalTransactionId ?: $purchase->transactionId];
            $existing = DB::table('user_subscriptions')->where($identity)->first();
            $values = ['user_id' => $receipt->user_id, 'subscription_plan_id' => $product->subscription_plan_id, 'status' => $status, 'starts_at' => $purchase->startsAt, 'expires_at' => $purchase->expiresAt, 'updated_at' => now()];
            if ($existing) DB::table('user_subscriptions')->where('id', $existing->id)->update($values);
            else DB::table('user_subscriptions')->insert($identity + $values + ['public_id' => (string) Str::ulid(), 'created_at' => now()]);
            $receipt->update(['status' => $status, 'provider_transaction_id' => $purchase->transactionId, 'provider_original_transaction_id' => $purchase->originalTransactionId, 'verified_at' => now(), 'expires_at' => $purchase->expiresAt, 'failure_code' => null]);
        });
    }
}
