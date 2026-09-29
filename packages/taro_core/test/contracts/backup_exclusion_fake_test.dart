import 'package:taro_core/taro_core.dart';
import 'package:test/test.dart';

import '../fakes/fakes.dart';
import 'contracts.dart';

void main() {
  runBackupExclusionContract(FakeBackupExclusion.new);
  runBackupExclusionContract(NoOpBackupExclusion.new);

  test('the fake records paths and fails on demand', () async {
    final exclusion = FakeBackupExclusion();
    expectOk(await exclusion.exclude(['/a.db', '/a.db-wal']));
    exclusion.failNext(const Failure.storage(), on: 'exclude');
    expect(
      expectErr(await exclusion.exclude(['/b.db'])),
      const Failure.storage(),
    );
    expect(exclusion.excluded, ['/a.db', '/a.db-wal']);
    expect(exclusion.callCount('exclude'), 2);
  });
}
