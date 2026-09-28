/// What may trigger the in-app review prompt (01 §6).
enum ReviewTrigger {
  /// An AI reading was rated up. Classic readings never count.
  positiveRating,
}

/// The in-app review prompt (02 §5). The adapter applies the policy
/// (`review.promptAfterPositiveReadings`, at most once per 120 days).
// A port is an interface with swappable adapters, even with one member.
// ignore: one_member_abstracts
abstract interface class ReviewPrompter {
  /// Prompts if the policy allows it.
  Future<void> maybePrompt(ReviewTrigger trigger);
}
