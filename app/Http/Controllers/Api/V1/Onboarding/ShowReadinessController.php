<?php

namespace App\Http\Controllers\Api\V1\Onboarding;

use App\Http\Controllers\Controller;
use App\Support\ApiResponse;
use App\Support\Onboarding\ProfileReadiness;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class ShowReadinessController extends Controller
{
    /**
     * Handle the incoming request.
     */
    public function __invoke(Request $request, ProfileReadiness $readiness): JsonResponse
    {
        return ApiResponse::success(
            data: ['readiness' => $readiness->for($request->user())],
            message: 'Onboarding readiness loaded successfully.',
        );
    }
}
