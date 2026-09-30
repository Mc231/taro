import DeviceCheck
import Flutter
import UIKit

/// App Attest as the plugin uses it (`DCAppAttestService`), so tests can fake it.
public protocol AppAttestServicing {
  var isSupported: Bool { get }
  func generateKey(completionHandler: @escaping (String?, Error?) -> Void)
  func attestKey(
    _ keyId: String, clientDataHash: Data, completionHandler: @escaping (Data?, Error?) -> Void)
  func generateAssertion(
    _ keyId: String, clientDataHash: Data, completionHandler: @escaping (Data?, Error?) -> Void)
}

/// DeviceCheck as the plugin uses it (`DCDevice`), so tests can fake it.
public protocol DeviceCheckServicing {
  var isSupported: Bool { get }
  func generateToken(completionHandler: @escaping (Data?, Error?) -> Void)
}

/// `DCAppAttestService.shared` behind [AppAttestServicing].
final class SystemAppAttestService: AppAttestServicing {
  private let service = DCAppAttestService.shared

  var isSupported: Bool { service.isSupported }

  func generateKey(completionHandler: @escaping (String?, Error?) -> Void) {
    service.generateKey { keyId, error in completionHandler(keyId, error) }
  }

  func attestKey(
    _ keyId: String, clientDataHash: Data, completionHandler: @escaping (Data?, Error?) -> Void
  ) {
    service.attestKey(keyId, clientDataHash: clientDataHash) { object, error in
      completionHandler(object, error)
    }
  }

  func generateAssertion(
    _ keyId: String, clientDataHash: Data, completionHandler: @escaping (Data?, Error?) -> Void
  ) {
    service.generateAssertion(keyId, clientDataHash: clientDataHash) { assertion, error in
      completionHandler(assertion, error)
    }
  }
}

/// `DCDevice.current` behind [DeviceCheckServicing].
final class SystemDeviceCheckService: DeviceCheckServicing {
  private let device = DCDevice.current

  var isSupported: Bool { device.isSupported }

  func generateToken(completionHandler: @escaping (Data?, Error?) -> Void) {
    device.generateToken { token, error in completionHandler(token, error) }
  }
}

/// The channel error codes, one per Dart `AttestationErrorKind` (02 §6.4).
enum AttestationErrorCode: String {
  case unsupported
  case keyInvalidated
  case rejected
  case quota
  case transient

  /// The code of a DeviceCheck / App Attest error; anything else is transient.
  static func of(_ error: Error) -> AttestationErrorCode {
    let nsError = error as NSError
    guard nsError.domain == DCErrorDomain, let code = DCError.Code(rawValue: nsError.code) else {
      return .transient
    }
    switch code {
    case .featureUnsupported: return .unsupported
    case .invalidKey: return .keyInvalidated
    case .invalidInput: return .rejected
    case .serverUnavailable, .unknownSystemFailure: return .transient
    @unknown default: return .transient
    }
  }
}

/// iOS side of `taro_attestation` (02 AR9, §6.4): App Attest (`generateKey`,
/// `attestKey`, `generateAssertion`) and DeviceCheck (`deviceCheckToken`).
/// The Android methods answer `FlutterMethodNotImplemented`, which the Dart
/// side maps to `unsupported`. Errors are `FlutterError(code:)` with an
/// [AttestationErrorCode]; messages never carry keys or tokens.
public class TaroAttestationPlugin: NSObject, FlutterPlugin {
  static let channelName = "taro_attestation"

  private let appAttest: AppAttestServicing
  private let deviceCheck: DeviceCheckServicing
  private let deliver: (@escaping () -> Void) -> Void

  /// A plugin over [appAttest] and [deviceCheck]; results are handed to
  /// Flutter through [deliver] (the main queue by default).
  init(
    appAttest: AppAttestServicing = SystemAppAttestService(),
    deviceCheck: DeviceCheckServicing = SystemDeviceCheckService(),
    deliver: @escaping (@escaping () -> Void) -> Void = { block in
      DispatchQueue.main.async(execute: block)
    }
  ) {
    self.appAttest = appAttest
    self.deviceCheck = deviceCheck
    self.deliver = deliver
  }

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: channelName, binaryMessenger: registrar.messenger())
    registrar.addMethodCallDelegate(TaroAttestationPlugin(), channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "isSupported":
      result(appAttest.isSupported)
    case "generateKey":
      guard appAttest.isSupported else { return result(Self.unsupported("App Attest")) }
      appAttest.generateKey { keyId, error in
        self.finish(result, keyId, error)
      }
    case "attestKey":
      withKeyAndHash(call, result) { keyId, hash in
        self.appAttest.attestKey(keyId, clientDataHash: hash) { object, error in
          self.finish(result, object.map(FlutterStandardTypedData.init(bytes:)), error)
        }
      }
    case "generateAssertion":
      withKeyAndHash(call, result) { keyId, hash in
        self.appAttest.generateAssertion(keyId, clientDataHash: hash) { assertion, error in
          self.finish(result, assertion.map(FlutterStandardTypedData.init(bytes:)), error)
        }
      }
    case "deviceCheckToken":
      guard deviceCheck.isSupported else { return result(Self.unsupported("DeviceCheck")) }
      deviceCheck.generateToken { token, error in
        self.finish(result, token.map(FlutterStandardTypedData.init(bytes:)), error)
      }
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  /// Runs [body] with the `keyId` and `clientDataHash` arguments, or answers
  /// `rejected` when one is missing and `unsupported` without App Attest.
  private func withKeyAndHash(
    _ call: FlutterMethodCall, _ result: @escaping FlutterResult,
    _ body: (String, Data) -> Void
  ) {
    guard appAttest.isSupported else { return result(Self.unsupported("App Attest")) }
    let args = call.arguments as? [String: Any]
    guard let keyId = args?["keyId"] as? String,
      let hash = args?["clientDataHash"] as? FlutterStandardTypedData
    else {
      return result(
        FlutterError(
          code: AttestationErrorCode.rejected.rawValue,
          message: "keyId and clientDataHash are required", details: nil))
    }
    body(keyId, hash.data)
  }

  /// Hands [value] or the mapped [error] to Flutter; neither is `transient`.
  private func finish(_ result: @escaping FlutterResult, _ value: Any?, _ error: Error?) {
    let answer: Any
    if let error = error {
      let nsError = error as NSError
      answer = FlutterError(
        code: AttestationErrorCode.of(error).rawValue,
        message: "\(nsError.domain)(\(nsError.code))", details: nil)
    } else if let value = value {
      answer = value
    } else {
      answer = FlutterError(
        code: AttestationErrorCode.transient.rawValue, message: "empty answer", details: nil)
    }
    deliver { result(answer) }
  }

  private static func unsupported(_ api: String) -> FlutterError {
    FlutterError(
      code: AttestationErrorCode.unsupported.rawValue, message: "\(api) is not supported",
      details: nil)
  }
}
