<?php

namespace App\Http\Controllers\Api\V1\Auth;

use App\Contracts\Auth\GoogleTokenVerifier;
use App\Enums\Auth\SocialProvider;
use App\Http\Controllers\Controller;
use App\Http\Requests\Api\V1\Auth\GoogleSignInRequest;
use App\Http\Resources\Api\V1\UserResource;
use App\Models\SocialAccount;
use App\Models\User;
use App\Support\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\DB;

class GoogleSignInController extends Controller
{
    public function __invoke(
        GoogleSignInRequest $request,
        GoogleTokenVerifier $googleTokenVerifier,
    ): JsonResponse {
        $identity = $googleTokenVerifier->verify(
            $request->string('id_token')->toString(),
        );

        if ($identity === null) {
            return ApiResponse::error(
                code: 'INVALID_GOOGLE_TOKEN',
                message: 'Google authentication could not be verified.',
                status: 401,
            );
        }

        if (
            $identity->email === null
            || ! $identity->emailVerified
        ) {
            return ApiResponse::error(
                code: 'GOOGLE_EMAIL_NOT_VERIFIED',
                message: 'A verified Google email address is required.',
                status: 422,
            );
        }

        $deviceName = $request
            ->string('device_name')
            ->toString();

        $requestedLocale = $request->validated(
            'locale',
        );

        return DB::transaction(
            function () use (
                $identity,
                $deviceName,
                $requestedLocale,
                $request,
            ): JsonResponse {
                $socialAccount = SocialAccount::query()
                    ->where(
                        'provider',
                        SocialProvider::Google,
                    )
                    ->where(
                        'provider_user_id',
                        $identity->subject,
                    )
                    ->lockForUpdate()
                    ->first();

                $isNewUser = false;

                if ($socialAccount !== null) {
                    $user = $socialAccount
                        ->user()
                        ->lockForUpdate()
                        ->firstOrFail();

                    $socialAccount->forceFill([
                        'provider_email' => $identity->email,
                        'provider_email_verified' => true,
                    ])->save();
                } else {
                    $user = User::query()
                        ->where(
                            'email',
                            $identity->email,
                        )
                        ->lockForUpdate()
                        ->first();

                    if ($user === null) {
                        $user = new User();

                        $user->forceFill([
                            'name' => $this->limitedName(
                                $identity->name,
                            ),
                            'email' => $identity->email,
                            'email_verified_at' => now(),
                            'preferred_locale' => is_string(
                                $requestedLocale,
                            )
                                ? $requestedLocale
                                : config(
                                    'soul.translations.fallback_locale',
                                    'en',
                                ),
                            'status' => User::STATUS_ACTIVE,
                        ])->save();

                        $isNewUser = true;
                    }

                    $existingGoogleAccount = $user
                        ->socialAccounts()
                        ->where(
                            'provider',
                            SocialProvider::Google,
                        )
                        ->lockForUpdate()
                        ->first();

                    if ($existingGoogleAccount !== null) {
                        return ApiResponse::error(
                            code: 'GOOGLE_ACCOUNT_CONFLICT',
                            message: 'A different Google account is already linked to this account.',
                            status: 409,
                        );
                    }

                    $user->socialAccounts()->create([
                        'provider' => SocialProvider::Google,
                        'provider_user_id' => $identity->subject,
                        'provider_email' => $identity->email,
                        'provider_email_verified' => true,
                    ]);
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

                if (
                    $user->name === null
                    && $identity->name !== null
                ) {
                    $attributes['name'] = $this->limitedName(
                        $identity->name,
                    );
                }

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
                            new UserResource(
                                $user->refresh(),
                            )
                        )->resolve($request),
                        'is_new_user' => $isNewUser,
                        'next_step' => $user->onboarding_completed_at
                            === null
                                ? 'onboarding'
                                : 'home',
                        'authentication' => [
                            'token_type' => 'Bearer',
                            'access_token' => $token
                                ->plainTextToken,
                            'expires_at' => $tokenExpiresAt
                                ->toISOString(),
                        ],
                    ],
                    message: $isNewUser
                        ? 'Account created successfully.'
                        : 'Signed in successfully.',
                );
            },
        );
    }

    private function limitedName(
        ?string $name,
    ): ?string {
        if ($name === null) {
            return null;
        }

        $name = trim($name);

        if ($name === '') {
            return null;
        }

        return mb_substr(
            $name,
            0,
            255,
        );
    }
}
