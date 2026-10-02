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
    launcher.failNext(const Failure.storage(), on: 'openInApp');
    expect(
      (await launcher.openInApp(Uri.parse('https://a.example'))).isErr,
      isTrue,
    );
    launcher.failNext(const Failure.storage(), on: 'openAppSettings');
    expect((await launcher.openAppSettings()).isErr, isTrue);
    expectOk(await launcher.openAppSettings());
    expect(launcher.settingsOpened, 1);
  });

  test('NoOpUrlLauncher reports success', () async {
    // A tear-off, so the constructor runs at test time (not as a const).
    const UrlLauncher Function() create = NoOpUrlLauncher.new;
    final launcher = create();
    expectOk(await launcher.open(Uri.parse('ftp://x')));
    expectOk(await launcher.openInApp(Uri.parse('ftp://x')));
    expectOk(await launcher.openAppSettings());
  });
}
