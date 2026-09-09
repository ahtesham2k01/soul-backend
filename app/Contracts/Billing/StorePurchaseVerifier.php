<?php

namespace App\Contracts\Billing;

use App\Support\Billing\VerifiedStorePurchase;

interface StorePurchaseVerifier
{
    public function verify(string $platform, string $productId, string $receipt): VerifiedStorePurchase;

    /** @return list<VerifiedStorePurchase> */
    public function verifyWebhook(string $platform, string $payload): array;
}
