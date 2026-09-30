import DeviceCheck
import Flutter
import UIKit
import XCTest

@testable import taro_attestation

// XCTest suite of the Swift plugin code, measured with xccov as the coverage
// unit taro_attestation_ios (06 §5.2, RC40). Run it with
// `tools/ci/native_coverage_ios.sh`.

private struct SomeError: Error {}

private func dcError(_ code: DCError.Code) -> NSError {
  NSError(domain: DCErrorDomain, code: code.rawValue)
}

/// Scripted App Attest: answers every call with the configured values.
private final class FakeAppAttest: AppAttestServicing {
  var isSupported = true
  var keyId: String? = "key-1"
  var object: Data? = Data([0xA1, 0x01])
  var error: Error?
  var calls: [String] = []
  var hashes: [Data] = []

  func generateKey(completionHandler: @escaping (String?, Error?) -> Void) {
    calls.append("generateKey")
    completionHandler(error == nil ? keyId : nil, error)
  }

  func attestKey(
    _ keyId: String, clientDataHash: Data, completionHandler: @escaping (Data?, Error?) -> Void
  ) {
    calls.append("attestKey \(keyId)")
    hashes.append(clientDataHash)
    completionHandler(error == nil ? object : nil, error)
  }

  func generateAssertion(
    _ keyId: String, clientDataHash: Data, completionHandler: @escaping (Data?, Error?) -> Void
  ) {
    calls.append("generateAssertion \(keyId)")
    hashes.append(clientDataHash)
    completionHandler(error == nil ? object : nil, error)
  }
}

/// Scripted DeviceCheck.
private final class FakeDeviceCheck: DeviceCheckServicing {
  var isSupported = true
  var token: Data? = Data([0x0D, 0x0C])
  var error: Error?

  func generateToken(completionHandler: @escaping (Data?, Error?) -> Void) {
    completionHandler(error == nil ? token : nil, error)
  }
}

class RunnerTests: XCTestCase {
  private var appAttest: FakeAppAttest!
  private var deviceCheck: FakeDeviceCheck!
  private var plugin: TaroAttestationPlugin!
  private let clientHash = FlutterStandardTypedData(bytes: Data(repeating: 7, count: 32))

  override func setUp() {
    super.setUp()
    appAttest = FakeAppAttest()
    deviceCheck = FakeDeviceCheck()
    plugin = TaroAttestationPlugin(appAttest: appAttest, deviceCheck: deviceCheck)
  }

  /// Calls [method] and waits for the answer (delivered on the main queue).
  private func invoke(_ method: String, _ arguments: Any? = nil) -> Any? {
    let answered = expectation(description: "\(method) answers")
    var answer: Any?
    plugin.handle(FlutterMethodCall(methodName: method, arguments: arguments)) { value in
      answer = value
      answered.fulfill()
    }
    wait(for: [answered], timeout: 5)
    return answer
  }

  private func assertError(
    _ answer: Any?, _ code: String, file: StaticString = #filePath, line: UInt = #line
  ) {
    guard let error = answer as? FlutterError else {
      return XCTFail("expected FlutterError(\(code)), got \(String(describing: answer))",
        file: file, line: line)
    }
    XCTAssertEqual(error.code, code, file: file, line: line)
  }

  private var keyAndHash: [String: Any] { ["keyId": "key-1", "clientDataHash": clientHash] }

  // MARK: isSupported

  func testIsSupportedMirrorsAppAttest() {
    XCTAssertEqual(invoke("isSupported") as? Bool, true)
    appAttest.isSupported = false
    XCTAssertEqual(invoke("isSupported") as? Bool, false)
  }

  // MARK: generateKey

  func testGenerateKeyReturnsTheKeyId() {
    XCTAssertEqual(invoke("generateKey") as? String, "key-1")
  }

  func testGenerateKeyWithoutAppAttestIsUnsupported() {
    appAttest.isSupported = false
    assertError(invoke("generateKey"), "unsupported")
    XCTAssertEqual(appAttest.calls, [])
  }

  func testEveryDeviceCheckErrorMapsToItsKind() {
    let cases: [(Error, String)] = [
      (dcError(.featureUnsupported), "unsupported"),
      (dcError(.invalidKey), "keyInvalidated"),
      (dcError(.invalidInput), "rejected"),
      (dcError(.serverUnavailable), "transient"),
      (dcError(.unknownSystemFailure), "transient"),
      (NSError(domain: DCErrorDomain, code: 999), "transient"),
      (NSError(domain: NSURLErrorDomain, code: NSURLErrorTimedOut), "transient"),
      (SomeError(), "transient"),
    ]
    for (error, code) in cases {
      appAttest.error = error
      assertError(invoke("generateKey"), code)
      assertError(invoke("attestKey", keyAndHash), code)
      assertError(invoke("generateAssertion", keyAndHash), code)
      deviceCheck.error = error
      assertError(invoke("deviceCheckToken"), code)
    }
  }

  func testErrorMessagesNameTheDomainAndCode() {
    appAttest.error = dcError(.invalidKey)
    let error = invoke("generateAssertion", keyAndHash) as? FlutterError
    XCTAssertEqual(error?.message, "\(DCErrorDomain)(\(DCError.Code.invalidKey.rawValue))")
  }

  func testAnEmptyAnswerIsTransient() {
    appAttest.keyId = nil
    appAttest.object = nil
    deviceCheck.token = nil
    assertError(invoke("generateKey"), "transient")
    assertError(invoke("attestKey", keyAndHash), "transient")
    assertError(invoke("generateAssertion", keyAndHash), "transient")
    assertError(invoke("deviceCheckToken"), "transient")
    XCTAssertEqual((invoke("generateKey") as? FlutterError)?.message, "empty answer")
  }

  // MARK: attestKey / generateAssertion

  func testAttestKeyReturnsTheAttestationObject() {
    let answer = invoke("attestKey", keyAndHash) as? FlutterStandardTypedData
    XCTAssertEqual(answer?.data, Data([0xA1, 0x01]))
    XCTAssertEqual(appAttest.calls, ["attestKey key-1"])
    XCTAssertEqual(appAttest.hashes, [clientHash.data])
  }

  func testGenerateAssertionReturnsTheAssertion() {
    appAttest.object = Data([0xB2])
    let answer = invoke("generateAssertion", keyAndHash) as? FlutterStandardTypedData
    XCTAssertEqual(answer?.data, Data([0xB2]))
    XCTAssertEqual(appAttest.calls, ["generateAssertion key-1"])
    XCTAssertEqual(appAttest.hashes, [clientHash.data])
  }

  func testMissingArgumentsAreRejected() {
    for method in ["attestKey", "generateAssertion"] {
      assertError(invoke(method, nil), "rejected")
      assertError(invoke(method, ["keyId": "key-1"]), "rejected")
      assertError(invoke(method, ["clientDataHash": clientHash]), "rejected")
      assertError(invoke(method, ["keyId": 1, "clientDataHash": clientHash]), "rejected")
    }
    XCTAssertEqual(appAttest.calls, [])
  }

  func testAttestAndAssertWithoutAppAttestAreUnsupported() {
    appAttest.isSupported = false
    assertError(invoke("attestKey", keyAndHash), "unsupported")
    assertError(invoke("generateAssertion", keyAndHash), "unsupported")
    XCTAssertEqual(appAttest.calls, [])
  }

  // MARK: deviceCheckToken

  func testDeviceCheckTokenReturnsTheToken() {
    let answer = invoke("deviceCheckToken") as? FlutterStandardTypedData
    XCTAssertEqual(answer?.data, Data([0x0D, 0x0C]))
  }

  func testDeviceCheckWithoutSupportIsUnsupported() {
    deviceCheck.isSupported = false
    let error = invoke("deviceCheckToken") as? FlutterError
    XCTAssertEqual(error?.code, "unsupported")
    XCTAssertEqual(error?.message, "DeviceCheck is not supported")
  }

  // MARK: other methods

  func testAndroidAndUnknownMethodsAreNotImplemented() {
    for method in ["prepareStandard", "requestStandardToken", "androidId", "unknownMethod"] {
      XCTAssertTrue((invoke(method) as AnyObject) === FlutterMethodNotImplemented, method)
    }
  }

  // MARK: system services (the simulator has neither App Attest nor DeviceCheck)

  func testSystemServicesAnswerOnTheSimulator() {
    let system = SystemAppAttestService()
    XCTAssertFalse(system.isSupported)
    let done = expectation(description: "system App Attest answers")
    done.expectedFulfillmentCount = 3
    system.generateKey { keyId, error in
      XCTAssertNil(keyId)
      XCTAssertNotNil(error)
      done.fulfill()
    }
    system.attestKey("key", clientDataHash: clientHash.data) { object, error in
      XCTAssertNil(object)
      XCTAssertNotNil(error)
      done.fulfill()
    }
    system.generateAssertion("key", clientDataHash: clientHash.data) { assertion, error in
      XCTAssertNil(assertion)
      XCTAssertNotNil(error)
      done.fulfill()
    }
    let device = SystemDeviceCheckService()
    XCTAssertFalse(device.isSupported)
    let token = expectation(description: "system DeviceCheck answers")
    device.generateToken { data, error in
      XCTAssertNil(data)
      XCTAssertNotNil(error)
      token.fulfill()
    }
    wait(for: [done, token], timeout: 10)
  }

  func testTheDefaultPluginUsesTheSystemServices() {
    plugin = TaroAttestationPlugin()
    XCTAssertEqual(invoke("isSupported") as? Bool, false)
    assertError(invoke("generateKey"), "unsupported")
    assertError(invoke("deviceCheckToken"), "unsupported")
  }
}
