<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class PrivatePhotoCaptureEvent extends Model
{
    protected $fillable = ['private_photo_access_request_id', 'profile_photo_id', 'owner_user_id', 'viewer_user_id', 'client_event_id', 'event_type', 'occurred_at'];

    protected function casts(): array
    {
        return ['occurred_at' => 'immutable_datetime'];
    }
}
