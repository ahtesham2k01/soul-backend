<?php

namespace App\Support\Media;

final class CloudinaryDeliveryUrl
{
    public function forAuthenticatedImage(string $publicId, string $format): string
    {
        $cloudName = rawurlencode((string) config('soul.media.cloudinary.cloud_name'));
        $secret = (string) config('soul.media.cloudinary.api_secret');
        $algorithm = (string) config('soul.media.cloudinary.response_signature_algorithm', 'sha1');
        if (! in_array($algorithm, ['sha1', 'sha256'], true)) {
            $algorithm = 'sha1';
        }
        $signedPath = $publicId.'.'.$format;
        $digest = hash($algorithm, $signedPath.$secret, true);
        $signature = substr(rtrim(strtr(base64_encode($digest), '+/', '-_'), '='), 0, 8);
        $path = implode('/', array_map('rawurlencode', explode('/', $publicId)));

        return "https://res.cloudinary.com/{$cloudName}/image/authenticated/s--{$signature}--/{$path}.{$format}";
    }
}
