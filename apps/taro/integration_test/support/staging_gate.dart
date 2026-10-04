/// The manual-dispatch switch of the staging tests
/// (`--dart-define=TARO_STAGING_SMOKE=1`). `1`, `true` and `yes` enable
/// them; unset, `0`, `false` and `no` skip them; anything else throws so a
/// typo never turns into a silent skip (BUG-16).
bool get stagingSmokeEnabled =>
    parseStagingSmoke(const String.fromEnvironment('TARO_STAGING_SMOKE'));

/// Parses the `TARO_STAGING_SMOKE` define [raw] (case-insensitive).
bool parseStagingSmoke(String raw) {
  switch (raw.trim().toLowerCase()) {
    case '1' || 'true' || 'yes':
      return true;
    case '' || '0' || 'false' || 'no':
      return false;
    default:
      throw ArgumentError.value(
        raw,
        'TARO_STAGING_SMOKE',
        'TARO_STAGING_SMOKE must be 1/true/yes or 0/false/no',
      );
  }
}
