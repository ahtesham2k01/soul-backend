import assert from 'node:assert/strict';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import test from 'node:test';
import { spawnSync } from 'node:child_process';

const script = path.resolve('scripts/configure-flutter-platforms.mjs');

test('adds iOS photo permission and Apple sign-in once', () => {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), 'soul-flutter-'));
  const runner = path.join(root, 'ios', 'Runner');
  fs.mkdirSync(runner, { recursive: true });
  const xcode = path.join(root, 'ios', 'Runner.xcodeproj');
  fs.mkdirSync(xcode, { recursive: true });
  const plist = path.join(runner, 'Info.plist');
  fs.writeFileSync(plist, '<?xml version="1.0"?><plist><dict>\n</dict></plist>\n');
  fs.writeFileSync(path.join(xcode, 'project.pbxproj'), 'buildSettings = {\n  PRODUCT_BUNDLE_IDENTIFIER = com.soul.test;\n};\n');

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
  const project = fs.readFileSync(path.join(xcode, 'project.pbxproj'), 'utf8');
  assert.equal(project.match(/CODE_SIGN_ENTITLEMENTS/g)?.length, 1);
  assert.match(fs.readFileSync(path.join(runner, 'Runner.entitlements'), 'utf8'), /com\.apple\.developer\.applesignin/);
});

test('fails safely when Flutter runner projects were not generated', () => {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), 'soul-flutter-'));
  const result = spawnSync(process.execPath, [script, root], { encoding: 'utf8' });
  assert.notEqual(result.status, 0);
  assert.match(result.stderr, /Missing generated iOS Info\.plist/);
});
