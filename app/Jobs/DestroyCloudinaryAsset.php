<?php

namespace App\Jobs;

use App\Support\Media\CloudinaryUploadVerifier;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Queue\Queueable;
use Illuminate\Support\Facades\Http;
use RuntimeException;

class DestroyCloudinaryAsset implements ShouldQueue
{
    use Queueable;

    public int $tries = 5;

    /** @var array<int, int> */
    public array $backoff = [60, 300, 900, 3600];

    public function __construct(public readonly string $providerAssetId) {}

    public function handle(CloudinaryUploadVerifier $verifier): void
    {
        if (! $verifier->canSignUploads()) {
            throw new RuntimeException('Cloudinary is not configured for asset deletion.');
        }

        $timestamp = now()->timestamp;
        $cloudName = (string) config('soul.media.cloudinary.cloud_name');

        Http::asForm()
            ->timeout(15)
            ->post(sprintf(
                'https://api.cloudinary.com/v1_1/%s/image/destroy',
                rawurlencode($cloudName),
            ), [
                'api_key' => (string) config('soul.media.cloudinary.api_key'),
                'invalidate' => 'true',
                'public_id' => $this->providerAssetId,
                'timestamp' => $timestamp,
                'signature' => $verifier->signDestroy(
                    $this->providerAssetId,
                    $timestamp,
                ),
            ])
            ->throw();
    }
}
