<?php

namespace App\Http\Controllers\Api\V1\Auth;

use App\Contracts\Auth\GoogleTokenVerifier;
use App\Enums\Auth\SocialProvider;
use App\Http\Controllers\Controller;
use App\Http\Requests\Api\V1\Auth\GoogleSignInRequest;
use App\Http\Resources\Api\V1\UserResource;
use App\Models\SocialAccount;
use App\Models\User;
use App\Services\Auth\EmailOtpService;
use App\Services\Auth\MobileTokenIssuer;
use App\Support\ApiResponse;
use Illuminate\Database\UniqueConstraintViolationException;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\DB;

class GoogleSignInController extends Controller
{
    public function __invoke(
        GoogleSignInRequest $request,
        GoogleTokenVerifier $googleTokenVerifier,
        EmailOtpService $emailOtpService,
        MobileTokenIssuer $tokenIssuer,
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

        $normalizedEmail = $emailOtpService->normalizeEmail(
            $identity->email,
        );

        $deviceName = $request
            ->string('device_name')
            ->toString();

        $requestedLocale = $request->validated(
            'locale',
        );

        $authenticate = fn (): JsonResponse => DB::transaction(
            function () use (
                $identity,
                $normalizedEmail,
                $deviceName,
                $requestedLocale,
                $request,
                $tokenIssuer,
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
                        'provider_email' => $normalizedEmail,
                        'provider_email_verified' => true,
                    ])->save();
                } else {
                    $user = User::query()->firstOrCreate(
                        ['email' => $normalizedEmail],
                        [
                            'name' => $this->limitedName(
                                $identity->name,
                            ),
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
                        ],
                    );

                    $isNewUser = $user->wasRecentlyCreated;

                    $user = User::query()
                        ->whereKey($user->getKey())
                        ->lockForUpdate()
                        ->firstOrFail();

                    if (! in_array($user->status, [
                        User::STATUS_ACTIVE,
                        User::STATUS_BLOCKED,
                        User::STATUS_DELETION_SCHEDULED,
                    ], true)) {
                        return ApiResponse::error(
                            code: 'ACCOUNT_UNAVAILABLE',
                            message: 'This account is currently unavailable.',
                            status: 403,
                        );
                    }

                    $existingGoogleAccount = $user
                        ->socialAccounts()
                        ->where(
                            'provider',
                            SocialProvider::Google,
                        )
                        ->lockForUpdate()
                        ->first();

                    if (
                        $existingGoogleAccount !== null
                        && $existingGoogleAccount->provider_user_id
                            !== $identity->subject
                    ) {
                        return ApiResponse::error(
                            code: 'GOOGLE_ACCOUNT_CONFLICT',
                            message: 'A different Google account is already linked to this account.',
                            status: 409,
                        );
                    }

                    if ($existingGoogleAccount !== null) {
                        $existingGoogleAccount->forceFill([
                            'provider_email' => $normalizedEmail,
                            'provider_email_verified' => true,
                        ])->save();
                    } else {
                        $linkedGoogleAccount = SocialAccount::query()
                            ->firstOrCreate(
                                [
                                    'provider' => SocialProvider::Google,
                                    'provider_user_id' =>
                                        $identity->subject,
                                ],
                                [
                                    'user_id' => $user->getKey(),
                                    'provider_email' => $normalizedEmail,
                                    'provider_email_verified' => true,
                                ],
                            );

                        if (
                            $linkedGoogleAccount->user_id
                            !== $user->getKey()
                        ) {
                            return ApiResponse::error(
                                code: 'GOOGLE_ACCOUNT_CONFLICT',
                                message: 'This Google identity is already linked to another account.',
                                status: 409,
                            );
                        }
                    }
                }

                if (! in_array($user->status, [
                    User::STATUS_ACTIVE,
                    User::STATUS_BLOCKED,
                    User::STATUS_DELETION_SCHEDULED,
                ], true)) {
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

                $token = $tokenIssuer->issue($user, $deviceName);

                return ApiResponse::success(
                    data: [
                        'user' => (
                            new UserResource(
                                $user->refresh(),
                            )
                        )->resolve($request),
                        'is_new_user' => $isNewUser,
                        'next_step' => match ($user->status) {
                            User::STATUS_BLOCKED => 'account_appeal',
                            User::STATUS_DELETION_SCHEDULED => 'deletion_recovery',
                            default => $user->onboarding_completed_at === null
                                ? 'onboarding'
                                : 'home',
                        },
                        'authentication' => [
                            'token_type' => 'Bearer',
                            'access_token' => $token
                                ->plainTextToken,
                            'expires_at' => $token->accessToken
                                ->expires_at?->toISOString(),
                        ],
                    ],
                    message: $isNewUser
                        ? 'Account created successfully.'
                        : 'Signed in successfully.',
                );
            },
        );
        try {
            return $authenticate();
        } catch (UniqueConstraintViolationException) {
            // A concurrent first sign-in may win a unique email/provider
            // insert. Retry once so the now-persisted identity is resolved
            // normally instead of surfacing a transient 500.
            return $authenticate();
        }

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
