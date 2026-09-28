import 'package:taro_core/taro_core.dart';

const AnalyticsSpread _spread = AnalyticsSpread.threePpf;
const AnalyticsProduct _product = AnalyticsProduct.packM;

/// One event per catalogue entry, built through the `TaroAnalyticsEvent`
/// factories: the snapshot input.
List<TaroAnalyticsEvent> canonicalEvents() => [
  const TaroAnalyticsEvent.screenView(
    screen: ScreenId.s09,
    previous: ScreenId.s08,
  ),
  const TaroAnalyticsEvent.onboardingStepViewed(
    step: AnalyticsOnboardingStep.aiConsent,
  ),
  const TaroAnalyticsEvent.onboardingCompleted(durationS: 42, aiConsent: true),
  const TaroAnalyticsEvent.disclaimerAccepted(),
  const TaroAnalyticsEvent.aiConsentDecided(
    granted: true,
    origin: AiConsentOrigin.onboarding,
    consentVersion: 1,
  ),
  const TaroAnalyticsEvent.consentUmpResult(
    status: UmpResultStatus.obtained,
    formShown: true,
    canRequestAds: true,
  ),
  const TaroAnalyticsEvent.consentAttResult(
    status: AttResultStatus.denied,
    prepromptShown: true,
  ),
  const TaroAnalyticsEvent.analyticsToggled(enabled: false),
  const TaroAnalyticsEvent.readingFlowStarted(
    source: ReadingFlowSource.home,
    spread: _spread,
  ),
  const TaroAnalyticsEvent.readingGateBlocked(
    reason: GateBlockReason.insufficientCredits,
    spread: _spread,
  ),
  const TaroAnalyticsEvent.readingHoldResult(
    result: HoldResult.held,
    spread: _spread,
  ),
  const TaroAnalyticsEvent.questionSubmitted(
    spread: _spread,
    hasQuestion: true,
    questionLenBucket: QuestionLengthBucket.medium,
    usedSuggestion: false,
  ),
  const TaroAnalyticsEvent.drawCompleted(
    spread: _spread,
    autoDraw: false,
    reversedCount: 1,
    majorCount: 2,
    durationMs: 5300,
  ),
  const TaroAnalyticsEvent.readingGenerated(
    spread: _spread,
    latencyMs: 7400,
    promptVersion: 1,
    creditType: CreditType.free,
    locale: AnalyticsLocale.uk,
  ),
  const TaroAnalyticsEvent.readingFailed(
    spread: _spread,
    error: ReadingFailureKind.timeout,
    refunded: true,
  ),
  const TaroAnalyticsEvent.classicReadingStarted(
    spread: _spread,
    reason: ClassicReadingReason.paused,
  ),
  const TaroAnalyticsEvent.classicReadingCompleted(
    spread: _spread,
    reason: ClassicReadingReason.noConsent,
  ),
  const TaroAnalyticsEvent.readingReported(
    spread: _spread,
    reason: ReportReason.harmfulAdvice,
  ),
  const TaroAnalyticsEvent.readingRefused(
    spread: _spread,
    category: RefusalCategory.selfHarm,
    canRephrase: false,
  ),
  const TaroAnalyticsEvent.crisisResourcesViewed(
    origin: CrisisResourcesOrigin.reading,
  ),
  const TaroAnalyticsEvent.readingViewed(
    spread: _spread,
    origin: ReadingViewOrigin.journal,
  ),
  const TaroAnalyticsEvent.readingRated(
    spread: _spread,
    rating: Rating.down,
    reason: RatingReason.tooGeneric,
  ),
  const TaroAnalyticsEvent.readingShared(
    spread: _spread,
    includeQuestion: false,
  ),
  const TaroAnalyticsEvent.reflectionPromptUsed(spread: _spread),
  const TaroAnalyticsEvent.dailyCardRevealed(
    reversed: true,
    arcana: Arcana.major,
    streakDays: 3,
  ),
  const TaroAnalyticsEvent.dailyCardDeeperTapped(),
  const TaroAnalyticsEvent.journalNoteSaved(
    entryType: JournalEntryType.reading,
    noteLenBucket: NoteLengthBucket.short,
  ),
  const TaroAnalyticsEvent.journalEntryDeleted(
    entryType: JournalEntryType.daily,
    undone: true,
  ),
  const TaroAnalyticsEvent.journalFavouriteToggled(
    entryType: JournalEntryType.reading,
    on: true,
  ),
  const TaroAnalyticsEvent.journalFilterUsed(filter: JournalFilter.card),
  const TaroAnalyticsEvent.patternsViewed(range: PatternsRange.d90),
  TaroAnalyticsEvent.learnCardViewed(
    card: AnalyticsCardId.fromId(const CardId('cups_03')),
    orientation: CardOrientation.reversed,
    origin: LearnCardOrigin.search,
  ),
  const TaroAnalyticsEvent.learnSearch(
    resultsBucket: SearchResultsBucket.few,
  ),
  const TaroAnalyticsEvent.learnSpreadViewed(spread: AnalyticsSpread.single),
  const TaroAnalyticsEvent.reminderOfferAnswered(accepted: true),
  const TaroAnalyticsEvent.notificationPermissionResult(granted: false),
  const TaroAnalyticsEvent.reminderChanged(enabled: true, hour: 8),
  const TaroAnalyticsEvent.reminderOpened(),
  const TaroAnalyticsEvent.readingGateEvaluated(
    decision: GateDecisionKind.needsCredits,
    spread: _spread,
  ),
  const TaroAnalyticsEvent.freeReadingUsed(bucket: ChargeSource.free),
  const TaroAnalyticsEvent.readingCreditConsumed(bucket: ChargeSource.paid),
  const TaroAnalyticsEvent.outOfReadingsViewed(
    source: OutOfReadingsSource.hold402,
    rewardedAvailable: true,
    freeResetInMin: 185,
  ),
  const TaroAnalyticsEvent.storeViewed(source: StoreSource.balanceChip),
  const TaroAnalyticsEvent.paywallDismissed(
    surface: PaywallSurface.outOfReadings,
    secondsVisible: 12,
    actionTaken: PaywallAction.reward,
  ),
  const TaroAnalyticsEvent.iapProductsLoaded(
    count: 4,
    ms: 310,
    result: IapLoadResult.ok,
  ),
  const TaroAnalyticsEvent.purchaseStarted(
    product: _product,
    priceMicros: 4990000,
    currency: AnalyticsCurrency.usd,
  ),
  const TaroAnalyticsEvent.purchasePending(product: _product),
  const TaroAnalyticsEvent.purchaseCancelled(product: _product),
  const TaroAnalyticsEvent.purchaseFailed(
    product: _product,
    error: PurchaseErrorKind.verifyRejected,
  ),
  const TaroAnalyticsEvent.purchaseVerificationDelayed(product: _product),
  const TaroAnalyticsEvent.iapVerifyResult(
    product: _product,
    status: IapVerifyStatus.alreadyGranted,
    ms: 820,
    attempt: 2,
  ),
  const TaroAnalyticsEvent.iapVerifyStuck(product: _product, hours: 49),
  const TaroAnalyticsEvent.purchaseCompleted(
    product: _product,
    valueMicros: 4990000,
    currency: AnalyticsCurrency.eur,
    credits: 10,
    isFirstPurchase: true,
  ),
  const TaroAnalyticsEvent.restoreCompleted(result: RestoreResult.removeAds),
  const TaroAnalyticsEvent.removeAdsChanged(
    owned: true,
    source: RemoveAdsSource.ownershipCheck,
  ),
  const TaroAnalyticsEvent.rewardedOfferShown(
    eligible: false,
    ineligibleReason: RewardUnavailableReason.noFill,
  ),
  const TaroAnalyticsEvent.rewardedOfferTapped(source: RewardedSource.store),
  const TaroAnalyticsEvent.rewardedAdResult(
    result: RewardedAdResult.completed,
  ),
  const TaroAnalyticsEvent.rewardedGrantResult(
    result: RewardedGrantResult.granted,
    waitMs: 2400,
  ),
  const TaroAnalyticsEvent.adBannerImpression(
    screenId: BannerScreen.journalList,
  ),
  const TaroAnalyticsEvent.adBannerFailed(
    screenId: BannerScreen.home,
    errorCode: 3,
  ),
  const TaroAnalyticsEvent.configValueClamped(key: ConfigKey.rewardedDailyCap),
  const TaroAnalyticsEvent.exportCompleted(entriesBucket: EntriesBucket.some),
  const TaroAnalyticsEvent.exportFailed(
    entriesBucket: EntriesBucket.few,
    error: ExportError.storage,
  ),
  const TaroAnalyticsEvent.importCompleted(
    mode: ImportMode.merge,
    entriesBucket: EntriesBucket.many,
    schemaVersion: 1,
  ),
  const TaroAnalyticsEvent.importFailed(
    reason: ImportFailureReason.newerVersion,
  ),
  const TaroAnalyticsEvent.dataDeleted(workerAck: true),
  const TaroAnalyticsEvent.themeChanged(mode: ThemeMode.dark),
  const TaroAnalyticsEvent.languageChanged(locale: AnalyticsLocale.ar),
  const TaroAnalyticsEvent.languageChanged(locale: null),
  const TaroAnalyticsEvent.reversalsChanged(enabled: false),
  const TaroAnalyticsEvent.hapticsChanged(enabled: true),
  const TaroAnalyticsEvent.appUpdateRequiredShown(
    origin: AppNoticeOrigin.launch,
  ),
  const TaroAnalyticsEvent.appUpdateAvailableShown(
    origin: AppNoticeOrigin.resume,
  ),
  const TaroAnalyticsEvent.readingsPausedShown(
    origin: AppNoticeOrigin.readingGate,
  ),
  const TaroAnalyticsEvent.deviceUnverifiedShown(
    origin: AppNoticeOrigin.launch,
  ),
  const TaroAnalyticsEvent.ratePromptShown(),
  const TaroAnalyticsEvent.errorShown(
    kind: ErrorKind.rateLimited,
    screen: ScreenId.s07,
  ),
];

/// Every event with every value of each enum parameter (one parameter varied
/// at a time), plus both states of every optional parameter.
List<TaroAnalyticsEvent> exhaustiveEvents() => [
  ...canonicalEvents(),
  // Non-constant arguments and tear-offs so every constructor also runs at
  // runtime, not only in constant evaluation.
  for (final flag in const [true, false]) ...[
    AnalyticsToggledEvent(enabled: flag),
    DataDeletedEvent(workerAck: flag),
    ReminderOfferAnsweredEvent(accepted: flag),
    NotificationPermissionResultEvent(granted: flag),
    ReminderChangedEvent(enabled: flag, hour: 7),
    OnboardingCompletedEvent(durationS: 1, aiConsent: flag),
    SettingChangedEvent.reversals(enabled: flag),
    SettingChangedEvent.haptics(enabled: flag),
  ],
  for (final create in <TaroAnalyticsEvent Function()>[
    DisclaimerAcceptedEvent.new,
    DailyCardDeeperTappedEvent.new,
    ReminderOpenedEvent.new,
    RatePromptShownEvent.new,
  ])
    create(),
  for (final s in ScreenId.values) ScreenViewEvent(screen: s, previous: s),
  const ScreenViewEvent(screen: ScreenId.s01),
  for (final s in AnalyticsOnboardingStep.values)
    OnboardingStepViewedEvent(step: s),
  for (final o in AiConsentOrigin.values)
    AiConsentDecidedEvent(granted: false, origin: o, consentVersion: 2),
  for (final s in UmpResultStatus.values)
    ConsentUmpResultEvent(status: s, formShown: false, canRequestAds: false),
  for (final s in AttResultStatus.values)
    ConsentAttResultEvent(status: s, prepromptShown: false),
  for (final spread in AnalyticsSpread.values) ...[
    ReadingFlowStartedEvent(source: ReadingFlowSource.home, spread: spread),
    ReadingGateBlockedEvent(reason: GateBlockReason.offline, spread: spread),
    ReadingHoldResultEvent(result: HoldResult.error, spread: spread),
    QuestionSubmittedEvent(
      spread: spread,
      hasQuestion: false,
      questionLenBucket: QuestionLengthBucket.empty,
      usedSuggestion: true,
    ),
    DrawCompletedEvent(
      spread: spread,
      autoDraw: true,
      reversedCount: 0,
      majorCount: 0,
      durationMs: 0,
    ),
    ReadingGeneratedEvent(
      spread: spread,
      latencyMs: 1,
      promptVersion: 2,
      creditType: CreditType.paid,
      locale: AnalyticsLocale.en,
    ),
    ReadingFailedEvent(
      spread: spread,
      error: ReadingFailureKind.network,
      refunded: false,
    ),
    ClassicReadingStartedEvent(
      spread: spread,
      reason: ClassicReadingReason.region,
    ),
    ClassicReadingCompletedEvent(
      spread: spread,
      reason: ClassicReadingReason.region,
    ),
    ReadingReportedEvent(spread: spread, reason: ReportReason.other),
    ReadingRefusedEvent(
      spread: spread,
      category: RefusalCategory.other,
      canRephrase: true,
    ),
    ReadingViewedEvent(spread: spread, origin: ReadingViewOrigin.fresh),
    ReadingRatedEvent(spread: spread, rating: Rating.up),
    ReadingSharedEvent(spread: spread, includeQuestion: true),
    ReflectionPromptUsedEvent(spread: spread),
    LearnSpreadViewedEvent(spread: spread),
    ReadingGateEvaluatedEvent(
      decision: GateDecisionKind.allowed,
      spread: spread,
    ),
  ],
  for (final s in ReadingFlowSource.values)
    ReadingFlowStartedEvent(source: s, spread: _spread),
  for (final r in GateBlockReason.values)
    ReadingGateBlockedEvent(reason: r, spread: _spread),
  for (final r in HoldResult.values)
    ReadingHoldResultEvent(result: r, spread: _spread),
  for (final b in QuestionLengthBucket.values)
    QuestionSubmittedEvent(
      spread: _spread,
      hasQuestion: b != QuestionLengthBucket.empty,
      questionLenBucket: b,
      usedSuggestion: false,
    ),
  for (final c in CreditType.values)
    for (final l in AnalyticsLocale.values)
      ReadingGeneratedEvent(
        spread: _spread,
        latencyMs: 1,
        promptVersion: 1,
        creditType: c,
        locale: l,
      ),
  for (final e in ReadingFailureKind.values)
    ReadingFailedEvent(spread: _spread, error: e, refunded: true),
  for (final r in ClassicReadingReason.values) ...[
    ClassicReadingStartedEvent(spread: _spread, reason: r),
    ClassicReadingCompletedEvent(spread: _spread, reason: r),
  ],
  for (final r in ReportReason.values)
    ReadingReportedEvent(spread: _spread, reason: r),
  for (final c in RefusalCategory.values)
    ReadingRefusedEvent(spread: _spread, category: c, canRephrase: true),
  for (final o in CrisisResourcesOrigin.values)
    CrisisResourcesViewedEvent(origin: o),
  for (final o in ReadingViewOrigin.values)
    ReadingViewedEvent(spread: _spread, origin: o),
  for (final rating in Rating.values)
    for (final reason in RatingReason.values)
      ReadingRatedEvent(spread: _spread, rating: rating, reason: reason),
  for (final a in Arcana.values)
    DailyCardRevealedEvent(reversed: false, arcana: a, streakDays: 0),
  for (final t in JournalEntryType.values) ...[
    for (final b in NoteLengthBucket.values)
      JournalNoteSavedEvent(entryType: t, noteLenBucket: b),
    JournalEntryDeletedEvent(entryType: t, undone: false),
    JournalFavouriteToggledEvent(entryType: t, on: false),
  ],
  for (final f in JournalFilter.values) JournalFilterUsedEvent(filter: f),
  for (final r in PatternsRange.values) PatternsViewedEvent(range: r),
  for (final id in kCardIds)
    LearnCardViewedEvent(
      card: AnalyticsCardId.fromId(id),
      orientation: CardOrientation.upright,
      origin: LearnCardOrigin.deck,
    ),
  const LearnCardViewedEvent(
    card: AnalyticsCardId.unknown,
    orientation: CardOrientation.upright,
    origin: LearnCardOrigin.deck,
  ),
  for (final o in CardOrientation.values)
    for (final origin in LearnCardOrigin.values)
      LearnCardViewedEvent(
        card: AnalyticsCardId.fromId(const CardId('major_00')),
        orientation: o,
        origin: origin,
      ),
  for (final b in SearchResultsBucket.values)
    LearnSearchEvent(resultsBucket: b),
  for (final d in GateDecisionKind.values)
    ReadingGateEvaluatedEvent(decision: d, spread: _spread),
  for (final b in ChargeSource.values) ...[
    FreeReadingUsedEvent(bucket: b),
    ReadingCreditConsumedEvent(bucket: b),
  ],
  for (final s in OutOfReadingsSource.values)
    OutOfReadingsViewedEvent(
      source: s,
      rewardedAvailable: false,
      freeResetInMin: 0,
    ),
  for (final s in StoreSource.values) StoreViewedEvent(source: s),
  for (final s in PaywallSurface.values)
    for (final a in PaywallAction.values)
      PaywallDismissedEvent(surface: s, secondsVisible: 1, actionTaken: a),
  for (final r in IapLoadResult.values)
    IapProductsLoadedEvent(count: 0, ms: 0, result: r),
  for (final p in AnalyticsProduct.values) ...[
    for (final c in AnalyticsCurrency.values) ...[
      PurchaseStartedEvent(product: p, priceMicros: 1, currency: c),
      PurchaseCompletedEvent(
        product: p,
        valueMicros: 1,
        currency: c,
        credits: 0,
        isFirstPurchase: false,
      ),
    ],
    PurchasePendingEvent(product: p),
    PurchaseCancelledEvent(product: p),
    PurchaseFailedEvent(product: p),
    for (final e in PurchaseErrorKind.values) ...[
      PurchaseCancelledEvent(product: p, error: e),
      PurchaseFailedEvent(product: p, error: e),
    ],
    PurchaseVerificationDelayedEvent(product: p),
    for (final s in IapVerifyStatus.values)
      IapVerifyResultEvent(product: p, status: s, ms: 1, attempt: 1),
    IapVerifyStuckEvent(product: p, hours: 1),
  ],
  for (final r in RestoreResult.values) RestoreCompletedEvent(result: r),
  for (final s in RemoveAdsSource.values)
    RemoveAdsChangedEvent(owned: false, source: s),
  const RewardedOfferShownEvent(eligible: true),
  for (final r in RewardUnavailableReason.values)
    RewardedOfferShownEvent(eligible: false, ineligibleReason: r),
  for (final s in RewardedSource.values) RewardedOfferTappedEvent(source: s),
  for (final r in RewardedAdResult.values) RewardedAdResultEvent(result: r),
  for (final r in RewardedGrantResult.values)
    RewardedGrantResultEvent(result: r, waitMs: 0),
  for (final s in BannerScreen.values) ...[
    AdBannerImpressionEvent(screenId: s),
    AdBannerFailedEvent(screenId: s),
  ],
  for (final k in ConfigKey.values) ConfigValueClampedEvent(key: k),
  for (final b in EntriesBucket.values) ...[
    ExportCompletedEvent(entriesBucket: b),
    ExportFailedEvent(entriesBucket: b),
    for (final m in ImportMode.values)
      ImportCompletedEvent(mode: m, entriesBucket: b, schemaVersion: 1),
  ],
  for (final e in ExportError.values)
    ExportFailedEvent(entriesBucket: EntriesBucket.none, error: e),
  for (final r in ImportFailureReason.values) ImportFailedEvent(reason: r),
  const DataDeletedEvent(workerAck: false),
  for (final m in ThemeMode.values) SettingChangedEvent.theme(mode: m),
  for (final l in AnalyticsLocale.values)
    SettingChangedEvent.language(locale: l),
  const SettingChangedEvent.reversals(enabled: true),
  const SettingChangedEvent.haptics(enabled: false),
  for (final o in AppNoticeOrigin.values) ...[
    AppUpdateRequiredShownEvent(origin: o),
    AppUpdateAvailableShownEvent(origin: o),
    ReadingsPausedShownEvent(origin: o),
    DeviceUnverifiedShownEvent(origin: o),
  ],
  for (final k in ErrorKind.values)
    for (final s in ScreenId.values) ErrorShownEvent(kind: k, screen: s),
];
