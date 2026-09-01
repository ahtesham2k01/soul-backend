<?php

namespace App\Http\Controllers\Api\V1\Onboarding;

use App\Http\Controllers\Controller;
use App\Http\Resources\Api\V1\UserProfileDraftResource;
use App\Support\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class ShowProfileDraftController extends Controller
{
    public function __invoke(Request $request): JsonResponse
    {
        $profile = $request->user()
            ->profile()
            ->with(['intentions', 'spokenLanguages'])
            ->first();

        return ApiResponse::success(
            data: [
                'profile' => $profile === null
                    ? null
                    : (new UserProfileDraftResource($profile))
                        ->resolve($request),
            ],
            message: $profile === null
                ? 'Profile draft has not been started.'
                : 'Profile draft loaded successfully.',
        );
    }
}
