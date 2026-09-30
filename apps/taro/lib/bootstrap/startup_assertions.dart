import 'package:taro/bootstrap/build_defines.dart';
import 'package:taro/bootstrap/flavor_config.dart';
import 'package:taro/services/attestation/debug_attestation_service.dart';
import 'package:taro_core/taro_core.dart';

/// The startup checks of 02 §15 (run by `bootstrap` in every build, not as
/// `assert`s, so a release build fails fast too):
///
/// * `IapCatalog.validate()`: every product ID is fully qualified (rule 9);
/// * in prod, the CSPRNG is the [SecureRandomSource] (never
///   `SeededRandomSource`), the attestation is never the
///   [DebugAttestationService], and `TARO_ENV=test` is not set.
///
/// Throws [StateError] (or the catalog's error) on a violation.
void assertStartup({
  required FlavorConfig flavor,
  required RandomSource random,
  required AttestationService attestation,
  String taroEnv = BuildDefines.taroEnv,
}) {
  IapCatalog.validate();
  if (!flavor.isProd) return;
  if (random is! SecureRandomSource) {
    throw StateError('A prod build must draw with SecureRandomSource.');
  }
  if (attestation is DebugAttestationService) {
    throw StateError('A prod build must not use DebugAttestationService.');
  }
  if (taroEnv == BuildDefines.testEnv) {
    throw StateError('A prod build must not run with TARO_ENV=test.');
  }
}
