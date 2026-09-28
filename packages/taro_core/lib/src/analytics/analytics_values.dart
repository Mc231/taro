/// Closed value sets for analytics parameters (01 §15, 04 §14, PR18).
///
/// Every analytics parameter is a bounded enum, an int or a bool. The enums
/// here carry their wire value ([AnalyticsEnum.wire]); domain enums reused as
/// parameters are converted with [analyticsWire].
library;

import 'package:meta/meta.dart';
import 'package:taro_core/src/model/credit_balance.dart';
import 'package:taro_core/src/model/reading.dart';
import 'package:taro_core/src/model/remote_config.dart';
import 'package:taro_core/src/model/spread.dart';
import 'package:taro_core/src/model/user_settings.dart';
import 'package:taro_core/src/monetization/taro_products.dart';
import 'package:taro_core/src/result/failure.dart';
import 'package:taro_core/src/result/ids.dart';
import 'package:taro_core/src/result/refusal_category.dart';

// Owned next to their single source (the `GateDecision` variants and the
// keys `RemoteConfig.fromJson` reads); re-exported as analytics values.
export 'package:taro_core/src/logic/reading_gate.dart' show GateDecisionKind;
export 'package:taro_core/src/model/remote_config.dart' show ConfigKey;

final RegExp _upper = RegExp('[A-Z]');

String _snakeCase(String camel) =>
    camel.replaceAllMapped(_upper, (m) => '_${m[0]!.toLowerCase()}');

/// An enum usable as an analytics parameter value.
///
/// The default [wire] is the snake_case form of the enum name
/// (`spreadsGuide` → `spreads_guide`); enums with other wire values override
/// it.
mixin AnalyticsEnum on Enum {
  /// The parameter value sent to analytics.
  String get wire => _snakeCase(name);
}

/// The analytics wire value of any enum.
///
/// [AnalyticsEnum]s and domain enums with a wire form ([RefusalCategory],
/// [RatingReason], [ConfigKey]) use it; any other enum uses its snake_case
/// name.
String analyticsWire(Enum value) => switch (value) {
  AnalyticsEnum(:final wire) => wire,
  RefusalCategory(:final wire) => wire,
  RatingReason(:final wire) => wire,
  ConfigKey(:final wire) => wire,
  _ => _snakeCase(value.name),
};

/// The screen IDs `S01`…`S33` (GLOSSARY §10, RC94): `screen_view.screen`,
/// `screen_view.previous` and `error_shown.screen`.
enum ScreenId with AnalyticsEnum {
  /// Launch / bootstrap.
  s01,

  /// Onboarding: Welcome.
  s02,

  /// Onboarding: Disclaimer.
  s03,

  /// AI consent.
  s04,

  /// Home.
  s05,

  /// Spread picker.
  s06,

  /// Question input + Begin.
  s07,

  /// Draw ritual.
  s08,

  /// Reading result.
  s09,

  /// Out-of-readings sheet.
  s10,

  /// Store / paywall.
  s11,

  /// Rewarded flow overlay.
  s12,

  /// Daily card.
  s13,

  /// Journal list.
  s14,

  /// Journal entry detail.
  s15,

  /// Learn: deck browser.
  s16,

  /// Learn: card detail.
  s17,

  /// Learn: spreads guide.
  s18,

  /// Learn: About tarot & Taro.
  s19,

  /// Settings.
  s20,

  /// Language picker.
  s21,

  /// Reminder settings.
  s22,

  /// Privacy choices.
  s23,

  /// Export backup.
  s24,

  /// Import backup.
  s25,

  /// Delete all data.
  s26,

  /// Crisis resources.
  s27,

  /// FAQ / Help.
  s28,

  /// Legal.
  s29,

  /// Update required.
  s30,

  /// Readings paused.
  s31,

  /// Classic reading result.
  s32,

  /// Report reading.
  s33;

  /// The literal ID, e.g. `S01`.
  @override
  String get wire => name.toUpperCase();
}

/// A spread ID as an analytics value (`spread_id`, RC2).
enum AnalyticsSpread with AnalyticsEnum {
  /// `single`.
  single,

  /// `three_ppf`.
  threePpf,

  /// `three_sao`.
  threeSao,

  /// `relationship`.
  relationship,

  /// `two_paths`.
  twoPaths,

  /// `celtic_cross`.
  celticCross,

  /// Any ID outside [kSpreadIds].
  unknown;

  /// The value for [id]; [unknown] if it is not a v1 spread.
  static AnalyticsSpread fromId(SpreadId id) {
    for (final spread in values) {
      if (spread.wire == id.value) return spread;
    }
    return unknown;
  }
}

/// A card ID as an analytics value (`learn_card_viewed.card_id`, RC1):
/// one of the 78 IDs, or `unknown`.
@immutable
final class AnalyticsCardId {
  const AnalyticsCardId._(this.wire);

  /// The value for [id]; `unknown` unless it matches the RC1 format.
  factory AnalyticsCardId.fromId(CardId id) =>
      AnalyticsCardId._(CardId.isValid(id.value) ? id.value : unknown.wire);

  /// The value for an invalid card ID.
  static const AnalyticsCardId unknown = AnalyticsCardId._('unknown');

  /// The parameter value.
  final String wire;

  @override
  bool operator ==(Object other) =>
      other is AnalyticsCardId && other.wire == wire;

  @override
  int get hashCode => wire.hashCode;

  @override
  String toString() => 'AnalyticsCardId($wire)';
}

/// An app locale as an analytics value (01 §13).
enum AnalyticsLocale with AnalyticsEnum {
  /// English.
  en,

  /// Arabic.
  ar,

  /// German.
  de,

  /// Spanish.
  es,

  /// French.
  fr,

  /// Italian.
  it,

  /// Japanese.
  ja,

  /// Korean.
  ko,

  /// Dutch.
  nl,

  /// Portuguese (Brazil).
  pt,

  /// Turkish.
  tr,

  /// Ukrainian.
  uk,

  /// Any tag outside [kSupportedLocales].
  other;

  /// The value for a language tag such as `pt` or `pt-BR`; [other] if the
  /// language is not supported.
  static AnalyticsLocale fromTag(String tag) {
    final language = tag.split(RegExp('[-_]')).first.toLowerCase();
    for (final locale in values) {
      if (locale != other && locale.name == language) return locale;
    }
    return other;
  }
}

/// `onboarding_step_viewed.step`.
enum AnalyticsOnboardingStep with AnalyticsEnum {
  /// S02.
  welcome,

  /// S03.
  disclaimer,

  /// S04.
  aiConsent,

  /// The UMP form.
  ump,

  /// The ATT pre-prompt (iOS).
  att,
}

/// `ai_consent_decided.origin`.
enum AiConsentOrigin with AnalyticsEnum {
  /// Onboarding step S04.
  onboarding,

  /// Re-prompt from the reading gate.
  readingGate,

  /// Privacy choices (S23).
  settings,
}

/// `consent_ump_result.status`.
enum UmpResultStatus with AnalyticsEnum {
  /// Consent obtained.
  obtained,

  /// Consent not required in this region.
  notRequired,

  /// Consent required and declined.
  requiredDeclined,

  /// The UMP SDK failed.
  error,
}

/// `consent_att_result.status`.
enum AttResultStatus with AnalyticsEnum {
  /// Tracking authorized.
  authorized,

  /// Tracking denied.
  denied,

  /// Tracking restricted by the device.
  restricted,

  /// The system prompt was not answered.
  notDetermined,
}

/// `reading_flow_started.source`.
enum ReadingFlowSource with AnalyticsEnum {
  /// Home.
  home,

  /// Learn spreads guide.
  spreadsGuide,

  /// Daily card "go deeper".
  dailyCard,

  /// `taro://reading/new`.
  deepLink,

  /// Retry from a failed journal entry.
  journalRetry,
}

/// `reading_gate_blocked.reason`.
enum GateBlockReason with AnalyticsEnum {
  /// No AI consent.
  noConsent,

  /// Offline.
  offline,

  /// No credits: paywall.
  insufficientCredits,

  /// Kill switch or budget stop.
  readingsPaused,

  /// The spread is disabled by config.
  spreadDisabled,

  /// Attestation failed.
  deviceUnverified,

  /// Rate limited.
  rateLimited,

  /// Daily cap reached.
  dailyLimit,

  /// Low-trust cap reached.
  lowTrust,

  /// AI unavailable in the region.
  region,

  /// Free readings paused (RC64).
  freePaused,
}

/// `reading_hold_result.result`.
enum HoldResult with AnalyticsEnum {
  /// The hold was placed.
  held,

  /// `402 INSUFFICIENT_CREDITS`.
  insufficientCredits,

  /// Readings are paused.
  paused,

  /// Any other failure.
  error,
}

/// `question_submitted.question_len_bucket`.
enum QuestionLengthBucket with AnalyticsEnum {
  /// No question.
  empty('0'),

  /// 1–50 characters.
  short('1-50'),

  /// 51–150 characters.
  medium('51-150'),

  /// 151–300 characters.
  long('151-300');

  const QuestionLengthBucket(this.wire);

  @override
  final String wire;

  /// The bucket for a question of [length] grapheme clusters.
  static QuestionLengthBucket fromLength(int length) {
    if (length <= 0) return empty;
    if (length <= 50) return short;
    if (length <= 150) return medium;
    return long;
  }
}

/// `reading_generated.credit_type`.
enum CreditType with AnalyticsEnum {
  /// The daily free reading.
  free,

  /// A purchased reading.
  paid,

  /// An earned (bonus) reading.
  rewarded;

  /// The credit type for the bucket a reading was paid from.
  static CreditType fromChargeSource(ChargeSource source) => switch (source) {
    ChargeSource.free => free,
    ChargeSource.bonus => rewarded,
    ChargeSource.paid => paid,
  };
}

/// `reading_failed.error`.
enum ReadingFailureKind with AnalyticsEnum {
  /// Offline.
  network,

  /// Timed out.
  timeout,

  /// Server failure.
  server,

  /// Blocked by moderation.
  moderation,

  /// The hold was lost.
  holdLost,

  /// Delivery expired and was refunded.
  deliveryExpired,
}

/// `classic_reading_started.reason` / `classic_reading_completed.reason`.
enum ClassicReadingReason with AnalyticsEnum {
  /// No AI consent.
  noConsent,

  /// AI unavailable in the region.
  region,

  /// Readings paused.
  paused,
}

/// `reading_reported.reason` (S33, CS7).
enum ReportReason with AnalyticsEnum {
  /// Offensive.
  offensive,

  /// Harmful advice.
  harmfulAdvice,

  /// Sexual.
  sexual,

  /// Hateful.
  hateful,

  /// Other.
  other,
}

/// `crisis_resources_viewed.origin`.
enum CrisisResourcesOrigin with AnalyticsEnum {
  /// From a declined reading.
  reading,

  /// From Help.
  help,

  /// From Settings.
  settings,
}

/// `reading_viewed.origin`.
enum ReadingViewOrigin with AnalyticsEnum {
  /// Right after generation.
  fresh,

  /// Opened from the journal.
  journal,
}

/// `entry_type` of the journal events.
enum JournalEntryType with AnalyticsEnum {
  /// A reading.
  reading,

  /// A daily card.
  daily,
}

/// `journal_note_saved.note_len_bucket` (notes are ≤ 5,000 chars).
enum NoteLengthBucket with AnalyticsEnum {
  /// Empty note.
  empty('0'),

  /// 1–100 characters.
  short('1-100'),

  /// 101–500 characters.
  medium('101-500'),

  /// 501–2000 characters.
  long('501-2000'),

  /// More than 2000 characters.
  veryLong('2001+');

  const NoteLengthBucket(this.wire);

  @override
  final String wire;

  /// The bucket for a note of [length] characters.
  static NoteLengthBucket fromLength(int length) {
    if (length <= 0) return empty;
    if (length <= 100) return short;
    if (length <= 500) return medium;
    if (length <= 2000) return long;
    return veryLong;
  }
}

/// `journal_filter_used.filter`.
enum JournalFilter with AnalyticsEnum {
  /// Entry type.
  type,

  /// Spread.
  spread,

  /// Card.
  card,

  /// Favourites.
  favourites,

  /// Search.
  search,
}

/// `patterns_viewed.range`.
enum PatternsRange with AnalyticsEnum {
  /// 30 days.
  d30,

  /// 90 days.
  d90,
}

/// `learn_card_viewed.orientation`.
enum CardOrientation with AnalyticsEnum {
  /// Upright.
  upright,

  /// Reversed.
  reversed,
}

/// `learn_card_viewed.origin`.
enum LearnCardOrigin with AnalyticsEnum {
  /// Deck browser.
  deck,

  /// Search.
  search,

  /// A reading.
  reading,

  /// Journal patterns.
  patterns,
}

/// `learn_search.results_bucket`.
enum SearchResultsBucket with AnalyticsEnum {
  /// No results.
  none('0'),

  /// 1–5 results.
  few('1-5'),

  /// 6 or more results.
  many('6+');

  const SearchResultsBucket(this.wire);

  @override
  final String wire;

  /// The bucket for [count] results.
  static SearchResultsBucket fromCount(int count) {
    if (count <= 0) return none;
    if (count <= 5) return few;
    return many;
  }
}

/// `entries_bucket` of the backup events.
enum EntriesBucket with AnalyticsEnum {
  /// No entries.
  none('0'),

  /// 1–10 entries.
  few('1-10'),

  /// 11–50 entries.
  some('11-50'),

  /// 51–200 entries.
  many('51-200'),

  /// More than 200 entries.
  lots('201+');

  const EntriesBucket(this.wire);

  @override
  final String wire;

  /// The bucket for [count] entries.
  static EntriesBucket fromCount(int count) {
    if (count <= 0) return none;
    if (count <= 10) return few;
    if (count <= 50) return some;
    if (count <= 200) return many;
    return lots;
  }
}

/// `out_of_readings_viewed.source` (RC74).
enum OutOfReadingsSource with AnalyticsEnum {
  /// The question screen gate.
  questionGate('question_gate'),

  /// The hold answered `402`.
  hold402('hold_402'),

  /// The balance chip.
  balanceChip('balance_chip'),

  /// A hold was lost.
  holdLost('hold_lost'),

  /// Low-trust cap.
  lowTrust('low_trust');

  const OutOfReadingsSource(this.wire);

  @override
  final String wire;
}

/// `store_viewed.source`.
enum StoreSource with AnalyticsEnum {
  /// From S10.
  outOfReadings,

  /// From Settings.
  settings,

  /// From the balance chip.
  balanceChip,

  /// `taro://store`.
  deepLink,
}

/// `paywall_dismissed.surface`.
enum PaywallSurface with AnalyticsEnum {
  /// S10.
  outOfReadings,

  /// S11.
  store,
}

/// `paywall_dismissed.action_taken`.
enum PaywallAction with AnalyticsEnum {
  /// Closed without acting.
  none,

  /// A purchase was made.
  purchase,

  /// A rewarded ad was watched.
  reward,
}

/// `iap_products_loaded.result`.
enum IapLoadResult with AnalyticsEnum {
  /// Every product was found.
  ok,

  /// Some products were not found.
  partial,

  /// No product was found.
  empty,

  /// The store query failed.
  error,
}

/// The analytics alias of a product (`product`, GLOSSARY §3, RC3). Never
/// the raw product ID.
enum AnalyticsProduct with AnalyticsEnum {
  /// `readings_3`.
  packS,

  /// `readings_10`.
  packM,

  /// `readings_30`.
  packL,

  /// `remove_ads`.
  removeAds;

  /// The alias of [product] (its `alias`).
  static AnalyticsProduct fromProduct(TaroProduct product) =>
      values.firstWhere((p) => p.wire == product.alias);
}

/// Store currency (ISO 4217) as a closed set: `currency` of the purchase
/// events. Unlisted codes map to [other].
enum AnalyticsCurrency with AnalyticsEnum {
  /// UAE dirham.
  aed,

  /// Australian dollar.
  aud,

  /// Bulgarian lev.
  bgn,

  /// Brazilian real.
  brl,

  /// Canadian dollar.
  cad,

  /// Swiss franc.
  chf,

  /// Chilean peso.
  clp,

  /// Chinese yuan.
  cny,

  /// Colombian peso.
  cop,

  /// Czech koruna.
  czk,

  /// Danish krone.
  dkk,

  /// Egyptian pound.
  egp,

  /// Euro.
  eur,

  /// Pound sterling.
  gbp,

  /// Hong Kong dollar.
  hkd,

  /// Hungarian forint.
  huf,

  /// Indonesian rupiah.
  idr,

  /// Israeli shekel.
  ils,

  /// Indian rupee.
  inr,

  /// Japanese yen.
  jpy,

  /// Korean won.
  krw,

  /// Kuwaiti dinar.
  kwd,

  /// Kazakhstani tenge.
  kzt,

  /// Mexican peso.
  mxn,

  /// Malaysian ringgit.
  myr,

  /// Nigerian naira.
  ngn,

  /// Norwegian krone.
  nok,

  /// New Zealand dollar.
  nzd,

  /// Peruvian sol.
  pen,

  /// Philippine peso.
  php,

  /// Pakistani rupee.
  pkr,

  /// Polish złoty.
  pln,

  /// Qatari riyal.
  qar,

  /// Romanian leu.
  ron,

  /// Saudi riyal.
  sar,

  /// Swedish krona.
  sek,

  /// Singapore dollar.
  sgd,

  /// Thai baht.
  thb,

  /// Turkish lira.
  tryLira,

  /// New Taiwan dollar.
  twd,

  /// Tanzanian shilling.
  tzs,

  /// Ukrainian hryvnia.
  uah,

  /// US dollar.
  usd,

  /// Vietnamese dong.
  vnd,

  /// South African rand.
  zar,

  /// Any other currency.
  other;

  /// The upper-case ISO code (`USD`), or `other`.
  @override
  String get wire =>
      this == other ? 'other' : name.substring(0, 3).toUpperCase();

  /// The value for an ISO 4217 [code] in any case; [other] if unlisted.
  static AnalyticsCurrency fromCode(String code) {
    final upper = code.toUpperCase();
    for (final currency in values) {
      if (currency.wire == upper) return currency;
    }
    return other;
  }
}

/// `error` of `purchase_cancelled` / `purchase_failed`.
enum PurchaseErrorKind with AnalyticsEnum {
  /// The store reported an error.
  storeError,

  /// The Worker rejected the receipt.
  verifyRejected,

  /// Claimed by another install.
  alreadyClaimed,

  /// Purchases are blocked.
  purchasesBlocked,

  /// The product is not available.
  productUnavailable,

  /// Offline or timed out.
  network,

  /// Anything else.
  unknown;

  /// The error kind for a purchase [failure].
  static PurchaseErrorKind fromFailure(Failure failure) => switch (failure) {
    PurchaseFailure(:final wireCode)
        when wireCode == 'PURCHASE_INVALID' || wireCode == 'PRODUCT_UNKNOWN' =>
      verifyRejected,
    PurchaseFailure() => storeError,
    PurchaseAlreadyClaimedFailure() => alreadyClaimed,
    PurchasesBlockedFailure() => purchasesBlocked,
    ProductUnavailableFailure() => productUnavailable,
    NetworkFailure() || TimeoutFailure() => network,
    _ => unknown,
  };
}

/// `iap_verify_result.status`.
enum IapVerifyStatus with AnalyticsEnum {
  /// `200 granted`.
  granted,

  /// `200 already_granted` (idempotent replay).
  alreadyGranted,

  /// `202 pending` (Android).
  pending,

  /// `422 PURCHASE_INVALID` / `PRODUCT_UNKNOWN`.
  rejected,

  /// `409 PURCHASE_ALREADY_CLAIMED`.
  alreadyClaimed,

  /// Any other failure (retried).
  error,
}

/// `restore_completed.result`.
enum RestoreResult with AnalyticsEnum {
  /// Nothing to restore.
  nothing,

  /// Remove Ads restored.
  removeAds,
}

/// `remove_ads_changed.source`.
enum RemoveAdsSource with AnalyticsEnum {
  /// A purchase.
  purchase,

  /// A restore.
  restore,

  /// The launch ownership check.
  ownershipCheck,

  /// A refund or revocation.
  revoked,
}

/// `rewarded_offer_tapped.source` (RC34).
enum RewardedSource with AnalyticsEnum {
  /// From S10.
  outOfReadings,

  /// From S11.
  store,
}

/// `rewarded_ad_result.result`.
enum RewardedAdResult with AnalyticsEnum {
  /// Watched to the end.
  completed,

  /// Closed early.
  dismissed,

  /// No fill.
  noFill,

  /// The ad failed.
  error,
}

/// `rewarded_grant_result.result` (RC57).
enum RewardedGrantResult with AnalyticsEnum {
  /// Granted.
  granted,

  /// Not yet granted when polling stopped.
  delayed,

  /// Daily cap reached.
  capped,

  /// Cooldown active.
  cooldown,
}

/// `export_failed.error`.
enum ExportError with AnalyticsEnum {
  /// Writing the file failed.
  storage,

  /// The share sheet failed.
  shareFailed,

  /// Anything else.
  unknown,
}

/// `import_completed.mode`.
enum ImportMode with AnalyticsEnum {
  /// Merged into the journal.
  merge,

  /// Replaced the journal.
  replace,
}

/// `import_failed.reason`.
enum ImportFailureReason with AnalyticsEnum {
  /// Not a Taro backup.
  notTaro,

  /// Written by a newer app version.
  newerVersion,

  /// Corrupt file.
  corrupt,

  /// Too large.
  tooLarge,

  /// Local storage failed.
  storage,
}

/// `setting_changed.key`.
enum SettingKey with AnalyticsEnum {
  /// Theme.
  theme,

  /// App language.
  language,

  /// Reversed cards.
  reversals,

  /// Haptics.
  haptics,
}

/// `setting_changed.value` besides [ThemeMode] (theme) and
/// [AnalyticsLocale] (language).
enum SettingValue with AnalyticsEnum {
  /// The language follows the device.
  system,

  /// Toggle on.
  on,

  /// Toggle off.
  off,
}

/// `origin` of the app notice events.
enum AppNoticeOrigin with AnalyticsEnum {
  /// Cold start.
  launch,

  /// App resume.
  resume,

  /// The reading gate.
  readingGate,
}
