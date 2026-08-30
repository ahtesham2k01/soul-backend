<?php

namespace App\Models;

use App\Enums\Auth\SocialProvider;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Attributes\Hidden;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

#[Fillable([
    'provider',
    'provider_user_id',
    'provider_email',
    'provider_email_verified',
])]
#[Hidden([
    'id',
    'user_id',
    'provider_user_id',
])]
class SocialAccount extends Model
{
    /**
     * Get the SOUL user that owns this social account.
     *
     * @return BelongsTo<User, $this>
     */
    public function user(): BelongsTo
    {
        return $this->belongsTo(
            User::class,
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
            'provider' => SocialProvider::class,
            'provider_email_verified' => 'boolean',
        ];
    }
}
