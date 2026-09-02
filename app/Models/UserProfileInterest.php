<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class UserProfileInterest extends Model
{
    protected $fillable = ['value'];

    public function userProfile(): BelongsTo
    {
        return $this->belongsTo(UserProfile::class);
    }
}
