import 'package:taro_core/taro_core.dart';
import 'package:test/test.dart';

/// What the `AnalyticsService` contract needs besides the port.
abstract interface class AnalyticsServiceHarness {
  /// The service under test (collection on).
  AnalyticsService get subject;

  /// The `eventName` of every event that reached the backend, oldest first.
  List<String> get deliveredEventNames;
}

/// The `AnalyticsService` contract (02 §13, rule 18).
void runAnalyticsServiceContract(AnalyticsServiceHarness Function() create) {
  group('AnalyticsService contract', () {
    late AnalyticsServiceHarness harness;
    late AnalyticsService analytics;
    const opened = TaroAnalyticsEvent.disclaimerAccepted();
    const backgrounded = TaroAnalyticsEvent.reminderOpened();

    setUp(() {
      harness = create();
      analytics = harness.subject;
    });

    test('delivers typed events in order', () async {
      await analytics.log(opened);
      await analytics.log(backgrounded);
      expect(harness.deliveredEventNames, [
        opened.eventName,
        backgrounded.eventName,
      ]);
    });

    test('delivers nothing while collection is off', () async {
      await analytics.setCollectionEnabled(enabled: false);
      await analytics.log(opened);
      await analytics.setCollectionEnabled(enabled: true);
      await analytics.log(backgrounded);
      expect(harness.deliveredEventNames, [backgrounded.eventName]);
    });

    test('screen views and consent mode complete', () async {
      await analytics.setConsent(AnalyticsConsent.allDenied());
      await analytics.screen('S05');
      await analytics.setConsent(AnalyticsConsent.allGranted());
    });
  });
}

/// The `CrashReporter` contract (02 §13). [create] returns a reporter with
/// collection on. Reporting must never throw, whatever it is given.
void runCrashReporterContract(CrashReporter Function() create) {
  group('CrashReporter contract', () {
    late CrashReporter crash;

    setUp(() => crash = create());

    test('records errors and breadcrumbs without throwing', () async {
      crash.log('sync started');
      await crash.recordError(
        StateError('boom'),
        StackTrace.current,
        context: {'step': 'balance'},
      );
      await crash.recordError('fatal', StackTrace.empty, fatal: true);
    });

    test('keeps working while collection is off', () async {
      await crash.setCollectionEnabled(enabled: false);
      crash.log('ignored');
      await crash.recordError(Exception('ignored'), StackTrace.empty);
      await crash.setCollectionEnabled(enabled: true);
    });
  });
}

/// The `ReviewPrompter` contract (01 §6). Prompting is best effort and
/// never throws.
void runReviewPrompterContract(ReviewPrompter Function() create) {
  group('ReviewPrompter contract', () {
    test('maybePrompt completes, repeatedly', () async {
      final prompter = create();
      await prompter.maybePrompt(ReviewTrigger.positiveRating);
      await prompter.maybePrompt(ReviewTrigger.positiveRating);
    });
  });
}
