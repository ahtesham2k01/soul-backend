<?php

namespace App\Http\Controllers\Api\V1\Safety;

use App\Http\Controllers\Controller;
use App\Models\UserProfile;
use App\Support\ApiResponse;
use App\Support\Safety\CloseUserInteraction;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class BlockUserController extends Controller
{
    public function __invoke(Request $request, string $profile, CloseUserInteraction $closer): JsonResponse
    {
        $validated = $request->validate(['reason' => ['nullable', 'string', 'max:500']]);
        $target = UserProfile::query()->where('public_id', $profile)->first();
        if ($target === null || $target->user_id === $request->user()->id) {
            return ApiResponse::error('PROFILE_UNAVAILABLE', 'Profile unavailable.', 404);
        }
        DB::transaction(fn () => $closer->block($request->user()->id, $target->user_id, $validated['reason'] ?? null));

        return ApiResponse::success(['blocked' => true], 'User blocked successfully.');
    }
}
