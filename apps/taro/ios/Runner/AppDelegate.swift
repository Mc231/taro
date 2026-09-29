import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "BackupExclusionPlugin") {
      BackupExclusionPlugin.register(with: registrar)
    }
  }
}

/// `taro/backup_exclusion` (02 §6.1, RC75): sets NSURLIsExcludedFromBackupKey
/// on taro_device.db and its -wal/-shm/-journal siblings. Absent files are
/// skipped. Dart side: lib/services/backup/platform_backup_exclusion.dart.
final class BackupExclusionPlugin: NSObject, FlutterPlugin {
  static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "taro/backup_exclusion",
      binaryMessenger: registrar.messenger()
    )
    registrar.addMethodCallDelegate(BackupExclusionPlugin(), channel: channel)
  }

  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard call.method == "exclude",
      let arguments = call.arguments as? [String: Any],
      let paths = arguments["paths"] as? [String]
    else {
      result(FlutterMethodNotImplemented)
      return
    }
    do {
      for path in paths where FileManager.default.fileExists(atPath: path) {
        var url = URL(fileURLWithPath: path)
        var values = URLResourceValues()
        values.isExcludedFromBackup = true
        try url.setResourceValues(values)
      }
      result(nil)
    } catch {
      result(FlutterError(code: "exclude_failed", message: error.localizedDescription, details: nil))
    }
  }
}
