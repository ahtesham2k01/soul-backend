<?php

namespace App\Http\Controllers\Api\V1\Auth;

use App\Enums\Auth\EmailVerificationPurpose;
use App\Http\Controllers\Controller;
use App\Http\Requests\Api\V1\Auth\LoginVerifyOtpRequest;
use App\Http\Resources\Api\V1\UserResource;
use App\Models\User;
use App\Services\Auth\EmailOtpService;
use App\Support\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\DB;

class LoginVerifyOtpController extends Controller
{
    public function __invoke(
        LoginVerifyOtpRequest $request,
        EmailOtpService $emailOtpService,
    ): JsonResponse {
        $email = $emailOtpService->normalizeEmail(
            $request->string('email')->toString(),
        );

        $verificationId = $request
            ->string('verification_id')
            ->toString();

        $plainCode = $request
            ->string('code')
            ->toString();

        $deviceName = $request
            ->string('device_name')
            ->toString();

        $requestedLocale = $request->validated(
            'locale',
        );

        return DB::transaction(
            function () use (
                $emailOtpService,
                $verificationId,
                $email,
                $plainCode,
                $deviceName,
                $requestedLocale,
                $request,
            ): JsonResponse {
                $verification = $emailOtpService->verify(
                    verificationId: $verificationId,
                    email: $email,
                    purpose: EmailVerificationPurpose::Login,
                    plainCode: $plainCode,
                );

                if ($verification === null) {
                    return ApiResponse::error(
                        code: 'INVALID_OR_EXPIRED_OTP',
                        message: 'The verification code is invalid or has expired.',
                        status: 422,
                    );
                }

                $user = User::query()
                    ->where('email', $email)
                    ->first();

                if ($user === null) {
                    return ApiResponse::error(
                        code: 'ACCOUNT_NOT_FOUND',
                        message: 'No account was found for this email.',
                        status: 404,
                        details: [
                            'suggested_action' => 'create_account',
                        ],
                    );
                }

                if ($user->status !== User::STATUS_ACTIVE) {
                    return ApiResponse::error(
                        code: 'ACCOUNT_UNAVAILABLE',
                        message: 'This account is currently unavailable.',
                        status: 403,
                    );
                }

                $attributes = [
                    'email_verified_at' => $user->email_verified_at
                        ?? now(),
                    'last_login_at' => now(),
                ];

                if (is_string($requestedLocale)) {
                    $attributes['preferred_locale'] = $requestedLocale;
                }

                $user->forceFill(
                    $attributes,
                )->save();

                $tokenExpiresAt = now()->addDays(90);

                $token = $user->createToken(
                    name: $deviceName,
                    abilities: [
                        'mobile',
                    ],
                    expiresAt: $tokenExpiresAt,
                );

                return ApiResponse::success(
                    data: [
                        'user' => (
                            new UserResource($user->refresh())
                        )->resolve($request),
                        'is_new_user' => false,
                        'next_step' => $user->onboarding_completed_at
                            === null
                                ? 'onboarding'
                                : 'home',
                        'authentication' => [
                            'token_type' => 'Bearer',
                            'access_token' => $token->plainTextToken,
                            'expires_at' => $tokenExpiresAt
                                ->toISOString(),
                        ],
                    ],
                    message: 'Signed in successfully.',
                );
            },
        );
    }
}
