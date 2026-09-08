<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class NotificationPreference extends Model
{
    protected $fillable = ['user_id', 'new_matches', 'new_messages', 'safety_updates', 'marketing', 'push_private_photos', 'push_verification', 'push_account', 'push_marketing', 'email_new_matches', 'email_new_messages', 'email_private_photos', 'email_verification', 'email_account', 'email_marketing', 'marketing_consented_at'];

    protected function casts(): array
    {
        return ['new_matches' => 'boolean', 'new_messages' => 'boolean', 'safety_updates' => 'boolean', 'marketing' => 'boolean', 'push_private_photos' => 'boolean', 'push_verification' => 'boolean', 'push_account' => 'boolean', 'push_marketing' => 'boolean', 'email_new_matches' => 'boolean', 'email_new_messages' => 'boolean', 'email_private_photos' => 'boolean', 'email_verification' => 'boolean', 'email_account' => 'boolean', 'email_marketing' => 'boolean', 'marketing_consented_at' => 'immutable_datetime'];
    }
}
