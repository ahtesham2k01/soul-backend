import assert from 'node:assert/strict';
import { execFileSync, spawnSync } from 'node:child_process';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import test from 'node:test';

const auditScript = path.resolve('scripts/audit-migration-identifiers.mjs');

const fixture = (migration) => {
    const root = fs.mkdtempSync(path.join(os.tmpdir(), 'soul-migrations-'));
    fs.mkdirSync(path.join(root, 'database/migrations'), { recursive: true });
    fs.writeFileSync(path.join(root, 'database/migrations/fixture.php'), migration);
    return root;
};

test('repository migrations stay within the MySQL identifier limit', () => {
    const report = JSON.parse(execFileSync(process.execPath, [auditScript], { encoding: 'utf8' }));

    assert.equal(report.maximumIdentifierLength, 64);
    assert.ok(report.migrations > 0);
    assert.deepEqual(report.failures, []);
});

test('overlong generated compound indexes are rejected', (context) => {
    const root = fixture(`<?php
Schema::create('exceptionally_long_member_relationship_records', function ($table) {
    $table->index(['first_participant_user_id', 'second_participant_user_id']);
});
`);
    context.after(() => fs.rmSync(root, { recursive: true, force: true }));
    const result = spawnSync(process.execPath, [auditScript], {
        encoding: 'utf8',
        env: { ...process.env, SOUL_MIGRATION_ROOT: root },
    });
    const report = JSON.parse(result.stdout);

    assert.equal(result.status, 1);
    assert.equal(report.failures.length, 1);
    assert.ok(report.failures[0].length > 64);
});

test('an explicit short index name avoids a false failure', (context) => {
    const root = fixture(`<?php
Schema::create('exceptionally_long_member_relationship_records', function ($table) {
    $table->index(['first_participant_user_id', 'second_participant_user_id'], 'member_relationship_pair_index');
});
`);
    context.after(() => fs.rmSync(root, { recursive: true, force: true }));
    const result = spawnSync(process.execPath, [auditScript], {
        encoding: 'utf8',
        env: { ...process.env, SOUL_MIGRATION_ROOT: root },
    });

    assert.equal(result.status, 0);
    assert.deepEqual(JSON.parse(result.stdout).failures, []);
});

test('arrow-function schema changes are audited', (context) => {
    const root = fixture(`<?php
Schema::table('exceptionally_long_member_relationship_records', fn ($table) => $table->unique(['first_participant_user_id', 'second_participant_user_id']));
`);
    context.after(() => fs.rmSync(root, { recursive: true, force: true }));
    const result = spawnSync(process.execPath, [auditScript], {
        encoding: 'utf8',
        env: { ...process.env, SOUL_MIGRATION_ROOT: root },
    });

    assert.equal(result.status, 1);
    assert.equal(JSON.parse(result.stdout).failures.length, 1);
});
