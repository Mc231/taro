import 'package:taro_core/taro_core.dart';
import 'package:test/test.dart';

import '../fakes/fakes.dart';
import 'contracts.dart';

void main() {
  runUrlLauncherContract(FakeUrlLauncher.new);

  test('records opened links and injected failures', () async {
    final launcher = FakeUrlLauncher()..failNext(const Failure.storage());
    expect((await launcher.open(Uri.parse('tel:1'))).isErr, isTrue);
    expectOk(await launcher.open(Uri.parse('tel:2')));
    expect(launcher.opened, [Uri.parse('tel:2')]);
  });

  test('NoOpUrlLauncher reports success', () async {
    // A tear-off, so the constructor runs at test time (not as a const).
    const UrlLauncher Function() create = NoOpUrlLauncher.new;
    expectOk(await create().open(Uri.parse('ftp://x')));
  });
}
