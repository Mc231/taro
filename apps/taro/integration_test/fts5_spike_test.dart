import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:taro/data/db/fts5_probe.dart';

/// RC91 spike: FTS5 through drift + drift_flutter + sqlite3 build hooks on
/// the iOS simulator / Android emulator.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('FTS5 MATCH works in memory', (_) async {
    final result = await Fts5Probe.runInMemory();
    debugPrint('FTS5_SPIKE memory: $result');
    expect(result.fts5Available, isTrue, reason: '$result');
  });

  testWidgets('FTS5 MATCH works through driftDatabase (file)', (_) async {
    final result = await Fts5Probe.runOnDevice();
    debugPrint('FTS5_SPIKE driftDatabase: $result');
    expect(result.fts5Available, isTrue, reason: '$result');
  });
}
