<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class ProfileDecision extends Model
{
    protected $fillable = ['actor_user_id', 'target_user_id', 'decision'];
}
