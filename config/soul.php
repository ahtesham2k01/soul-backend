<?php

return [

    'legal' => [
        'terms_version' => env('SOUL_TERMS_VERSION', '1.0'),
        'privacy_version' => env('SOUL_PRIVACY_VERSION', '1.0'),
        'community_guidelines_version' => env('SOUL_COMMUNITY_GUIDELINES_VERSION', '1.0'),
        'commitment_version' => env('SOUL_COMMITMENT_VERSION', '1.0'),
    ],

    /*
    |--------------------------------------------------------------------------
    | Translation catalog
    |--------------------------------------------------------------------------
    |
    | SOUL brand name and logo are never translated.
    | This version changes whenever translation content changes.
    |
    */

    'translations' => [
        'fallback_locale' => 'en',
        'catalog_version' => '17',

        /*
         * Product-approved global target. This includes useful member
         * languages across South Asia, Muslim-majority markets, Europe,
         * East and Southeast Asia, Africa and the Americas. SOUL
         * intentionally serves Roman Urdu in Latin script.
         */
        'target_locales' => [
            'en', 'en-GB', 'ur', 'ar', 'fa', 'he', 'hi', 'bn',
            'pa', 'gu', 'mr', 'ta', 'te', 'zh-CN', 'zh-TW',
            'es', 'fr', 'de', 'pt-BR', 'pt-PT', 'ru', 'uk',
            'ja', 'ko', 'id', 'ms', 'tr', 'it', 'nl', 'pl',
            'vi', 'th', 'fil', 'sw',
        ],

        /*
         * A catalog is launch-ready only after product/native-language
         * review. Draft catalogs remain addressable for QA but clients must
         * not present them as finished translations.
         */
        'launch_ready_locales' => ['en', 'en-GB', 'ur'],

        'locales' => [
            'en' => [
                'name' => 'English',
                'native_name' => 'English',
                'direction' => 'ltr',
            ],

            'en-GB' => [
                'name' => 'English (United Kingdom)',
                'native_name' => 'English (United Kingdom)',
                'direction' => 'ltr',
            ],

            'ur' => [
                'name' => 'Roman Urdu',
                'native_name' => 'Roman Urdu',
                'direction' => 'ltr',
            ],

            'ar' => [
                'name' => 'Arabic',
                'native_name' => 'العربية',
                'direction' => 'rtl',
            ],

            'fa' => [
                'name' => 'Persian',
                'native_name' => 'فارسی',
                'direction' => 'rtl',
            ],

            'he' => [
                'name' => 'Hebrew',
                'native_name' => 'עברית',
                'direction' => 'rtl',
            ],

            'hi' => [
                'name' => 'Hindi',
                'native_name' => 'हिन्दी',
                'direction' => 'ltr',
            ],

            'bn' => [
                'name' => 'Bengali',
                'native_name' => 'বাংলা',
                'direction' => 'ltr',
            ],

            'pa' => [
                'name' => 'Punjabi',
                'native_name' => 'ਪੰਜਾਬੀ',
                'direction' => 'ltr',
            ],

            'gu' => [
                'name' => 'Gujarati',
                'native_name' => 'ગુજરાતી',
                'direction' => 'ltr',
            ],

            'mr' => [
                'name' => 'Marathi',
                'native_name' => 'मराठी',
                'direction' => 'ltr',
            ],

            'ta' => [
                'name' => 'Tamil',
                'native_name' => 'தமிழ்',
                'direction' => 'ltr',
            ],

            'te' => [
                'name' => 'Telugu',
                'native_name' => 'తెలుగు',
                'direction' => 'ltr',
            ],

            'zh-CN' => [
                'name' => 'Chinese (Simplified)',
                'native_name' => '简体中文',
                'direction' => 'ltr',
            ],

            'zh-TW' => [
                'name' => 'Chinese (Traditional)',
                'native_name' => '繁體中文',
                'direction' => 'ltr',
            ],

            'es' => [
                'name' => 'Spanish',
                'native_name' => 'Español',
                'direction' => 'ltr',
            ],

            'fr' => [
                'name' => 'French',
                'native_name' => 'Français',
                'direction' => 'ltr',
            ],

            'de' => [
                'name' => 'German',
                'native_name' => 'Deutsch',
                'direction' => 'ltr',
            ],

            'pt-BR' => [
                'name' => 'Portuguese (Brazil)',
                'native_name' => 'Português (Brasil)',
                'direction' => 'ltr',
            ],

            'pt-PT' => [
                'name' => 'Portuguese (Portugal)',
                'native_name' => 'Português (Portugal)',
                'direction' => 'ltr',
            ],

            'ru' => [
                'name' => 'Russian',
                'native_name' => 'Русский',
                'direction' => 'ltr',
            ],

            'uk' => [
                'name' => 'Ukrainian',
                'native_name' => 'Українська',
                'direction' => 'ltr',
            ],

            'ja' => [
                'name' => 'Japanese',
                'native_name' => '日本語',
                'direction' => 'ltr',
            ],

            'ko' => [
                'name' => 'Korean',
                'native_name' => '한국어',
                'direction' => 'ltr',
            ],

            'id' => [
                'name' => 'Indonesian',
                'native_name' => 'Bahasa Indonesia',
                'direction' => 'ltr',
            ],

            'ms' => [
                'name' => 'Malay',
                'native_name' => 'Bahasa Melayu',
                'direction' => 'ltr',
            ],

            'tr' => [
                'name' => 'Turkish',
                'native_name' => 'Türkçe',
                'direction' => 'ltr',
            ],

            'it' => [
                'name' => 'Italian',
                'native_name' => 'Italiano',
                'direction' => 'ltr',
            ],

            'nl' => [
                'name' => 'Dutch',
                'native_name' => 'Nederlands',
                'direction' => 'ltr',
            ],

            'pl' => [
                'name' => 'Polish',
                'native_name' => 'Polski',
                'direction' => 'ltr',
            ],

            'vi' => [
                'name' => 'Vietnamese',
                'native_name' => 'Tiếng Việt',
                'direction' => 'ltr',
            ],

            'th' => [
                'name' => 'Thai',
                'native_name' => 'ไทย',
                'direction' => 'ltr',
            ],

            'fil' => [
                'name' => 'Filipino',
                'native_name' => 'Filipino',
                'direction' => 'ltr',
            ],

            'sw' => [
                'name' => 'Swahili',
                'native_name' => 'Kiswahili',
                'direction' => 'ltr',
            ],
        ],
    ],

    /*
    |--------------------------------------------------------------------------
    | Location
    |--------------------------------------------------------------------------
    |
    | Local development uses the null provider.
    | Production may use Cloudflare visitor location headers.
    |
    */

    'location' => [
        'driver' => env(
            'GEOLOCATION_DRIVER',
            'none',
        ),

        'cloudflare_headers_enabled' => filter_var(
            env(
                'CLOUDFLARE_LOCATION_HEADERS_ENABLED',
                false,
            ),
            FILTER_VALIDATE_BOOL,
        ),
    ],

    'privacy' => [
        'export_disk' => env('SOUL_PRIVATE_EXPORT_DISK', 'local'),
        'retention' => [
            'failed_store_webhook_days' => (int) env('SOUL_FAILED_WEBHOOK_RETENTION_DAYS', 30),
            'delivered_notification_days' => (int) env('SOUL_DELIVERED_NOTIFICATION_RETENTION_DAYS', 90),
            'failed_notification_days' => (int) env('SOUL_FAILED_NOTIFICATION_RETENTION_DAYS', 180),
        ],
    ],

    'support' => [
        'attachment_disk' => env('SOUL_SUPPORT_ATTACHMENT_DISK', 'local'),
        'max_attachment_kilobytes' => 5120,
    ],

    'operations' => [
        'database_connection_warning_percent' => (int) env('SOUL_DATABASE_CONNECTION_WARNING_PERCENT', 80),
        'warning_thresholds' => [
            'queued_jobs' => (int) env('SOUL_QUEUE_WARNING_COUNT', 1000),
            'oldest_queued_job_age_seconds' => (int) env('SOUL_QUEUE_WAIT_WARNING_SECONDS', 900),
            'failed_jobs_24h' => (int) env('SOUL_FAILED_JOBS_WARNING_COUNT', 0),
            'stale_exports' => (int) env('SOUL_STALE_EXPORT_WARNING_COUNT', 0),
            'stale_notification_deliveries' => (int) env('SOUL_STALE_NOTIFICATION_WARNING_COUNT', 0),
            'stale_store_webhooks' => (int) env('SOUL_STALE_WEBHOOK_WARNING_COUNT', 0),
        ],
    ],

    'release' => [
        'backup' => [
            'maximum_age_hours' => (int) env('SOUL_BACKUP_MAXIMUM_AGE_HOURS', 24),
        ],
    ],

    'performance' => [
        'slow_query_warning_ms' => (int) env('SOUL_SLOW_QUERY_WARNING_MS', 500),
        'synthetic' => [
            'maximum_users' => (int) env('SOUL_SYNTHETIC_MAX_USERS', 50000),
            'maximum_matches' => (int) env('SOUL_SYNTHETIC_MAX_MATCHES', 50000),
            'maximum_messages_per_match' => (int) env('SOUL_SYNTHETIC_MAX_MESSAGES_PER_MATCH', 100),
        ],
    ],

    'security' => [
        'maximum_active_sessions' => (int) env('SOUL_MAXIMUM_ACTIVE_SESSIONS', 20),
        'maximum_json_request_kilobytes' => (int) env('SOUL_MAXIMUM_JSON_REQUEST_KILOBYTES', 256),
        'maximum_multipart_request_kilobytes' => (int) env('SOUL_MAXIMUM_MULTIPART_REQUEST_KILOBYTES', 6144),
        'trusted_proxies' => array_values(array_filter(array_map('trim', explode(',', (string) env('SOUL_TRUSTED_PROXIES', ''))))),
        'cors_allowed_origins' => array_values(array_filter(array_map('trim', explode(',', (string) env('SOUL_CORS_ALLOWED_ORIGINS', ''))))),
    ],

    'media' => [
        'cloudinary' => [
            'cloud_name' => env('CLOUDINARY_CLOUD_NAME'),
            'api_key' => env('CLOUDINARY_API_KEY'),
            'api_secret' => env('CLOUDINARY_API_SECRET'),
            'upload_session_ttl_minutes' => (int) env(
                'CLOUDINARY_UPLOAD_SESSION_TTL_MINUTES',
                10,
            ),
            'webhook_tolerance_seconds' => (int) env(
                'CLOUDINARY_WEBHOOK_TOLERANCE_SECONDS',
                7200,
            ),
            'response_signature_algorithm' => env(
                'CLOUDINARY_RESPONSE_SIGNATURE_ALGORITHM',
                'sha1',
            ),
        ],
    ],

];
