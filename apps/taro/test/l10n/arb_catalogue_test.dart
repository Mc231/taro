import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taro/l10n/generated/taro_localizations.dart';

/// The ARB catalogue (Phase 13 Sprint 13.5): compliance copy, spread keys,
/// plurals and the 12-locale load.
Map<String, Object?> _arb(String locale) =>
    jsonDecode(File('lib/l10n/arb/app_$locale.arb').readAsStringSync())
        as Map<String, Object?>;

void main() {
  final en = _arb('en');

  test('05 §3 compliance keys carry the fixed copy', () {
    const fixed = {
      'disclaimerShort':
          'For entertainment and self-reflection. Not professional advice.',
      'disclaimerOnboardingTitle': 'Tarot for reflection',
      'aiConsentTitle': 'Your readings use AI',
      'aiConsentAccept': 'Allow AI readings',
      'aiConsentDecline': 'Not now',
      'aiLabel': 'AI-generated',
      'crisisTitle': 'You’re not alone',
      'reportReadingTitle': 'Report this reading',
      'reportReadingDisclosure':
          'Your question and this reading will be sent to Taro and kept for '
          '90 days.',
    };
    for (final MapEntry(:key, :value) in fixed.entries) {
      expect(en[key], value, reason: key);
    }
    for (final key in [
      'disclaimerOnboardingBody',
      'aiConsentBody',
      'refusalGeneric',
      'crisisBody',
    ]) {
      expect(en[key], isA<String>(), reason: key);
    }
    // Owner 2026-10-06: the app names no AI vendor (the privacy policy
    // does), but still says a third-party AI service gets the question
    // (5.1.2(i)).
    expect(en['aiConsentBody'], contains('third-party AI service'));
    expect(en['aiConsentBody'], contains('privacy policy names'));
    expect(en['privacyAiAllowedSubtitle'], contains('third-party AI service'));
  });

  test('no locale names an AI vendor in app copy', () {
    final vendor = RegExp('OpenAI|GPT|ChatGPT|Anthropic|Claude|Gemini');
    for (final locale in [
      'en', 'ar', 'de', 'es', 'fr', 'it', 'ja', 'ko', 'nl', 'pt', 'tr', 'uk', //
    ]) {
      final arb = _arb(locale);
      for (final MapEntry(:key, :value) in arb.entries) {
        if (key.startsWith('@') || value is! String) continue;
        expect(vendor.hasMatch(value), isFalse, reason: '$locale $key');
      }
    }
  });

  // V2-10: the app is "Taro" (Latin) in every locale; in uk, tarot is
  // "карти таро", never a bare "Таро" that reads like the app's name.
  test('uk never uses a bare "Таро" next to the app name "Taro"', () {
    final uk = _arb('uk');
    for (final MapEntry(:key, :value) in uk.entries) {
      if (key.startsWith('@') || value is! String) continue;
      expect(
        value,
        isNot(contains(RegExp('(^|[^А-Яа-яЇїІіЄєҐґ’])Таро'))),
        reason: key,
      );
    }
  });

  test('every spread, position and suggestion key of spreads.json exists', () {
    final spreads =
        (jsonDecode(File('assets/deck/spreads.json').readAsStringSync())
                as Map<String, Object?>)['spreads']!
            as List<Object?>;
    expect(spreads, hasLength(6));
    for (final spread in spreads.cast<Map<String, Object?>>()) {
      final id = spread['id']! as String;
      expect(en, contains('spread_${id}_name'));
      expect(en, contains('spread_${id}_meta'));
      expect(en, contains('spread_${id}_whenToUse'));
      for (final position
          in (spread['positions']! as List<Object?>)
              .cast<Map<String, Object?>>()) {
        final pos = position['id']! as String;
        expect(en, contains('spread_${id}_pos_${pos}_name'));
        expect(en, contains('spread_${id}_pos_${pos}_desc'));
      }
      for (final key in (spread['questionSuggestionKeys']! as List<Object?>)) {
        expect(en, contains(key));
      }
    }
  });

  test('every other locale has every key (x-translate placeholders)', () {
    final keys = en.keys.where((k) => !k.startsWith('@')).toSet();
    for (final locale in TaroLocalizations.supportedLocales) {
      final arb = _arb(locale.languageCode);
      expect(
        arb.keys.where((k) => !k.startsWith('@')).toSet(),
        keys,
        reason: locale.languageCode,
      );
    }
  });

  test('R3-01: the first pick title never says "more"; the remaining one '
      'differs from it in every locale', () async {
    for (final locale in TaroLocalizations.supportedLocales) {
      final l10n = await TaroLocalizations.delegate.load(locale);
      for (var n = 1; n <= 10; n++) {
        expect(
          l10n.drawPickTitle(n),
          isNot(l10n.drawPickMoreTitle(n)),
          reason: '$locale $n',
        );
      }
    }
    final uk = await TaroLocalizations.delegate.load(const Locale('uk'));
    expect(uk.drawPickTitle(3), 'Виберіть 3 карти');
    expect(uk.drawPickTitle(10), 'Виберіть 10 карт');
    expect(uk.drawPickMoreTitle(2), 'Виберіть ще 2 карти');
    for (var n = 1; n <= 10; n++) {
      expect(uk.drawPickTitle(n), isNot(contains('ще')));
    }
  });

  test('plurals and placeholders (en)', () async {
    final l10n = await TaroLocalizations.delegate.load(const Locale('en'));
    expect(l10n.balanceReadings(0), '0 readings');
    expect(l10n.balanceReadings(1), '1 reading');
    expect(l10n.balanceReadings(12), '12 readings');
    expect(l10n.storeGranted(10), '+10 readings');
    expect(l10n.cardDrawnTimes(0), 'Not in your journal yet');
    expect(l10n.cardDrawnTimes(1), 'In your journal: drawn once');
    expect(l10n.cardDrawnTimes(4), 'In your journal: drawn 4 times');
    expect(l10n.drawPickTitle(1), 'Pick a card');
    expect(l10n.drawPickTitle(3), 'Pick 3 cards');
    expect(l10n.drawPickMoreTitle(1), 'Pick one more card');
    expect(l10n.drawPickMoreTitle(2), 'Pick 2 more cards');
    expect(
      l10n.importSummary(96, 40),
      '96 readings · 40 daily cards',
    );
    expect(l10n.drawPickedProgress(2, 3), '2 of 3 picked');
    expect(l10n.spread_three_ppf_pos_past_name, 'Past');
  });

  test('glossary terms are translated, not placeholders', () async {
    final de = await TaroLocalizations.delegate.load(const Locale('de'));
    expect(de.suitCups, 'Kelche');
    expect(de.learnSectionMajor, 'Große Arkana');
    final ja = await TaroLocalizations.delegate.load(const Locale('ja'));
    expect(ja.balanceReadings(1), isNotEmpty);
  });

  test('ja and ko keep only the CLDR "other" plural branch', () {
    for (final locale in ['ja', 'ko']) {
      final arb = _arb(locale);
      for (final entry in arb.entries) {
        if (entry.key.startsWith('@') || entry.value is! String) continue;
        expect(
          (entry.value! as String).contains(' one{'),
          isFalse,
          reason: '$locale ${entry.key}',
        );
      }
    }
  });
}
