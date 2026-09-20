import fs from 'node:fs';
import path from 'node:path';

const appRoot = path.resolve(process.argv[2] ?? 'apps/member_app');
const plistPath = path.join(appRoot, 'ios', 'Runner', 'Info.plist');

if (!fs.existsSync(plistPath)) {
  console.error(`Missing generated iOS Info.plist: ${plistPath}`);
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

if (!plist.includes(key)) {
  console.error('Unable to configure iOS photo-library permission.');
  process.exit(1);
}

console.log('Flutter native permission configuration is ready.');
