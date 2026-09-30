import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taro/app_state/balance_controller.dart';
import 'package:taro/di/providers.dart';
import 'package:taro_core/taro_core.dart';

import 'pump_app.dart';

class _Probe extends ConsumerWidget {
  const _Probe();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balance = ref.watch(balanceProvider);
    return Text('${ref.watch(appLocaleProvider)()} ${balance?.bonus}');
  }
}

void main() {
  testWidgets('pumpTaro wires TaroFakes into a ProviderScope', (tester) async {
    final fakes = await pumpTaro(
      tester,
      const _Probe(),
      locale: const Locale('uk'),
    );
    expect(fakes.locale, 'uk');
    expect(find.text('uk ${fakes.balance.cached!.bonus}'), findsOneWidget);
  });

  test(
    'FakeStoreOwnership answers the owned products or a queued answer',
    () async {
      final fakes = TaroFakes();
      fakes.iap.owned.add(TaroProducts.removeAds.id);
      expect(
        (await fakes.storeOwnership.queryOwnership()).valueOrNull,
        {TaroProducts.removeAds.id},
      );
      fakes.storeOwnership.next = const Result.err(Failure.network());
      expect((await fakes.storeOwnership.queryOwnership()).isOk, isFalse);
    },
  );
}
