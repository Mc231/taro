# taro_attestation

Taro's own device-attestation plugin (02 AR9, §6.4; RC12, RC40, RC87).

| Platform | API | Dart methods |
|---|---|---|
| iOS | App Attest (`DCAppAttestService`), DeviceCheck (`DCDevice`) | `isSupported`, `generateKey`, `attestKey`, `generateAssertion`, `deviceCheckToken` |
| Android | Play Integrity **Standard** API (no Classic API), `Settings.Secure.ANDROID_ID` | `isSupported`, `prepareStandard`, `requestStandardToken`, `androidId` |

Every method throws only `TaroAttestationException` with an
`AttestationErrorKind` (`unsupported`, `keyInvalidated`, `rejected`, `quota`,
`transient`). A method of the other platform is `unsupported`. The app adapter
`PlatformAttestationService` (`apps/taro/lib/services/attestation/`) maps the
kind onto `taro_core`'s `AttestationFailureKind` and builds the Worker wire
values (03 §3.3, §3.4, §3.7).

Native error mapping:

| Native | Kind |
|---|---|
| `DCError.featureUnsupported`; Play `API_NOT_AVAILABLE`, `PLAY_STORE_NOT_FOUND`, `PLAY_SERVICES_NOT_FOUND`, `*_VERSION_OUTDATED` | `unsupported` |
| `DCError.invalidKey` | `keyInvalidated` |
| `DCError.invalidInput`; Play `APP_NOT_INSTALLED`, `APP_UID_MISMATCH`, `CLOUD_PROJECT_NUMBER_IS_INVALID`, `REQUEST_HASH_TOO_LONG`; missing arguments | `rejected` |
| Play `TOO_MANY_REQUESTS` | `quota` |
| everything else (`serverUnavailable`, network, provider, internal errors) | `transient` |

The Android side prepares a new token provider once and retries when Play
reports `INTEGRITY_TOKEN_PROVIDER_INVALID`.

## Tests

- Dart: `flutter test` (method-channel mock, every error mapping).
- Swift: `tools/ci/native_coverage_ios.sh` (XCTest in `example/ios/RunnerTests`
  behind `AppAttestServicing` / `DeviceCheckServicing`; iOS simulator).
- Kotlin: `tools/ci/native_coverage_android.sh` (JUnit + Mockito behind
  `IntegrityProvider` / `AndroidIdProvider`; JaCoCo).

Real App Attest and Play Integrity verdicts need a physical device (Sprint 12.6).
