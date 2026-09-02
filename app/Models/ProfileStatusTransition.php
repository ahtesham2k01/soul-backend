<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class ProfileStatusTransition extends Model
{
    public const UPDATED_AT = null;

    protected $fillable = [
        'actor_user_id', 'from_status', 'to_status', 'source',
        'reason', 'correction_screen',
    ];

    /** @return BelongsTo<UserProfile, $this> */
    public function profile(): BelongsTo
    {
        return $this->belongsTo(UserProfile::class, 'user_profile_id');
    }

    /** @return BelongsTo<User, $this> */
    public function actor(): BelongsTo
    {
        return $this->belongsTo(User::class, 'actor_user_id');
    }

    protected function casts(): array
    {
        return ['created_at' => 'immutable_datetime'];
    }
}
