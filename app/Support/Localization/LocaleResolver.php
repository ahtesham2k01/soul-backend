<?php

namespace App\Support\Localization;

final class LocaleResolver
{
    public function resolve(
        ?string $requestedLocale,
        ?string $acceptLanguage = null,
    ): string {
        $supportedLocales = array_keys(
            config('soul.translations.locales', [])
        );

        $fallbackLocale = config(
            'soul.translations.fallback_locale',
            'en',
        );

        if ($requestedLocale !== null && trim($requestedLocale) !== '') {
            return $this->matchSupportedLocale(
                locale: $requestedLocale,
                supportedLocales: $supportedLocales,
            ) ?? $fallbackLocale;
        }

        foreach ($this->parseAcceptLanguage($acceptLanguage) as $candidate) {
            $resolved = $this->matchSupportedLocale(
                locale: $candidate,
                supportedLocales: $supportedLocales,
            );

            if ($resolved !== null) {
                return $resolved;
            }
        }

        return $fallbackLocale;
    }

    private function parseAcceptLanguage(?string $header): array
    {
        if ($header === null || trim($header) === '') {
            return [];
        }

        $locales = [];

        foreach (explode(',', $header) as $position => $item) {
            $item = trim($item);
            $locale = trim(explode(';', $item, 2)[0]);

            if ($locale === '*' || $locale === '') {
                continue;
            }

            $quality = 1.0;
            $hasQualityParameter = preg_match(
                '/(?:^|;)\\s*q\\s*=/i',
                $item,
            ) === 1;

            if ($hasQualityParameter) {
                if (preg_match(
                    '/(?:^|;)\\s*q\\s*=\\s*(0(?:\\.\\d{0,3})?|1(?:\\.0{0,3})?)(?:\\s*;|$)/i',
                    $item,
                    $matches,
                ) !== 1) {
                    continue;
                }

                $quality = (float) $matches[1];
            }

            if ($quality <= 0.0) {
                continue;
            }

            $locales[] = [
                'locale' => $locale,
                'quality' => $quality,
                'position' => $position,
            ];
        }

        usort(
            $locales,
            fn (array $first, array $second): int =>
                $second['quality'] <=> $first['quality']
                ?: $first['position'] <=> $second['position'],
        );

        return array_column($locales, 'locale');
    }

    private function matchSupportedLocale(
        string $locale,
        array $supportedLocales,
    ): ?string {
        $normalizedLocale = $this->normalize($locale);

        $aliases = [
            'zh-Hans' => 'zh-CN',
            'zh-SG' => 'zh-CN',
            'zh-Hant' => 'zh-TW',
            'zh-HK' => 'zh-TW',
            'zh-MO' => 'zh-TW',
            'pt' => 'pt-PT',
        ];

        $normalizedLocale = $aliases[$normalizedLocale]
            ?? $normalizedLocale;

        foreach ($supportedLocales as $supportedLocale) {
            if (
                strcasecmp($supportedLocale, $normalizedLocale)
                === 0
            ) {
                return $supportedLocale;
            }
        }

        $baseLanguage = strtolower(
            explode('-', $normalizedLocale)[0]
        );

        foreach ($supportedLocales as $supportedLocale) {
            if (strtolower($supportedLocale) === $baseLanguage) {
                return $supportedLocale;
            }
        }

        return null;
    }

    private function normalize(string $locale): string
    {
        $locale = str_replace('_', '-', trim($locale));
        $parts = explode('-', $locale);

        $language = strtolower($parts[0]);

        if (! isset($parts[1])) {
            return $language;
        }

        $regionOrScript = strlen($parts[1]) === 4
            ? ucfirst(strtolower($parts[1]))
            : strtoupper($parts[1]);

        return $language.'-'.$regionOrScript;
    }
}
