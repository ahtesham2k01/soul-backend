<?php

namespace App\Models;

use Database\Factories\ProfilePhotoUploadFactory;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Support\Str;

class ProfilePhotoUpload extends Model
{
    /** @use HasFactory<ProfilePhotoUploadFactory> */
    use HasFactory;

    protected $fillable = [
        'position',
        'provider_asset_id',
        'expires_at',
        'consumed_at',
    ];

    /** @return BelongsTo<User, $this> */
    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    protected static function booted(): void
    {
        static::creating(function (ProfilePhotoUpload $upload): void {
            $upload->public_id ??= (string) Str::ulid();
        });
    }

    /** @return array<string, string> */
    protected function casts(): array
    {
        return [
            'position' => 'integer',
            'expires_at' => 'immutable_datetime',
            'consumed_at' => 'immutable_datetime',
        ];
    }
}
