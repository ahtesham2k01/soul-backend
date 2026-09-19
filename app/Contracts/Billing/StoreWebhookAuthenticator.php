<?php

namespace App\Contracts\Billing;

use Illuminate\Http\Request;

interface StoreWebhookAuthenticator
{
    /**
     * Verify that a callback was issued by the relevant store before it is
     * persisted or allowed to consume queue capacity.
     */
    public function authenticate(string $platform, Request $request): bool;
}
