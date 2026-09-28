/// Typed identifiers (02 §4): extension types over `String` so IDs of
/// different kinds cannot be mixed up at compile time.
library;

/// The RC1 card ID format: `major_00`…`major_21` and
/// `{wands,cups,swords,pentacles}_01`…`_14` (GLOSSARY §1).
final RegExp cardIdPattern = RegExp(
  r'^(major_(0\d|1\d|2[01])|(wands|cups|swords|pentacles)_(0[1-9]|1[0-4]))$',
);

/// A tarot card ID such as `major_00` or `cups_03` (RC1).
extension type const CardId(String value) {
  /// Parses [raw], throwing a [FormatException] unless it matches
  /// [cardIdPattern]. Use for trusted, bundled content.
  factory CardId.parse(String raw) {
    final id = tryParse(raw);
    if (id == null) {
      throw FormatException('Invalid card ID', raw);
    }
    return id;
  }

  /// Returns the [CardId] for [raw], or `null` if [raw] is not a valid ID.
  static CardId? tryParse(String raw) => isValid(raw) ? CardId(raw) : null;

  /// Whether [raw] is a valid card ID.
  static bool isValid(String raw) => cardIdPattern.hasMatch(raw);
}

/// A spread ID such as `single` or `celtic_cross` (RC2, 01 §10.3).
extension type const SpreadId(String value) {}

/// A spread position ID such as `past` or `challenge`.
extension type const PositionId(String value) {}

/// A reading ID: client-generated UUIDv4, equal to `clientReadingId` and the
/// `Idempotency-Key` (RC42).
extension type const ReadingId(String value) {}

/// The install ID (never logged, 01 §15).
extension type const InstallId(String value) {}

/// A fully qualified store product ID such as
/// `com.vshyrochuk.taro.readings_3`.
extension type const ProductId(String value) {}

/// A rewarded-ad intent ID (`ad_rewards.id`, 03 §7.3).
extension type const IntentId(String value) {}
