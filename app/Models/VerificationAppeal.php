<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\Str;

class VerificationAppeal extends Model
{
    protected $fillable = ['user_id', 'statement', 'status', 'submitted_at', 'resolved_at'];
    protected static function booted(): void { static::creating(fn (self $appeal) => $appeal->public_id ??= (string) Str::ulid()); }
    protected function casts(): array { return ['submitted_at' => 'immutable_datetime', 'resolved_at' => 'immutable_datetime']; }
}
