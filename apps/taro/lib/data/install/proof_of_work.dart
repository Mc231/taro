import 'dart:convert';
import 'dart:isolate';

import 'package:crypto/crypto.dart';

/// Solves the registration proof of work for [challenge], [installId] and
/// difficulty [bits] (03 §2.4, RC65). Replaceable in tests.
typedef ProofOfWorkSolver =
    Future<String> Function({
      required String challenge,
      required String installId,
      required int bits,
    });

/// The longest `pow` the Worker accepts (`POW_MAX_LENGTH`).
const int kProofOfWorkMaxLength = 64;

/// The number of leading zero bits of [bytes].
int leadingZeroBits(List<int> bytes) {
  var bits = 0;
  for (final byte in bytes) {
    if (byte == 0) {
      bits += 8;
      continue;
    }
    var mask = 0x80;
    while (byte & mask == 0) {
      bits++;
      mask >>= 1;
    }
    return bits;
  }
  return bits;
}

/// Whether [pow] solves the challenge: `SHA-256(challenge ‖ installId ‖
/// pow)` (UTF-8) has at least [bits] leading zero bits. Mirrors the
/// Worker's `verifyProofOfWork`.
bool verifiesProofOfWork({
  required String challenge,
  required String installId,
  required String pow,
  required int bits,
}) =>
    pow.isNotEmpty &&
    pow.length <= kProofOfWorkMaxLength &&
    leadingZeroBits(
          sha256.convert(utf8.encode('$challenge$installId$pow')).bytes,
        ) >=
        bits;

/// The smallest decimal counter that solves the challenge. The expected
/// work is `2^bits` hashes (about a million at the default 20 bits).
String solveProofOfWork({
  required String challenge,
  required String installId,
  required int bits,
}) {
  for (var n = 0; ; n++) {
    final pow = '$n';
    if (verifiesProofOfWork(
      challenge: challenge,
      installId: installId,
      pow: pow,
      bits: bits,
    )) {
      return pow;
    }
  }
}

/// [solveProofOfWork] on a background isolate, so the first frame is not
/// blocked on a device without platform attestation.
Future<String> solveProofOfWorkInIsolate({
  required String challenge,
  required String installId,
  required int bits,
}) => Isolate.run(
  () =>
      solveProofOfWork(challenge: challenge, installId: installId, bits: bits),
);
