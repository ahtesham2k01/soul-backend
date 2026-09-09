<?php

namespace App\Support\Billing;

use Carbon\CarbonImmutable;

final readonly class VerifiedStorePurchase
{
    public function __construct(
        public string $productId,
        public string $transactionId,
        public ?string $originalTransactionId,
        public string $status,
        public CarbonImmutable $startsAt,
        public ?CarbonImmutable $expiresAt,
    ) {}
}
