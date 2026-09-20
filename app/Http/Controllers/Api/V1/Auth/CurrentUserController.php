<?php

namespace App\Http\Controllers\Api\V1\Auth;

use App\Http\Controllers\Controller;
use App\Http\Resources\Api\V1\UserResource;
use App\Models\User;
use App\Support\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

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

    public function status(Request $request): JsonResponse
    {
        $user = $request->user();

        return ApiResponse::success([
            'status' => $user->status,
            'appeal_available' => $user->status === User::STATUS_BLOCKED,
            'deletion_scheduled' => $user->status === User::STATUS_DELETION_SCHEDULED,
        ]);
    }

    public function updatePreferences(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'preferred_locale' => [
                'required',
                'string',
                Rule::in(array_keys(config('soul.translations.locales', []))),
            ],
        ]);

        $request->user()->update([
            'preferred_locale' => $validated['preferred_locale'],
        ]);

        return ApiResponse::success(
            data: [
                'user' => (new UserResource($request->user()->fresh()))
                    ->resolve($request),
            ],
            message: 'Account preferences updated successfully.',
        );
    }
}
