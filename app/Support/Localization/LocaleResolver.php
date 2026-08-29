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

        $candidates = array_filter([
            $requestedLocale,
            ...$this->parseAcceptLanguage($acceptLanguage),
        ]);

        foreach ($candidates as $candidate) {
            $resolved = $this->matchSupportedLocale(
                locale: $candidate,
                supportedLocales: $supportedLocales,
            );

            if ($resolved !== null) {
                return $resolved;
            }
        }

        return config(
            'soul.translations.fallback_locale',
            'en',
        );
    }

    private function parseAcceptLanguage(?string $header): array
    {
        if ($header === null || trim($header) === '') {
            return [];
        }

        $locales = [];

        foreach (explode(',', $header) as $position => $item) {
            [$locale, $quality] = array_pad(
                explode(';q=', trim($item), 2),
                2,
                '1',
            );

            if ($locale === '*' || $locale === '') {
                continue;
            }

            $locales[] = [
                'locale' => $locale,
                'quality' => (float) $quality,
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
