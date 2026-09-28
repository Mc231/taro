import 'package:taro_core/taro_core.dart';
import 'package:test/test.dart';

import '../fakes/fakes.dart';
import 'contracts.dart';

void main() {
  runReviewPrompterContract(FakeReviewPrompter.new);

  test('records triggers', () async {
    final prompter = FakeReviewPrompter();
    await prompter.maybePrompt(ReviewTrigger.positiveRating);
    expect(prompter.triggers, [ReviewTrigger.positiveRating]);
  });
}
