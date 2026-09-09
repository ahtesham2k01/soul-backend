<?php

namespace App\Http\Controllers\Api\V1\Subscriptions;

use App\Contracts\Billing\StorePurchaseVerifier;
use App\Http\Controllers\Controller;
use App\Models\StoreProduct;
use App\Models\StorePurchaseReceipt;
use App\Support\ApiResponse;
use App\Support\Billing\SubscriptionLifecycle;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Throwable;

class PurchaseController extends Controller
{
    public function store(Request $request, StorePurchaseVerifier $verifier, SubscriptionLifecycle $lifecycle): JsonResponse
    {
        $data = $request->validate(['product_id' => ['required', 'string', 'max:190'], 'platform' => ['required', 'in:ios,android'], 'receipt' => ['required', 'string', 'max:20000']]);
        $product = StoreProduct::query()->where('platform', $data['platform'])->where('product_id', $data['product_id'])->where('is_active', true)->first();
        if (! $product) return ApiResponse::error('PRODUCT_NOT_FOUND', 'Subscription product not found.', 404);
        $hash = hash('sha256', $data['platform'].'|'.$data['receipt']);
        $receipt = StorePurchaseReceipt::query()->firstOrCreate(['receipt_hash' => $hash], ['user_id' => $request->user()->id, 'store_product_id' => $product->id, 'platform' => $data['platform'], 'encrypted_receipt' => $data['receipt']]);
        if ($receipt->user_id !== $request->user()->id) return ApiResponse::error('PURCHASE_ALREADY_CLAIMED', 'This purchase is already linked to another account.', 409);

        try {
            $receipt->increment('attempts');
            $lifecycle->apply($receipt, $verifier->verify($data['platform'], $product->product_id, $data['receipt']));
        } catch (Throwable $exception) {
            $receipt->update(['status' => 'failed', 'failure_code' => 'PROVIDER_VERIFICATION_FAILED']);
            report($exception);
            return ApiResponse::error('PURCHASE_NOT_VERIFIED', 'The store could not verify this purchase.', 422);
        }
        return ApiResponse::success(['purchase' => ['id' => $receipt->public_id, 'status' => $receipt->status, 'expires_at' => $receipt->expires_at?->toIso8601String()]], 'Purchase verified.');
    }
}
