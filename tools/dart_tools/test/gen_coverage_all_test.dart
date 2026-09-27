import 'package:taro_dart_tools/gen_coverage_all.dart';
import 'package:test/test.dart';

void main() {
  test('genCoverageAll is a no-op that succeeds', () async {
    expect(await genCoverageAll(const []), 0);
  });
}
