import fs from 'node:fs';
import path from 'node:path';

const appRoot = path.resolve(process.argv[2] ?? 'apps/member_app');
const plistPath = path.join(appRoot, 'ios', 'Runner', 'Info.plist');
const entitlementPath = path.join(appRoot, 'ios', 'Runner', 'Runner.entitlements');
const appDelegatePath = path.join(appRoot, 'ios', 'Runner', 'AppDelegate.swift');
const projectPath = path.join(appRoot, 'ios', 'Runner.xcodeproj', 'project.pbxproj');
const androidManifestPath = path.join(appRoot, 'android', 'app', 'src', 'main', 'AndroidManifest.xml');
const androidBuildPath = path.join(appRoot, 'android', 'app', 'build.gradle.kts');
const kotlinRoot = path.join(appRoot, 'android', 'app', 'src', 'main', 'kotlin');

for (const [label, file] of [
  ['iOS Info.plist', plistPath],
  ['iOS AppDelegate.swift', appDelegatePath],
  ['iOS Xcode project', projectPath],
  ['Android manifest', androidManifestPath],
  ['Android app Gradle file', androidBuildPath],
]) {
  if (!fs.existsSync(file)) {
    console.error(`Missing generated ${label}: ${file}`);
    process.exit(1);
  }
}

const findMainActivity = (directory) => {
  if (!fs.existsSync(directory)) return null;
  for (const entry of fs.readdirSync(directory, { withFileTypes: true })) {
    const candidate = path.join(directory, entry.name);
    if (entry.isDirectory()) {
      const nested = findMainActivity(candidate);
      if (nested) return nested;
    } else if (entry.name === 'MainActivity.kt') {
      return candidate;
    }
  }
  return null;
};

const mainActivityPath = findMainActivity(kotlinRoot);
if (mainActivityPath === null) {
  console.error(`Missing generated Android MainActivity under: ${kotlinRoot}`);
  process.exit(1);
}

let plist = fs.readFileSync(plistPath, 'utf8');
for (const [key, insertion] of [
  [
    'NSPhotoLibraryUsageDescription',
    '<key>NSPhotoLibraryUsageDescription</key>\n\t<string>SOUL uses your selected photos to create and review your matchmaking profile.</string>',
  ],
  [
    'NSCameraUsageDescription',
    '<key>NSCameraUsageDescription</key>\n\t<string>SOUL uses the camera only when you choose to take a profile or verification photo.</string>',
  ],
  [
    'NSLocationWhenInUseUsageDescription',
    '<key>NSLocationWhenInUseUsageDescription</key>\n\t<string>SOUL uses your location while the app is open to resolve your current city for matchmaking.</string>',
  ],
]) {
  if (!plist.includes(`<key>${key}</key>`)) {
    plist = plist.replace(/\n<\/dict>/, `\n\t${insertion}\n</dict>`);
  }
}
if (!plist.includes('<key>UIBackgroundModes</key>')) {
  plist = plist.replace(
    /\n<\/dict>/,
    '\n\t<key>UIBackgroundModes</key>\n\t<array>\n\t\t<string>remote-notification</string>\n\t</array>\n</dict>',
  );
}
plist = plist
  .replace('<string>Soul Member App</string>', '<string>SOUL</string>')
  .replace('<string>soul_member_app</string>', '<string>SOUL</string>');
fs.writeFileSync(plistPath, plist);

const apsEnvironment = process.env.SOUL_APS_ENVIRONMENT === 'production'
  ? 'production'
  : 'development';
fs.writeFileSync(
  entitlementPath,
  `<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
\t<key>aps-environment</key>
\t<string>${apsEnvironment}</string>
\t<key>com.apple.developer.applesignin</key>
\t<array><string>Default</string></array>
</dict>
</plist>
`,
);

let project = fs.readFileSync(projectPath, 'utf8');
if (!project.includes('CODE_SIGN_ENTITLEMENTS = Runner/Runner.entitlements;')) {
  project = project.replace(
    /(\s+)(PRODUCT_BUNDLE_IDENTIFIER = com\.soul\.[^;]+;)/g,
    '$1CODE_SIGN_ENTITLEMENTS = Runner/Runner.entitlements;$1$2',
  );
}
fs.writeFileSync(projectPath, project);

fs.writeFileSync(appDelegatePath, `import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate, FlutterStreamHandler {
  private var securityEventSink: FlutterEventSink?
  private var securityEnabled = false
  private var captureObserver: NSObjectProtocol?
  private var screenshotObserver: NSObjectProtocol?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    captureObserver = NotificationCenter.default.addObserver(
      forName: UIScreen.capturedDidChangeNotification,
      object: nil,
      queue: .main
    ) { [weak self] _ in
      self?.emitRecordingState()
    }
    screenshotObserver = NotificationCenter.default.addObserver(
      forName: UIApplication.userDidTakeScreenshotNotification,
      object: nil,
      queue: .main
    ) { [weak self] _ in
      guard let self, self.securityEnabled else { return }
      self.securityEventSink?([
        "type": "screenshot",
        "active": true,
      ])
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    guard let registrar = engineBridge.pluginRegistry.registrar(
      forPlugin: "SoulNativeSecurity"
    ) else {
      return
    }
    let messenger = registrar.messenger()

    let methodChannel = FlutterMethodChannel(
      name: "com.soul/member_security",
      binaryMessenger: messenger
    )
    methodChannel.setMethodCallHandler { [weak self] call, result in
      guard let self else {
        result(FlutterError(code: "SECURITY_UNAVAILABLE", message: nil, details: nil))
        return
      }
      if call.method != "setProtected" {
        result(FlutterMethodNotImplemented)
        return
      }
      let arguments = call.arguments as? [String: Any]
      self.securityEnabled = arguments?["enabled"] as? Bool ?? false
      self.emitRecordingState()
      result(UIScreen.main.isCaptured)
    }

    let eventChannel = FlutterEventChannel(
      name: "com.soul/member_security_events",
      binaryMessenger: messenger
    )
    eventChannel.setStreamHandler(self)
  }

  func onListen(
    withArguments arguments: Any?,
    eventSink events: @escaping FlutterEventSink
  ) -> FlutterError? {
    securityEventSink = events
    emitRecordingState()
    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    securityEventSink = nil
    return nil
  }

  private func emitRecordingState() {
    securityEventSink?([
      "type": "screen_recording",
      "active": securityEnabled && UIScreen.main.isCaptured,
    ])
  }

  deinit {
    if let captureObserver {
      NotificationCenter.default.removeObserver(captureObserver)
    }
    if let screenshotObserver {
      NotificationCenter.default.removeObserver(screenshotObserver)
    }
  }
}
`);

let manifest = fs.readFileSync(androidManifestPath, 'utf8');
for (const permission of [
  'android.permission.CAMERA',
  'android.permission.POST_NOTIFICATIONS',
  'android.permission.ACCESS_COARSE_LOCATION',
  'android.permission.ACCESS_FINE_LOCATION',
]) {
  if (!manifest.includes(`android:name="${permission}"`)) {
    manifest = manifest.replace(
      /<manifest([^>]*)>/,
      `<manifest$1>\n    <uses-permission android:name="${permission}" />`,
    );
  }
}
manifest = manifest.replace(/android:label="[^"]*"/, 'android:label="SOUL"');
fs.writeFileSync(androidManifestPath, manifest);

let androidBuild = fs.readFileSync(androidBuildPath, 'utf8');
androidBuild = androidBuild.replace(
  'minSdk = flutter.minSdkVersion',
  'minSdk = maxOf(flutter.minSdkVersion, 24)',
);
fs.writeFileSync(androidBuildPath, androidBuild);

const originalMainActivity = fs.readFileSync(mainActivityPath, 'utf8');
const packageName = originalMainActivity.match(/^package\s+([^\s]+)/m)?.[1];
if (!packageName) {
  console.error('Unable to determine Android MainActivity package.');
  process.exit(1);
}
fs.writeFileSync(mainActivityPath, `package ${packageName}

import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.soul/member_security",
        ).setMethodCallHandler { call, result ->
            if (call.method != "setProtected") {
                result.notImplemented()
                return@setMethodCallHandler
            }

            val enabled = call.argument<Boolean>("enabled") ?: false
            runOnUiThread {
                if (enabled) {
                    window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
                } else {
                    window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
                }
                result.success(false)
            }
        }

        EventChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.soul/member_security_events",
        ).setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) = Unit
            override fun onCancel(arguments: Any?) = Unit
        })
    }
}
`);

for (const [file, pattern] of [
  [plistPath, /NSPhotoLibraryUsageDescription/],
  [plistPath, /NSCameraUsageDescription/],
  [plistPath, /NSLocationWhenInUseUsageDescription/],
  [plistPath, /remote-notification/],
  [entitlementPath, /com\.apple\.developer\.applesignin/],
  [entitlementPath, /aps-environment/],
  [projectPath, /CODE_SIGN_ENTITLEMENTS = Runner\/Runner\.entitlements;/],
  [appDelegatePath, /guard let registrar/],
  [appDelegatePath, /userDidTakeScreenshotNotification/],
  [androidManifestPath, /android\.permission\.POST_NOTIFICATIONS/],
  [androidManifestPath, /android\.permission\.ACCESS_COARSE_LOCATION/],
  [androidManifestPath, /android\.permission\.ACCESS_FINE_LOCATION/],
  [androidBuildPath, /maxOf\(flutter\.minSdkVersion, 24\)/],
  [mainActivityPath, /FLAG_SECURE/],
]) {
  if (!pattern.test(fs.readFileSync(file, 'utf8'))) {
    console.error(`Unable to configure native Flutter release requirement in ${file}.`);
    process.exit(1);
  }
}

console.log('Flutter native permissions, push entitlements and protected-view hooks are ready.');
