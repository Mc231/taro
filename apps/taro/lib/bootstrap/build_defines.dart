/// Compile-time values outside `config/<flavor>.json` (02 §15, 06 §4).
abstract final class BuildDefines {
  /// `TARO_ENV`: `test` for the fake-backed integration flows (06 §4).
  static const String taroEnv = String.fromEnvironment('TARO_ENV');

  /// `TARO_DEBUG_ATTESTATION_TOKEN`: the dev/staging
  /// `DEBUG_ATTESTATION_TOKEN` for simulators and emulators (RC86). Never
  /// set for prod builds, and ignored there.
  static const String debugAttestationToken = String.fromEnvironment(
    'TARO_DEBUG_ATTESTATION_TOKEN',
  );

  /// The `TARO_ENV` value of the integration flows.
  static const String testEnv = 'test';
}
