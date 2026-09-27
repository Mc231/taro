import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taro/bootstrap/bootstrap.dart';
import 'package:taro/bootstrap/flavor_config.dart';

void main() {
  Future<Widget> boot(Flavor flavor) async {
    Widget? app;
    await bootstrap(flavor, runner: (w) => app = w, defines: const {});
    return app!;
  }

  testWidgets('dev shows the placeholder with the flavor label', (
    tester,
  ) async {
    await tester.pumpWidget(await boot(Flavor.dev));
    await tester.pumpAndSettle();
    expect(find.text('Taro'), findsOneWidget);
    expect(find.text('dev'), findsOneWidget);
  });

  testWidgets('prod hides the flavor label', (tester) async {
    await tester.pumpWidget(await boot(Flavor.prod));
    await tester.pumpAndSettle();
    expect(find.text('Taro'), findsOneWidget);
    expect(find.text('prod'), findsNothing);
  });

  test('a config for another flavor fails fast', () {
    expect(
      () => bootstrap(
        Flavor.dev,
        runner: (_) {},
        defines: const {'flavor': 'prod'},
      ),
      throwsStateError,
    );
  });
}
