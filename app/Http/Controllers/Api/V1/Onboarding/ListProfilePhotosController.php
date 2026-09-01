<?php

namespace App\Http\Controllers\Api\V1\Onboarding;

use App\Http\Controllers\Controller;
use App\Http\Resources\Api\V1\ProfilePhotoResource;
use App\Support\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class ListProfilePhotosController extends Controller
{
    /**
     * Handle the incoming request.
     */
    public function __invoke(Request $request): JsonResponse
    {
        $photos = $request->user()->profile?->photos()->get() ?? collect();

        return ApiResponse::success(
            data: [
                'photos' => ProfilePhotoResource::collection($photos)
                    ->resolve($request),
                'maximum_photos' => 3,
            ],
            message: 'Profile photos loaded successfully.',
        );
    }
}
