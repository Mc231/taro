import 'package:flutter_test/flutter_test.dart';
import 'package:taro/services/ids/secure_id_generator.dart';

import '../../../../../packages/taro_core/test/contracts/contracts.dart';

void main() {
  runIdGeneratorContract(SecureIdGenerator.new);

  test('issues distinct canonical lowercase UUIDv4s', () {
    final ids = SecureIdGenerator();
    final issued = [for (var i = 0; i < 100; i++) ids.uuidV4()];
    final v4 = RegExp(
      r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
    );
    expect(issued, everyElement(matches(v4)));
    expect(issued.toSet(), hasLength(100));
  });
}
