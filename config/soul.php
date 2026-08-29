<?php

return [

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
        'catalog_version' => '2',

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

];
