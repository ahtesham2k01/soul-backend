<?php

namespace App\Models;

use App\Enums\Auth\EmailVerificationPurpose;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Attributes\Hidden;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\Str;

#[Fillable([
    'email_hash',
    'purpose',
    'code_hash',
    'expires_at',
])]
#[Hidden([
    'id',
    'email_hash',
    'code_hash',
])]
class EmailVerificationCode extends Model
{
    public const MAX_ATTEMPTS = 5;

    /**
     * Use public ULIDs for route model binding.
     */
    public function getRouteKeyName(): string
    {
        return 'public_id';
    }

    /**
     * Determine whether the OTP has expired.
     */
    public function isExpired(): bool
    {
        return $this->expires_at->isPast();
    }

    /**
     * Determine whether the OTP has already been used.
     */
    public function isConsumed(): bool
    {
        return $this->consumed_at !== null;
    }

    /**
     * Determine whether maximum verification attempts were reached.
     */
    public function hasTooManyAttempts(): bool
    {
        return $this->attempts >= self::MAX_ATTEMPTS;
    }

    /**
     * Determine whether this OTP can still be verified.
     */
    public function isUsable(): bool
    {
        return ! $this->isExpired()
            && ! $this->isConsumed()
            && ! $this->hasTooManyAttempts();
    }

    /**
     * Record an unsuccessful verification attempt.
     */
    public function recordFailedAttempt(): void
    {
        $this->increment('attempts');
        $this->refresh();
    }

    /**
     * Mark the OTP as successfully consumed.
     */
    public function markAsConsumed(): void
    {
        $this->forceFill([
            'consumed_at' => now(),
        ])->save();
    }

    /**
     * Automatically generate the public verification identifier.
     */
    protected static function booted(): void
    {
        static::creating(
            function (EmailVerificationCode $verification): void {
                if ($verification->public_id === null) {
                    $verification->public_id = (string) Str::ulid();
                }
            },
        );
    }

    /**
     * Get the attributes that should be cast.
     *
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'purpose' => EmailVerificationPurpose::class,
            'attempts' => 'integer',
            'expires_at' => 'datetime',
            'consumed_at' => 'datetime',
        ];
    }
}
