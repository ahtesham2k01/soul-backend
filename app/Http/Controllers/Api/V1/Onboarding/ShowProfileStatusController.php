<?php

namespace App\Http\Controllers\Api\V1\Onboarding;

use App\Http\Controllers\Controller;
use App\Http\Resources\Api\V1\ProfileLifecycleResource;
use App\Support\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class ShowProfileStatusController extends Controller
{
    public function __invoke(Request $request): JsonResponse
    {
        $profile = $request->user()->profile;

        return ApiResponse::success(
            data: [
                'profile' => $profile === null
                    ? ['status' => 'draft']
                    : (new ProfileLifecycleResource($profile))->resolve($request),
            ],
            message: 'Profile lifecycle status loaded successfully.',
        );
    }
}
