<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasOne;
use Illuminate\Support\Str;

class ProfileVerificationCase extends Model
{
    protected $fillable = ['user_id', 'type', 'status', 'reason', 'submitted_at', 'reviewed_at'];
    public function appeal(): HasOne { return $this->hasOne(VerificationAppeal::class); }
    protected static function booted(): void { static::creating(fn (self $case) => $case->public_id ??= (string) Str::ulid()); }
    protected function casts(): array { return ['submitted_at' => 'immutable_datetime', 'reviewed_at' => 'immutable_datetime']; }
}
