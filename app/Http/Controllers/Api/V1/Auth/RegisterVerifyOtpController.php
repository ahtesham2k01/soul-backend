<?php

namespace App\Http\Controllers\Api\V1\Auth;

use App\Enums\Auth\EmailVerificationPurpose;
use App\Http\Controllers\Controller;
use App\Http\Requests\Api\V1\Auth\RegisterVerifyOtpRequest;
use App\Http\Resources\Api\V1\UserResource;
use App\Models\User;
use App\Services\Auth\EmailOtpService;
use App\Support\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\DB;

class RegisterVerifyOtpController extends Controller
{
    public function __invoke(
        RegisterVerifyOtpRequest $request,
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

        $locale = $request->validated(
            'locale',
            'en',
        );

        return DB::transaction(
            function () use (
                $emailOtpService,
                $verificationId,
                $email,
                $plainCode,
                $deviceName,
                $locale,
                $request,
            ): JsonResponse {
                $verification = $emailOtpService->verify(
                    verificationId: $verificationId,
                    email: $email,
                    purpose: EmailVerificationPurpose::Register,
                    plainCode: $plainCode,
                );

                if ($verification === null) {
                    return ApiResponse::error(
                        code: 'INVALID_OR_EXPIRED_OTP',
                        message: 'The verification code is invalid or has expired.',
                        status: 422,
                    );
                }

                $user = User::query()->firstOrCreate(
                    [
                        'email' => $email,
                    ],
                    [
                        'preferred_locale' => $locale,
                    ],
                );

                $isNewUser = $user->wasRecentlyCreated;

                $user->refresh();

                if ($user->status !== User::STATUS_ACTIVE) {
                    return ApiResponse::error(
                        code: 'ACCOUNT_UNAVAILABLE',
                        message: 'This account is currently unavailable.',
                        status: 403,
                    );
                }

                $user->forceFill([
                    'email_verified_at' => $user->email_verified_at
                        ?? now(),
                    'preferred_locale' => $locale,
                    'last_login_at' => now(),
                ])->save();

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
                        'is_new_user' => $isNewUser,
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
                    message: $isNewUser
                        ? 'Account created successfully.'
                        : 'Signed in successfully.',
                    status: $isNewUser ? 201 : 200,
                );
            },
        );
    }
}
