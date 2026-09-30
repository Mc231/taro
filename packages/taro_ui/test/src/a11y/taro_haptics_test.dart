import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taro_ui/taro_ui.dart';

void main() {
  late List<Object?> calls;

  setUp(() {
    calls = [];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          if (call.method.startsWith('HapticFeedback')) {
            calls.add(call.arguments);
          }
          return null;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  Future<BuildContext> pump(WidgetTester tester, {bool? enabled}) async {
    late BuildContext captured;
    Widget child = Builder(
      builder: (context) {
        captured = context;
        return const SizedBox();
      },
    );
    if (enabled != null) {
      child = TaroA11yScope(hapticsEnabled: enabled, child: child);
    }
    await tester.pumpWidget(Theme(data: TaroTheme.light(), child: child));
    return captured;
  }

  testWidgets('pick, flip and ready play the haptic tokens', (tester) async {
    final context = await pump(tester);
    await TaroHaptics.pick(context);
    await TaroHaptics.flip(context);
    await TaroHaptics.ready(context);
    expect(calls, [
      'HapticFeedbackType.selectionClick',
      'HapticFeedbackType.lightImpact',
      'HapticFeedbackType.mediumImpact',
    ]);
  });

  testWidgets('the haptics setting turns them off', (tester) async {
    final context = await pump(tester, enabled: false);
    await TaroHaptics.pick(context);
    await TaroHaptics.flip(context);
    await TaroHaptics.ready(context);
    expect(calls, isEmpty);
  });

  test('play maps every token value', () async {
    for (final pattern in [
      'selection',
      'light',
      'medium',
      'heavy',
      'vibrate',
    ]) {
      await TaroHaptics.play(pattern);
    }
    await TaroHaptics.play('buzz');
    expect(calls, [
      'HapticFeedbackType.selectionClick',
      'HapticFeedbackType.lightImpact',
      'HapticFeedbackType.mediumImpact',
      'HapticFeedbackType.heavyImpact',
      null,
    ]);
  });
}
