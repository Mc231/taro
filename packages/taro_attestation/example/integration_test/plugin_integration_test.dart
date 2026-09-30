import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:taro_attestation/taro_attestation.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Answers on every device: false on a simulator or emulator without Play
  // services, true on a real device (Sprint 12.6 checks the rest by hand).
  testWidgets('isSupported answers', (_) async {
    expect(await const TaroAttestation().isSupported(), isA<bool>());
  });
}
