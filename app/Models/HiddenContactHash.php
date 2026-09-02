<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class HiddenContactHash extends Model
{
    protected $fillable = ['phone_hash'];

    protected $hidden = ['id', 'user_id', 'phone_hash'];
}
