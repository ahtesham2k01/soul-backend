import assert from 'node:assert/strict';
import { execFileSync, spawnSync } from 'node:child_process';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import test from 'node:test';

const auditScript = path.resolve('scripts/audit-localization.mjs');

const createFixture = () => {
    const root = fs.mkdtempSync(path.join(os.tmpdir(), 'soul-localization-'));
    fs.mkdirSync(path.join(root, 'config'), { recursive: true });
    fs.mkdirSync(path.join(root, 'resources'), { recursive: true });
    fs.copyFileSync('config/soul.php', path.join(root, 'config/soul.php'));
    fs.copyFileSync(
        'config/localization-baseline.json',
        path.join(root, 'config/localization-baseline.json'),
    );
    fs.cpSync('resources/lang', path.join(root, 'resources/lang'), { recursive: true });
    return root;
};

const runAudit = (root) => spawnSync(
    process.execPath,
    [auditScript, '--format=json'],
    {
        encoding: 'utf8',
        env: { ...process.env, SOUL_LOCALIZATION_ROOT: root },
    },
);

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

test('a launch-ready catalog with a new English fallback is rejected', (context) => {
    const root = createFixture();
    context.after(() => fs.rmSync(root, { recursive: true, force: true }));
    const catalogPath = path.join(root, 'resources/lang/ur.json');
    const catalog = JSON.parse(fs.readFileSync(catalogPath, 'utf8'));
    catalog['common.close'] = 'Close';
    fs.writeFileSync(catalogPath, `${JSON.stringify(catalog, null, 2)}\n`);

    const result = runAudit(root);
    const report = JSON.parse(result.stdout);

    assert.equal(result.status, 1);
    assert.ok(report.failures.some((failure) => failure.includes('ur: launch-ready catalog')));
    assert.deepEqual(
        report.catalogs.find(({ locale }) => locale === 'ur').fallbackKeys,
        ['common.close'],
    );
    assert.ok(! result.stdout.includes('Band karein'));
});

test('missing and unexpected keys are reported as catalog drift', (context) => {
    const root = createFixture();
    context.after(() => fs.rmSync(root, { recursive: true, force: true }));
    const catalogPath = path.join(root, 'resources/lang/es.json');
    const catalog = JSON.parse(fs.readFileSync(catalogPath, 'utf8'));
    delete catalog['common.close'];
    catalog['unexpected.member_key'] = 'No debe existir';
    fs.writeFileSync(catalogPath, `${JSON.stringify(catalog, null, 2)}\n`);

    const result = runAudit(root);
    const report = JSON.parse(result.stdout);

    assert.equal(result.status, 1);
    assert.ok(report.failures.includes('es: missing=1, extra=1, empty=0'));
});

test('JSON report exposes fallback keys but never catalog values', () => {
    const output = execFileSync(
        process.execPath,
        [auditScript, '--format=json'],
        { encoding: 'utf8' },
    );

    assert.ok(output.includes('fallbackKeys'));
    assert.ok(! output.includes('Correo electrónico'));
    assert.ok(! output.includes('Communications commerciales'));
});

test('localized coverage cannot fall below its committed baseline', (context) => {
    const root = createFixture();
    context.after(() => fs.rmSync(root, { recursive: true, force: true }));
    const catalogPath = path.join(root, 'resources/lang/es.json');
    const catalog = JSON.parse(fs.readFileSync(catalogPath, 'utf8'));
    catalog['common.close'] = 'Close';
    fs.writeFileSync(catalogPath, `${JSON.stringify(catalog, null, 2)}\n`);

    const result = runAudit(root);
    const report = JSON.parse(result.stdout);

    assert.equal(result.status, 1);
    assert.ok(report.failures.includes('es: localized coverage regressed from 179 to 178'));
});

test('baseline locale drift and invalid counts are rejected', (context) => {
    const root = createFixture();
    context.after(() => fs.rmSync(root, { recursive: true, force: true }));
    const baselinePath = path.join(root, 'config/localization-baseline.json');
    const baseline = JSON.parse(fs.readFileSync(baselinePath, 'utf8'));
    delete baseline.sw;
    baseline.unexpected = 1;
    baseline.es = 999;
    fs.writeFileSync(baselinePath, `${JSON.stringify(baseline, null, 2)}\n`);

    const result = runAudit(root);
    const report = JSON.parse(result.stdout);

    assert.equal(result.status, 1);
    assert.ok(report.failures.includes('baseline: missing=1, extra=1'));
    assert.ok(report.failures.includes('es: localization baseline is invalid'));
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
