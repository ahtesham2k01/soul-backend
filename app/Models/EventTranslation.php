<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class EventTranslation extends Model
{
    protected $fillable = ['locale', 'title', 'description'];
}
