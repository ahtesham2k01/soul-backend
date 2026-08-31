<?php

namespace App\Models;

use App\Enums\Profile\RelationshipIntention;
use Database\Factories\UserProfileIntentionFactory;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class UserProfileIntention extends Model
{
    /** @use HasFactory<UserProfileIntentionFactory> */
    use HasFactory;

    protected $fillable = [
        'intention',
    ];

    /** @return BelongsTo<UserProfile, $this> */
    public function userProfile(): BelongsTo
    {
        return $this->belongsTo(UserProfile::class);
    }

    /** @return array<string, string> */
    protected function casts(): array
    {
        return [
            'intention' => RelationshipIntention::class,
        ];
    }
}
