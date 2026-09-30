/// The route locations of 01 §8.1 / 02 §8.1 (GLOSSARY §10, RC17).
///
/// Features navigate with these (through `routing/routes.dart`), never with
/// string literals.
abstract final class RoutePaths {
  /// S01 Launch / bootstrap.
  static const String launch = '/';

  /// S02 Onboarding: Welcome.
  static const String onboardingWelcome = '/onboarding/welcome';

  /// S03 Onboarding: Disclaimer.
  static const String onboardingDisclaimer = '/onboarding/disclaimer';

  /// S04 AI consent (onboarding step 3 and gate re-entry).
  static const String consentAi = '/consent/ai';

  /// S05 Home, tab "Today".
  static const String home = '/home';

  /// S06 Spread picker.
  static const String readingSpreads = '/reading/spreads';

  /// S07 Question input (`?spread=`).
  static const String readingQuestionPath = '/reading/question';

  /// S08 Draw ritual.
  static const String readingDraw = '/reading/draw';

  /// S09 / S32 reading result (`/reading/:id`, `?mode=classic` for S32).
  static const String readingPattern = '/reading/:id';

  /// S11 Store.
  static const String store = '/store';

  /// S13 Daily card.
  static const String daily = '/daily';

  /// S14 Journal list, tab "Journal".
  static const String journal = '/journal';

  /// S16 Learn deck browser, tab "Learn".
  static const String learn = '/learn';

  /// S19 About tarot & Taro.
  static const String learnAbout = '/learn/about';

  /// S18 Spreads guide.
  static const String learnSpreads = '/learn/spreads';

  /// S20 Settings, tab "Settings".
  static const String settings = '/settings';

  /// S21 Language.
  static const String settingsLanguage = '/settings/language';

  /// S22 Reminder.
  static const String settingsReminder = '/settings/reminder';

  /// S23 Privacy choices.
  static const String settingsPrivacy = '/settings/privacy';

  /// S24 Export backup.
  static const String settingsExport = '/settings/export';

  /// S25 Import backup.
  static const String settingsImport = '/settings/import';

  /// S26 Delete all data.
  static const String settingsDelete = '/settings/delete';

  /// S28 FAQ / Help.
  static const String help = '/help';

  /// S27 Crisis resources.
  static const String helpCrisis = '/help/crisis';

  /// S30 Update required.
  static const String update = '/update';

  /// The `mode` query value of S32.
  static const String classicMode = 'classic';

  /// S07 for [spreadId].
  ///
  /// [source] is the `reading_flow_started.source` wire value; [cardId] and
  /// [reversed] preset the daily card for "Reflect deeper" (01 §7.6). The
  /// preset only fixes the card: the gate and the hold still run on Begin.
  static String readingQuestion(
    String spreadId, {
    String? source,
    String? cardId,
    bool reversed = false,
  }) => Uri(
    path: readingQuestionPath,
    queryParameters: {
      'spread': spreadId,
      'source': ?source,
      'card': ?cardId,
      if (cardId != null && reversed) 'reversed': '1',
    },
  ).toString();

  /// S09 (or S32 when [classic]) for the reading [id].
  static String reading(String id, {bool classic = false}) => Uri(
    path: '/reading/${Uri.encodeComponent(id)}',
    queryParameters: classic ? {'mode': classicMode} : null,
  ).toString();

  /// S15 for the journal entry [id].
  static String journalEntry(String id) =>
      '$journal/${Uri.encodeComponent(id)}';

  /// S17 for [cardId].
  static String learnCard(String cardId) =>
      '$learn/card/${Uri.encodeComponent(cardId)}';

  /// S18 spread detail for [spreadId].
  static String learnSpread(String spreadId) =>
      '$learnSpreads/${Uri.encodeComponent(spreadId)}';

  /// S29 legal document [doc] (`disclaimer | terms | privacy | licenses`).
  static String legal(String doc) => '/legal/${Uri.encodeComponent(doc)}';

  /// S04 opened from [origin] (the `ai_consent_decided.origin` wire value,
  /// query `origin`; none = onboarding).
  static String consentAiFrom(String origin) => Uri(
    path: consentAi,
    queryParameters: {'origin': origin},
  ).toString();

  /// S27 opened from [origin] (the `crisis_resources_viewed.origin` wire
  /// value, query `origin`; none = help).
  static String helpCrisisFrom(String origin) => Uri(
    path: helpCrisis,
    queryParameters: {'origin': origin},
  ).toString();

  /// The onboarding locations (S02, S03, S04).
  static const Set<String> onboarding = {
    onboardingWelcome,
    onboardingDisclaimer,
    consentAi,
  };
}
