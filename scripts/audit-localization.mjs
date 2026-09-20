import fs from 'node:fs';
import path from 'node:path';

const root = process.env.SOUL_LOCALIZATION_ROOT || process.cwd();
const formatArgument = process.argv.find((argument) => argument.startsWith('--format='));
const outputFormat = formatArgument?.split('=', 2)[1] ?? 'table';

if (! ['table', 'json'].includes(outputFormat)) {
    console.error('Unsupported format. Use --format=table or --format=json.');
    process.exit(2);
}
const languageDirectory = path.join(root, 'resources', 'lang');
const configSource = fs.readFileSync(path.join(root, 'config', 'soul.php'), 'utf8');
const baselinePath = path.join(root, 'config', 'localization-baseline.json');

const configuredBlock = configSource.match(/'target_locales'\s*=>\s*\[([\s\S]*?)\],/);
const readyBlock = configSource.match(/'launch_ready_locales'\s*=>\s*\[([\s\S]*?)\],/);

if (! configuredBlock || ! readyBlock) {
    throw new Error('Translation target/readiness configuration is missing.');
}

const parsePhpStringList = (block) => [
    ...block.matchAll(/'([^']+)'/g),
].map((match) => match[1]);

const targetLocales = parsePhpStringList(configuredBlock[1]);
const launchReadyLocales = parsePhpStringList(readyBlock[1]);
const baseline = JSON.parse(fs.readFileSync(baselinePath, 'utf8'));
const english = JSON.parse(
    fs.readFileSync(path.join(languageDirectory, 'en.json'), 'utf8'),
);
const englishKeys = Object.keys(english).sort();
const memberKeys = englishKeys.filter((key) => ! key.startsWith('admin.'));
const sourceCatalogLocales = new Set(['en', 'en-GB']);
const intentionalIdenticalMemberTerms = {
    es: new Set(['profile.answer_no']),
    fr: new Set(['notifications.title']),
    id: new Set(['auth.email']),
    it: new Set([
        'nav.home',
        'nav.chat',
        'profile.answer_no',
        'settings.privacy',
        'chat.offline',
    ]),
    nl: new Set([
        'profile.man',
        'profile.student',
        'discovery.filters',
        'matches.title',
        'notifications.marketing',
        'settings.privacy',
        'chat.offline',
    ]),
    ur: new Set([
        'auth.email', 'nav.home', 'nav.explore', 'nav.chat', 'nav.profile',
        'profile.date_of_birth', 'profile.gender', 'profile.nationality',
        'profile.intention_serious', 'profile.intention_casual', 'profile.height',
        'profile.job_title', 'profile.traits', 'profile.family_involvement',
        'profile.student', 'profile.retired', 'photos.cover', 'photos.public',
        'photos.private', 'discovery.filters', 'discovery.like', 'discovery.pass',
        'matches.title', 'notifications.title', 'notifications.safety',
        'notifications.marketing', 'settings.title', 'settings.language',
        'settings.privacy', 'settings.devices', 'chat.offline',
    ]),
};
const failures = [];
const rows = [];
const unsafeControlPattern = /[\u0000-\u0008\u000B\u000C\u000E-\u001F\u007F\u202A-\u202E\u2066-\u2069]/u;
const placeholderPattern = /:[A-Za-z_][A-Za-z0-9_]*|\{[A-Za-z_][A-Za-z0-9_]*\}/g;

const placeholders = (value) => [...(value.match(placeholderPattern) ?? [])].sort();

const missingBaselineLocales = targetLocales.filter((locale) => ! Object.hasOwn(baseline, locale));
const unexpectedBaselineLocales = Object.keys(baseline).filter((locale) => ! targetLocales.includes(locale));

if (missingBaselineLocales.length || unexpectedBaselineLocales.length) {
    failures.push(
        `baseline: missing=${missingBaselineLocales.length}, extra=${unexpectedBaselineLocales.length}`,
    );
}

for (const locale of targetLocales) {
    const catalogPath = path.join(languageDirectory, `${locale}.json`);

    if (! fs.existsSync(catalogPath)) {
        failures.push(`${locale}: catalog file is missing`);
        continue;
    }

    const catalog = JSON.parse(fs.readFileSync(catalogPath, 'utf8'));
    const keys = Object.keys(catalog).sort();
    const missing = englishKeys.filter((key) => ! keys.includes(key));
    const extra = keys.filter((key) => ! englishKeys.includes(key));
    const empty = keys.filter((key) => typeof catalog[key] !== 'string' || catalog[key].trim() === '');
    const memberCatalogKeys = memberKeys.filter((key) => typeof catalog[key] === 'string');
    const surroundingWhitespaceKeys = memberCatalogKeys.filter(
        (key) => catalog[key] !== catalog[key].trim(),
    );
    const nonNormalizedKeys = memberCatalogKeys.filter(
        (key) => catalog[key] !== catalog[key].normalize('NFC'),
    );
    const unsafeControlKeys = memberCatalogKeys.filter(
        (key) => unsafeControlPattern.test(catalog[key]),
    );
    const placeholderMismatchKeys = memberCatalogKeys.filter(
        (key) => JSON.stringify(placeholders(catalog[key])) !== JSON.stringify(placeholders(english[key])),
    );
    const allowedIdenticalTerms = intentionalIdenticalMemberTerms[locale] ?? new Set();
    const fallbackKeys = sourceCatalogLocales.has(locale) ? [] : memberKeys.filter(
        (key) => catalog[key] === english[key] && ! allowedIdenticalTerms.has(key),
    );
    const localized = memberKeys.length - fallbackKeys.length;
    const baselineLocalized = baseline[locale];

    if (missing.length || extra.length || empty.length) {
        failures.push(
            `${locale}: missing=${missing.length}, extra=${extra.length}, empty=${empty.length}`,
        );
    }

    if (surroundingWhitespaceKeys.length || nonNormalizedKeys.length || unsafeControlKeys.length || placeholderMismatchKeys.length) {
        failures.push(
            `${locale}: whitespace=${surroundingWhitespaceKeys.length}, normalization=${nonNormalizedKeys.length}, unsafe-controls=${unsafeControlKeys.length}, placeholders=${placeholderMismatchKeys.length}`,
        );
    }

    if (launchReadyLocales.includes(locale) && fallbackKeys.length) {
        failures.push(`${locale}: launch-ready catalog has ${fallbackKeys.length} English fallbacks`);
    }

    if (! Number.isInteger(baselineLocalized) || baselineLocalized < 0 || baselineLocalized > memberKeys.length) {
        failures.push(`${locale}: localization baseline is invalid`);
    } else if (localized < baselineLocalized) {
        failures.push(`${locale}: localized coverage regressed from ${baselineLocalized} to ${localized}`);
    }

    rows.push({
        locale,
        status: launchReadyLocales.includes(locale) ? 'launch-ready' : 'draft',
        memberKeys: memberKeys.length,
        localized,
        baselineLocalized,
        progress: localized === memberKeys.length ? 'complete' : 'in-progress',
        englishFallbacks: fallbackKeys.length,
        fallbackKeys,
        qualityIssueKeys: {
            surroundingWhitespace: surroundingWhitespaceKeys,
            nonNormalized: nonNormalizedKeys,
            unsafeControls: unsafeControlKeys,
            placeholderMismatch: placeholderMismatchKeys,
        },
    });
}

for (const locale of launchReadyLocales) {
    if (! targetLocales.includes(locale)) {
        failures.push(`${locale}: launch-ready locale is not a launch target`);
    }
}

if (outputFormat === 'json') {
    console.log(JSON.stringify({ catalogs: rows, failures }, null, 2));
} else {
    console.table(rows.map(({ fallbackKeys, ...row }) => row));
}

if (failures.length) {
    if (outputFormat === 'table') {
        console.error('\nLocalization audit failed:');
        failures.forEach((failure) => console.error(`- ${failure}`));
    }
    process.exit(1);
}

if (outputFormat === 'table') {
    console.log(`\n${targetLocales.length} target catalogs have exact key parity with English.`);
    console.log('Draft means translation/native-language review is still required.');
}
