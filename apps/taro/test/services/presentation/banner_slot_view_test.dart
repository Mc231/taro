import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taro/services/presentation/banner_slot_view.dart';

void main() {
  testWidgets('BannerSlotView is an empty placeholder', (tester) async {
    // Non-const on purpose: a const instance is built at compile time, so the
    // constructor line would never be hit at runtime (06 QA2 per-file floor).
    // ignore: prefer_const_constructors
    await tester.pumpWidget(BannerSlotView());
    expect(find.byType(SizedBox), findsOneWidget);
  });
}
