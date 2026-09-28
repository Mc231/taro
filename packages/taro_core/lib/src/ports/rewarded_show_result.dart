/// How a rewarded ad ended (04 §6.6).
enum RewardedShowResult {
  /// `onUserEarnedReward` fired; poll the intent for the grant.
  earned,

  /// Closed before the reward: no grant, no penalty, cap slot freed.
  dismissedEarly,

  /// The ad loaded but could not be shown.
  failedToShow,

  /// No ad to show (no fill or load timeout).
  noFill,
}
