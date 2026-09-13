import fs from 'node:fs';
import path from 'node:path';

const root = process.cwd();
const languageDirectory = path.join(root, 'resources', 'lang');
const configSource = fs.readFileSync(path.join(root, 'config', 'soul.php'), 'utf8');

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
const english = JSON.parse(
    fs.readFileSync(path.join(languageDirectory, 'en.json'), 'utf8'),
);
const englishKeys = Object.keys(english).sort();
const memberKeys = englishKeys.filter((key) => ! key.startsWith('admin.'));
const intentionalIdenticalMemberTerms = {
    es: new Set(['profile.answer_no']),
    fr: new Set(['notifications.title']),
};
const failures = [];
const rows = [];

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
    const allowedIdenticalTerms = intentionalIdenticalMemberTerms[locale] ?? new Set();
    const unchanged = memberKeys.filter(
        (key) => catalog[key] === english[key] && ! allowedIdenticalTerms.has(key),
    ).length;

    if (missing.length || extra.length || empty.length) {
        failures.push(
            `${locale}: missing=${missing.length}, extra=${extra.length}, empty=${empty.length}`,
        );
    }

    rows.push({
        locale,
        status: launchReadyLocales.includes(locale) ? 'launch-ready' : 'draft',
        memberKeys: memberKeys.length,
        localized: memberKeys.length - unchanged,
        englishFallbacks: unchanged,
    });
}

for (const locale of launchReadyLocales) {
    if (! targetLocales.includes(locale)) {
        failures.push(`${locale}: launch-ready locale is not a launch target`);
    }
}

console.table(rows);

if (failures.length) {
    console.error('\nLocalization audit failed:');
    failures.forEach((failure) => console.error(`- ${failure}`));
    process.exit(1);
}

console.log(`\n${targetLocales.length} target catalogs have exact key parity with English.`);
console.log('Draft means translation/native-language review is still required.');
