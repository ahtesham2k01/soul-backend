<?php

namespace App\Models;

use App\Enums\Profile\ProfilePhotoModerationStatus;
use App\Enums\Profile\ProfilePhotoVisibility;
use Database\Factories\ProfilePhotoFactory;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Support\Str;

class ProfilePhoto extends Model
{
    /** @use HasFactory<ProfilePhotoFactory> */
    use HasFactory;

    protected $fillable = [
        'position',
        'visibility',
        'storage_provider',
        'provider_asset_id',
        'moderation_status',
        'rejection_reason',
        'face_detected',
        'screenshot_protection_enabled',
    ];

    /** @return BelongsTo<UserProfile, $this> */
    public function userProfile(): BelongsTo
    {
        return $this->belongsTo(UserProfile::class);
    }

    protected static function booted(): void
    {
        static::creating(function (ProfilePhoto $photo): void {
            $photo->public_id ??= (string) Str::ulid();
        });
    }

    /** @return array<string, string> */
    protected function casts(): array
    {
        return [
            'position' => 'integer',
            'visibility' => ProfilePhotoVisibility::class,
            'moderation_status' => ProfilePhotoModerationStatus::class,
            'face_detected' => 'boolean',
            'screenshot_protection_enabled' => 'boolean',
        ];
    }
}
