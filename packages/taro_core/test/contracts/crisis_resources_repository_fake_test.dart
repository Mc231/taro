import 'package:taro_core/taro_core.dart';
import 'package:test/test.dart';

import '../fakes/fakes.dart';
import 'contracts.dart';

void main() {
  runCrisisResourcesRepositoryContract(FakeCrisisResourcesRepository.new);

  test('failNext', () async {
    final crisis = FakeCrisisResourcesRepository()
      ..failNext(const Failure.storage(), on: 'directory')
      ..failNext(const Failure.storage(), on: 'select');
    expect((await crisis.directory()).isErr, isTrue);
    expect((await crisis.select()).isErr, isTrue);
  });
}
