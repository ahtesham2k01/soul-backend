import assert from 'node:assert/strict';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import test from 'node:test';
import { spawnSync } from 'node:child_process';

const script = path.resolve('scripts/configure-flutter-platforms.mjs');

const fixture = () => {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), 'soul-flutter-'));
  const runner = path.join(root, 'ios', 'Runner');
  fs.mkdirSync(runner, { recursive: true });
  const xcode = path.join(root, 'ios', 'Runner.xcodeproj');
  fs.mkdirSync(xcode, { recursive: true });
  fs.writeFileSync(
    path.join(runner, 'Info.plist'),
    '<?xml version="1.0"?><plist><dict>\n<string>Soul Member App</string>\n</dict></plist>\n',
  );
  fs.writeFileSync(path.join(runner, 'AppDelegate.swift'), 'import Flutter\nimport UIKit\n');
  fs.writeFileSync(
    path.join(xcode, 'project.pbxproj'),
    'buildSettings = {\n  PRODUCT_BUNDLE_IDENTIFIER = com.soul.test;\n};\n',
  );

  const android = path.join(root, 'android', 'app');
  const kotlin = path.join(android, 'src', 'main', 'kotlin', 'com', 'soul', 'test');
  fs.mkdirSync(kotlin, { recursive: true });
  fs.writeFileSync(
    path.join(android, 'src', 'main', 'AndroidManifest.xml'),
    '<manifest xmlns:android="http://schemas.android.com/apk/res/android"><application android:label="soul_member_app"/></manifest>\n',
  );
  fs.writeFileSync(
    path.join(android, 'build.gradle.kts'),
    'defaultConfig {\n  minSdk = flutter.minSdkVersion\n}\n',
  );
  fs.writeFileSync(path.join(kotlin, 'MainActivity.kt'), 'package com.soul.test\n\nclass MainActivity\n');
  return root;
};

test('configures native permissions, push and protected-view hooks idempotently', () => {
  const root = fixture();
  for (let attempt = 0; attempt < 2; attempt++) {
    const result = spawnSync(process.execPath, [script, root], { encoding: 'utf8' });
    assert.equal(result.status, 0, result.stderr);
  }

  const plist = fs.readFileSync(path.join(root, 'ios', 'Runner', 'Info.plist'), 'utf8');
  assert.equal(plist.match(/NSPhotoLibraryUsageDescription/g)?.length, 1);
  assert.equal(plist.match(/NSCameraUsageDescription/g)?.length, 1);
  assert.equal(plist.match(/UIBackgroundModes/g)?.length, 1);
  assert.match(plist, /remote-notification/);

  const entitlements = fs.readFileSync(path.join(root, 'ios', 'Runner', 'Runner.entitlements'), 'utf8');
  assert.match(entitlements, /com\.apple\.developer\.applesignin/);
  assert.match(entitlements, /aps-environment/);

  const appDelegate = fs.readFileSync(path.join(root, 'ios', 'Runner', 'AppDelegate.swift'), 'utf8');
  assert.match(appDelegate, /com\.soul\/member_security/);
  assert.match(appDelegate, /userDidTakeScreenshotNotification/);
  assert.match(appDelegate, /capturedDidChangeNotification/);

  const project = fs.readFileSync(path.join(root, 'ios', 'Runner.xcodeproj', 'project.pbxproj'), 'utf8');
  assert.equal(project.match(/CODE_SIGN_ENTITLEMENTS/g)?.length, 1);

  const manifest = fs.readFileSync(path.join(root, 'android', 'app', 'src', 'main', 'AndroidManifest.xml'), 'utf8');
  assert.equal(manifest.match(/android\.permission\.CAMERA/g)?.length, 1);
  assert.equal(manifest.match(/android\.permission\.POST_NOTIFICATIONS/g)?.length, 1);
  assert.match(manifest, /android:label="SOUL"/);

  const gradle = fs.readFileSync(path.join(root, 'android', 'app', 'build.gradle.kts'), 'utf8');
  assert.match(gradle, /maxOf\(flutter\.minSdkVersion, 24\)/);

  const mainActivity = fs.readFileSync(
    path.join(root, 'android', 'app', 'src', 'main', 'kotlin', 'com', 'soul', 'test', 'MainActivity.kt'),
    'utf8',
  );
  assert.match(mainActivity, /FLAG_SECURE/);
  assert.match(mainActivity, /com\.soul\/member_security_events/);
});

test('fails safely when Flutter runner projects were not generated', () => {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), 'soul-flutter-'));
  const result = spawnSync(process.execPath, [script, root], { encoding: 'utf8' });
  assert.notEqual(result.status, 0);
  assert.match(result.stderr, /Missing generated iOS Info\.plist/);
});
