<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Support\Str;

class SupportTicket extends Model
{
    protected $fillable = ['user_id', 'help_category_id', 'subject', 'status', 'priority', 'assigned_admin_id', 'last_message_at', 'closed_at'];

    protected static function booted(): void
    {
        static::creating(fn (self $ticket) => $ticket->public_id ??= (string) Str::ulid());
    }

    protected function casts(): array
    {
        return ['last_message_at' => 'immutable_datetime', 'closed_at' => 'immutable_datetime'];
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function category(): BelongsTo
    {
        return $this->belongsTo(HelpCategory::class, 'help_category_id');
    }

    public function messages(): HasMany
    {
        return $this->hasMany(SupportTicketMessage::class);
    }
}
