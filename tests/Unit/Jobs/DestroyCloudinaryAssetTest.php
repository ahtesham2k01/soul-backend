<?php

namespace Tests\Unit\Jobs;

use App\Jobs\DestroyCloudinaryAsset;
use App\Support\Media\CloudinaryUploadVerifier;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\Http;
use Tests\TestCase;

class DestroyCloudinaryAssetTest extends TestCase
{
    public function test_sends_signed_server_side_destroy_request_with_cdn_invalidation(): void
    {
        Carbon::setTestNow('2026-09-01 05:00:00');
        config()->set('soul.media.cloudinary.cloud_name', 'soul-test');
        config()->set('soul.media.cloudinary.api_key', 'test-key');
        config()->set('soul.media.cloudinary.api_secret', 'test-secret');
        config()->set('soul.media.cloudinary.response_signature_algorithm', 'sha1');
        Http::fake([
            'https://api.cloudinary.com/*' => Http::response(['result' => 'ok']),
        ]);

        $job = new DestroyCloudinaryAsset('soul/profile-photos/old');
        $job->handle(app(CloudinaryUploadVerifier::class));

        Http::assertSent(function ($request): bool {
            return $request->url() === 'https://api.cloudinary.com/v1_1/soul-test/image/destroy'
                && $request['api_key'] === 'test-key'
                && $request['invalidate'] === 'true'
                && $request['public_id'] === 'soul/profile-photos/old'
                && $request['timestamp'] === 1788238800
                && $request['signature'] === hash(
                    'sha1',
                    'invalidate=true&public_id=soul/profile-photos/old&timestamp=1788238800test-secret',
                );
        });
    }
}
