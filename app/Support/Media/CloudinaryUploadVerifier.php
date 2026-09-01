<?php

namespace App\Support\Media;

class CloudinaryUploadVerifier
{
    public function isConfigured(): bool
    {
        return filled(config('soul.media.cloudinary.api_secret'));
    }

    public function verify(string $publicId, int $version, string $signature): bool
    {
        $secret = (string) config('soul.media.cloudinary.api_secret');
        $algorithm = (string) config(
            'soul.media.cloudinary.response_signature_algorithm',
            'sha1',
        );

        if ($secret === '' || ! in_array($algorithm, ['sha1', 'sha256'], true)) {
            return false;
        }

        $expected = hash(
            $algorithm,
            "public_id={$publicId}&version={$version}{$secret}",
        );

        return hash_equals($expected, strtolower($signature));
    }
}
