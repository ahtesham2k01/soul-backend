<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class LegalAcceptance extends Model
{
    protected $fillable = [
        'document_type', 'document_version', 'accepted_at',
        'ip_address', 'device_context_hash',
    ];

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    protected function casts(): array
    {
        return ['accepted_at' => 'immutable_datetime'];
    }
}
