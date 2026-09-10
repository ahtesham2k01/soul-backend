<?php

namespace Tests\Unit\Support;

use App\Support\Media\CloudinaryDeliveryUrl;
use Tests\TestCase;

class CloudinaryDeliveryUrlTest extends TestCase
{
    public function test_it_generates_an_authenticated_delivery_signature_without_exposing_secret(): void
    {
        config([
            'soul.media.cloudinary.cloud_name' => 'demo',
            'soul.media.cloudinary.api_secret' => 'abcd',
            'soul.media.cloudinary.response_signature_algorithm' => 'sha256',
        ]);

        $url = app(CloudinaryDeliveryUrl::class)->forAuthenticatedImage('sample-authenticated', 'png');

        $this->assertSame('https://res.cloudinary.com/demo/image/authenticated/s--PkHCb2Jt--/sample-authenticated.png', $url);
        $this->assertStringNotContainsString('abcd', $url);
    }
}
