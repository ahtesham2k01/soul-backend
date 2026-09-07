<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class TranslationOverride extends Model
{
    protected $fillable = ['locale', 'key', 'value', 'is_active', 'updated_by_admin_id'];

    protected function casts(): array
    {
        return ['is_active' => 'boolean'];
    }
}
