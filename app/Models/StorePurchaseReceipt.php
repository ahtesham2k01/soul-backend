<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\Str;

class StorePurchaseReceipt extends Model
{
    protected $fillable = [
        'user_id', 'store_product_id', 'platform', 'receipt_hash', 'encrypted_receipt',
        'status', 'provider_transaction_id', 'provider_original_transaction_id',
        'verified_at', 'expires_at', 'failure_code', 'attempts', 'next_attempt_at',
    ];

    protected $hidden = ['id', 'user_id', 'store_product_id', 'receipt_hash', 'encrypted_receipt'];

    protected static function booted(): void
    {
        static::creating(fn (self $receipt) => $receipt->public_id ??= (string) Str::ulid());
    }

    protected function casts(): array
    {
        return [
            'encrypted_receipt' => 'encrypted',
            'verified_at' => 'immutable_datetime',
            'expires_at' => 'immutable_datetime',
            'next_attempt_at' => 'immutable_datetime',
        ];
    }
}
