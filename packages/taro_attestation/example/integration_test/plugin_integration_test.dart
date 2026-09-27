import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:taro_attestation/taro_attestation.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('getPlatformVersion returns a non-empty string', (_) async {
    final version = await TaroAttestation().getPlatformVersion();
    expect(version, isNotEmpty);
  });
}
