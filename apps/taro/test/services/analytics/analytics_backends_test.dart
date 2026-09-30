import 'package:flutter_test/flutter_test.dart';
import 'package:taro/services/analytics/analytics_user_properties.dart';
import 'package:taro/services/analytics/composite_analytics_service.dart';
import 'package:taro/services/analytics/console_analytics_service.dart';
import 'package:taro_core/taro_core.dart';

import '../../../../../packages/taro_core/test/contracts/contracts.dart';
import '../../../../../packages/taro_core/test/fakes/fakes.dart';
import 'recording_backend.dart';

const _disclaimer = TaroAnalyticsEvent.disclaimerAccepted();

const _allGrantedLine =
    'consent analytics=true ad=true ad_user_data=true ad_personalization=true';

/// Measures delivery through a console backend (it honours the toggle).
final class _CompositeHarness implements AnalyticsServiceHarness {
  final _ConsoleHarness console = _ConsoleHarness();

  @override
  late final AnalyticsService subject = CompositeAnalyticsService(
    [console.subject as TaroAnalyticsBackend, const NoOpAnalyticsService()],
    logger: CapturingLogger(),
  );

  @override
  List<String> get deliveredEventNames => console.deliveredEventNames;
}

final class _ConsoleHarness implements AnalyticsServiceHarness {
  final CapturingLogger logger = CapturingLogger();

  @override
  late final AnalyticsService subject = ConsoleAnalyticsService(
    logger: logger,
  );

  @override
  List<String> get deliveredEventNames => [
    for (final message in logger.messages)
      if (message.startsWith('event ')) message.split(' ')[1],
  ];
}

void main() {
  group('CompositeAnalyticsService', () {
    runAnalyticsServiceContract(_CompositeHarness.new);

    test(
      'fans every call out in order; a failing backend is skipped',
      () async {
        final broken = RecordingBackend()..failWith = StateError('down');
        final healthy = RecordingBackend();
        final logger = CapturingLogger();
        final composite = CompositeAnalyticsService([
          broken,
          healthy,
        ], logger: logger);

        await composite.log(_disclaimer);
        await composite.screen('S05');
        await composite.setCollectionEnabled(enabled: true);
        await composite.setConsent(AnalyticsConsent.allDenied());
        await composite.setUserProperties(
          const AnalyticsUserProperties(hasPurchased: true),
        );

        final expected = [
          'event disclaimer_accepted',
          'screen S05',
          'collection true',
          'consent ${AnalyticsConsent.allDenied()}',
          'properties {has_purchased: true}',
        ];
        expect(broken.calls, expected);
        expect(healthy.calls, expected);
        expect(logger.at(LogLevel.warning), hasLength(5));
        expect(logger.messages.first, 'RecordingBackend failed');
      },
    );
  });

  group('ConsoleAnalyticsService', () {
    runAnalyticsServiceContract(_ConsoleHarness.new);

    test('logs events, screens, consent and properties at FINE', () async {
      final logger = CapturingLogger();
      final console = ConsoleAnalyticsService(logger: logger);
      await console.log(
        const TaroAnalyticsEvent.analyticsToggled(enabled: true),
      );
      await console.screen('S05');
      await console.setConsent(AnalyticsConsent.allGranted());
      await console.setUserProperties(
        const AnalyticsUserProperties(adsRemoved: true),
      );
      await console.setCollectionEnabled(enabled: false);
      await console.screen('S06');
      await console.setUserProperties(
        const AnalyticsUserProperties(adsRemoved: false),
      );
      expect(logger.messages, [
        'event analytics_toggled {enabled: true}',
        'screen S05',
        _allGrantedLine,
        'user properties {ads_removed: true}',
        'collection off',
      ]);
      expect(logger.records.every((r) => r.level == LogLevel.fine), isTrue);
      expect(logger.records.first.logger, 'taro.analytics.console');
      await console.setCollectionEnabled(enabled: true);
      expect(logger.messages.last, 'collection on');
    });
  });

  group('NoOpAnalyticsService', () {
    test('accepts every call and does nothing', () async {
      // Not const, so the constructor line runs (coverage).
      // ignore: prefer_const_constructors
      final noOp = NoOpAnalyticsService();
      await noOp.log(_disclaimer);
      await noOp.screen('S05');
      await noOp.setCollectionEnabled(enabled: false);
      await noOp.setConsent(AnalyticsConsent.allDenied());
      await noOp.setUserProperties(const AnalyticsUserProperties());
    });
  });

  group('AnalyticsUserProperties', () {
    const full = AnalyticsUserProperties(
      appLocale: AnalyticsLocale.ar,
      theme: ThemeMode.system,
      reversalsEnabled: false,
      adsRemoved: true,
      aiConsent: AiConsentProperty.unknown,
      hasPurchased: false,
      journalSizeBucket: EntriesBucket.none,
    );

    test('only set fields reach the wire', () {
      expect(const AnalyticsUserProperties().toWire(), isEmpty);
      expect(full.toWire(), {
        'app_locale': 'ar',
        'theme': 'system',
        'reversals_enabled': 'false',
        'ads_removed': 'true',
        'ai_consent': 'unknown',
        'has_purchased': 'false',
        'journal_size_bucket': '0',
      });
    });

    test('property names fit Firebase (<= 24 chars, snake_case)', () {
      for (final name in full.toWire().keys) {
        expect(name.length, lessThanOrEqualTo(24));
        expect(name, matches(RegExp(r'^[a-z][a-z_]*$')));
      }
    });

    test('merge keeps older fields the newer set does not touch', () {
      final merged = full.merge(
        const AnalyticsUserProperties(
          appLocale: AnalyticsLocale.de,
          journalSizeBucket: EntriesBucket.lots,
        ),
      );
      expect(merged.appLocale, AnalyticsLocale.de);
      expect(merged.journalSizeBucket, EntriesBucket.lots);
      expect(merged.theme, ThemeMode.system);
      expect(merged.aiConsent, AiConsentProperty.unknown);
      expect(const AnalyticsUserProperties().merge(full), full);
    });

    test('value equality and toString', () {
      expect(
        full,
        full.merge(const AnalyticsUserProperties()),
      );
      expect(
        full.hashCode,
        full.merge(const AnalyticsUserProperties()).hashCode,
      );
      expect(full, isNot(const AnalyticsUserProperties()));
      expect(
        const AnalyticsUserProperties(adsRemoved: true).toString(),
        'AnalyticsUserProperties({ads_removed: true})',
      );
    });
  });
}
