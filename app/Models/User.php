<?php

namespace App\Models;

use App\Support\Privacy\PhoneLookupHasher;
use Database\Factories\UserFactory;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Attributes\Hidden;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\HasOne;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Illuminate\Support\Str;
use Laravel\Sanctum\HasApiTokens;

#[Fillable([
    'name',
    'email',
    'phone',
    'password',
    'preferred_locale',
])]
#[Hidden([
    'id',
    'password',
    'remember_token',
])]
class User extends Authenticatable
{
    /** @use HasFactory<UserFactory> */
    use HasApiTokens;

    use HasFactory;
    use Notifiable;

    public const STATUS_ACTIVE = 'active';

    public const STATUS_SUSPENDED = 'suspended';

    public const STATUS_BLOCKED = 'blocked';

    /**
     * Get the social identities linked to this user.
     *
     * @return HasMany<SocialAccount, $this>
     */
    public function socialAccounts(): HasMany
    {
        return $this->hasMany(
            SocialAccount::class,
        );
    }

    /** @return HasOne<UserReligionProfile, $this> */
    public function religionProfile(): HasOne
    {
        return $this->hasOne(UserReligionProfile::class);
    }

    public function discoveryPreference(): HasOne
    {
        return $this->hasOne(DiscoveryPreference::class);
    }

    /** @return HasOne<UserProfile, $this> */
    public function profile(): HasOne
    {
        return $this->hasOne(UserProfile::class);
    }

    /** @return HasMany<ProfilePhotoUpload, $this> */
    public function profilePhotoUploads(): HasMany
    {
        return $this->hasMany(ProfilePhotoUpload::class);
    }

    /** @return HasMany<LegalAcceptance, $this> */
    public function legalAcceptances(): HasMany
    {
        return $this->hasMany(LegalAcceptance::class);
    }

    public function devices(): HasMany
    {
        return $this->hasMany(UserDevice::class);
    }

    public function notificationPreference(): HasOne
    {
        return $this->hasOne(NotificationPreference::class);
    }

    public function notifications(): HasMany
    {
        return $this->hasMany(UserNotification::class);
    }

    public function privacySetting(): HasOne
    {
        return $this->hasOne(AccountPrivacySetting::class);
    }

    public function dataExportRequests(): HasMany
    {
        return $this->hasMany(DataExportRequest::class);
    }

    public function deletionRequests(): HasMany
    {
        return $this->hasMany(AccountDeletionRequest::class);
    }

    public function hiddenContactHashes(): HasMany
    {
        return $this->hasMany(HiddenContactHash::class);
    }

    /**
     * Use public ULIDs for route model binding.
     */
    public function getRouteKeyName(): string
    {
        return 'public_id';
    }

    /**
     * Automatically generate the public user identifier.
     */
    protected static function booted(): void
    {
        static::creating(function (User $user): void {
            if ($user->public_id === null) {
                $user->public_id = (string) Str::ulid();
            }
            if ($user->phone !== null) {
                $user->phone_lookup_hash = app(PhoneLookupHasher::class)->hash($user->phone);
            }
        });

        static::updating(function (User $user): void {
            if ($user->isDirty('phone')) {
                $user->phone_lookup_hash = $user->phone === null ? null : app(PhoneLookupHasher::class)->hash($user->phone);
            }
        });
    }

    /**
     * Get the attributes that should be cast.
     *
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'email_verified_at' => 'datetime',
            'phone_verified_at' => 'datetime',
            'last_login_at' => 'datetime',
            'onboarding_completed_at' => 'datetime',
            'password' => 'hashed',
        ];
    }
}
