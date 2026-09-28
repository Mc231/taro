import 'package:taro_core/taro_core.dart';
import 'package:test/test.dart';

void main() {
  group('taro_core barrel', () {
    test('exports Result, Failure, IDs and ErrorKind', () {
      const result = Result<CardId>.ok(CardId('major_00'));
      expect(result.valueOrNull?.value, 'major_00');
      expect(
        ErrorKind.fromFailure(const Failure.network()),
        ErrorKind.network,
      );
      expect(RefusalCategory.fromWire('self_harm'), RefusalCategory.selfHarm);
    });
  });
}
