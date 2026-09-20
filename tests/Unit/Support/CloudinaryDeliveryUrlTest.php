<?php

namespace Tests\Unit\Support;

use App\Support\Media\CloudinaryDeliveryUrl;
use Tests\TestCase;

class CloudinaryDeliveryUrlTest extends TestCase
{
    public function test_it_generates_a_public_delivery_url_with_safe_transformations(): void
    {
        config(['soul.media.cloudinary.cloud_name' => 'demo']);

        $url = app(CloudinaryDeliveryUrl::class)->forPublicImage('soul/users/example cover', 'jpg');

        $this->assertSame(
            'https://res.cloudinary.com/demo/image/upload/c_fill,g_auto,h_1600,q_auto,w_1200/soul/users/example%20cover.jpg',
            $url,
        );
    }

    public function test_profile_delivery_respects_the_cloudinary_delivery_type(): void
    {
        config([
            'soul.media.cloudinary.cloud_name' => 'demo',
            'soul.media.cloudinary.api_secret' => 'abcd',
            'soul.media.cloudinary.response_signature_algorithm' => 'sha256',
        ]);

        $delivery = app(CloudinaryDeliveryUrl::class);

        $this->assertStringContainsString(
            '/image/upload/',
            $delivery->forProfileImage('soul/users/public', 'jpg', 'upload'),
        );
        $this->assertStringContainsString(
            '/image/authenticated/s--',
            $delivery->forProfileImage('soul/users/public-auth', 'jpg', 'authenticated'),
        );
    }

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
