# SOUL localization guide

This guide explains the translation system in simple steps. Laravel owns translations for both Flutter and the React admin panel.

## What is complete

- English and simple Roman Urdu cover all current V1 feature areas.
- The catalog currently contains more than 225 keys.
- The React admin can switch between English and Roman Urdu.
- The selected admin language is saved in the browser.
- Flutter receives language, direction, catalog version, hash and values from bootstrap.
- API validation errors use the requested language when a server translation is available.
- SOUL is never translated.
- Other configured languages retain their existing translations and use safe English text for newly introduced keys until reviewed.

## Flutter: load translations

Call:

```http
GET /api/v1/bootstrap?locale=ur
Accept: application/json
```

Important response fields:

```json
{
  "data": {
    "locale": {
      "resolved": "ur",
      "fallback": "en",
      "direction": "ltr"
    },
    "translations": {
      "version": "8",
      "hash": "...",
      "values": {
        "common.continue": "Continue karein"
      }
    }
  }
}
```

Roman Urdu uses Latin letters, so its current direction is `ltr`. Flutter must still use the returned direction instead of assuming it. Arabic, Persian and Hebrew return `rtl`.

## Flutter: show a translated label

```dart
String tr(String key) {
  return translations[key] ?? englishFallback[key] ?? key;
}

Text(tr('auth.create_account'));
```

Keep this helper in one shared localization service. Do not write this in a screen:

```dart
// Avoid this pattern.
Text(locale == 'ur' ? 'Account banayein' : 'Create Account');
```

## Cache and refresh

1. Save `version`, `hash` and `values` after a successful bootstrap.
2. On the next launch, show the saved catalog while refreshing bootstrap.
3. Replace the cache when version or hash changes.
4. Keep the last valid catalog if the refresh fails.
5. Changing language must not log the user out or delete a profile draft.

Send `Accept-Language` with normal API requests as well. Laravel uses it for validation errors. Roman Urdu includes the common validation rules; rules without a reviewed Roman Urdu sentence safely fall back to English.

## React admin

The admin requests the same bootstrap endpoint. Its language switch stores `soul.admin.locale` in browser local storage. Labels, prompts, notices, moderation values and date formatting update from the Laravel catalog.

The admin does not contain a second English/Urdu dictionary. This avoids mobile and admin copy drifting apart.

## Add a new translation

1. Choose a clear feature key, for example `events.join`.
2. Add English text to `resources/lang/en.json`.
3. Add simple Roman Urdu to `resources/lang/ur.json`.
4. Add the key to every configured catalog. Use English only as a temporary safe fallback when a reviewed translation is not available.
5. Increase `soul.translations.catalog_version`.
6. Use the key in Flutter or React; do not duplicate the sentence.
7. Run localization tests and the React production build.

Use short, natural copy. Avoid formal Urdu. Keep placeholders and variables outside translated labels unless the catalog explicitly documents them.

## Review checklist

- Every new user-facing screen uses catalog keys.
- English and Roman Urdu contain the same keys.
- Important Roman Urdu keys are not silent English copies.
- Empty strings are rejected by tests.
- Brand key `brand.name` does not exist.
- The client applies returned direction.
- No sensitive server error details are exposed through translations.
- Catalog version changes when text changes.
