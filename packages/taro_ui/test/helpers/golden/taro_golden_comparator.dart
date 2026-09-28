import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

/// The largest share of differing pixels a golden may have and still pass:
/// 0.1% (06 QA8).
const double kTaroGoldenTolerance = 0.001;

/// A [LocalFileComparator] that accepts up to [tolerance] differing pixels
/// (06 QA8), to absorb anti-aliasing noise on the reference runner.
///
/// On a real failure it writes the masked diff and test images to
/// `<test dir>/failures/` exactly like the default comparator, so CI can
/// upload them.
class TaroGoldenComparator extends LocalFileComparator {
  /// Creates a comparator whose golden keys resolve next to [testFile].
  TaroGoldenComparator(super.testFile, {this.tolerance = kTaroGoldenTolerance})
    : assert(
        tolerance >= 0 && tolerance < 1,
        'tolerance is a fraction of pixels',
      );

  /// Wraps the per-file [LocalFileComparator] that `flutter test` installs,
  /// keeping its base directory.
  factory TaroGoldenComparator.replacing(
    GoldenFileComparator current, {
    double tolerance = kTaroGoldenTolerance,
  }) {
    if (current is! LocalFileComparator) {
      throw StateError(
        'Expected the default LocalFileComparator, got ${current.runtimeType}',
      );
    }
    return TaroGoldenComparator(
      current.basedir.resolve('flutter_test_config.dart'),
      tolerance: tolerance,
    );
  }

  /// The largest fraction (0..1) of differing pixels that still passes.
  final double tolerance;

  @override
  Future<bool> compare(Uint8List imageBytes, Uri golden) async {
    final result = await GoldenFileComparator.compareLists(
      imageBytes,
      await getGoldenBytes(golden),
    );
    try {
      if (result.passed || result.diffPercent <= tolerance) {
        return true;
      }
      final error = await generateFailureOutput(result, golden, basedir);
      throw FlutterError(error);
    } finally {
      result.dispose();
    }
  }
}
