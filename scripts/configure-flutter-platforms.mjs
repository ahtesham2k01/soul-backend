import fs from 'node:fs';
import path from 'node:path';

const appRoot = path.resolve(process.argv[2] ?? 'apps/member_app');
const plistPath = path.join(appRoot, 'ios', 'Runner', 'Info.plist');
const entitlementPath = path.join(appRoot, 'ios', 'Runner', 'Runner.entitlements');
const projectPath = path.join(appRoot, 'ios', 'Runner.xcodeproj', 'project.pbxproj');

if (!fs.existsSync(plistPath)) {
  console.error(`Missing generated iOS Info.plist: ${plistPath}`);
  process.exit(1);
}
if (!fs.existsSync(projectPath)) {
  console.error(`Missing generated iOS Xcode project: ${projectPath}`);
  process.exit(1);
}

let plist = fs.readFileSync(plistPath, 'utf8');
const key = '<key>NSPhotoLibraryUsageDescription</key>';
if (!plist.includes(key)) {
  const insertion = [
    '\t<key>NSPhotoLibraryUsageDescription</key>',
    '\t<string>SOUL uses your selected photos to create and review your matchmaking profile.</string>',
  ].join('\n');
  plist = plist.replace(/\n<\/dict>/, `\n${insertion}\n</dict>`);
  fs.writeFileSync(plistPath, plist);
}

const entitlement = `<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>com.apple.developer.applesignin</key>
	<array><string>Default</string></array>
</dict>
</plist>
`;
fs.writeFileSync(entitlementPath, entitlement);

let project = fs.readFileSync(projectPath, 'utf8');
if (!project.includes('CODE_SIGN_ENTITLEMENTS = Runner/Runner.entitlements;')) {
  project = project.replace(
    /(\s+)(PRODUCT_BUNDLE_IDENTIFIER = com\.soul\.[^;]+;)/g,
    '$1CODE_SIGN_ENTITLEMENTS = Runner/Runner.entitlements;$1$2',
  );
  fs.writeFileSync(projectPath, project);
}

if (!plist.includes(key)) {
  console.error('Unable to configure iOS photo-library permission.');
  process.exit(1);
}
if (!fs.readFileSync(projectPath, 'utf8').includes('CODE_SIGN_ENTITLEMENTS = Runner/Runner.entitlements;')) {
  console.error('Unable to configure Sign in with Apple entitlement.');
  process.exit(1);
}

console.log('Flutter native permission and sign-in configuration is ready.');
