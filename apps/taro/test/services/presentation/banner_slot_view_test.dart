import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taro/services/presentation/banner_slot_view.dart';

void main() {
  testWidgets('BannerSlotView is an empty placeholder', (tester) async {
    await tester.pumpWidget(const BannerSlotView());
    expect(find.byType(SizedBox), findsOneWidget);
  });
}
