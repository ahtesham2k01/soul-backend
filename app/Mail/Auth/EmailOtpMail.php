<?php

namespace App\Mail\Auth;

use App\Enums\Auth\EmailVerificationPurpose;
use App\Services\Auth\EmailOtpService;
use Illuminate\Bus\Queueable;
use Illuminate\Mail\Mailable;
use Illuminate\Mail\Mailables\Content;
use Illuminate\Mail\Mailables\Envelope;
use Illuminate\Queue\SerializesModels;

class EmailOtpMail extends Mailable
{
    use Queueable;
    use SerializesModels;

    public function __construct(
        public readonly string $code,
        public readonly EmailVerificationPurpose $purpose,
    ) {
    }

    /**
     * Get the message envelope.
     */
    public function envelope(): Envelope
    {
        return new Envelope(
            subject: 'Your SOUL verification code',
        );
    }

    /**
     * Get the message content definition.
     */
    public function content(): Content
    {
        return new Content(
            markdown: 'mail.auth.email-otp',
            with: [
                'code' => $this->code,
                'expiresInMinutes' => EmailOtpService::EXPIRES_AFTER_MINUTES,
                'actionText' => $this->actionText(),
            ],
        );
    }

    /**
     * Get the attachments for the message.
     *
     * @return array<int, mixed>
     */
    public function attachments(): array
    {
        return [];
    }

    private function actionText(): string
    {
        return match ($this->purpose) {
            EmailVerificationPurpose::Register => 'create your account',
            EmailVerificationPurpose::Login => 'log in to your account',
        };
    }
}
