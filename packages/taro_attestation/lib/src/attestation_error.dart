/// Why a platform attestation call failed (02 §6.4).
///
/// Mirrors `AttestationFailureKind` of `taro_core` value for value; the
/// plugin depends on no taro package (02 §2.1), so the app adapter maps one
/// onto the other by name.
enum AttestationErrorKind {
  /// The device, OS or build does not support the API (simulator, no Play
  /// services, the method does not exist on this platform).
  unsupported,

  /// The App Attest key is unknown to the OS (reinstall, restore): generate
  /// and attest a new key.
  keyInvalidated,

  /// The platform refused the request for good (bad input, wrong app
  /// identity, invalid cloud project number).
  rejected,

  /// The platform rate limit is exhausted (Play Integrity
  /// `TOO_MANY_REQUESTS`).
  quota,

  /// A network, server or unknown error: retry later.
  transient;

  /// The kind of the native error [code] sent over the channel (the enum
  /// name); an unknown code is [transient].
  static AttestationErrorKind fromCode(String code) {
    for (final kind in values) {
      if (kind.name == code) return kind;
    }
    return transient;
  }
}

/// The only exception the plugin throws.
final class TaroAttestationException implements Exception {
  /// An exception of [kind], with the native [message] when there is one.
  const TaroAttestationException(this.kind, [this.message]);

  /// What went wrong.
  final AttestationErrorKind kind;

  /// The native description (never contains key material or tokens).
  final String? message;

  @override
  String toString() => message == null
      ? 'TaroAttestationException(${kind.name})'
      : 'TaroAttestationException(${kind.name}): $message';
}
