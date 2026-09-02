<?php

namespace App\Models;

use App\Enums\Profile\Gender;
use App\Enums\Profile\ProfileStatus;
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
        'religious_practice',
        'prayer',
        'diet',
        'dress',
        'detailed_religion_visible',
        'relocation_preference',
        'family_involvement_preference',
        'profile_status',
        'submitted_at',
        'checks_completed_at',
        'live_at',
        'status_reason',
        'correction_screen',
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

    /** @return HasMany<UserProfileInterest, $this> */
    public function interests(): HasMany
    {
        return $this->hasMany(UserProfileInterest::class)->orderBy('id');
    }

    /** @return HasMany<UserProfileTrait, $this> */
    public function personalityTraits(): HasMany
    {
        return $this->hasMany(UserProfileTrait::class)->orderBy('id');
    }

    /** @return HasMany<UserProfileWithheldField, $this> */
    public function withheldFields(): HasMany
    {
        return $this->hasMany(UserProfileWithheldField::class)->orderBy('field');
    }

    /** @return HasMany<ProfileStatusTransition, $this> */
    public function statusTransitions(): HasMany
    {
        return $this->hasMany(ProfileStatusTransition::class)->latest('id');
    }

    protected static function booted(): void
    {
        static::creating(function (UserProfile $profile): void {
            $profile->public_id ??= (string) Str::ulid();
        });

        static::updated(function (UserProfile $profile): void {
            if (! $profile->wasChanged('profile_status')) {
                return;
            }

            $profile->statusTransitions()->create([
                'actor_user_id' => auth()->id(),
                'from_status' => (string) $profile->getRawOriginal('profile_status'),
                'to_status' => $profile->profile_status->value,
                'source' => request()?->route()?->getName() ?? 'system',
                'reason' => $profile->status_reason,
                'correction_screen' => $profile->correction_screen,
            ]);
        });
    }

    /** @return array<string, string> */
    protected function casts(): array
    {
        return [
            'date_of_birth' => 'date',
            'gender' => Gender::class,
            'profile_status' => ProfileStatus::class,
            'height_cm' => 'integer',
            'detailed_religion_visible' => 'boolean',
            'submitted_at' => 'immutable_datetime',
            'checks_completed_at' => 'immutable_datetime',
            'live_at' => 'immutable_datetime',
        ];
    }
}
