import 'package:flutter_test/flutter_test.dart';

import '../../integration_test/support/staging_gate.dart';

/// BUG-16: `TARO_STAGING_SMOKE=1` skipped the staging smoke silently
/// (`bool.fromEnvironment` reads only `true`).
void main() {
  test('1 / true / yes enable the smoke, any case and padding', () {
    for (final raw in ['1', 'true', 'TRUE', 'yes', 'Yes', ' 1 ']) {
      expect(parseStagingSmoke(raw), isTrue, reason: raw);
    }
  });

  test('unset, 0 / false / no leave it off', () {
    for (final raw in ['', '0', 'false', 'False', 'no', 'NO']) {
      expect(parseStagingSmoke(raw), isFalse, reason: raw);
    }
  });

  test('an unknown value fails loudly instead of skipping', () {
    for (final raw in ['on', '2', 'ture', 'y']) {
      expect(
        () => parseStagingSmoke(raw),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            contains('TARO_STAGING_SMOKE'),
          ),
        ),
        reason: raw,
      );
    }
  });
}
