/// The screen → controller-union map of the state inventory (01 §8.3,
/// Phase 13 Sprint 13.4).
///
/// Names, routes and banner IDs come from GLOSSARY §10; this table adds
/// what the glossary does not hold: which sealed state unions render each
/// screen, which of their states are ★ (golden at phone and tablet width,
/// RC24) and the 01 §8.3 states that are not union cases (view flags,
/// widget states, redirects).
library;

/// One screen of the inventory.
final class ScreenSpec {
  /// Creates a screen entry.
  const ScreenSpec(
    this.id, {
    this.unions = const [],
    this.only = const {},
    this.starred = const {},
    this.other = const [],
    this.otherStarred = const {},
  });

  /// `S01` … `S33`.
  final String id;

  /// The sealed state unions (class names) that render the screen; the
  /// first is the screen's own state, the others are sub-states.
  final List<String> unions;

  /// When not empty, only these states of the first union belong to this
  /// screen (S02/S03 share `OnboardingState`; S31 is a state of S07).
  final Set<String> only;

  /// ★ states of the first union.
  final Set<String> starred;

  /// 01 §8.3 states that are not union cases.
  final List<String> other;

  /// ★ entries of [other].
  final Set<String> otherStarred;
}

/// Every screen, in S-ID order.
const List<ScreenSpec> kScreens = [
  ScreenSpec(
    'S01',
    other: [
      'bootstrapping',
      'storageError (StorageErrorApp)',
      '→ updateRequired redirect',
      '→ onboarding or home',
    ],
  ),
  ScreenSpec(
    'S02',
    unions: ['OnboardingState'],
    only: {'welcome'},
    starred: {'welcome'},
  ),
  ScreenSpec(
    'S03',
    unions: ['OnboardingState'],
    only: {'disclaimer', 'acknowledged'},
    starred: {'disclaimer'},
  ),
  ScreenSpec(
    'S04',
    unions: ['AiConsentState', 'AttPrePromptState'],
    starred: {'undecided'},
  ),
  ScreenSpec(
    'S05',
    unions: ['HomeState'],
    starred: {'content'},
    other: [
      'content variants: freeAvailable / freeUsedWithCredits / zeroReadings',
      'firstRun (coachmark)',
      'balanceStale',
      'deviceUnverified',
      'dailyCardNotDrawn / dailyCardDrawn',
      'bannerLoaded / bannerFailed (BannerSlot)',
      'adsRemoved',
      'updateAvailable',
    ],
    otherStarred: {
      'content variants: freeAvailable / freeUsedWithCredits / zeroReadings',
    },
  ),
  ScreenSpec(
    'S06',
    unions: ['SpreadPickerState'],
    starred: {'content'},
    other: ['spreads disabled by remote config are hidden'],
  ),
  ScreenSpec(
    'S07',
    unions: ['QuestionState'],
    starred: {'editing', 'rephrase', 'refused'},
  ),
  ScreenSpec(
    'S08',
    unions: ['DrawState'],
    starred: {'shuffling', 'picking', 'awaitingReading'},
    other: ['reducedMotion variant'],
    otherStarred: {'reducedMotion variant'},
  ),
  ScreenSpec(
    'S09',
    unions: ['ReadingResultState'],
    starred: {'content'},
    other: ['alreadyReported (overflow shows "Reported")'],
  ),
  ScreenSpec(
    'S10',
    unions: ['OutOfReadingsState', 'PaywallPacks', 'RewardedOption'],
    starred: {'content'},
    other: ['lowTrustLimited copy'],
  ),
  ScreenSpec(
    'S11',
    unions: ['StoreState', 'StorePurchasePhase'],
    starred: {'loading', 'ready'},
    other: ['removeAdsOwned', 'purchasesBlocked(blocked | refundDebt)'],
  ),
  ScreenSpec('S12', unions: ['RewardedState'], starred: {'granted'}),
  ScreenSpec(
    'S13',
    unions: ['DailyCardState'],
    starred: {'notDrawn', 'drawn'},
  ),
  ScreenSpec(
    'S14',
    unions: ['JournalListState'],
    starred: {'empty', 'content'},
    other: ['patterns card (≥ 5 entries)', 'delete + 5 s undo'],
  ),
  ScreenSpec('S15', unions: ['JournalEntryState']),
  ScreenSpec('S16', unions: ['DeckBrowserState'], starred: {'content'}),
  ScreenSpec('S17', unions: ['CardDetailState'], starred: {'upright'}),
  ScreenSpec('S18', unions: ['SpreadGuideState']),
  ScreenSpec('S19', unions: ['AboutState']),
  ScreenSpec(
    'S20',
    unions: ['SettingsScreenState', 'SettingsRestore', 'SettingsTransfer'],
    starred: {'content'},
    other: ['adsRemoved'],
  ),
  ScreenSpec('S21', unions: ['LanguageState']),
  ScreenSpec('S22', unions: ['ReminderSettingsState']),
  ScreenSpec(
    'S23',
    unions: ['PrivacyState'],
    other: ['UMP required / not required', 'iOS / Android (Tracking row)'],
  ),
  ScreenSpec('S24', unions: ['ExportState']),
  ScreenSpec(
    'S25',
    unions: ['ImportState'],
    starred: {'invalid', 'preview'},
  ),
  ScreenSpec('S26', unions: ['DeleteDataState']),
  ScreenSpec(
    'S27',
    unions: ['CrisisResourcesState'],
    starred: {'content'},
  ),
  ScreenSpec('S28', unions: ['FaqState']),
  ScreenSpec('S29', unions: ['LegalState']),
  ScreenSpec(
    'S30',
    unions: ['UpdateRequiredState'],
    starred: {'content'},
  ),
  ScreenSpec(
    'S31',
    unions: ['QuestionState'],
    only: {'readingsPaused', 'aiUnavailableRegion'},
    other: ['freePaused copy variant'],
  ),
  ScreenSpec(
    'S32',
    unions: ['ClassicReadingState'],
    starred: {'content'},
  ),
  ScreenSpec(
    'S33',
    unions: ['ReportReadingState'],
    starred: {'editing'},
  ),
];
