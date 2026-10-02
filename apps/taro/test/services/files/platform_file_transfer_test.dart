import 'dart:io';
import 'dart:ui';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_plus/share_plus.dart';
import 'package:taro/services/files/platform_file_transfer.dart';
import 'package:taro_core/taro_core.dart';

import '../../../../../packages/taro_core/test/contracts/contracts.dart';
import '../../../../../packages/taro_core/test/fakes/fakes.dart';

final class _Share extends Fake implements SharePlus {
  final List<ShareParams> calls = [];
  Exception? error;
  ShareResultStatus status = ShareResultStatus.success;

  @override
  Future<ShareResult> share(ShareParams params) async {
    if (error != null) throw error!;
    calls.add(params);
    return ShareResult('raw', status);
  }
}

final class _File extends PlatformFile {
  _File(this.bytes);

  final Uint8List bytes;

  @override
  String get name => 'backup.json';

  @override
  Uri get uri => Uri.file('/tmp/backup.json');

  @override
  XFile get xFile => XFile.fromData(bytes, name: name);

  @override
  int? lengthSync() => bytes.length;

  @override
  Future<int?> length() async => bytes.length;

  @override
  Future<Uint8List> readAsBytes() async => bytes;

  @override
  Stream<Uint8List> readAsByteStream() => Stream.value(bytes);
}

/// Claims `chunk.length * chunks` bytes and streams them chunk by chunk.
final class _HugeFile extends _File {
  _HugeFile(super.bytes, {required this.chunks});

  final int chunks;
  bool wholeRead = false;

  @override
  Future<int?> length() async => bytes.length * chunks;

  @override
  Future<Uint8List> readAsBytes() async {
    wholeRead = true;
    return bytes;
  }

  @override
  Stream<Uint8List> readAsByteStream() =>
      Stream.fromIterable(List.filled(chunks, bytes));
}

final class _UnknownLengthFile extends _File {
  _UnknownLengthFile(super.bytes);

  @override
  Future<int?> length() async => null;
}

final class _Harness implements FileTransferHarness {
  final _Share shares = _Share();
  final List<Uint8List?> _picks = [];

  @override
  late final FileTransfer subject = PlatformFileTransfer(
    logger: CapturingLogger(),
    share: shares,
    pick: () async {
      final next = _picks.removeAt(0);
      return next == null ? <PlatformFile>[] : [_File(next)];
    },
    origin: () => null,
  );

  @override
  void userPicks(Uint8List? bytes) => _picks.add(bytes);

  @override
  List<String> get sharedFileNames => [
    for (final call in shares.calls) ...call.fileNameOverrides!,
  ];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late _Share shares;
  late CapturingLogger logger;
  final bytes = Uint8List.fromList(utf8Json);

  setUp(() {
    shares = _Share();
    logger = CapturingLogger();
  });

  PlatformFileTransfer transfer({
    JsonFilePicker? pick,
    ShareOrigin? origin,
  }) => PlatformFileTransfer(
    logger: logger,
    share: shares,
    pick: pick ?? () async => [],
    origin: origin ?? () => const Rect.fromLTWH(10, 20, 1, 1),
  );

  runFileTransferContract(_Harness.new);

  group('share', () {
    test('shares one file with its name, MIME type and anchor', () async {
      final result = await transfer().share(
        bytes,
        'taro-backup-2026-09-26.json',
        'application/json',
      );
      expect(result.isOk, isTrue);
      final params = shares.calls.single;
      final file = params.files!.single;
      expect(file.mimeType, 'application/json');
      expect(await file.readAsBytes(), bytes);
      expect(params.fileNameOverrides, ['taro-backup-2026-09-26.json']);
      expect(params.sharePositionOrigin, const Rect.fromLTWH(10, 20, 1, 1));
    });

    test('a dismissed sheet is still Ok', () async {
      shares.status = ShareResultStatus.dismissed;
      expect((await transfer().share(bytes, 'a.json', 'x')).isOk, isTrue);
    });

    test('a platform error is a StorageFailure', () async {
      shares.error = PlatformException(code: 'share');
      final result = await transfer().share(bytes, 'a.json', 'x');
      expect(result.failureOrNull, const Failure.storage());
      expect(logger.messages, ['share failed']);
    });

    test('anything else is an UnexpectedFailure', () async {
      shares.error = const FormatException('files');
      final result = await transfer().share(bytes, 'a.json', 'x');
      expect(result.failureOrNull, isA<UnexpectedFailure>());
    });
  });

  group('pickJson', () {
    test('returns the first picked file', () async {
      final result = await transfer(
        pick: () async => [_File(bytes), _File(Uint8List(1))],
      ).pickJson();
      expect(expectOk(result), bytes);
    });

    test('a file over the limit is read only past the limit', () async {
      const max = BackupSchemaV1.maxFileBytes;
      final chunk = Uint8List(max ~/ 4);
      final file = _HugeFile(chunk, chunks: 100);
      final result = await transfer(pick: () async => [file]).pickJson();
      final read = expectOk(result)!;
      expect(read.length, greaterThan(max));
      expect(read.length, lessThanOrEqualTo(max + chunk.length));
      expect(file.wholeRead, isFalse);
    });

    test('a file of unknown length is read whole', () async {
      final result = await transfer(
        pick: () async => [_UnknownLengthFile(bytes)],
      ).pickJson();
      expect(expectOk(result), bytes);
    });

    test('a cancelled picker is Ok(null)', () async {
      expect(expectOk(await transfer().pickJson()), isNull);
    });

    test('a file-system error is a StorageFailure', () async {
      final result = await transfer(
        pick: () async => throw const FileSystemException('gone'),
      ).pickJson();
      expect(result.failureOrNull, const Failure.storage());
      expect(logger.messages, ['pick failed']);
    });

    test('anything else is an UnexpectedFailure', () async {
      final result = await transfer(
        pick: () async => throw StateError('picker'),
      ).pickJson();
      expect(result.failureOrNull, isA<UnexpectedFailure>());
    });
  });

  group('defaults', () {
    test('the picker asks file_picker for .json files', () async {
      final previous = FilePickerPlatform.instance;
      final picker = _Picker();
      FilePickerPlatform.instance = picker;
      addTearDown(() => FilePickerPlatform.instance = previous);
      expect(await PlatformFileTransfer.pickJsonFiles(), isEmpty);
      expect(picker.type, FileType.custom);
      expect(picker.extensions, ['json']);
    });

    test('the anchor is the centre of the first view', () {
      final rect = PlatformFileTransfer.centreOfFirstView();
      final view = PlatformDispatcher.instance.views.first;
      final size = view.physicalSize / view.devicePixelRatio;
      expect(rect!.center, size.center(Offset.zero));
      expect(rect.size, const Size(1, 1));
    });

    test('plugins default to their singletons', () {
      expect(PlatformFileTransfer(logger: logger), isA<FileTransfer>());
    });
  });
}

const List<int> utf8Json = [123, 34, 102, 34, 58, 49, 125];

final class _Picker extends FilePickerPlatform {
  FileType? type;
  List<String>? extensions;

  @override
  Future<List<PlatformFile>> pickFiles({
    String? dialogTitle,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    dynamic Function(FilePickerStatus)? onFileLoading,
    int compressionQuality = 0,
    AndroidOptions androidOptions = const AndroidOptions(),
    DarwinOptions darwinOptions = const DarwinOptions(),
    WindowsOptions windowsOptions = const WindowsOptions(),
    LinuxOptions linuxOptions = const LinuxOptions(),
    WebOptions webOptions = const WebOptions(),
  }) async {
    this.type = type;
    extensions = allowedExtensions;
    return [];
  }
}
