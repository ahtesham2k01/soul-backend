<?php

namespace App\Http\Controllers\Api\V1;

use App\Contracts\Location\GeolocationProvider;
use App\Http\Controllers\Controller;
use App\Support\ApiResponse;
use App\Support\Localization\LocaleResolver;
use App\Support\Localization\TranslationCatalog;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\File;

class AppBootstrapController extends Controller
{
    public function __invoke(
        Request $request,
        LocaleResolver $localeResolver,
        TranslationCatalog $translationCatalog,
        GeolocationProvider $geolocationProvider,
    ): JsonResponse {
        $queryLocale = $request->query('locale');

        $requestedLocale = is_string($queryLocale)
            ? $queryLocale
            : null;

        $matchedLocale = $localeResolver->resolve(
            requestedLocale: $requestedLocale,
            acceptLanguage: $request->header(
                'Accept-Language',
            ),
        );

        $catalog = $translationCatalog->load(
            $matchedLocale,
        );

        /*
         * Production Cloudflare driver approximate
         * IP location return karega.
         *
         * Local/failed detection par null rahega.
         */
        $location = $geolocationProvider->fromIp(
            $request->ip(),
        );

        return ApiResponse::success(
            data: [
                'brand' => [
                    'name' => 'SOUL',
                    'translate' => false,
                ],

                'locale' => [
                    'requested' => $requestedLocale
                        ?? $request->header('Accept-Language'),

                    'matched' => $matchedLocale,
                    'resolved' => $catalog['locale'],
                    'fallback' => $catalog['fallback_locale'],
                    'direction' => $catalog['direction'],
                ],

                'translations' => [
                    'version' => $catalog['version'],
                    'hash' => $catalog['hash'],
                    'values' => $catalog['values'],
                ],

                'supported_languages' =>
                    $this->availableLanguages(),

                'location' => $location?->toArray(),

                'location_status' => $location === null
                    ? 'unavailable'
                    : 'resolved',
            ],
            message: 'App bootstrap loaded successfully.',
        );
    }

    private function availableLanguages(): array
    {
        $configuredLocales = config(
            'soul.translations.locales',
            [],
        );

        $languages = [];

        foreach ($configuredLocales as $code => $details) {
            if (! File::exists(lang_path($code.'.json'))) {
                continue;
            }

            $languages[] = [
                'code' => $code,
                'name' => $details['name'],
                'native_name' => $details['native_name'],
                'direction' => $details['direction'],
            ];
        }

        return $languages;
    }
}
