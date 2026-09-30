import 'package:taro_core/taro_core.dart';

/// A [ReviewPrompter] that never prompts (02 §5): tests, screenshot mode
/// and builds without store review.
final class NoOpReviewPrompter implements ReviewPrompter {
  /// Creates the no-op prompter.
  const NoOpReviewPrompter();

  @override
  Future<void> maybePrompt(ReviewTrigger trigger) async {}
}
