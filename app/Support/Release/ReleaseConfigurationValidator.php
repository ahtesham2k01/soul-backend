<?php

namespace App\Support\Release;

final class ReleaseConfigurationValidator
{
    /** @return array<string, array{ready: bool, missing: array<int, string>, invalid: array<int, string>}> */
    public function providerReadiness(): array
    {
        return [
            'cloudinary' => $this->group(['cloud_name' => config('soul.media.cloudinary.cloud_name'), 'api_key' => config('soul.media.cloudinary.api_key'), 'api_secret' => config('soul.media.cloudinary.api_secret')]),
            'google_sign_in' => $this->group(['client_ids' => collect(config('services.google.client_ids', []))->filter()->first()]),
            'apple_sign_in' => $this->group(['client_ids' => collect(config('services.apple.client_ids', []))->filter()->first()]),
            'apple_store' => $this->group(config('services.stores.apple', []), [
                'private_key' => fn (mixed $value): bool => $this->isPrivateKey($value),
            ]),
            'google_play' => $this->group(config('services.stores.google', []), [
                'service_account_json' => fn (mixed $value): bool => $this->isServiceAccount($value),
            ]),
            'fcm' => $this->group(config('services.push.fcm', []), [
                'service_account_json' => fn (mixed $value): bool => $this->isServiceAccount($value),
            ]),
            'apns' => $this->group(config('services.push.apns', []), [
                'private_key' => fn (mixed $value): bool => $this->isPrivateKey($value),
            ]),
            'email' => $this->group(['mailer' => in_array(config('mail.default'), ['array', 'log'], true) ? null : config('mail.default'), 'from_address' => config('mail.from.address')]),
            'broadcasting' => $this->group(['connection' => in_array(config('broadcasting.default'), ['log', 'null'], true) ? null : config('broadcasting.default')]),
        ];
    }

    /** @return array<int, array{name: string, status: string, message: string}> */
    public function validate(bool $production = false): array
    {
        $checks = [
            $this->check('Application key', filled(config('app.key')), 'APP_KEY must be generated.'),
            $this->check('Application URL', filter_var(config('app.url'), FILTER_VALIDATE_URL) !== false, 'APP_URL must be a valid URL.'),
            $this->check('Export disk', config('filesystems.disks.'.config('soul.privacy.export_disk')) !== null, 'SOUL_PRIVATE_EXPORT_DISK must name a configured disk.'),
            $this->check('Cloudinary TTL', (int) config('soul.media.cloudinary.upload_session_ttl_minutes') > 0, 'Upload-session TTL must be positive.'),
            $this->check('Legal versions', collect(['terms_version', 'privacy_version', 'community_guidelines_version', 'commitment_version'])->every(fn (string $key): bool => filled(config('soul.legal.'.$key))), 'Terms, privacy, guidelines and commitment versions are required.'),
        ];

        if (! $production) {
            return $checks;
        }

        $providers = $this->providerReadiness();

        return [...$checks,
            $this->check('Environment', app()->environment('production'), 'APP_ENV must be production.'),
            $this->check('Debug mode', config('app.debug') === false, 'APP_DEBUG must be false.'),
            $this->check('HTTPS URL', str_starts_with((string) config('app.url'), 'https://'), 'APP_URL must use HTTPS.'),
            $this->check('Production database', in_array(config('database.default'), ['mysql', 'pgsql'], true), 'Use MySQL or PostgreSQL.'),
            $this->check('Database host', filled(config('database.connections.'.config('database.default').'.host')), 'A database host is required.'),
            $this->check('Database name', filled(config('database.connections.'.config('database.default').'.database')), 'A database name is required.'),
            $this->check('Database user', filled(config('database.connections.'.config('database.default').'.username')), 'A database user is required.'),
            $this->check('Redis cache', config('cache.default') === 'redis', 'Use Redis for shared production cache.'),
            $this->check('Redis queue', config('queue.default') === 'redis', 'Use Redis for the production queue.'),
            $this->check('Transactional mail', ! in_array(config('mail.default'), ['array', 'log'], true), 'Configure a transactional mailer.'),
            $this->check('Encrypted sessions', config('session.encrypt') === true, 'SESSION_ENCRYPT must be true.'),
            $this->check('Secure admin cookie', config('session.secure') === true, 'SESSION_SECURE_COOKIE must be true.'),
            $this->check('Trusted proxies', $this->trustedProxiesAreSafe(), 'Configure explicit proxy IP/CIDR values; wildcard trust is prohibited.'),
            $this->check('CORS origins', $this->corsOriginsAreSafe(), 'CORS origins must be explicit HTTPS origins without wildcards, paths or credentials.'),
            $this->check('JSON request limit', (int) config('soul.security.maximum_json_request_kilobytes') >= 64, 'JSON request limit must be at least 64 KB.'),
            $this->check('Multipart request limit', (int) config('soul.security.maximum_multipart_request_kilobytes') >= (int) config('soul.support.max_attachment_kilobytes'), 'Multipart request limit must cover the configured support attachment size.'),
            $this->check('Backup freshness policy', (int) config('soul.release.backup.maximum_age_hours') > 0, 'SOUL_BACKUP_MAXIMUM_AGE_HOURS must be positive.'),
            $this->check('Connection warning policy', in_array((int) config('soul.operations.database_connection_warning_percent'), range(1, 100), true), 'Database connection warning percent must be between 1 and 100.'),
            $this->check('Cloudinary credentials', $this->cloudinaryCredentialsPresent(), 'Cloudinary cloud, key and secret are required.'),
            $this->check('Cloudinary webhook signing', config('soul.media.cloudinary.response_signature_algorithm') === 'sha256', 'Production Cloudinary callbacks must use SHA-256 signatures.'),
            $this->check('Google audiences', $this->audiencesPresent('services.google.client_ids'), 'GOOGLE_CLIENT_IDS is required.'),
            $this->check('Apple audiences', $this->audiencesPresent('services.apple.client_ids'), 'APPLE_CLIENT_IDS is required.'),
            $this->check('Apple Store API', $providers['apple_store']['ready'], 'Apple Store issuer, key, bundle and private key are required.'),
            $this->check('Google Play API', $providers['google_play']['ready'], 'Google Play package and service account are required.'),
            $this->check('FCM delivery', $providers['fcm']['ready'], 'FCM project and service account are required.'),
            $this->check('APNs delivery', $providers['apns']['ready'], 'APNs team, key, bundle and private key are required.'),
            $this->check('Broadcast transport', $providers['broadcasting']['ready'], 'Configure a non-log broadcast transport.'),
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

    private function trustedProxiesAreSafe(): bool
    {
        $proxies = config('soul.security.trusted_proxies', []);

        return is_array($proxies) && $proxies !== [] && collect($proxies)->every(function (string $proxy): bool {
            [$address, $prefix] = array_pad(explode('/', $proxy, 2), 2, null);
            if (filter_var($address, FILTER_VALIDATE_IP) === false) {
                return false;
            }
            if ($prefix === null) {
                return true;
            }

            $maximumPrefix = filter_var($address, FILTER_VALIDATE_IP, FILTER_FLAG_IPV4) !== false ? 32 : 128;

            return ctype_digit($prefix) && (int) $prefix <= $maximumPrefix;
        });
    }

    private function corsOriginsAreSafe(): bool
    {
        $origins = config('soul.security.cors_allowed_origins', []);
        if (! is_array($origins) || in_array('*', $origins, true)) {
            return false;
        }

        return collect($origins)->every(function (string $origin): bool {
            $parts = parse_url($origin);

            return is_array($parts)
                && ($parts['scheme'] ?? null) === 'https'
                && filled($parts['host'] ?? null)
                && array_intersect(['user', 'pass', 'path', 'query', 'fragment'], array_keys($parts)) === [];
        });
    }

    /** @param array<string, mixed> $values
     * @param array<string, callable(mixed): bool> $validators
     * @return array{ready: bool, missing: array<int, string>, invalid: array<int, string>}
     */
    private function group(array $values, array $validators = []): array
    {
        $missing = collect($values)->filter(fn (mixed $value): bool => blank($value))->keys()->values()->all();
        $invalid = collect($validators)
            ->filter(fn (callable $validator, string $key): bool => ! in_array($key, $missing, true) && ! $validator($values[$key] ?? null))
            ->keys()
            ->values()
            ->all();

        return ['ready' => $missing === [] && $invalid === [], 'missing' => $missing, 'invalid' => $invalid];
    }

    private function isServiceAccount(mixed $value): bool
    {
        if (! is_string($value) || $value === '') return false;
        try {
            $json = json_decode($value, true, flags: JSON_THROW_ON_ERROR);
        } catch (\Throwable) {
            return false;
        }

        return is_array($json)
            && ($json['type'] ?? null) === 'service_account'
            && filled($json['client_email'] ?? null)
            && $this->isPrivateKey($json['private_key'] ?? null);
    }

    private function isPrivateKey(mixed $value): bool
    {
        if (! is_string($value) || $value === '') return false;

        return openssl_pkey_get_private(str_replace('\\n', "\n", $value)) !== false;
    }
}
