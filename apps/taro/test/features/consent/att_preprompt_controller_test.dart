import 'package:flutter_test/flutter_test.dart';
import 'package:taro/features/consent/controller/att_preprompt_controller.dart';

import '../feature_test_support.dart';

void main() {
  late TaroFakes fakes;

  group('AttPrePromptController', () {
    test('request shows it until Continue', () async {
      fakes = TaroFakes();
      final container = fakes.container();
      final log = StateLog(container, attPrePromptProvider);
      final controller = container.read(attPrePromptProvider.notifier);
      var done = false;
      final first = controller.request().then((_) => done = true);
      final second = controller.request();
      expect(log.last, isA<AttPrePromptVisible>());
      await pumpEventQueue();
      expect(done, isFalse);
      controller.proceed();
      await Future.wait([first, second]);
      expect(done, isTrue);
      expect(log.last, isA<AttPrePromptHidden>());
      controller.proceed();
    });

    test('a pending request completes on dispose', () async {
      fakes = TaroFakes();
      final container = fakes.container();
      final pending = container.read(attPrePromptProvider.notifier).request();
      container.dispose();
      await pending;
    });
  });
}
