<?php

namespace App\Http\Controllers\Api\V1\Subscriptions;

use App\Http\Controllers\Controller;
use App\Support\ApiResponse;
use App\Support\Entitlements\EntitlementResolver;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

class EntitlementController extends Controller
{
    public function __invoke(Request $request, EntitlementResolver $resolver): JsonResponse
    {
        $validated = $request->validate(['platform' => ['nullable', Rule::in(['ios', 'android'])]]);

        return ApiResponse::success(['capabilities' => $resolver->for($request->user(), $validated['platform'] ?? null)]);
    }
}
