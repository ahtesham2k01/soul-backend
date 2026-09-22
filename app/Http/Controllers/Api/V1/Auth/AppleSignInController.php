<?php

namespace App\Http\Controllers\Api\V1\Auth;

use App\Contracts\Auth\AppleTokenVerifier;
use App\Enums\Auth\SocialProvider;
use App\Http\Controllers\Controller;
use App\Http\Requests\Api\V1\Auth\AppleSignInRequest;
use App\Http\Resources\Api\V1\UserResource;
use App\Models\SocialAccount;
use App\Models\User;
use App\Services\Auth\EmailOtpService;
use App\Services\Auth\MobileTokenIssuer;
use App\Support\ApiResponse;
use Illuminate\Database\UniqueConstraintViolationException;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\DB;

class AppleSignInController extends Controller
{
    public function __invoke(
        AppleSignInRequest $request,
        AppleTokenVerifier $appleTokenVerifier,
        EmailOtpService $emailOtpService,
        MobileTokenIssuer $tokenIssuer,
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

        $normalizedEmail = $identity->email === null
            ? null
            : $emailOtpService->normalizeEmail($identity->email);

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

        $authenticate = fn (): JsonResponse => DB::transaction(
            function () use (
                $identity,
                $normalizedEmail,
                $deviceName,
                $requestedLocale,
                $displayName,
                $request,
                $tokenIssuer,
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
                            $socialAccount->provider_email_verified
                            || $identity->emailVerified,
                    ];

                    if ($normalizedEmail !== null) {
                        $socialAttributes['provider_email'] =
                            $normalizedEmail;
                    }

                    $socialAccount->forceFill(
                        $socialAttributes,
                    )->save();
                } else {
                    if (
                        $normalizedEmail === null
                        || $normalizedEmail === ''
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

                    $user = User::query()->firstOrCreate(
                        ['email' => $normalizedEmail],
                        [
                            'name' => $displayName,
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

                    $existingAppleAccount = $user
                        ->socialAccounts()
                        ->where(
                            'provider',
                            SocialProvider::Apple,
                        )
                        ->lockForUpdate()
                        ->first();

                    if (
                        $existingAppleAccount !== null
                        && $existingAppleAccount->provider_user_id
                            !== $identity->subject
                    ) {
                        return ApiResponse::error(
                            code: 'APPLE_ACCOUNT_CONFLICT',
                            message: 'A different Apple account is already linked to this account.',
                            status: 409,
                        );
                    }

                    if ($existingAppleAccount !== null) {
                        $existingAppleAccount->forceFill([
                            'provider_email' => $normalizedEmail,
                            'provider_email_verified' => true,
                        ])->save();
                    } else {
                        $linkedAppleAccount = SocialAccount::query()
                            ->firstOrCreate(
                                [
                                    'provider' => SocialProvider::Apple,
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
                            $linkedAppleAccount->user_id
                            !== $user->getKey()
                        ) {
                            return ApiResponse::error(
                                code: 'APPLE_ACCOUNT_CONFLICT',
                                message: 'This Apple identity is already linked to another account.',
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
                    'last_login_at' => now(),
                ];

                if (
                    $user->email_verified_at === null
                    && $identity->emailVerified
                    && $normalizedEmail !== null
                    && is_string($user->email)
                    && strcasecmp($user->email, $normalizedEmail) === 0
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
