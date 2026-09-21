import Flutter
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
