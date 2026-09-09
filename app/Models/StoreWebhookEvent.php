<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class StoreWebhookEvent extends Model
{
    protected $fillable = [
        'platform', 'event_hash', 'provider_event_id', 'event_type', 'encrypted_payload',
        'status', 'attempts', 'processing_started_at', 'processed_at', 'failure_code',
    ];

    protected $hidden = ['id', 'event_hash', 'encrypted_payload'];

    protected function casts(): array
    {
        return ['encrypted_payload' => 'encrypted', 'processing_started_at' => 'immutable_datetime', 'processed_at' => 'immutable_datetime'];
    }
}
