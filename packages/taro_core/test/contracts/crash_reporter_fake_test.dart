import 'package:test/test.dart';

import '../fakes/fakes.dart';
import 'contracts.dart';

void main() {
  runCrashReporterContract(FakeCrashReporter.new);

  test('keeps errors and breadcrumbs only while collecting', () async {
    final crash = FakeCrashReporter()..log('a');
    await crash.recordError('e', StackTrace.empty, fatal: true);
    await crash.setCollectionEnabled(enabled: false);
    crash.log('b');
    await crash.recordError('f', StackTrace.empty);
    expect(crash.breadcrumbs, ['a']);
    expect(crash.errors.single.fatal, isTrue);
  });
}
