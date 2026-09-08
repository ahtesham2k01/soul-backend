<?php

namespace App\Http\Controllers\Api\V1\Subscriptions;

use App\Http\Controllers\Controller;
use App\Models\StoreProduct;
use App\Support\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

class ProductController extends Controller
{
    public function __invoke(Request $request): JsonResponse
    {
        $v = $request->validate(['platform' => ['required', Rule::in(['ios', 'android'])], 'country_code' => ['nullable', 'string', 'size:2']]);
        $country = strtoupper($v['country_code'] ?? $request->user()->profile?->country_code ?? '');
        $products = StoreProduct::with('plan:id,public_id,key,name,description,trial_days')->where('platform', $v['platform'])->where('is_active', true)->whereHas('plan', fn ($q) => $q->where('status', 'active'))->where(fn ($q) => $q->whereNull('country_code')->orWhere('country_code', $country))->get();

        return ApiResponse::success(['products' => $products->map(fn ($x) => ['id' => $x->public_id, 'platform' => $x->platform, 'product_id' => $x->product_id, 'country_code' => $x->country_code, 'plan' => ['id' => $x->plan->public_id, 'key' => $x->plan->key, 'name' => $x->plan->name, 'description' => $x->plan->description, 'trial_days' => $x->plan->trial_days]])->values()]);
    }
}
