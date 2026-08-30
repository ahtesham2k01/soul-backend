<?php

namespace App\Http\Controllers\Api\V1\Auth;

use App\Contracts\Auth\AppleTokenVerifier;
use App\Enums\Auth\SocialProvider;
use App\Http\Controllers\Controller;
use App\Http\Requests\Api\V1\Auth\AppleSignInRequest;
use App\Http\Resources\Api\V1\UserResource;
use App\Models\SocialAccount;
use App\Models\User;
use App\Support\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\DB;

class AppleSignInController extends Controller
{
    public function __invoke(
        AppleSignInRequest $request,
        AppleTokenVerifier $appleTokenVerifier,
    ): JsonResponse {
        $identity = $appleTokenVerifier->verify(
            identityToken: $request
                ->string('identity_token')
                ->toString(),
            rawNonce: $request
                ->string('raw_nonce')
                ->toString(),
        );

        if ($identity === null) {
            return ApiResponse::error(
                code: 'INVALID_APPLE_TOKEN',
                message: 'Apple authentication could not be verified.',
                status: 401,
            );
        }

        $deviceName = $request
            ->string('device_name')
            ->toString();

        $requestedLocale = $request->validated(
            'locale',
        );

        $displayName = $this->displayName(
            $request->validated('given_name'),
            $request->validated('family_name'),
        );

        return DB::transaction(
            function () use (
                $identity,
                $deviceName,
                $requestedLocale,
                $displayName,
                $request,
            ): JsonResponse {
                $socialAccount = SocialAccount::query()
                    ->where(
                        'provider',
                        SocialProvider::Apple,
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

                    $socialAttributes = [
                        'provider_email_verified' =>
                            $identity->emailVerified,
                    ];

                    if ($identity->email !== null) {
                        $socialAttributes['provider_email'] =
                            $identity->email;
                    }

                    $socialAccount->forceFill(
                        $socialAttributes,
                    )->save();
                } else {
                    if (
                        $identity->email === null
                        || ! $identity->emailVerified
                    ) {
                        return ApiResponse::error(
                            code: 'APPLE_EMAIL_REQUIRED',
                            message: 'Apple did not provide a verified email address for this new account.',
                            status: 422,
                            details: [
                                'suggested_action' =>
                                    'restart_apple_authorization',
                            ],
                        );
                    }

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
                            'name' => $displayName,
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

                    $existingAppleAccount = $user
                        ->socialAccounts()
                        ->where(
                            'provider',
                            SocialProvider::Apple,
                        )
                        ->lockForUpdate()
                        ->first();

                    if ($existingAppleAccount !== null) {
                        return ApiResponse::error(
                            code: 'APPLE_ACCOUNT_CONFLICT',
                            message: 'A different Apple account is already linked to this account.',
                            status: 409,
                        );
                    }

                    $user->socialAccounts()->create([
                        'provider' => SocialProvider::Apple,
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
                    'last_login_at' => now(),
                ];

                if (
                    $user->email_verified_at === null
                    && $identity->emailVerified
                ) {
                    $attributes['email_verified_at'] = now();
                }

                if (
                    $user->name === null
                    && $displayName !== null
                ) {
                    $attributes['name'] = $displayName;
                }

                if (is_string($requestedLocale)) {
                    $attributes['preferred_locale'] =
                        $requestedLocale;
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

    private function displayName(
        mixed $givenName,
        mixed $familyName,
    ): ?string {
        $parts = array_filter([
            is_string($givenName)
                ? trim($givenName)
                : null,
            is_string($familyName)
                ? trim($familyName)
                : null,
        ]);

        if ($parts === []) {
            return null;
        }

        return mb_substr(
            implode(
                ' ',
                $parts,
            ),
            0,
            255,
        );
    }
}
