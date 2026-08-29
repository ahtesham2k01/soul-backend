<?php

namespace App\Http\Controllers\Api\V1\Auth;

use App\Http\Controllers\Controller;
use App\Http\Resources\Api\V1\UserResource;
use App\Support\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class CurrentUserController extends Controller
{
    public function __invoke(
        Request $request,
    ): JsonResponse {
        $user = $request->user();

        return ApiResponse::success(
            data: [
                'user' => (
                    new UserResource($user)
                )->resolve($request),
                'next_step' => $user->onboarding_completed_at
                    === null
                        ? 'onboarding'
                        : 'home',
            ],
            message: 'Current user loaded successfully.',
        );
    }
}
