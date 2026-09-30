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
    await tester.pumpWidget(const ExampleApp(plugin: TaroAttestation()));
    await tester.pumpAndSettle();
  }

  testWidgets('shows a supported device', (tester) async {
    await pumpWith(tester, (_) async => true);
    expect(find.text('Attestation: supported'), findsOneWidget);
  });

  testWidgets('shows an unsupported device', (tester) async {
    await pumpWith(tester, (_) async => false);
    expect(find.text('Attestation: unsupported'), findsOneWidget);
  });

  testWidgets('shows the error kind of a failure', (tester) async {
    await pumpWith(
      tester,
      (_) async => throw PlatformException(code: 'transient'),
    );
    expect(find.text('Attestation: error: transient'), findsOneWidget);
  });
}
