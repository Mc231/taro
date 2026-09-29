import 'dart:async';
import 'dart:typed_data';

import 'package:taro_core/taro_core.dart';

import 'builders/builders.dart';
import 'fake_behaviour.dart';

/// The ads SDK. [showRewarded] waits for the test to finish the ad with
/// [completeRewarded], [dismissRewarded] or [finishRewarded], unless a
/// result is queued ([nextShow]) or [autoResult] is set.
final class FakeAdsService with FakeBehaviour implements AdsService {
  /// A fake that answers every show with [autoResult] when set.
  FakeAdsService({this.autoResult});

  @override
  String get fakeName => 'AdsService';

  /// Answer every show immediately with this result.
  RewardedShowResult? autoResult;

  /// The policy of the last [initialize].
  AdRequestPolicy? policy;

  /// [preloadRewarded] calls.
  int preloads = 0;

  /// Intents of every [showRewarded] call.
  final List<RewardIntent> shown = [];

  final List<RewardedShowResult> _scripted = [];
  Completer<Result<RewardedShowResult>>? _showing;
  bool _initialized = false;

  /// Whether an ad is on screen, waiting for the test.
  bool get isShowing => _showing != null;

  /// Queues the result of the next show.
  void nextShow(RewardedShowResult result) => _scripted.add(result);

  /// The user watched to the end (`onUserEarnedReward`).
  void completeRewarded() => finishRewarded(RewardedShowResult.earned);

  /// The user closed the ad early.
  void dismissRewarded() => finishRewarded(RewardedShowResult.dismissedEarly);

  /// Ends the ad on screen with [result].
  void finishRewarded(RewardedShowResult result) {
    final showing = _showing;
    if (showing == null) throw StateError('no rewarded ad is showing');
    _showing = null;
    showing.complete(Result.ok(result));
  }

  @override
  bool get isInitialized => _initialized;

  @override
  Future<void> initialize(AdRequestPolicy policy) async {
    record('initialize');
    this.policy = policy;
    _initialized = true;
  }

  @override
  Future<void> preloadRewarded() async {
    record('preloadRewarded');
    preloads++;
  }

  @override
  Future<Result<RewardedShowResult>> showRewarded(RewardIntent intent) {
    record('showRewarded');
    shown.add(intent);
    final failure = takeFailure('showRewarded');
    if (failure != null) return Future.value(Result.err(failure));
    if (_scripted.isNotEmpty) {
      return Future.value(Result.ok(_scripted.removeAt(0)));
    }
    final auto = autoResult;
    if (auto != null) return Future.value(Result.ok(auto));
    return (_showing = Completer()).future;
  }
}

/// Google UMP. With status `required` or `unknown`, [gather] shows the
/// form and ends in [afterForm]; otherwise it returns the current state.
final class FakeConsentService with FakeBehaviour implements ConsentService {
  /// A fake in [status] (`notRequired` by default: outside the EEA).
  FakeConsentService({
    AdsConsentStatus status = AdsConsentStatus.notRequired,
    this.afterForm = const AdsConsent(
      status: AdsConsentStatus.obtained,
      canRequestAds: true,
      privacyOptionsRequired: true,
    ),
  }) : consent = AdsConsent(
         status: status,
         canRequestAds:
             status == AdsConsentStatus.notRequired ||
             status == AdsConsentStatus.obtained,
       );

  @override
  String get fakeName => 'ConsentService';

  /// The current UMP state.
  AdsConsent consent;

  /// The state after the user answers the form.
  AdsConsent afterForm;

  /// How often the form was shown.
  int formsShown = 0;

  /// How often the privacy options form was shown.
  int privacyOptionsShown = 0;

  /// The `debugEea` flag of every [gather] call.
  final List<bool> debugEeaRequests = [];

  @override
  Future<AdsConsent> gather({bool debugEea = false}) async {
    record('gather');
    debugEeaRequests.add(debugEea);
    if (consent.status == AdsConsentStatus.required ||
        consent.status == AdsConsentStatus.unknown) {
      formsShown++;
      consent = afterForm;
    }
    return consent;
  }

  @override
  Future<void> showPrivacyOptions() async {
    record('showPrivacyOptions');
    privacyOptionsShown++;
  }

  @override
  Future<AdsConsent> current() async {
    record('current');
    return consent;
  }
}

/// ATT: the first [request] while `notDetermined` prompts and ends in
/// [answer]; later requests return the stored status.
final class FakeTrackingAuthorization
    with FakeBehaviour
    implements TrackingAuthorization {
  /// A fake in [current] that answers a prompt with [answer].
  FakeTrackingAuthorization({
    this.current = TrackingStatus.notDetermined,
    this.answer = TrackingStatus.authorized,
  });

  @override
  String get fakeName => 'TrackingAuthorization';

  /// The stored status.
  TrackingStatus current;

  /// The user's answer to the system prompt.
  TrackingStatus answer;

  /// How often the system prompt was shown.
  int prompts = 0;

  @override
  Future<TrackingStatus> status() async {
    record('status');
    return current;
  }

  @override
  Future<TrackingStatus> request() async {
    record('request');
    if (current == TrackingStatus.notDetermined) {
      prompts++;
      current = answer;
    }
    return current;
  }
}

/// Product analytics: events are kept in [events] while collection is on
/// and in [dropped] while it is off.
final class FakeAnalyticsService
    with FakeBehaviour
    implements AnalyticsService {
  @override
  String get fakeName => 'AnalyticsService';

  /// Delivered events, oldest first.
  final List<TaroAnalyticsEvent> events = [];

  /// Events logged while collection was off.
  final List<TaroAnalyticsEvent> dropped = [];

  /// Delivered screen views.
  final List<String> screens = [];

  /// Every consent-mode setting, oldest first.
  final List<AnalyticsConsent> consents = [];

  /// Whether collection is on.
  bool collectionEnabled = true;

  /// The names of [events].
  List<String> get eventNames => [for (final e in events) e.eventName];

  @override
  Future<void> log(TaroAnalyticsEvent event) async {
    record('log');
    (collectionEnabled ? events : dropped).add(event);
  }

  @override
  Future<void> screen(String screenId) async {
    record('screen');
    if (collectionEnabled) screens.add(screenId);
  }

  @override
  Future<void> setCollectionEnabled({required bool enabled}) async {
    record('setCollectionEnabled');
    collectionEnabled = enabled;
  }

  @override
  Future<void> setConsent(AnalyticsConsent consent) async {
    record('setConsent');
    consents.add(consent);
  }
}

/// One [FakeCrashReporter.recordError] call.
typedef CrashRecord = ({
  Object error,
  StackTrace stack,
  bool fatal,
  Map<String, Object> context,
});

/// Crash reporting; nothing is kept while collection is off.
final class FakeCrashReporter with FakeBehaviour implements CrashReporter {
  @override
  String get fakeName => 'CrashReporter';

  /// Recorded errors.
  final List<CrashRecord> errors = [];

  /// Breadcrumbs.
  final List<String> breadcrumbs = [];

  /// Whether collection is on.
  bool collectionEnabled = true;

  @override
  Future<void> recordError(
    Object error,
    StackTrace stack, {
    bool fatal = false,
    Map<String, Object> context = const {},
  }) async {
    record('recordError');
    if (collectionEnabled) {
      errors.add((error: error, stack: stack, fatal: fatal, context: context));
    }
  }

  @override
  void log(String breadcrumb) {
    record('log');
    if (collectionEnabled) breadcrumbs.add(breadcrumb);
  }

  @override
  Future<void> setCollectionEnabled({required bool enabled}) async {
    record('setCollectionEnabled');
    collectionEnabled = enabled;
  }
}

/// Local reminders: [scheduled] is the one pending daily reminder.
final class FakeReminderScheduler
    with FakeBehaviour
    implements ReminderScheduler {
  /// A fake whose permission prompt answers [permission].
  FakeReminderScheduler({this.permission = true});

  @override
  String get fakeName => 'ReminderScheduler';

  /// The answer to [requestPermission].
  bool permission;

  /// The scheduled reminder and its locale, if any.
  (ReminderSettings, String)? scheduled;

  /// How often permission was requested.
  int permissionRequests = 0;

  final StreamController<String> _taps = StreamController.broadcast();

  /// The user taps a notification opening [route].
  void tap(String route) => _taps.add(route);

  @override
  Future<void> schedule(ReminderSettings settings, String locale) async {
    record('schedule');
    scheduled = settings.enabled ? (settings, locale) : null;
  }

  @override
  Future<void> cancelAll() async {
    record('cancelAll');
    scheduled = null;
  }

  @override
  Future<bool> requestPermission() async {
    record('requestPermission');
    permissionRequests++;
    return permission;
  }

  @override
  Stream<String> get taps => _taps.stream;
}

/// Platform attestation of kind [kind] (`none` = unsupported device).
final class FakeAttestationService
    with FakeBehaviour
    implements AttestationService {
  /// A fake attesting with [kind].
  FakeAttestationService([this.kind = AttestationType.appAttest]);

  @override
  String get fakeName => 'AttestationService';

  /// The attestation kind.
  final AttestationType kind;

  /// Challenges passed to [attest].
  final List<String> challenges = [];

  /// `(installId, signal)` of every [attest] call.
  final List<(String, DeviceSignal)> attestedInstalls = [];

  /// Client data hashes passed to [assert_].
  final List<List<int>> assertions = [];

  /// Key IDs passed to [assert_], in order.
  final List<String?> assertionKeyIds = [];

  @override
  bool get isSupported => kind != AttestationType.none;

  @override
  Future<Result<AttestationBlob>> attest({
    required String challenge,
    required String installId,
    required DeviceSignal signal,
  }) async {
    record('attest');
    challenges.add(challenge);
    attestedInstalls.add((installId, signal));
    final failure = takeFailure('attest');
    if (failure != null) return Result.err(failure);
    return Result.ok(
      AttestationBlob(
        type: kind,
        challenge: challenge,
        payload: isSupported ? 'attestation-${challenges.length}' : null,
        keyId: kind == AttestationType.appAttest
            ? 'key-${challenges.length}'
            : null,
      ),
    );
  }

  @override
  Future<Result<AssertionBlob>> assert_({
    required List<int> clientDataHash,
    String? keyId,
  }) async {
    record('assert');
    assertions.add(clientDataHash);
    assertionKeyIds.add(keyId);
    final failure = takeFailure('assert');
    if (failure != null) return Result.err(failure);
    final n = assertions.length;
    return Result.ok(
      AssertionBlob(
        header: switch (kind) {
          AttestationType.appAttest => 'aa1.assertion-$n',
          AttestationType.playIntegrity => 'pi1.token-$n',
          AttestationType.none => 'none',
        },
      ),
    );
  }

  @override
  Future<DeviceSignal> deviceSignal() async {
    record('deviceSignal');
    return switch (kind) {
      AttestationType.appAttest => const DeviceSignal(
        deviceCheckToken: 'devicecheck-token',
      ),
      AttestationType.playIntegrity => const DeviceSignal(
        deviceKey: 'device-key',
      ),
      AttestationType.none => const DeviceSignal(),
    };
  }
}

/// One shared file.
typedef SharedFile = ({Uint8List bytes, String fileName, String mime});

/// Share sheet and file picker: [shared] keeps shared files; [pickJson]
/// returns the queued picks ([willPick]) and cancels when none is queued.
final class FakeFileTransfer with FakeBehaviour implements FileTransfer {
  @override
  String get fakeName => 'FileTransfer';

  /// Every shared file.
  final List<SharedFile> shared = [];

  final List<Uint8List?> _picks = [];

  /// The user picks a file with [bytes] (`null` = cancels).
  void willPick(Uint8List? bytes) => _picks.add(bytes);

  @override
  Future<Result<void>> share(
    Uint8List bytes,
    String fileName,
    String mime,
  ) async {
    record('share');
    final failure = takeFailure('share');
    if (failure != null) return Result.err(failure);
    shared.add((bytes: bytes, fileName: fileName, mime: mime));
    return const Result.ok(null);
  }

  @override
  Future<Result<Uint8List?>> pickJson() async {
    record('pickJson');
    final failure = takeFailure('pickJson');
    if (failure != null) return Result.err(failure);
    return Result.ok(_picks.isEmpty ? null : _picks.removeAt(0));
  }
}

/// A connectivity hint; [setOnline] emits only on a change.
final class FakeConnectivityMonitor
    with FakeBehaviour
    implements ConnectivityMonitor {
  /// A monitor starting [online].
  FakeConnectivityMonitor({bool online = true}) : _online = online;

  @override
  String get fakeName => 'ConnectivityMonitor';

  bool _online;
  final StreamController<bool> _changes = StreamController.broadcast();

  /// Changes the hint.
  void setOnline({required bool online}) {
    if (online == _online) return;
    _online = online;
    _changes.add(online);
  }

  @override
  Stream<bool> get online => _changes.stream;

  @override
  Future<bool> isOnline() async {
    record('isOnline');
    return _online;
  }
}

/// The in-app review prompt; records every trigger.
final class FakeReviewPrompter with FakeBehaviour implements ReviewPrompter {
  @override
  String get fakeName => 'ReviewPrompter';

  /// Every trigger, oldest first.
  final List<ReviewTrigger> triggers = [];

  @override
  Future<void> maybePrompt(ReviewTrigger trigger) async {
    record('maybePrompt');
    triggers.add(trigger);
  }
}

/// OS-backup exclusion: [excluded] keeps every path passed, in order.
final class FakeBackupExclusion with FakeBehaviour implements BackupExclusion {
  @override
  String get fakeName => 'BackupExclusion';

  /// Every excluded path, oldest first (duplicates kept).
  final List<String> excluded = [];

  @override
  Future<Result<void>> exclude(List<String> paths) async {
    record('exclude');
    final failure = takeFailure('exclude');
    if (failure != null) return Result.err(failure);
    excluded.addAll(paths);
    return const Result.ok(null);
  }
}

/// Static app facts.
final class FakeAppInfo implements AppInfo {
  /// Facts with test defaults.
  const FakeAppInfo({
    this.version = kTestAppVersion,
    this.buildNumber = kTestBuildNumber,
    this.platform = AppPlatform.ios,
    this.osVersion = '18.0',
    this.deviceModelClass = 'phone',
  });

  @override
  final String version;

  @override
  final String buildNumber;

  @override
  final AppPlatform platform;

  @override
  final String osVersion;

  @override
  final String deviceModelClass;
}

/// Bundled content: the full deck, the six spreads, placeholder `en` card
/// text for every card (other locales fall back to `en`) and crisis
/// resources.
final class FakeContentRepository
    with FakeBehaviour
    implements ContentRepository {
  /// Content with test defaults.
  FakeContentRepository({
    Deck? deck,
    List<SpreadDefinition>? spreads,
    Map<(CardId, String), CardText>? texts,
    List<CrisisResource>? crisisResources,
  }) : bundledDeck = deck ?? aDeck().build(),
       bundledSpreads = spreads ?? allSpreads(),
       texts =
           texts ??
           {for (final id in kCardIds) (id, kTestLocale): aCardText(id)},
       crisisResources = crisisResources ?? [aCrisisResource()];

  @override
  String get fakeName => 'ContentRepository';

  /// The deck.
  Deck bundledDeck;

  /// The spreads.
  List<SpreadDefinition> bundledSpreads;

  /// Card text by `(cardId, locale)`.
  final Map<(CardId, String), CardText> texts;

  /// The bundled crisis resources.
  List<CrisisResource> crisisResources;

  @override
  Future<Result<Deck>> deck() async {
    record('deck');
    final failure = takeFailure('deck');
    if (failure != null) return Result.err(failure);
    return Result.ok(bundledDeck);
  }

  @override
  Future<Result<List<SpreadDefinition>>> spreads() async {
    record('spreads');
    final failure = takeFailure('spreads');
    if (failure != null) return Result.err(failure);
    return Result.ok(bundledSpreads);
  }

  @override
  Future<Result<CardText>> cardText(CardId cardId, String locale) async {
    record('cardText');
    final failure = takeFailure('cardText');
    if (failure != null) return Result.err(failure);
    final text = texts[(cardId, locale)] ?? texts[(cardId, kTestLocale)];
    return text == null ? const Result.err(Failure.storage()) : Result.ok(text);
  }

  @override
  Future<Result<List<CrisisResource>>> fallbackCrisisResources(
    String region,
  ) async {
    record('fallbackCrisisResources');
    final failure = takeFailure('fallbackCrisisResources');
    if (failure != null) return Result.err(failure);
    return Result.ok(crisisResources);
  }
}

/// The bundled crisis directory (`aCrisisDirectory()` by default).
final class FakeCrisisResourcesRepository
    with FakeBehaviour
    implements CrisisResourcesRepository {
  /// A repository over [directory].
  FakeCrisisResourcesRepository([CrisisDirectory? directory])
    : bundled = directory ?? aCrisisDirectory();

  @override
  String get fakeName => 'CrisisResourcesRepository';

  /// The directory.
  final CrisisDirectory bundled;

  @override
  Future<Result<CrisisDirectory>> directory() async {
    record('directory');
    final failure = takeFailure('directory');
    if (failure != null) return Result.err(failure);
    return Result.ok(bundled);
  }

  @override
  Future<Result<List<CrisisResource>>> select({
    String? country,
    String? locale,
  }) async {
    record('select');
    final failure = takeFailure('select');
    if (failure != null) return Result.err(failure);
    return Result.ok(bundled.select(country: country, locale: locale));
  }
}
