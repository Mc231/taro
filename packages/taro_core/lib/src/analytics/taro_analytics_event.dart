/// The typed analytics event catalogue (01 §15, 04 §14; `docs/ANALYTICS_EVENTS.md`).
///
/// Every event has a literal [TaroAnalyticsEvent.eventName] and a
/// [TaroAnalyticsEvent.parameters] map whose values are bounded enum wire
/// strings, ints or bools (PR18). Events never carry user content or
/// identifiers.
library;

import 'package:collection/collection.dart';
import 'package:meta/meta.dart';
import 'package:taro_core/src/analytics/analytics_values.dart';
import 'package:taro_core/src/logic/banner_policy.dart';
import 'package:taro_core/src/model/credit_balance.dart';
import 'package:taro_core/src/model/deck_card.dart';
import 'package:taro_core/src/model/reading.dart';
import 'package:taro_core/src/model/user_settings.dart';
import 'package:taro_core/src/result/error_kind.dart';
import 'package:taro_core/src/result/failure.dart';
import 'package:taro_core/src/result/refusal_category.dart';

part 'events/app_events.dart';
part 'events/consent_events.dart';
part 'events/daily_card_events.dart';
part 'events/data_events.dart';
part 'events/error_events.dart';
part 'events/journal_events.dart';
part 'events/learn_events.dart';
part 'events/monetization_events.dart';
part 'events/notification_events.dart';
part 'events/onboarding_events.dart';
part 'events/reading_events.dart';
part 'events/screen_events.dart';
part 'events/settings_events.dart';

const MapEquality<String, Object> _mapEquality = MapEquality();

/// A typed analytics event (01 §15). Sent through `AnalyticsService` behind
/// `ConsentAwareAnalytics` (RC68).
///
/// Two events are equal when their [eventName] and [parameters] are.
@immutable
sealed class TaroAnalyticsEvent {
  const TaroAnalyticsEvent._();

  // ScreenEvent

  /// `screen_view`.
  const factory TaroAnalyticsEvent.screenView({
    required ScreenId screen,
    ScreenId? previous,
  }) = ScreenViewEvent;

  // OnboardingEvent

  /// `onboarding_step_viewed`.
  const factory TaroAnalyticsEvent.onboardingStepViewed({
    required AnalyticsOnboardingStep step,
  }) = OnboardingStepViewedEvent;

  /// `onboarding_completed`.
  const factory TaroAnalyticsEvent.onboardingCompleted({
    required int durationS,
    required bool aiConsent,
  }) = OnboardingCompletedEvent;

  /// `disclaimer_accepted`.
  const factory TaroAnalyticsEvent.disclaimerAccepted() =
      DisclaimerAcceptedEvent;

  // ConsentEvent

  /// `ai_consent_decided`.
  const factory TaroAnalyticsEvent.aiConsentDecided({
    required bool granted,
    required AiConsentOrigin origin,
    required int consentVersion,
  }) = AiConsentDecidedEvent;

  /// `consent_ump_result`.
  const factory TaroAnalyticsEvent.consentUmpResult({
    required UmpResultStatus status,
    required bool formShown,
    required bool canRequestAds,
  }) = ConsentUmpResultEvent;

  /// `consent_att_result`.
  const factory TaroAnalyticsEvent.consentAttResult({
    required AttResultStatus status,
    required bool prepromptShown,
  }) = ConsentAttResultEvent;

  /// `analytics_toggled`.
  const factory TaroAnalyticsEvent.analyticsToggled({required bool enabled}) =
      AnalyticsToggledEvent;

  // ReadingEvent

  /// `reading_flow_started`.
  const factory TaroAnalyticsEvent.readingFlowStarted({
    required ReadingFlowSource source,
    required AnalyticsSpread spread,
  }) = ReadingFlowStartedEvent;

  /// `reading_gate_blocked`.
  const factory TaroAnalyticsEvent.readingGateBlocked({
    required GateBlockReason reason,
    required AnalyticsSpread spread,
  }) = ReadingGateBlockedEvent;

  /// `reading_hold_result`.
  const factory TaroAnalyticsEvent.readingHoldResult({
    required HoldResult result,
    required AnalyticsSpread spread,
  }) = ReadingHoldResultEvent;

  /// `question_submitted`.
  const factory TaroAnalyticsEvent.questionSubmitted({
    required AnalyticsSpread spread,
    required bool hasQuestion,
    required QuestionLengthBucket questionLenBucket,
    required bool usedSuggestion,
  }) = QuestionSubmittedEvent;

  /// `draw_completed`.
  const factory TaroAnalyticsEvent.drawCompleted({
    required AnalyticsSpread spread,
    required bool autoDraw,
    required int reversedCount,
    required int majorCount,
    required int durationMs,
  }) = DrawCompletedEvent;

  /// `reading_generated`.
  const factory TaroAnalyticsEvent.readingGenerated({
    required AnalyticsSpread spread,
    required int latencyMs,
    required int promptVersion,
    required CreditType creditType,
    required AnalyticsLocale locale,
  }) = ReadingGeneratedEvent;

  /// `reading_failed`.
  const factory TaroAnalyticsEvent.readingFailed({
    required AnalyticsSpread spread,
    required ReadingFailureKind error,
    required bool refunded,
  }) = ReadingFailedEvent;

  /// `classic_reading_started`.
  const factory TaroAnalyticsEvent.classicReadingStarted({
    required AnalyticsSpread spread,
    required ClassicReadingReason reason,
  }) = ClassicReadingStartedEvent;

  /// `classic_reading_completed`.
  const factory TaroAnalyticsEvent.classicReadingCompleted({
    required AnalyticsSpread spread,
    required ClassicReadingReason reason,
  }) = ClassicReadingCompletedEvent;

  /// `reading_reported`.
  const factory TaroAnalyticsEvent.readingReported({
    required AnalyticsSpread spread,
    required ReportReason reason,
  }) = ReadingReportedEvent;

  /// `reading_refused`.
  const factory TaroAnalyticsEvent.readingRefused({
    required AnalyticsSpread spread,
    required RefusalCategory category,
    required bool canRephrase,
  }) = ReadingRefusedEvent;

  /// `crisis_resources_viewed`.
  const factory TaroAnalyticsEvent.crisisResourcesViewed({
    required CrisisResourcesOrigin origin,
  }) = CrisisResourcesViewedEvent;

  /// `reading_viewed`.
  const factory TaroAnalyticsEvent.readingViewed({
    required AnalyticsSpread spread,
    required ReadingViewOrigin origin,
  }) = ReadingViewedEvent;

  /// `reading_rated`.
  const factory TaroAnalyticsEvent.readingRated({
    required AnalyticsSpread spread,
    required Rating rating,
    RatingReason? reason,
  }) = ReadingRatedEvent;

  /// `reading_shared`.
  const factory TaroAnalyticsEvent.readingShared({
    required AnalyticsSpread spread,
    required bool includeQuestion,
  }) = ReadingSharedEvent;

  /// `reflection_prompt_used`.
  const factory TaroAnalyticsEvent.reflectionPromptUsed({
    required AnalyticsSpread spread,
  }) = ReflectionPromptUsedEvent;

  // DailyCardEvent

  /// `daily_card_revealed`.
  const factory TaroAnalyticsEvent.dailyCardRevealed({
    required bool reversed,
    required Arcana arcana,
    required int streakDays,
  }) = DailyCardRevealedEvent;

  /// `daily_card_deeper_tapped`.
  const factory TaroAnalyticsEvent.dailyCardDeeperTapped() =
      DailyCardDeeperTappedEvent;

  // JournalEvent

  /// `journal_note_saved`.
  const factory TaroAnalyticsEvent.journalNoteSaved({
    required JournalEntryType entryType,
    required NoteLengthBucket noteLenBucket,
  }) = JournalNoteSavedEvent;

  /// `journal_entry_deleted`.
  const factory TaroAnalyticsEvent.journalEntryDeleted({
    required JournalEntryType entryType,
    required bool undone,
  }) = JournalEntryDeletedEvent;

  /// `journal_favourite_toggled`.
  const factory TaroAnalyticsEvent.journalFavouriteToggled({
    required JournalEntryType entryType,
    required bool on,
  }) = JournalFavouriteToggledEvent;

  /// `journal_filter_used`.
  const factory TaroAnalyticsEvent.journalFilterUsed({
    required JournalFilter filter,
  }) = JournalFilterUsedEvent;

  /// `patterns_viewed`.
  const factory TaroAnalyticsEvent.patternsViewed({
    required PatternsRange range,
  }) = PatternsViewedEvent;

  // LearnEvent

  /// `learn_card_viewed`.
  const factory TaroAnalyticsEvent.learnCardViewed({
    required AnalyticsCardId card,
    required CardOrientation orientation,
    required LearnCardOrigin origin,
  }) = LearnCardViewedEvent;

  /// `learn_search`.
  const factory TaroAnalyticsEvent.learnSearch({
    required SearchResultsBucket resultsBucket,
  }) = LearnSearchEvent;

  /// `learn_spread_viewed`.
  const factory TaroAnalyticsEvent.learnSpreadViewed({
    required AnalyticsSpread spread,
  }) = LearnSpreadViewedEvent;

  // NotificationEvent

  /// `reminder_offer_answered`.
  const factory TaroAnalyticsEvent.reminderOfferAnswered({
    required bool accepted,
  }) = ReminderOfferAnsweredEvent;

  /// `notification_permission_result`.
  const factory TaroAnalyticsEvent.notificationPermissionResult({
    required bool granted,
  }) = NotificationPermissionResultEvent;

  /// `reminder_changed`.
  const factory TaroAnalyticsEvent.reminderChanged({
    required bool enabled,
    required int hour,
  }) = ReminderChangedEvent;

  /// `reminder_opened`.
  const factory TaroAnalyticsEvent.reminderOpened() = ReminderOpenedEvent;

  // MonetizationEvent (04 §14)

  /// `reading_gate_evaluated`.
  const factory TaroAnalyticsEvent.readingGateEvaluated({
    required GateDecisionKind decision,
    required AnalyticsSpread spread,
  }) = ReadingGateEvaluatedEvent;

  /// `free_reading_used`.
  const factory TaroAnalyticsEvent.freeReadingUsed({
    required ChargeSource bucket,
  }) = FreeReadingUsedEvent;

  /// `reading_credit_consumed`.
  const factory TaroAnalyticsEvent.readingCreditConsumed({
    required ChargeSource bucket,
  }) = ReadingCreditConsumedEvent;

  /// `out_of_readings_viewed`.
  const factory TaroAnalyticsEvent.outOfReadingsViewed({
    required OutOfReadingsSource source,
    required bool rewardedAvailable,
    required int freeResetInMin,
  }) = OutOfReadingsViewedEvent;

  /// `store_viewed`.
  const factory TaroAnalyticsEvent.storeViewed({required StoreSource source}) =
      StoreViewedEvent;

  /// `paywall_dismissed`.
  const factory TaroAnalyticsEvent.paywallDismissed({
    required PaywallSurface surface,
    required int secondsVisible,
    required PaywallAction actionTaken,
  }) = PaywallDismissedEvent;

  /// `iap_products_loaded`.
  const factory TaroAnalyticsEvent.iapProductsLoaded({
    required int count,
    required int ms,
    required IapLoadResult result,
  }) = IapProductsLoadedEvent;

  /// `purchase_started`.
  const factory TaroAnalyticsEvent.purchaseStarted({
    required AnalyticsProduct product,
    required int priceMicros,
    required AnalyticsCurrency currency,
  }) = PurchaseStartedEvent;

  /// `purchase_pending`.
  const factory TaroAnalyticsEvent.purchasePending({
    required AnalyticsProduct product,
  }) = PurchasePendingEvent;

  /// `purchase_cancelled`.
  const factory TaroAnalyticsEvent.purchaseCancelled({
    required AnalyticsProduct product,
    PurchaseErrorKind? error,
  }) = PurchaseCancelledEvent;

  /// `purchase_failed`.
  const factory TaroAnalyticsEvent.purchaseFailed({
    required AnalyticsProduct product,
    PurchaseErrorKind? error,
  }) = PurchaseFailedEvent;

  /// `purchase_verification_delayed`.
  const factory TaroAnalyticsEvent.purchaseVerificationDelayed({
    required AnalyticsProduct product,
  }) = PurchaseVerificationDelayedEvent;

  /// `iap_verify_result`.
  const factory TaroAnalyticsEvent.iapVerifyResult({
    required AnalyticsProduct product,
    required IapVerifyStatus status,
    required int ms,
    required int attempt,
  }) = IapVerifyResultEvent;

  /// `iap_verify_stuck`.
  const factory TaroAnalyticsEvent.iapVerifyStuck({
    required AnalyticsProduct product,
    required int hours,
  }) = IapVerifyStuckEvent;

  /// `purchase_completed`.
  const factory TaroAnalyticsEvent.purchaseCompleted({
    required AnalyticsProduct product,
    required int valueMicros,
    required AnalyticsCurrency currency,
    required int credits,
    required bool isFirstPurchase,
  }) = PurchaseCompletedEvent;

  /// `restore_completed`.
  const factory TaroAnalyticsEvent.restoreCompleted({
    required RestoreResult result,
  }) = RestoreCompletedEvent;

  /// `remove_ads_changed`.
  const factory TaroAnalyticsEvent.removeAdsChanged({
    required bool owned,
    required RemoveAdsSource source,
  }) = RemoveAdsChangedEvent;

  /// `rewarded_offer_shown`.
  const factory TaroAnalyticsEvent.rewardedOfferShown({
    required bool eligible,
    RewardUnavailableReason? ineligibleReason,
  }) = RewardedOfferShownEvent;

  /// `rewarded_offer_tapped`.
  const factory TaroAnalyticsEvent.rewardedOfferTapped({
    required RewardedSource source,
  }) = RewardedOfferTappedEvent;

  /// `rewarded_ad_result`.
  const factory TaroAnalyticsEvent.rewardedAdResult({
    required RewardedAdResult result,
  }) = RewardedAdResultEvent;

  /// `rewarded_grant_result`.
  const factory TaroAnalyticsEvent.rewardedGrantResult({
    required RewardedGrantResult result,
    required int waitMs,
  }) = RewardedGrantResultEvent;

  /// `ad_banner_impression`.
  const factory TaroAnalyticsEvent.adBannerImpression({
    required BannerScreen screenId,
  }) = AdBannerImpressionEvent;

  /// `ad_banner_failed`.
  const factory TaroAnalyticsEvent.adBannerFailed({
    required BannerScreen screenId,
    int? errorCode,
  }) = AdBannerFailedEvent;

  /// `config_value_clamped`.
  const factory TaroAnalyticsEvent.configValueClamped({
    required ConfigKey key,
  }) = ConfigValueClampedEvent;

  // DataEvent

  /// `export_completed`.
  const factory TaroAnalyticsEvent.exportCompleted({
    required EntriesBucket entriesBucket,
  }) = ExportCompletedEvent;

  /// `export_failed`.
  const factory TaroAnalyticsEvent.exportFailed({
    required EntriesBucket entriesBucket,
    ExportError? error,
  }) = ExportFailedEvent;

  /// `import_completed`.
  const factory TaroAnalyticsEvent.importCompleted({
    required ImportMode mode,
    required EntriesBucket entriesBucket,
    required int schemaVersion,
  }) = ImportCompletedEvent;

  /// `import_failed`.
  const factory TaroAnalyticsEvent.importFailed({
    required ImportFailureReason reason,
  }) = ImportFailedEvent;

  /// `data_deleted`.
  const factory TaroAnalyticsEvent.dataDeleted({required bool workerAck}) =
      DataDeletedEvent;

  // SettingsEvent

  /// `setting_changed` for the theme.
  const factory TaroAnalyticsEvent.themeChanged({required ThemeMode mode}) =
      SettingChangedEvent.theme;

  /// `setting_changed` for the app language; `null` follows the device.
  const factory TaroAnalyticsEvent.languageChanged({
    required AnalyticsLocale? locale,
  }) = SettingChangedEvent.language;

  /// `setting_changed` for reversed cards.
  const factory TaroAnalyticsEvent.reversalsChanged({required bool enabled}) =
      SettingChangedEvent.reversals;

  /// `setting_changed` for haptics.
  const factory TaroAnalyticsEvent.hapticsChanged({required bool enabled}) =
      SettingChangedEvent.haptics;

  // AppEvent

  /// `app_update_required_shown`.
  const factory TaroAnalyticsEvent.appUpdateRequiredShown({
    required AppNoticeOrigin origin,
  }) = AppUpdateRequiredShownEvent;

  /// `app_update_available_shown`.
  const factory TaroAnalyticsEvent.appUpdateAvailableShown({
    required AppNoticeOrigin origin,
  }) = AppUpdateAvailableShownEvent;

  /// `readings_paused_shown`.
  const factory TaroAnalyticsEvent.readingsPausedShown({
    required AppNoticeOrigin origin,
  }) = ReadingsPausedShownEvent;

  /// `device_unverified_shown`.
  const factory TaroAnalyticsEvent.deviceUnverifiedShown({
    required AppNoticeOrigin origin,
  }) = DeviceUnverifiedShownEvent;

  /// `rate_prompt_shown`.
  const factory TaroAnalyticsEvent.ratePromptShown() = RatePromptShownEvent;

  // ErrorEvent

  /// `error_shown`.
  const factory TaroAnalyticsEvent.errorShown({
    required ErrorKind kind,
    required ScreenId screen,
  }) = ErrorShownEvent;

  /// The event name: snake_case, ≤ 40 characters.
  String get eventName;

  /// The parameters: at most 25, each a bounded enum wire string, an int or
  /// a bool (PR18). Absent optional parameters are omitted.
  Map<String, Object> get parameters;

  @override
  bool operator ==(Object other) =>
      other is TaroAnalyticsEvent &&
      other.eventName == eventName &&
      _mapEquality.equals(other.parameters, parameters);

  @override
  int get hashCode => Object.hash(eventName, _mapEquality.hash(parameters));

  @override
  String toString() => '$eventName$parameters';
}
