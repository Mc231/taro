import 'package:taro_core/taro_core.dart';
import 'package:test/test.dart';

import '../fakes/fakes.dart';
import 'contracts.dart';

final class _Harness implements AnalyticsServiceHarness {
  final FakeAnalyticsService analytics = FakeAnalyticsService();

  @override
  AnalyticsService get subject => analytics;

  @override
  List<String> get deliveredEventNames => analytics.eventNames;
}

void main() {
  runAnalyticsServiceContract(_Harness.new);

  test('keeps dropped events, screens and consents', () async {
    final analytics = FakeAnalyticsService();
    await analytics.screen('S01');
    await analytics.setCollectionEnabled(enabled: false);
    await analytics.log(const TaroAnalyticsEvent.reminderOpened());
    await analytics.screen('S02');
    await analytics.setConsent(AnalyticsConsent.allGranted());
    expect(analytics.screens, ['S01']);
    expect(analytics.dropped, hasLength(1));
    expect(analytics.consents.single.adStorage, isTrue);
  });
}
