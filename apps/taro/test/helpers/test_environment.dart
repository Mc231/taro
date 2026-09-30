import 'package:drift/native.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:taro/bootstrap/flavor_config.dart';
import 'package:taro/bootstrap/taro_environment.dart';
import 'package:taro/data/db/device/device_database.dart';
import 'package:taro/data/db/journal/journal_database.dart';
import 'package:taro_core/taro_core.dart';

import 'pump_app.dart';

/// Test-only control of an app booted on fakes (`TARO_ENV=test`, 06 §4):
/// the `FakeClock` and the scripted Worker behind the fakes.
final class TestControlPort {
  /// Controls [fakes].
  TestControlPort(this.fakes);

  /// The fakes behind the running app.
  final TaroFakes fakes;

  /// Moves the clock forward by [by].
  void advance(Duration by) => fakes.clock.advance(by);

  /// Jumps the clock to [instant].
  void setNow(DateTime instant) => fakes.clock.setNow(instant);

  /// Moves the device to the time zone [iana].
  void setTimeZone(String iana, {Duration utcOffset = Duration.zero}) =>
      fakes.clock.setTimeZone(iana, utcOffset: utcOffset);

  /// What `GET /v1/balance` returns from now on.
  CreditBalance get serverBalance => fakes.balance.server;
  set serverBalance(CreditBalance balance) => fakes.balance.server = balance;

  /// Makes the next balance sync fail with [failure].
  void failNextBalanceSync(Failure failure) =>
      fakes.balance.failNext(failure, on: 'sync');

  /// Makes the next time zone update fail with [failure] (e.g.
  /// `Failure.timezoneChangeRejected`).
  void failNextTimezoneUpdate(Failure failure) =>
      fakes.install.failNext(failure, on: 'updateTimezone');

  /// Switches the connectivity hint.
  void setOnline({required bool online}) =>
      fakes.connectivity.setOnline(online: online);
}

/// A [TaroEnvironment] over [TaroFakes] (RC76): `bootstrap_test.dart` and
/// the `TARO_ENV=test` integration flows boot the real composition root
/// with it. Nothing touches a platform channel.
final class FakeTaroEnvironment implements TaroEnvironment {
  /// An environment over [fakes] (fresh defaults when omitted).
  FakeTaroEnvironment({TaroFakes? fakes}) : fakes = fakes ?? TaroFakes();

  /// The fakes behind every port.
  final TaroFakes fakes;

  /// The test control port of this environment.
  late final TestControlPort control = TestControlPort(fakes);

  /// Makes the next [openDatabases] throw (S01 `storageError`).
  bool failDatabases = false;

  /// Whether [initFirebase] ran.
  bool firebaseInitialized = false;

  /// The crash reporter handed to [installErrorHandlers].
  CrashReporter? errorHandlersFor;

  /// Every widget passed to [runApp], oldest first.
  final List<Widget> mounted = [];

  /// Extra overrides appended to the fakes' ones.
  List<Override> extraOverrides = const [];

  /// The last mounted widget.
  Widget get app => mounted.last;

  @override
  FlavorConfig get flavor => fakes.flavor;

  @override
  SecureStore get secureStore => fakes.secureStore;

  @override
  Future<void> initFirebase() async => firebaseInitialized = true;

  @override
  Future<TaroDatabases> openDatabases() async {
    if (failDatabases) {
      failDatabases = false;
      throw StateError('storage unavailable');
    }
    return (
      journal: JournalDatabase(NativeDatabase.memory()),
      device: DeviceDatabase(NativeDatabase.memory()),
    );
  }

  @override
  Future<List<Override>> buildOverrides(
    FlavorConfig flavor,
    TaroDatabases dbs,
  ) async => [...fakes.toOverrides(), ...extraOverrides];

  @override
  void installErrorHandlers(CrashReporter crash) => errorHandlersFor = crash;

  @override
  void runApp(Widget app) => mounted.add(app);
}
