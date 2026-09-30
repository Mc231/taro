import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taro_ui/taro_ui.dart';

Future<(TaroMotionTokens, bool)> _read(
  WidgetTester tester, {
  required bool disableAnimations,
  bool? inAppReduce,
}) async {
  late TaroMotionTokens motion;
  late bool reduced;
  Widget child = Builder(
    builder: (context) {
      motion = context.motion;
      reduced = context.reduceMotion;
      return const SizedBox();
    },
  );
  if (inAppReduce != null) {
    child = TaroA11yScope(reduceMotion: inAppReduce, child: child);
  }
  await tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData(disableAnimations: disableAnimations),
      child: Theme(data: TaroTheme.light(), child: child),
    ),
  );
  return (motion, reduced);
}

void main() {
  testWidgets('default motion when nothing asks for reduced motion', (
    tester,
  ) async {
    final (motion, reduced) = await _read(tester, disableAnimations: false);
    expect(reduced, isFalse);
    expect(motion.ritual.flip, TaroMotionTokens.light.ritual.flip);
  });

  testWidgets('MediaQuery.disableAnimations gives the reduced values', (
    tester,
  ) async {
    final (motion, reduced) = await _read(tester, disableAnimations: true);
    expect(reduced, isTrue);
    expect(motion.ritual.flip, TaroMotionTokens.reduced.ritual.flip);
    expect(motion.ritual.dealStagger, Duration.zero);
  });

  testWidgets('the in-app setting gives the reduced values', (tester) async {
    final (motion, reduced) = await _read(
      tester,
      disableAnimations: false,
      inAppReduce: true,
    );
    expect(reduced, isTrue);
    expect(motion.ritual.shuffle, TaroMotionTokens.reduced.ritual.shuffle);
    final (off, offReduced) = await _read(
      tester,
      disableAnimations: false,
      inAppReduce: false,
    );
    expect(offReduced, isFalse);
    expect(off.ritual.shuffle, TaroMotionTokens.light.ritual.shuffle);
  });

  testWidgets('without a MediaQuery nothing is reduced', (tester) async {
    late bool reduced;
    await tester.pumpWidget(
      Builder(
        builder: (context) {
          reduced = TaroMotion.isReduced(context);
          return const SizedBox();
        },
      ),
    );
    // The test binding supplies a View-level MediaQuery with animations on.
    expect(reduced, isFalse);
  });

  test('TaroA11yScope notifies on change only', () {
    const a = TaroA11yScope(child: SizedBox());
    const b = TaroA11yScope(child: SizedBox());
    const c = TaroA11yScope(hapticsEnabled: false, child: SizedBox());
    const d = TaroA11yScope(reduceMotion: true, child: SizedBox());
    expect(a.updateShouldNotify(b), isFalse);
    expect(a.updateShouldNotify(c), isTrue);
    expect(a.updateShouldNotify(d), isTrue);
  });
}
