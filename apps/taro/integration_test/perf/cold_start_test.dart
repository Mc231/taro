import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:taro/bootstrap/bootstrap.dart';
import 'package:taro/bootstrap/flavor_config.dart';
import 'package:taro/bootstrap/taro_environment.dart';
import 'package:taro_core/taro_core.dart';

/// The real `dev` environment (drift files, Keychain / Keystore, Firebase
/// if configured, the Worker at `config/dev.json`) with two test
/// adjustments: the crash handlers stay the test framework's, and the app
/// is mounted by the tester.
final class _PerfEnvironment implements TaroEnvironment {
  _PerfEnvironment(this._real);

  final ProductionEnvironment _real;
  Widget? app;

  @override
  FlavorConfig get flavor => _real.flavor;

  @override
  SecureStore get secureStore => _real.secureStore;

  @override
  Future<void> initFirebase() => _real.initFirebase();

  @override
  Future<TaroDatabases> openDatabases() => _real.openDatabases();

  @override
  Future<List<Override>> buildOverrides(
    FlavorConfig flavor,
    TaroDatabases dbs,
  ) => _real.buildOverrides(flavor, dbs);

  @override
  void installErrorHandlers(CrashReporter crash) {}

  @override
  void runApp(Widget app) => this.app = app;
}

/// Cold-start baseline (02 §17; budgets enforced in Phase 19): one launch
/// of the `dev` composition root per process, measured from `bootstrap()`
/// to the first rasterized frame and to the first screen (S02 on a fresh
/// install, S05 once onboarded). Engine start-up before `main` is not in
/// the numbers (see the `Flutter first frame` line of the device log).
///
/// Run with `--flavor dev --dart-define-from-file=config/dev.json`; the
/// result is printed as `PERF cold_start {json}` and stored in
/// `reportData` for `flutter drive`.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('cold start: bootstrap → first frame → first screen', (
    tester,
  ) async {
    final clock = Stopwatch()..start();
    final env = _PerfEnvironment(ProductionEnvironment(Flavor.dev));
    final container = await bootstrap(env);
    expect(container, isNotNull, reason: 'bootstrap failed');
    addTearDown(container!.dispose);
    final bootstrapMs = clock.elapsedMilliseconds;

    await tester.pumpWidget(env.app!);
    await binding.waitUntilFirstFrameRasterized;
    final firstFrameMs = clock.elapsedMilliseconds;

    // The first screen past S01 (S02 on a fresh install, S05 onboarded).
    final screens = find.byWidgetPredicate((w) => w.key is ValueKey<ScreenId>);
    final first = find.byWidgetPredicate(
      (w) =>
          w.key is ValueKey<ScreenId> &&
          (w.key! as ValueKey<ScreenId>).value != ScreenId.s01,
    );
    for (var i = 0; i < 600 && !tester.any(first); i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect(
      first,
      findsOneWidget,
      reason: 'on: ${screens.evaluate().map((e) => e.widget.key).toList()}',
    );
    final firstScreenMs = clock.elapsedMilliseconds;

    final result = {
      'mode': kReleaseMode
          ? 'release'
          : kProfileMode
          ? 'profile'
          : 'debug',
      'platform': defaultTargetPlatform.name,
      'bootstrap_ms': bootstrapMs,
      'first_frame_ms': firstFrameMs,
      'first_screen_ms': firstScreenMs,
    };
    binding.reportData = {...?binding.reportData, 'cold_start': result};
    debugPrint('PERF cold_start ${jsonEncode(result)}');
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
