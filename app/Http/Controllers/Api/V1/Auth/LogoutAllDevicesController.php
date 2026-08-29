<?php

namespace App\Http\Controllers\Api\V1\Auth;

use App\Http\Controllers\Controller;
use App\Support\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class LogoutAllDevicesController extends Controller
{
    public function __invoke(
        Request $request,
    ): JsonResponse {
        $request
            ->user()
            ->tokens()
            ->delete();

        return ApiResponse::success(
            data: null,
            message: 'Logged out from all devices successfully.',
        );
    }
}
