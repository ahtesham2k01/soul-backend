<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class NotificationDeliveryAttempt extends Model
{
    protected $fillable = [
        'user_notification_id', 'user_device_id', 'channel', 'provider',
        'deduplication_key', 'status', 'attempts', 'next_attempt_at', 'processing_started_at',
        'delivered_at', 'provider_message_id', 'failure_code',
    ];

    protected $hidden = ['id', 'user_notification_id', 'user_device_id', 'deduplication_key', 'provider_message_id'];

    protected function casts(): array
    {
        return ['next_attempt_at' => 'immutable_datetime', 'processing_started_at' => 'immutable_datetime', 'delivered_at' => 'immutable_datetime'];
    }

    public function notification(): BelongsTo { return $this->belongsTo(UserNotification::class, 'user_notification_id'); }
    public function device(): BelongsTo { return $this->belongsTo(UserDevice::class, 'user_device_id'); }
}
