import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taro/data/install/proof_of_work.dart';

const _challenge = 'IQHFT9HQGrIldMs3iq71sQAAAABqt5jMvEl1R6Tv51CAfvvf7KdmAg';
const _installId = 'c0a80101-0000-4000-8000-000000000001';

void main() {
  test('counts leading zero bits', () {
    expect(leadingZeroBits([0x80]), 0);
    expect(leadingZeroBits([0x01]), 7);
    expect(leadingZeroBits([0x00, 0x10]), 11);
    expect(leadingZeroBits([0x00, 0x00]), 16);
    expect(leadingZeroBits([]), 0);
  });

  test('the solution meets the difficulty over SHA-256(challenge ‖ id ‖ '
      'pow), like the Worker', () {
    final pow = solveProofOfWork(
      challenge: _challenge,
      installId: _installId,
      bits: 12,
    );
    final digest = sha256
        .convert(utf8.encode('$_challenge$_installId$pow'))
        .bytes;
    expect(digest[0], 0);
    expect(digest[1] & 0xf0, 0);
    expect(int.parse(pow), isNonNegative);
    // The smallest counter: nothing below it solves the challenge.
    for (var n = 0; n < int.parse(pow); n++) {
      expect(
        verifiesProofOfWork(
          challenge: _challenge,
          installId: _installId,
          pow: '$n',
          bits: 12,
        ),
        isFalse,
      );
    }
  });

  test('rejects an empty, a too long or a wrong answer', () {
    bool check(String pow, int bits) => verifiesProofOfWork(
      challenge: _challenge,
      installId: _installId,
      pow: pow,
      bits: bits,
    );
    expect(check('', 0), isFalse);
    expect(check('1' * (kProofOfWorkMaxLength + 1), 0), isFalse);
    expect(check('1' * kProofOfWorkMaxLength, 0), isTrue);
    expect(check('0', 256), isFalse);
  });

  test('solves on a background isolate', () async {
    final pow = await solveProofOfWorkInIsolate(
      challenge: _challenge,
      installId: _installId,
      bits: 8,
    );
    expect(
      pow,
      solveProofOfWork(challenge: _challenge, installId: _installId, bits: 8),
    );
  });
}
