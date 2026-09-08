<?php

namespace App\Support\Privacy;

final class PhoneLookupHasher
{
    public function hash(string $phone): string
    {
        $normalized = preg_replace('/[^0-9+]/', '', trim($phone)) ?? '';

        return hash_hmac('sha256', $normalized, (string) config('app.key'));
    }
}
