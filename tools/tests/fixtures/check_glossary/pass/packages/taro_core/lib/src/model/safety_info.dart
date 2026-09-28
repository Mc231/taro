/// Refusal categories (03 §9.4): an enhanced enum, like the real one.
enum RefusalCategory {
  selfHarm('self_harm', 'safetyDeclinedSelfHarm'),
  harmToOthers('harm_to_others', 'safetyDeclinedHarmToOthers'),
  health('health', 'safetyDeclinedHealth'),
  pregnancy('pregnancy', 'safetyDeclinedPregnancy'),
  death('death', 'safetyDeclinedDeath'),
  legal('legal', 'safetyDeclinedLegal'),
  financial('financial', 'safetyDeclinedFinancial'),
  gambling('gambling', 'safetyDeclinedGambling'),
  sexualMinors('sexual_minors', 'safetyDeclinedSexualMinors'),
  hateOrHarassment('hate_or_harassment', 'safetyDeclinedHateOrHarassment'),
  other('other', 'refusalGeneric');

  const RefusalCategory(this.wire, this.messageKey);

  final String wire;

  final String messageKey;

  bool get crisis => this == selfHarm || this == harmToOthers;
}
