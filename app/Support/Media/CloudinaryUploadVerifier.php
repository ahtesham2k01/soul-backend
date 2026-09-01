<?php

namespace App\Support\Media;

final class CloudinaryUploadVerifier
{
    public function isConfigured(): bool
    {
        return filled(config('soul.media.cloudinary.api_secret'));
    }

    public function canSignUploads(): bool
    {
        return $this->isConfigured()
            && filled(config('soul.media.cloudinary.cloud_name'))
            && filled(config('soul.media.cloudinary.api_key'));
    }

    public function signUpload(string $publicId, int $timestamp): string
    {
        return $this->digest(
            "public_id={$publicId}&timestamp={$timestamp}",
        );
    }

    public function signDestroy(string $publicId, int $timestamp): string
    {
        return $this->digest(
            "invalidate=true&public_id={$publicId}&timestamp={$timestamp}",
        );
    }

    public function verify(string $publicId, int $version, string $signature): bool
    {
        if (! $this->isConfigured()) {
            return false;
        }

        $expected = $this->digest(
            "public_id={$publicId}&version={$version}",
        );

        return hash_equals($expected, strtolower($signature));
    }

    private function digest(string $payload): string
    {
        $secret = (string) config('soul.media.cloudinary.api_secret');
        $algorithm = (string) config(
            'soul.media.cloudinary.response_signature_algorithm',
            'sha1',
        );

        if ($secret === '' || ! in_array($algorithm, ['sha1', 'sha256'], true)) {
            return '';
        }

        return hash($algorithm, $payload.$secret);
    }
}
