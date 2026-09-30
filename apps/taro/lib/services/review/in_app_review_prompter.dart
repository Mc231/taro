import 'package:in_app_review/in_app_review.dart';
import 'package:taro/services/review/review_prompt_ledger.dart';
import 'package:taro_core/taro_core.dart';

/// The production [ReviewPrompter] over `in_app_review` (02 §5, 01 §6.1).
///
/// Policy: the OS review sheet is requested after the Nth positively rated
/// AI reading (`review.promptAfterPositiveReadings`, default 3; Classic
/// readings never send a trigger), at most once per [cooldown] (120 days),
/// and never again after [recordRefusal]. The count restarts after each
/// prompt. Any storage or platform error leaves the user unprompted.
final class InAppReviewPrompter implements ReviewPrompter {
  /// A prompter over [review] (default: the plugin singleton).
  InAppReviewPrompter({
    required Clock clock,
    required RemoteConfigRepository config,
    required ReviewPromptLedger ledger,
    required Logger logger,
    InAppReview? review,
  }) : _clock = clock,
       _config = config,
       _ledger = ledger,
       _logger = logger.child('review'),
       _review = review ?? InAppReview.instance;

  /// The minimum time between two prompts.
  static const Duration cooldown = Duration(days: 120);

  final Clock _clock;
  final RemoteConfigRepository _config;
  final ReviewPromptLedger _ledger;
  final Logger _logger;
  final InAppReview _review;
  Future<void> _queue = Future<void>.value();

  @override
  Future<void> maybePrompt(ReviewTrigger trigger) =>
      _serial(() => _maybePrompt(trigger));

  /// The user refused to review: never prompt again.
  Future<void> recordRefusal() => _serial(() async {
    final state = await _ledger.read();
    if (state == null || state.refused) return;
    await _ledger.write(state.copyWith(refused: true));
  });

  Future<void> _maybePrompt(ReviewTrigger trigger) async {
    final stored = await _ledger.read();
    if (stored == null || stored.refused) return;
    final state = switch (trigger) {
      ReviewTrigger.positiveRating => stored.copyWith(
        positiveRatings: stored.positiveRatings + 1,
      ),
    };
    final now = _clock.now();
    if (!_due(state, now)) {
      await _ledger.write(state);
      return;
    }
    try {
      if (!await _review.isAvailable()) {
        await _ledger.write(state);
        return;
      }
      // Record first: a crash inside the sheet must not re-prompt.
      final prompted = ReviewPromptState(lastPromptAt: now);
      if (!await _ledger.write(prompted)) return;
      await _review.requestReview();
    } on Object catch (error, stack) {
      _logger.warning('review request failed', error: error, stack: stack);
    }
  }

  bool _due(ReviewPromptState state, DateTime now) {
    final threshold = _config.current.reviewPromptAfterPositiveReadings;
    if (state.positiveRatings < threshold) return false;
    final last = state.lastPromptAt;
    return last == null || now.difference(last) >= cooldown;
  }

  Future<void> _serial(Future<void> Function() action) {
    final run = _queue.then((_) => action());
    _queue = run;
    return run;
  }
}
