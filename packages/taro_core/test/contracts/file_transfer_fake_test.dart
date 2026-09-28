import 'dart:typed_data';

import 'package:taro_core/taro_core.dart';
import 'package:test/test.dart';

import '../fakes/fakes.dart';
import 'contracts.dart';

final class _Harness implements FileTransferHarness {
  final FakeFileTransfer files = FakeFileTransfer();

  @override
  FileTransfer get subject => files;

  @override
  void userPicks(Uint8List? bytes) => files.willPick(bytes);

  @override
  List<String> get sharedFileNames => [
    for (final f in files.shared) f.fileName,
  ];
}

void main() {
  runFileTransferContract(_Harness.new);

  test('no queued pick cancels; failNext fails', () async {
    final files = FakeFileTransfer();
    expect(expectOk(await files.pickJson()), isNull);
    files
      ..failNext(const Failure.storage(), on: 'share')
      ..failNext(const Failure.storage(), on: 'pickJson');
    expect((await files.share(Uint8List(0), 'a', 'b')).isErr, isTrue);
    expect((await files.pickJson()).isErr, isTrue);
  });
}
