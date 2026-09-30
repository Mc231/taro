import 'dart:convert';
import 'dart:ui' show FrameTiming;

import 'package:flutter/foundation.dart';
import 'package:integration_test/integration_test.dart';

import '../support/flow_harness.dart';

/// Draw-screen frame timing baseline (02 §17; budgets in Phase 19): the S08
/// ritual (shuffle → "Draw for me" → "Reveal all" → S09) on the fake-backed
/// app, summarized by `FrameTimingSummarizer` (average / p90 / p99 / worst
/// build and raster times, missed frame budgets). Printed as
/// `PERF draw_screen {json}` and stored in `reportData` under
/// `draw_screen`.
///
/// This is `watchPerformance` without its GC counts: those need the VM
/// service, which an app started by `flutter test` on Android cannot reach.
void main() {
  taroFlow('draw screen: frame timing summary', ($) async {
    final binding = IntegrationTestWidgetsFlutterBinding.instance;
    final app = await FlowApp.launch($, fakes: flowFakes());
    await app.openQuestion();
    await app.begin();
    await app.waitForScreen(ScreenId.s08);

    // Let the engine flush the timings of earlier frames first.
    await Future<void>.delayed(const Duration(seconds: 2));
    final timings = <FrameTiming>[];
    binding.addTimingsCallback(timings.addAll);
    await app.drawAndRevealAll();
    await app.waitForScreen(ScreenId.s09);
    // The engine reports timings in batches (about once a second).
    await app.waitUntil(
      () => timings.isNotEmpty,
      timeout: const Duration(seconds: 10),
    );
    await Future<void>.delayed(const Duration(seconds: 2));
    binding.removeTimingsCallback(timings.addAll);

    final summary = FrameTimingSummarizer(timings).summary;
    binding.reportData = {...?binding.reportData, 'draw_screen': summary};
    debugPrint(
      'PERF draw_screen ${jsonEncode({
        'mode': kReleaseMode
            ? 'release'
            : kProfileMode
            ? 'profile'
            : 'debug',
        'platform': defaultTargetPlatform.name,
        ...summary,
      })}',
    );
  });
}
