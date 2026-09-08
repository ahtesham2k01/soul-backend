<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Support\Str;

class SupportTicketAttachment extends Model
{
    protected $fillable = ['disk', 'path', 'original_name', 'mime_type', 'size_bytes', 'sha256'];

    protected $hidden = ['id', 'disk', 'path', 'sha256'];

    protected static function booted(): void
    {
        static::creating(fn (self $attachment) => $attachment->public_id ??= (string) Str::ulid());
    }

    public function message(): BelongsTo
    {
        return $this->belongsTo(SupportTicketMessage::class, 'support_ticket_message_id');
    }
}
