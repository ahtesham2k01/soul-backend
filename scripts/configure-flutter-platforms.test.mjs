import assert from 'node:assert/strict';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import test from 'node:test';
import { spawnSync } from 'node:child_process';

const script = path.resolve('scripts/configure-flutter-platforms.mjs');

test('adds the iOS photo permission once and remains idempotent', () => {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), 'soul-flutter-'));
  const runner = path.join(root, 'ios', 'Runner');
  fs.mkdirSync(runner, { recursive: true });
  const plist = path.join(runner, 'Info.plist');
  fs.writeFileSync(plist, '<?xml version="1.0"?><plist><dict>\n</dict></plist>\n');

  for (let attempt = 0; attempt < 2; attempt++) {
    const result = spawnSync(process.execPath, [script, root], { encoding: 'utf8' });
    assert.equal(result.status, 0, result.stderr);
  }

  const configured = fs.readFileSync(plist, 'utf8');
  assert.equal(
    configured.match(/NSPhotoLibraryUsageDescription/g)?.length,
    1,
  );
  assert.match(configured, /SOUL uses your selected photos/);
});

test('fails safely when Flutter runner projects were not generated', () => {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), 'soul-flutter-'));
  const result = spawnSync(process.execPath, [script, root], { encoding: 'utf8' });
  assert.notEqual(result.status, 0);
  assert.match(result.stderr, /Missing generated iOS Info\.plist/);
});
