import 'package:test/test.dart';

import '../fakes/fakes.dart';
import 'contracts.dart';

void main() {
  runIdGeneratorContract(SequentialIdGenerator.new);

  test('prefixed IDs are readable and recorded', () {
    final ids = SequentialIdGenerator('id-');
    expect(ids.peek, 'id-1');
    expect([ids.uuidV4(), ids.uuidV4()], ['id-1', 'id-2']);
    expect(ids.issued, ['id-1', 'id-2']);
    expect(
      SequentialIdGenerator().uuidV4(),
      '00000000-0000-4000-8000-000000000001',
    );
  });
}
