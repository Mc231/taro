import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taro_attestation/taro_attestation.dart';
import 'package:taro_attestation_example/main.dart';

void main() {
  const channel = MethodChannel('taro_attestation');

  Future<void> pumpWith(
    WidgetTester tester,
    Future<Object?> Function(MethodCall call) handler,
  ) async {
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      handler,
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        channel,
        null,
      ),
    );
    await tester.pumpWidget(ExampleApp(plugin: TaroAttestation()));
    await tester.pumpAndSettle();
  }

  testWidgets('shows the platform version', (tester) async {
    await pumpWith(tester, (_) async => 'iOS 26');
    expect(find.text('Running on: iOS 26'), findsOneWidget);
  });

  testWidgets('shows a failure message on PlatformException', (tester) async {
    await pumpWith(tester, (_) async => throw PlatformException(code: 'x'));
    expect(
      find.text('Running on: Failed to get platform version.'),
      findsOneWidget,
    );
  });
}
