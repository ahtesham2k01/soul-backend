<?php

namespace App\Support\Release;

final class ReleaseConfigurationValidator
{
    /** @return array<int, array{name: string, status: string, message: string}> */
    public function validate(bool $production = false): array
    {
        $checks = [
            $this->check('Application key', filled(config('app.key')), 'APP_KEY must be generated.'),
            $this->check('Application URL', filter_var(config('app.url'), FILTER_VALIDATE_URL) !== false, 'APP_URL must be a valid URL.'),
            $this->check('Export disk', config('filesystems.disks.'.config('soul.privacy.export_disk')) !== null, 'SOUL_PRIVATE_EXPORT_DISK must name a configured disk.'),
            $this->check('Cloudinary TTL', (int) config('soul.media.cloudinary.upload_session_ttl_minutes') > 0, 'Upload-session TTL must be positive.'),
            $this->check('Legal versions', filled(config('soul.legal.terms_version')) && filled(config('soul.legal.privacy_version')), 'Terms and privacy versions are required.'),
        ];

        if (! $production) {
            return $checks;
        }

        return [...$checks,
            $this->check('Environment', app()->environment('production'), 'APP_ENV must be production.'),
            $this->check('Debug mode', config('app.debug') === false, 'APP_DEBUG must be false.'),
            $this->check('HTTPS URL', str_starts_with((string) config('app.url'), 'https://'), 'APP_URL must use HTTPS.'),
            $this->check('Production database', in_array(config('database.default'), ['mysql', 'pgsql'], true), 'Use MySQL or PostgreSQL.'),
            $this->check('Shared cache', ! in_array(config('cache.default'), ['array', 'file'], true), 'Use database or Redis cache.'),
            $this->check('Async queue', config('queue.default') !== 'sync', 'Use a persistent asynchronous queue.'),
            $this->check('Transactional mail', ! in_array(config('mail.default'), ['array', 'log'], true), 'Configure a transactional mailer.'),
            $this->check('Secure admin cookie', config('session.secure') === true, 'SESSION_SECURE_COOKIE must be true.'),
            $this->check('Cloudinary credentials', $this->cloudinaryCredentialsPresent(), 'Cloudinary cloud, key and secret are required.'),
            $this->check('Google audiences', $this->audiencesPresent('services.google.client_ids'), 'GOOGLE_CLIENT_IDS is required.'),
            $this->check('Apple audiences', $this->audiencesPresent('services.apple.client_ids'), 'APPLE_CLIENT_IDS is required.'),
        ];
    }

    /** @param array<int, array{name: string, status: string, message: string}> $checks */
    public function passes(array $checks): bool
    {
        return collect($checks)->every(fn (array $check): bool => $check['status'] === 'pass');
    }

    /** @return array{name: string, status: string, message: string} */
    private function check(string $name, bool $passes, string $failure): array
    {
        return [
            'name' => $name,
            'status' => $passes ? 'pass' : 'fail',
            'message' => $passes ? 'Ready' : $failure,
        ];
    }

    private function cloudinaryCredentialsPresent(): bool
    {
        return filled(config('soul.media.cloudinary.cloud_name'))
            && filled(config('soul.media.cloudinary.api_key'))
            && filled(config('soul.media.cloudinary.api_secret'));
    }

    private function audiencesPresent(string $key): bool
    {
        return collect(config($key, []))->filter()->isNotEmpty();
    }
}
