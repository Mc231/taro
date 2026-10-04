import 'dart:async';

import 'package:taro_core/taro_core.dart';

import 'builders/builders.dart';
import 'fake_behaviour.dart';
import 'fake_clock.dart';
import 'journal_fakes.dart';

/// A [BalanceRepository] with a scripted Worker balance.
///
/// [sync] returns [server] (applied under RC67) unless a failure is
/// queued; concurrent syncs share one request ([requests] counts them).
/// [pauseSync] holds requests open until [resumeSync].
final class FakeBalanceRepository
    with FakeBehaviour
    implements BalanceRepository {
  /// A repository with [cached] on disk and [server] on the Worker
  /// (`aCreditBalance().build()` by default).
  FakeBalanceRepository({CreditBalance? cached, CreditBalance? server})
    : _cached = cached,
      server = server ?? aCreditBalance().build();

  @override
  String get fakeName => 'BalanceRepository';

  CreditBalance? _cached;
  final ChangeSignal _changes = ChangeSignal();
  Future<Result<CreditBalance>>? _inFlight;
  Completer<void>? _gate;

  /// What `GET /v1/balance` returns.
  CreditBalance server;

  /// Actual Worker requests (shared calls count once).
  int requests = 0;

  /// The reason of every [sync] call.
  final List<SyncReason> syncReasons = [];

  /// Every balance passed to [apply].
  final List<CreditBalance> applied = [];

  @override
  CreditBalance? get cached => _cached;

  /// Replaces the cache without recording a call.
  void seed(CreditBalance? balance) {
    _cached = balance;
    _changes.notify();
  }

  /// Holds new sync requests open until [resumeSync].
  void pauseSync() => _gate = Completer<void>();

  /// Releases held sync requests.
  void resumeSync() {
    _gate?.complete();
    _gate = null;
  }

  @override
  Stream<CreditBalance?> watch() => watchValue(() => _cached, _changes.stream);

  @override
  Future<Result<CreditBalance>> sync({required SyncReason reason}) {
    record('sync');
    syncReasons.add(reason);
    return _inFlight ??= _request().whenComplete(() => _inFlight = null);
  }

  Future<Result<CreditBalance>> _request() async {
    await _gate?.future;
    requests++;
    final failure = takeFailure('sync');
    if (failure != null) return Result.err(failure);
    return Result.ok(_apply(server));
  }

  @override
  Future<CreditBalance> apply(CreditBalance balance) async {
    record('apply');
    applied.add(balance);
    return _apply(balance);
  }

  CreditBalance _apply(CreditBalance balance) {
    final current = _cached;
    if (current == null || balance.shouldReplace(current)) {
      _cached = balance;
      _changes.notify();
    }
    return _cached!;
  }
}

/// An [InstallRepository] with an in-memory identity and a scripted
/// Worker. By default the install is registered (`anInstallIdentity()`);
/// [FakeInstallRepository.firstLaunch] starts with nothing stored.
final class FakeInstallRepository
    with FakeBehaviour
    implements InstallRepository {
  /// A repository holding [identity].
  FakeInstallRepository({InstallIdentity? identity, this.timezoneBalance})
    : identity = identity ?? anInstallIdentity();

  /// A fresh install: no identity yet.
  FakeInstallRepository.firstLaunch({this.timezoneBalance}) : identity = null;

  @override
  String get fakeName => 'InstallRepository';

  /// The stored identity.
  InstallIdentity? identity;

  /// The balance `PUT /v1/installs/me/timezone` returns (its
  /// `free.timezone` is replaced by the new zone).
  CreditBalance? timezoneBalance;

  /// Zones passed to [updateTimezone].
  final List<String> timezoneUpdates = [];

  @override
  Future<Result<InstallIdentity>> getOrCreate() async {
    record('getOrCreate');
    final failure = takeFailure('getOrCreate');
    if (failure != null) return Result.err(failure);
    return Result.ok(
      identity ??= const InstallIdentity(installId: kTestInstallId),
    );
  }

  @override
  Future<Result<InstallIdentity>> ensureRegistered() async {
    record('ensureRegistered');
    final failure = takeFailure('ensureRegistered');
    if (failure != null) return Result.err(failure);
    final current = identity ??= const InstallIdentity(
      installId: kTestInstallId,
    );
    if (!current.isRegistered) {
      identity = anInstallIdentity().copyWith(installId: current.installId);
    }
    return Result.ok(identity!);
  }

  /// The identity [repairRegistration] stores (default: the current one,
  /// registered).
  InstallIdentity? repairedIdentity;

  @override
  Future<Result<InstallIdentity>> repairRegistration() async {
    record('repairRegistration');
    final failure = takeFailure('repairRegistration');
    if (failure != null) return Result.err(failure);
    identity =
        repairedIdentity ??
        anInstallIdentity().copyWith(
          installId: identity?.installId ?? kTestInstallId,
        );
    return Result.ok(identity!);
  }

  @override
  Future<Result<void>> refreshToken() async {
    record('refreshToken');
    final failure = takeFailure('refreshToken');
    if (failure != null) return Result.err(failure);
    return const Result.ok(null);
  }

  @override
  Future<Result<CreditBalance>> updateTimezone(String iana) async {
    record('updateTimezone');
    timezoneUpdates.add(iana);
    final failure = takeFailure('updateTimezone');
    if (failure != null) return Result.err(failure);
    identity = identity?.copyWith(registeredTimezone: iana);
    final base = timezoneBalance ?? aCreditBalance().build();
    return Result.ok(
      base.copyWith(
        free: base.free.copyWith(timezone: iana),
        ledgerVersion: base.ledgerVersion + 1,
      ),
    );
  }
}

/// A [ReadingRepository] over an [InMemoryJournal] with a scripted Worker.
///
/// * [hold] reserves [holdSource] for [holdTtl] (server time), with
///   [holdBalance] (else the balance repository's cache, else a default).
/// * [submit] stores the reading as `pending` first, then applies the next
///   scripted outcome ([refuseNext], [completeNextWith]; default
///   `complete` with `aReadingContent`). A queued failure leaves it
///   `pending`, except `AiUnavailableFailure` and
///   `ReadingExpiredRefundedFailure`, which store `failed(refunded)`.
/// * A failed [ack] is queued in [pendingAcks] for [flushPendingAcks].
final class FakeReadingRepository
    with FakeBehaviour
    implements ReadingRepository {
  /// A repository over [journal].
  FakeReadingRepository({
    InMemoryJournal? journal,
    FakeClock? clock,
    this.balance,
  }) : journal = journal ?? InMemoryJournal(),
       clock = clock ?? FakeClock();

  @override
  String get fakeName => 'ReadingRepository';

  /// The backing store.
  final InMemoryJournal journal;

  /// The device clock.
  final FakeClock clock;

  /// The balance repository whose cache seeds [hold] balances.
  final FakeBalanceRepository? balance;

  /// How long a hold lasts (03 §9.0 `holdTtlSec`).
  Duration holdTtl = const Duration(minutes: 10);

  /// The bucket a hold reserves; `null` = the balance's `nextSource`.
  ChargeSource? holdSource;

  /// The balance returned with a hold; `null` = see class doc.
  CreditBalance? holdBalance;

  /// Every hold taken: `(readingId, spreadId, locale)`.
  final List<(ReadingId, SpreadId, String)> holds = [];

  /// Readings passed to [submit], as passed.
  final List<Reading> submitted = [];

  /// IDs whose delivery ack reached the Worker.
  final List<ReadingId> acked = [];

  /// IDs whose ack is queued (`pending_acks`).
  final List<ReadingId> pendingAcks = [];

  final List<Reading Function(Reading pending)> _outcomes = [];
  final List<Failure> _workerFailures = [];

  /// Makes the next Worker call ([hold], [submit], [resume], [ack],
  /// [flushPendingAcks]) fail with [failure]; local calls are unaffected.
  void failNextWorkerCall(Failure failure) => _workerFailures.add(failure);

  Failure? _takeWorkerFailure(String method) => _workerFailures.isNotEmpty
      ? _workerFailures.removeAt(0)
      : takeFailure(method);

  /// The next delivery is declined with [safety].
  void refuseNext({SafetyInfo? safety}) => _outcomes.add(
    (p) => p.copyWith(
      status: ReadingStatus.refused(safety: safety),
      content: null,
    ),
  );

  /// The next delivery completes with [content].
  void completeNextWith(ReadingContent content) => _outcomes.add(
    (p) => p.copyWith(status: const ReadingStatus.complete(), content: content),
  );

  /// The next delivery is left `pending` (still generating).
  void stayPendingNext() => _outcomes.add((p) => p);

  static Reading _complete(Reading p) => p.copyWith(
    status: const ReadingStatus.complete(),
    content: aReadingContent(draw: p.draw),
    promptVersion: 'v1',
    modelId: 'fake-model',
  );

  Reading _deliver(Reading pending) {
    final outcome = _outcomes.isEmpty ? _complete : _outcomes.removeAt(0);
    final delivered = outcome(pending).copyWith(updatedAt: clock.now());
    journal.putReading(delivered);
    return delivered;
  }

  @override
  Future<Result<ReadingHold>> hold(
    ReadingId readingId,
    SpreadDefinition spread, {
    required String locale,
  }) async {
    record('hold');
    holds.add((readingId, spread.id, locale));
    final failure = _takeWorkerFailure('hold');
    if (failure != null) return Result.err(failure);
    final b = holdBalance ?? balance?.cached ?? aCreditBalance().build();
    final serverNow = b.serverTime.add(clock.now().difference(b.syncedAt));
    return Result.ok(
      ReadingHold(
        readingId: readingId,
        chargeSource: holdSource ?? b.nextSource ?? ChargeSource.free,
        expiresAt: serverNow.add(holdTtl),
        balance: b,
      ),
    );
  }

  @override
  Future<Result<Reading>> submit(Reading pending) async {
    record('submit');
    submitted.add(pending);
    final stored = pending.copyWith(
      status: const ReadingStatus.pending(),
      deliveryAcked: false,
    );
    journal.putReading(stored);
    final failure = _takeWorkerFailure('submit');
    if (failure != null) {
      if (failure is AiUnavailableFailure ||
          failure is ReadingExpiredRefundedFailure) {
        journal.putReading(
          stored.copyWith(
            status: ReadingStatus.failed(failure, refunded: true),
            updatedAt: clock.now(),
          ),
        );
      }
      return Result.err(failure);
    }
    return Result.ok(_deliver(stored));
  }

  @override
  Future<Result<Reading>> resume(ReadingId id) async {
    record('resume');
    final failure = _takeWorkerFailure('resume');
    if (failure != null) return Result.err(failure);
    final stored = journal.readings[id];
    if (stored == null) {
      return const Result.err(Failure.contract(wireCode: 'NOT_FOUND'));
    }
    return Result.ok(
      stored.status is ReadingStatusPending ? _deliver(stored) : stored,
    );
  }

  @override
  Future<Result<void>> ack(ReadingId id) async {
    record('ack');
    final failure = _takeWorkerFailure('ack');
    if (failure != null) {
      if (!pendingAcks.contains(id)) pendingAcks.add(id);
      return Result.err(failure);
    }
    _markAcked(id);
    return const Result.ok(null);
  }

  void _markAcked(ReadingId id) {
    acked.add(id);
    final stored = journal.readings[id];
    if (stored != null) {
      journal.putReading(stored.copyWith(deliveryAcked: true));
    }
  }

  @override
  Future<Result<int>> flushPendingAcks() async {
    record('flushPendingAcks');
    final failure = _takeWorkerFailure('flushPendingAcks');
    if (failure != null) return Result.err(failure);
    final count = pendingAcks.length;
    pendingAcks
      ..forEach(_markAcked)
      ..clear();
    return Result.ok(count);
  }

  @override
  Future<Result<Reading>> saveClassic(Reading reading) async {
    record('saveClassic');
    final failure = takeFailure('saveClassic');
    if (failure != null) return Result.err(failure);
    journal.putReading(reading);
    return Result.ok(reading);
  }

  @override
  Future<Result<Reading?>> get(ReadingId id) async {
    record('get');
    final failure = takeFailure('get');
    if (failure != null) return Result.err(failure);
    return Result.ok(journal.readings[id]);
  }

  @override
  Future<Result<List<Reading>>> pending() async {
    record('pending');
    final failure = takeFailure('pending');
    if (failure != null) return Result.err(failure);
    return Result.ok([
      for (final r in journal.readings.values)
        if (r.status is ReadingStatusPending) r,
    ]);
  }

  @override
  Stream<Reading?> watch(ReadingId id) =>
      watchValue(() => journal.readings[id], journal.changes);

  Future<Result<void>> _change(
    String method,
    ReadingId id,
    Reading Function(Reading r) change,
  ) async {
    record(method);
    final failure = takeFailure(method);
    if (failure != null) return Result.err(failure);
    final stored = journal.readings[id];
    if (stored != null) {
      journal.putReading(change(stored).copyWith(updatedAt: clock.now()));
    }
    return const Result.ok(null);
  }

  @override
  Future<Result<void>> setNote(ReadingId id, String? note) =>
      _change('setNote', id, (r) => r.copyWith(note: note));

  @override
  Future<Result<void>> setFavourite(ReadingId id, {required bool favourite}) =>
      _change('setFavourite', id, (r) => r.copyWith(favourite: favourite));

  @override
  Future<Result<void>> setRating(
    ReadingId id,
    Rating? rating, {
    RatingReason? reason,
  }) => _change(
    'setRating',
    id,
    (r) => r.copyWith(rating: rating, ratingReason: reason),
  );

  @override
  Future<Result<void>> markReported(ReadingId id) =>
      _change('markReported', id, (r) => r.copyWith(reported: true));

  @override
  Future<Result<void>> delete(ReadingId id) async {
    record('delete');
    final failure = takeFailure('delete');
    if (failure != null) return Result.err(failure);
    final removed = journal.readings.remove(id);
    if (removed != null) _trash[id] = (reading: removed, at: clock.now());
    journal.notify();
    return const Result.ok(null);
  }

  /// Readings deleted recently enough for [undoDelete], by ID.
  final Map<ReadingId, ({Reading reading, DateTime at})> _trash = {};

  @override
  Future<Result<bool>> undoDelete(ReadingId id) async {
    record('undoDelete');
    final failure = takeFailure('undoDelete');
    if (failure != null) return Result.err(failure);
    final deleted = _trash.remove(id);
    if (deleted == null ||
        clock.now().difference(deleted.at) >= ReadingRepository.undoWindow) {
      return const Result.ok(false);
    }
    journal.putReading(deleted.reading);
    return const Result.ok(true);
  }
}

/// A [RemoteConfigRepository]: [refresh] returns [server], or keeps
/// [current] when [server] is `null` (`304 Not Modified`).
final class FakeRemoteConfigRepository
    with FakeBehaviour
    implements RemoteConfigRepository {
  /// A repository whose current config is [initial].
  FakeRemoteConfigRepository([RemoteConfig initial = RemoteConfig.defaults])
    : _current = initial;

  @override
  String get fakeName => 'RemoteConfigRepository';

  RemoteConfig _current;
  final ChangeSignal _changes = ChangeSignal();

  /// What the next [refresh] fetches; `null` = not modified.
  RemoteConfig? server;

  @override
  RemoteConfig get current => _current;

  /// Replaces the current config without recording a call.
  set current(RemoteConfig config) {
    _current = config;
    _changes.notify();
  }

  @override
  Stream<RemoteConfig> watch() => watchValue(() => _current, _changes.stream);

  @override
  Future<Result<RemoteConfig>> refresh() async {
    record('refresh');
    final failure = takeFailure('refresh');
    if (failure != null) return Result.err(failure);
    final fetched = server;
    if (fetched != null) current = fetched;
    return Result.ok(_current);
  }
}

/// A [PurchaseVerifier] that behaves like the Worker's
/// `POST /v1/purchases/verify`: a consumable is granted once per `txnKey`
/// ([kTestPackCredits]); a replay is `alreadyGranted`; a non-consumable or
/// unknown product is `PRODUCT_UNKNOWN`; [rejected] keys are
/// `PURCHASE_INVALID`. Every grant bumps the balance's `paid` and
/// `ledgerVersion`.
final class FakePurchaseVerifier
    with FakeBehaviour
    implements PurchaseVerifier {
  /// A verifier granting on top of [balance].
  FakePurchaseVerifier({CreditBalance? balance})
    : _balance = balance ?? aCreditBalance().build();

  @override
  String get fakeName => 'PurchaseVerifier';

  CreditBalance _balance;

  /// Every call: `(purchase, idempotencyKey)`.
  final List<(StorePurchase, String)> verifications = [];

  /// The `transferToken` of every call, in order (`null` = none, RC84).
  final List<String?> transferTokens = [];

  /// `txnKey`s already granted.
  final Set<String> granted = {};

  /// `txnKey`s the Worker rejects.
  final Set<String> rejected = {};

  /// Scripted results, used before the default behaviour.
  final List<GrantResult> scripted = [];

  /// Called at the start of every [verify] (for ordering checks).
  void Function(StorePurchase purchase, String idempotencyKey)? onVerify;

  @override
  Future<Result<GrantResult>> verify(
    StorePurchase purchase, {
    required String idempotencyKey,
    String? transferToken,
  }) async {
    record('verify');
    verifications.add((purchase, idempotencyKey));
    transferTokens.add(transferToken);
    onVerify?.call(purchase, idempotencyKey);
    final failure = takeFailure('verify');
    if (failure != null) return Result.err(failure);
    if (scripted.isNotEmpty) return Result.ok(scripted.removeAt(0));
    if (rejected.contains(purchase.txnKey)) {
      return const Result.err(Failure.purchase(wireCode: 'PURCHASE_INVALID'));
    }
    final credits = kTestPackCredits[purchase.productId];
    if (credits == null) {
      return const Result.err(Failure.purchase(wireCode: 'PRODUCT_UNKNOWN'));
    }
    if (granted.contains(purchase.txnKey)) {
      return Result.ok(
        GrantResult(
          status: GrantStatus.alreadyGranted,
          productId: purchase.productId,
          balance: _balance,
        ),
      );
    }
    final first = granted.isEmpty;
    granted.add(purchase.txnKey);
    _balance = _balance.copyWith(
      paid: _balance.paid + credits,
      ledgerVersion: _balance.ledgerVersion + 1,
      canRead: true,
      canReadReason: null,
      nextSource: _balance.nextSource ?? ChargeSource.paid,
    );
    return Result.ok(
      GrantResult(
        status: GrantStatus.granted,
        creditsGranted: credits,
        isFirstPurchase: first,
        purchaseId: 'purchase-${granted.length}',
        productId: purchase.productId,
        balance: _balance,
      ),
    );
  }
}

/// A [RewardGateway] that behaves like the Worker's reward intents.
///
/// Intents start `issued`; the SSV callback is simulated with [grant]
/// (or [autoGrant]), [reject] and [expire]. [scriptStatuses] overrides
/// what [status] returns for one intent (the last entry repeats).
final class FakeRewardGateway with FakeBehaviour implements RewardGateway {
  /// A gateway granting [amount] per view with [grantBalance].
  FakeRewardGateway({
    FakeClock? clock,
    this.amount = 1,
    this.grantBalance,
    this.autoGrant = false,
  }) : clock = clock ?? FakeClock();

  @override
  String get fakeName => 'RewardGateway';

  /// The clock for `expiresAt`.
  final FakeClock clock;

  /// Bonus readings per verified view.
  final int amount;

  /// The balance a granted status carries.
  CreditBalance? grantBalance;

  /// Grant an issued intent on its first [status] poll.
  bool autoGrant;

  /// Intent states by ID.
  final Map<IntentId, RewardIntentState> states = {};

  /// Ad unit IDs of every [createIntent] call.
  final List<String> adUnitIds = [];

  /// Intents passed to [cancel].
  final List<IntentId> cancelled = [];

  final Map<IntentId, List<RewardStatus>> _scripts = {};

  /// Simulates a verified SSV callback for [id].
  void grant(IntentId id, {CreditBalance? balance}) {
    states[id] = RewardIntentState.granted;
    if (balance != null) grantBalance = balance;
  }

  /// Simulates a rejected SSV callback for [id].
  void reject(IntentId id) => states[id] = RewardIntentState.rejected;

  /// Lets [id] lapse.
  void expire(IntentId id) => states[id] = RewardIntentState.expired;

  /// [status] of [id] returns [statuses] in order, repeating the last.
  void scriptStatuses(IntentId id, List<RewardStatus> statuses) =>
      _scripts[id] = [...statuses];

  @override
  Future<Result<RewardIntent>> createIntent(String adUnitId) async {
    record('createIntent');
    adUnitIds.add(adUnitId);
    final failure = takeFailure('createIntent');
    if (failure != null) return Result.err(failure);
    final id = IntentId('intent-${states.length + 1}');
    states[id] = RewardIntentState.issued;
    return Result.ok(
      RewardIntent(
        intentId: id,
        amount: amount,
        expiresAt: clock.now().add(const Duration(minutes: 15)),
      ),
    );
  }

  @override
  Future<Result<RewardStatus>> status(IntentId intentId) async {
    record('status');
    final failure = takeFailure('status');
    if (failure != null) return Result.err(failure);
    final script = _scripts[intentId];
    if (script != null && script.isNotEmpty) {
      return Result.ok(script.length == 1 ? script.first : script.removeAt(0));
    }
    final state = states[intentId];
    if (state == null) {
      return const Result.err(Failure.contract(wireCode: 'NOT_FOUND'));
    }
    if (state == RewardIntentState.issued && autoGrant) grant(intentId);
    final now = states[intentId]!;
    return Result.ok(
      RewardStatus(
        state: now,
        amount: amount,
        balance: now == RewardIntentState.granted ? grantBalance : null,
      ),
    );
  }

  @override
  Future<void> cancel(IntentId intentId) async {
    record('cancel');
    cancelled.add(intentId);
    if (states[intentId] == RewardIntentState.issued) {
      states[intentId] = RewardIntentState.cancelled;
    }
  }
}

/// A [ReportGateway] that behaves like `POST /v1/readings/{id}/report`: a
/// repeat for the same reading succeeds without counting, and more than
/// [dailyLimit] reports fail with `RateLimitedFailure(reportLimit)`.
final class FakeReportGateway with FakeBehaviour implements ReportGateway {
  /// A gateway allowing [dailyLimit] reports.
  FakeReportGateway({this.dailyLimit = 10});

  @override
  String get fakeName => 'ReportGateway';

  /// Reports per local day (RC72).
  final int dailyLimit;

  /// Stored reports by reading.
  final Map<ReadingId, ReadingReport> reports = {};

  @override
  Future<Result<void>> submit(ReadingReport report) async {
    record('submit');
    final failure = takeFailure('submit');
    if (failure != null) return Result.err(failure);
    if (reports.containsKey(report.readingId)) return const Result.ok(null);
    if (reports.length >= dailyLimit) {
      return const Result.err(
        Failure.rateLimited(reason: RateLimitReason.reportLimit),
      );
    }
    reports[report.readingId] = report;
    return const Result.ok(null);
  }
}

/// A [DataDeletionGateway] with an in-memory retry queue.
final class FakeDataDeletionGateway
    with FakeBehaviour
    implements DataDeletionGateway {
  @override
  String get fakeName => 'DataDeletionGateway';

  /// The queued idempotency key.
  String? queuedKey;

  /// Keys of every successful erasure.
  final List<String> erased = [];

  @override
  Future<Result<void>> eraseServerData({required String idempotencyKey}) async {
    record('eraseServerData');
    final failure = takeFailure('eraseServerData');
    if (failure != null) return Result.err(failure);
    erased.add(idempotencyKey);
    return const Result.ok(null);
  }

  @override
  Future<Result<void>> queue({required String idempotencyKey}) async {
    record('queue');
    final failure = takeFailure('queue');
    if (failure != null) return Result.err(failure);
    queuedKey = idempotencyKey;
    return const Result.ok(null);
  }

  @override
  Future<Result<String?>> queued() async {
    record('queued');
    final failure = takeFailure('queued');
    if (failure != null) return Result.err(failure);
    return Result.ok(queuedKey);
  }

  @override
  Future<Result<void>> clearQueue() async {
    record('clearQueue');
    final failure = takeFailure('clearQueue');
    if (failure != null) return Result.err(failure);
    queuedKey = null;
    return const Result.ok(null);
  }
}
