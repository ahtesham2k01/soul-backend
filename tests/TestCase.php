<?php

namespace Tests;

use Illuminate\Foundation\Testing\TestCase as BaseTestCase;
use Illuminate\Support\Facades\Cache;

abstract class TestCase extends BaseTestCase
{
    protected function setUp(): void
    {
        parent::setUp();

        // Feature tests must not inherit rate-limit or other cache state from a
        // previous test when CI exercises the production-like Redis store.
        Cache::flush();
    }
}
