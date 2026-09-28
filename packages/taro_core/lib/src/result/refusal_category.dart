/// Why a reading was declined (03 §9.4, RC27, GLOSSARY §5.2).
///
/// A declined reading is `200 status: declined`, never a `Failure`.
enum RefusalCategory {
  /// Wire `health`.
  health('health', 'safetyDeclinedHealth'),

  /// Wire `pregnancy`.
  pregnancy('pregnancy', 'safetyDeclinedPregnancy'),

  /// Wire `death`.
  death('death', 'safetyDeclinedDeath'),

  /// Wire `legal`.
  legal('legal', 'safetyDeclinedLegal'),

  /// Wire `financial`.
  financial('financial', 'safetyDeclinedFinancial'),

  /// Wire `gambling`.
  gambling('gambling', 'safetyDeclinedGambling'),

  /// Wire `self_harm`: crisis resources (S27).
  selfHarm('self_harm', 'safetyDeclinedSelfHarm'),

  /// Wire `harm_to_others`: crisis resources (S27, emergency line).
  harmToOthers('harm_to_others', 'safetyDeclinedHarmToOthers'),

  /// Wire `sexual_minors`: moderation-blocked copy (05).
  sexualMinors('sexual_minors', 'safetyDeclinedSexualMinors'),

  /// Wire `hate_or_harassment`: moderation-blocked copy (05).
  hateOrHarassment('hate_or_harassment', 'safetyDeclinedHateOrHarassment'),

  /// A model refusal or an unknown wire category.
  other('other', 'refusalGeneric');

  const RefusalCategory(this.wire, this.messageKey);

  /// The snake_case value on the wire (03 §9.4).
  final String wire;

  /// The ARB key of the refusal message (GLOSSARY §5.2).
  final String messageKey;

  /// Whether S27 crisis resources are shown (01 "crisis", RC27).
  bool get showsCrisisResources => this == selfHarm || this == harmToOthers;

  /// Whether 05's "moderation blocked" copy applies (RC27).
  bool get isModerationBlocked =>
      this == sexualMinors || this == hateOrHarassment;

  /// Parses a wire category; unknown values map to [other].
  static RefusalCategory fromWire(String wire) {
    for (final category in values) {
      if (category.wire == wire) return category;
    }
    return other;
  }
}
