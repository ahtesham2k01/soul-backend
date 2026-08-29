<?php

namespace App\Http\Controllers\Api\V1\Auth;

use App\Enums\Auth\EmailVerificationPurpose;
use App\Http\Controllers\Controller;
use App\Http\Requests\Api\V1\Auth\LoginRequestOtpRequest;
use App\Mail\Auth\EmailOtpMail;
use App\Services\Auth\EmailOtpService;
use App\Support\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\Mail;
use Throwable;

class LoginRequestOtpController extends Controller
{
    public function __invoke(
        LoginRequestOtpRequest $request,
        EmailOtpService $emailOtpService,
    ): JsonResponse {
        $email = $request->string('email')->toString();

        $issued = $emailOtpService->issue(
            email: $email,
            purpose: EmailVerificationPurpose::Login,
        );

        try {
            Mail::to($email)->send(
                new EmailOtpMail(
                    code: $issued->plainCode,
                    purpose: EmailVerificationPurpose::Login,
                ),
            );
        } catch (Throwable $exception) {
            $issued->verification->markAsConsumed();

            report($exception);

            return ApiResponse::error(
                code: 'OTP_DELIVERY_FAILED',
                message: 'We could not send the verification code. Please try again.',
                status: 503,
            );
        }

        return ApiResponse::success(
            data: [
                'verification_id' => $issued
                    ->verification
                    ->public_id,
                'expires_in_seconds' => EmailOtpService::EXPIRES_AFTER_MINUTES
                    * 60,
                'resend_after_seconds' => 60,
            ],
            message: 'If the email is valid, a verification code has been sent.',
            status: 202,
        );
    }
}
