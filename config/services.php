<?php

return [

    /*
    |--------------------------------------------------------------------------
    | Third Party Services
    |--------------------------------------------------------------------------
    |
    | This file is for storing the credentials for third party services such
    | as Resend, Postmark, AWS, and more. This file provides the de facto
    | location for this type of information, allowing packages to have
    | a conventional file to locate the various service credentials.
    |
    */

    'postmark' => [
        'key' => env('POSTMARK_API_KEY'),
    ],

    'resend' => [
        'key' => env('RESEND_API_KEY'),
    ],

    'ses' => [
        'key' => env('AWS_ACCESS_KEY_ID'),
        'secret' => env('AWS_SECRET_ACCESS_KEY'),
        'region' => env('AWS_DEFAULT_REGION', 'us-east-1'),
    ],

    'slack' => [
        'notifications' => [
            'bot_user_oauth_token' => env(
                'SLACK_BOT_USER_OAUTH_TOKEN',
            ),
            'channel' => env(
                'SLACK_BOT_USER_DEFAULT_CHANNEL',
            ),
        ],
    ],

    /*
    |--------------------------------------------------------------------------
    | Google Sign-In
    |--------------------------------------------------------------------------
    |
    | Flutter sends a Google ID token to the backend. The backend verifies
    | its signature and only accepts tokens issued for one of these client
    | IDs. Multiple client IDs may be provided as a comma-separated list.
    |
    */

    'google' => [
        'client_ids' => array_values(
            array_filter(
                array_map(
                    'trim',
                    explode(
                        ',',
                        (string) env(
                            'GOOGLE_CLIENT_IDS',
                            '',
                        ),
                    ),
                ),
            ),
        ),
    ],

    'apple' => [
        'client_ids' => array_values(
            array_filter(
                array_map(
                    'trim',
                    explode(
                        ',',
                        (string) env(
                            'APPLE_CLIENT_IDS',
                            '',
                        ),
                    ),
                ),
            ),
        ),
    ],

];
