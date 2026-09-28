import 'package:test/test.dart';

import '../fakes/fakes.dart';
import 'contracts.dart';

void main() {
  runLoggerContract(CapturingLogger.new);

  test('captures records of the logger and its children', () {
    final root = CapturingLogger();
    final error = StateError('x');
    root.warning('root warning', error: error);
    root.child('sync').info('child info');
    expect(root.messages, ['root warning', 'child info']);
    expect(root.records.last.logger, 'taro.sync');
    expect(root.at(LogLevel.warning).single.error, error);
    expect(root.logged('child', level: LogLevel.info), isTrue);
    expect(root.logged('child', level: LogLevel.severe), isFalse);
    expect(root.records.first.toString(), 'warning taro: root warning');
  });
}
