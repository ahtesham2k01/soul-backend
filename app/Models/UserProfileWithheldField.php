<?php

namespace App\Models;

use App\Enums\Profile\ProfileOptionalField;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class UserProfileWithheldField extends Model
{
    protected $fillable = ['field'];

    public function userProfile(): BelongsTo
    {
        return $this->belongsTo(UserProfile::class);
    }

    protected function casts(): array
    {
        return ['field' => ProfileOptionalField::class];
    }
}
