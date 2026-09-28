import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import 'taro_golden_comparator.dart';

/// A 100 x 100 PNG, black except for the first [whitePixels] pixels.
Future<Uint8List> _png(int whitePixels) async {
  const side = 100;
  final rgba = Uint8List(side * side * 4);
  for (var i = 0; i < side * side; i++) {
    final value = i < whitePixels ? 255 : 0;
    rgba
      ..[i * 4] = value
      ..[i * 4 + 1] = value
      ..[i * 4 + 2] = value
      ..[i * 4 + 3] = 255;
  }
  final buffer = await ui.ImmutableBuffer.fromUint8List(rgba);
  final descriptor = ui.ImageDescriptor.raw(
    buffer,
    width: side,
    height: side,
    pixelFormat: ui.PixelFormat.rgba8888,
  );
  final codec = await descriptor.instantiateCodec();
  final frame = await codec.getNextFrame();
  final data = await frame.image.toByteData(format: ui.ImageByteFormat.png);
  return data!.buffer.asUint8List();
}

void main() {
  late Directory dir;
  late TaroGoldenComparator comparator;
  final golden = Uri.parse('g.png');

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('taro_golden_');
    comparator = TaroGoldenComparator(Uri.file('${dir.path}/x_test.dart'));
  });

  tearDown(() => dir.delete(recursive: true));

  testWidgets('passes identical images and diffs within 0.1%', (
    tester,
  ) async {
    await tester.runAsync(() async {
      await comparator.update(golden, await _png(0));
      expect(await comparator.compare(await _png(0), golden), isTrue);
      // 10 of 10,000 pixels = 0.1%: the edge of the tolerance.
      expect(await comparator.compare(await _png(10), golden), isTrue);
    });
  });

  testWidgets('fails above 0.1% and writes failure images', (tester) async {
    await tester.runAsync(() async {
      await comparator.update(golden, await _png(0));
      final image = await _png(11);
      await expectLater(
        comparator.compare(image, golden),
        throwsA(isA<FlutterError>()),
      );
      expect(Directory('${dir.path}/failures').existsSync(), isTrue);
    });
  });

  test('defaults to the QA8 tolerance', () {
    expect(comparator.tolerance, kTaroGoldenTolerance);
    expect(kTaroGoldenTolerance, 0.001);
  });

  test('replacing keeps the base directory of the default comparator', () {
    final local = LocalFileComparator(Uri.file('${dir.path}/a/b_test.dart'));
    final replaced = TaroGoldenComparator.replacing(local, tolerance: 0.01);
    expect(replaced.basedir, local.basedir);
    expect(replaced.tolerance, 0.01);
  });

  test('replacing rejects a non-local comparator', () {
    expect(
      () => TaroGoldenComparator.replacing(_OtherComparator()),
      throwsStateError,
    );
  });
}

class _OtherComparator extends GoldenFileComparator {
  @override
  Future<bool> compare(Uint8List imageBytes, Uri golden) async => true;

  @override
  Future<void> update(Uri golden, Uint8List imageBytes) async {}
}
