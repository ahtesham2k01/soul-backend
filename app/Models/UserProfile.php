<?php

namespace App\Models;

use App\Enums\Profile\Gender;
use Database\Factories\UserProfileFactory;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\BelongsToMany;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Support\Str;

class UserProfile extends Model
{
    /** @use HasFactory<UserProfileFactory> */
    use HasFactory;

    protected $fillable = [
        'first_name',
        'date_of_birth',
        'gender',
        'city_name',
        'country_code',
        'nationality_country_code',
        'marital_status',
        'profession_status',
        'smoking',
        'alcohol',
        'current_children',
        'future_children',
        'bio',
        'education',
        'height_cm',
        'job_title',
        'employer',
        'grew_up_in',
        'ethnic_origin',
        'relocation_preference',
        'family_involvement_preference',
    ];

    /** @return BelongsTo<User, $this> */
    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    /** @return BelongsToMany<SpokenLanguage, $this> */
    public function spokenLanguages(): BelongsToMany
    {
        return $this->belongsToMany(SpokenLanguage::class)
            ->withTimestamps();
    }

    /** @return HasMany<UserProfileIntention, $this> */
    public function intentions(): HasMany
    {
        return $this->hasMany(UserProfileIntention::class);
    }

    /** @return HasMany<ProfilePhoto, $this> */
    public function photos(): HasMany
    {
        return $this->hasMany(ProfilePhoto::class)
            ->orderBy('position');
    }

    protected static function booted(): void
    {
        static::creating(function (UserProfile $profile): void {
            $profile->public_id ??= (string) Str::ulid();
        });
    }

    /** @return array<string, string> */
    protected function casts(): array
    {
        return [
            'date_of_birth' => 'date',
            'gender' => Gender::class,
            'height_cm' => 'integer',
        ];
    }
}
