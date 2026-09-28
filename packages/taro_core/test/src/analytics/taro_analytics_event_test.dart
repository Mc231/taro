import 'dart:convert';
import 'dart:io';

import 'package:taro_core/taro_core.dart';
import 'package:test/test.dart';

import 'analytics_samples.dart';

/// Regenerate with `UPDATE_SNAPSHOTS=1 dart test test/src/analytics`.
const _snapshotPath = 'test/src/analytics/snapshots/analytics_events.json';
const _docPath = '../../docs/ANALYTICS_EVENTS.md';

final RegExp _snake = RegExp(r'^[a-z][a-z0-9]*(_[a-z0-9]+)*$');
final RegExp _cellSplit = RegExp(r'[\s|\\(),`;:\[\]]+');

Map<String, Object> _entry(TaroAnalyticsEvent e) => {
  'name': e.eventName,
  'parameters': e.parameters,
};

String _snapshot(List<TaroAnalyticsEvent> events) {
  final lines = [for (final e in events) '  ${jsonEncode(_entry(e))}'];
  return '[\n${lines.join(',\n')}\n]\n';
}

const _eventsDir = 'lib/src/analytics/events';

/// Concrete event classes and their field declarations, read from the
/// source of the sealed library (dart:mirrors is unavailable here).
Map<String, List<String>> _eventClasses() {
  final classHeader = RegExp(
    r'^final class (\w+) extends \w+ \{',
    multiLine: true,
  );
  final field = RegExp(r'^  final ([\w?<>, ]+) \w+;', multiLine: true);
  final classes = <String, List<String>>{};
  final files = Directory(_eventsDir).listSync().whereType<File>();
  for (final file in files) {
    final source = file.readAsStringSync();
    final headers = classHeader.allMatches(source).toList();
    for (var i = 0; i < headers.length; i++) {
      final end = i + 1 < headers.length ? headers[i + 1].start : source.length;
      final body = source.substring(headers[i].end, end);
      classes[headers[i][1]!] = [
        for (final m in field.allMatches(body)) m[1]!,
      ];
    }
  }
  return classes;
}

/// Event name → Params cell, and value-set name → its tokens.
({Map<String, Set<String>> rows, Map<String, Set<String>> sets}) _doc() {
  final lines = File(_docPath).readAsLinesSync();
  final rows = <String, Set<String>>{};
  final sets = <String, Set<String>>{};
  String? set;
  final eventRow = RegExp(r'^\| `([a-z0-9_]+)` \| (.*?) \| ');
  for (final line in lines) {
    if (line.startsWith('### ')) {
      set = line.substring(4).trim();
      sets[set] = {};
      continue;
    }
    if (line.startsWith('## ')) set = null;
    final row = eventRow.firstMatch(line);
    if (row != null) {
      rows[row[1]!] = {
        for (final t in row[2]!.split(_cellSplit))
          t.endsWith('?') ? t.substring(0, t.length - 1) : t,
      };
    } else if (set != null) {
      sets[set]!.addAll(line.split(RegExp(r'[\s,]+')));
    }
  }
  return (rows: rows, sets: sets);
}

void main() {
  group('catalogue', () {
    test('every concrete event class has a canonical sample', () {
      final classes = _eventClasses().keys.toSet();
      final sampled = {
        for (final e in canonicalEvents()) e.runtimeType.toString(),
      };
      expect(classes, hasLength(74));
      expect(sampled, classes);
    });

    test('names are unique, snake_case and at most 40 chars', () {
      final byClass = <String, String>{};
      for (final e in exhaustiveEvents()) {
        final type = e.runtimeType.toString();
        expect(byClass.putIfAbsent(type, () => e.eventName), e.eventName);
        expect(e.eventName, matches(_snake));
        expect(e.eventName.length, lessThanOrEqualTo(40));
      }
      expect(byClass.values.toSet(), hasLength(byClass.length));
    });

    test('params are snake_case, at most 25, and int, bool or String', () {
      for (final e in exhaustiveEvents()) {
        expect(e.parameters.length, lessThanOrEqualTo(25), reason: '$e');
        for (final MapEntry(:key, :value) in e.parameters.entries) {
          expect(key, matches(_snake), reason: '$e');
          expect(value, anyOf(isA<int>(), isA<bool>(), isA<String>()));
        }
      }
    });
  });

  group('no free-form String (PR18, 01 §17.6)', () {
    test('no event class declares a String, Object or dynamic field', () {
      final allowed = RegExp(
        r'^(int|bool|AnalyticsCardId|Enum|[A-Z]\w*)\??$',
      );
      final forbidden = RegExp(r'^(String|Object|dynamic|Map|List|Set)\b');
      var fields = 0;
      _eventClasses().forEach((name, types) {
        for (final type in types) {
          fields++;
          expect(type, isNot(matches(forbidden)), reason: '$name: $type');
          expect(type, matches(allowed), reason: '$name: $type');
        }
      });
      expect(fields, greaterThan(100));
    });

    test('every non-primitive field type is an enum', () {
      // The field types used by the events, resolved to their values.
      final enums = <String, List<Enum>>{
        'ScreenId': ScreenId.values,
        'AnalyticsSpread': AnalyticsSpread.values,
        'AnalyticsLocale': AnalyticsLocale.values,
        'Enum': SettingValue.values,
      };
      final types = {
        for (final t in _eventClasses().values.expand((t) => t))
          t.replaceAll('?', ''),
      }..removeAll(['int', 'bool', 'AnalyticsCardId']);
      expect(types, containsAll(enums.keys));
      for (final type in types) {
        expect(type, matches(RegExp(r'^[A-Z]\w*$')), reason: type);
      }
    });

    test('every String value comes from a closed value set', () {
      final closed = <String>{
        for (final values in <List<Enum>>[
          ScreenId.values,
          AnalyticsSpread.values,
          AnalyticsLocale.values,
          AnalyticsOnboardingStep.values,
          AiConsentOrigin.values,
          UmpResultStatus.values,
          AttResultStatus.values,
          ReadingFlowSource.values,
          GateBlockReason.values,
          HoldResult.values,
          QuestionLengthBucket.values,
          CreditType.values,
          ReadingFailureKind.values,
          ClassicReadingReason.values,
          ReportReason.values,
          CrisisResourcesOrigin.values,
          ReadingViewOrigin.values,
          JournalEntryType.values,
          NoteLengthBucket.values,
          JournalFilter.values,
          PatternsRange.values,
          CardOrientation.values,
          LearnCardOrigin.values,
          SearchResultsBucket.values,
          EntriesBucket.values,
          GateDecisionKind.values,
          OutOfReadingsSource.values,
          StoreSource.values,
          PaywallSurface.values,
          PaywallAction.values,
          IapLoadResult.values,
          AnalyticsProduct.values,
          AnalyticsCurrency.values,
          PurchaseErrorKind.values,
          IapVerifyStatus.values,
          RestoreResult.values,
          RemoveAdsSource.values,
          RewardedSource.values,
          RewardedAdResult.values,
          RewardedGrantResult.values,
          BannerScreen.values,
          ConfigKey.values,
          ExportError.values,
          ImportMode.values,
          ImportFailureReason.values,
          SettingKey.values,
          SettingValue.values,
          AppNoticeOrigin.values,
          RefusalCategory.values,
          Rating.values,
          RatingReason.values,
          Arcana.values,
          ChargeSource.values,
          RewardUnavailableReason.values,
          ErrorKind.values,
          ThemeMode.values,
        ])
          for (final v in values) analyticsWire(v),
        for (final id in kCardIds) id.value,
        AnalyticsCardId.unknown.wire,
      };
      for (final e in exhaustiveEvents()) {
        for (final value in e.parameters.values.whereType<String>()) {
          expect(closed, contains(value), reason: '$e');
        }
      }
    });
  });

  group('docs/ANALYTICS_EVENTS.md', () {
    test('lists every event and every value each parameter can take', () {
      final doc = _doc();
      for (final e in exhaustiveEvents()) {
        final cell = doc.rows[e.eventName];
        expect(cell, isNotNull, reason: '${e.eventName} is not documented');
        for (final MapEntry(:key, :value) in e.parameters.entries) {
          expect(cell, contains(key), reason: '${e.eventName}.$key');
          if (value is! String) continue;
          if (key == 'card_id') {
            expect(
              value == 'unknown' || CardId.isValid(value),
              isTrue,
              reason: value,
            );
            continue;
          }
          final referenced = cell!.where(doc.sets.containsKey);
          final documented =
              cell.contains(value) ||
              referenced.any((s) => doc.sets[s]!.contains(value));
          expect(documented, isTrue, reason: '${e.eventName}.$key = $value');
        }
      }
    });
  });

  test('snapshot of every event name and parameters', () {
    final actual = _snapshot(canonicalEvents());
    final file = File(_snapshotPath);
    if (Platform.environment['UPDATE_SNAPSHOTS'] == '1') {
      file
        ..createSync(recursive: true)
        ..writeAsStringSync(actual);
    }
    expect(actual, file.readAsStringSync());
  });

  group('TaroAnalyticsEvent', () {
    test('equality is by name and parameters', () {
      const a = TaroAnalyticsEvent.storeViewed(source: StoreSource.settings);
      const b = StoreViewedEvent(source: StoreSource.settings);
      const c = TaroAnalyticsEvent.storeViewed(source: StoreSource.deepLink);
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(c));
      expect(
        a,
        isNot(const RewardedOfferTappedEvent(source: RewardedSource.store)),
      );
      expect(a.toString(), 'store_viewed{source: settings}');
    });

    test('optional parameters are omitted when absent', () {
      expect(
        const TaroAnalyticsEvent.screenView(screen: ScreenId.s05).parameters,
        {'screen': 'S05'},
      );
      expect(
        const TaroAnalyticsEvent.purchaseFailed(
          product: AnalyticsProduct.removeAds,
        ).parameters,
        {'product': 'remove_ads'},
      );
      expect(
        const TaroAnalyticsEvent.readingRated(
          spread: AnalyticsSpread.single,
          rating: Rating.up,
        ).parameters,
        {'spread_id': 'single', 'rating': 'up'},
      );
    });

    test('setting_changed keeps key and value consistent', () {
      expect(
        const TaroAnalyticsEvent.themeChanged(
          mode: ThemeMode.system,
        ).parameters,
        {'key': 'theme', 'value': 'system'},
      );
      expect(
        const TaroAnalyticsEvent.languageChanged(locale: null).parameters,
        {'key': 'language', 'value': 'system'},
      );
      expect(
        const TaroAnalyticsEvent.languageChanged(
          locale: AnalyticsLocale.pt,
        ).parameters,
        {'key': 'language', 'value': 'pt'},
      );
      expect(
        const TaroAnalyticsEvent.reversalsChanged(enabled: true).parameters,
        {'key': 'reversals', 'value': 'on'},
      );
      expect(
        const TaroAnalyticsEvent.hapticsChanged(enabled: false).parameters,
        {'key': 'haptics', 'value': 'off'},
      );
    });

    test('groups follow 01 §15', () {
      final groups = {
        for (final e in canonicalEvents())
          e.eventName: switch (e) {
            ScreenEvent() => 'screen',
            OnboardingEvent() => 'onboarding',
            ConsentEvent() => 'consent',
            ReadingEvent() => 'reading',
            DailyCardEvent() => 'daily',
            JournalEvent() => 'journal',
            LearnEvent() => 'learn',
            NotificationEvent() => 'notification',
            MonetizationEvent() => 'monetization',
            DataEvent() => 'data',
            SettingsEvent() => 'settings',
            AppEvent() => 'app',
            ErrorEvent() => 'error',
          },
      };
      expect(groups['consent_ump_result'], 'consent');
      expect(groups['purchase_completed'], 'monetization');
      expect(groups['reading_gate_evaluated'], 'monetization');
      expect(groups.values.toSet(), hasLength(13));
    });
  });
}
