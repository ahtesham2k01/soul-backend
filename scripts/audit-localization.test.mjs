import assert from 'node:assert/strict';
import { execFileSync, spawnSync } from 'node:child_process';
import test from 'node:test';

test('JSON audit is machine-readable and launch-ready catalogs have no unresolved fallbacks', () => {
    const output = execFileSync(
        process.execPath,
        ['scripts/audit-localization.mjs', '--format=json'],
        { encoding: 'utf8' },
    );
    const report = JSON.parse(output);

    assert.equal(report.failures.length, 0);
    assert.equal(report.catalogs.length, 34);

    for (const catalog of report.catalogs.filter(({ status }) => status === 'launch-ready')) {
        assert.equal(catalog.englishFallbacks, 0, catalog.locale);
        assert.deepEqual(catalog.fallbackKeys, [], catalog.locale);
    }
});

test('unsupported output formats fail without running the audit', () => {
    const result = spawnSync(
        process.execPath,
        ['scripts/audit-localization.mjs', '--format=xml'],
        { encoding: 'utf8' },
    );

    assert.equal(result.status, 2);
    assert.match(result.stderr, /Unsupported format/);
});
