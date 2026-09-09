<?php

namespace App\Models;

use App\Jobs\PrepareNotificationDeliveries;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Support\Str;

class UserNotification extends Model
{
    protected $fillable = ['user_id', 'broadcast_id', 'type', 'deduplication_key', 'data', 'delivery_channels', 'read_at'];

    protected static function booted(): void
    {
        static::creating(fn (self $x) => $x->public_id ??= (string) Str::ulid());
        static::created(fn (self $notification) => PrepareNotificationDeliveries::dispatch($notification->id)->afterCommit());
    }

    protected function casts(): array
    {
        return ['data' => 'array', 'delivery_channels' => 'array', 'read_at' => 'immutable_datetime'];
    }

    public function user(): BelongsTo { return $this->belongsTo(User::class); }
    public function deliveryAttempts(): HasMany { return $this->hasMany(NotificationDeliveryAttempt::class); }
}
