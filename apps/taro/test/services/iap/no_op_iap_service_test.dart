import 'package:flutter_test/flutter_test.dart';
import 'package:taro/services/iap/no_op_iap_service.dart';
import 'package:taro_core/taro_core.dart';

import '../../../../../packages/taro_core/test/contracts/contract_support.dart';
import '../../../../../packages/taro_core/test/fakes/fakes.dart';

void main() {
  final iap = NoOpIapService();

  test('lists nothing and sells nothing', () async {
    expect(expectOk(await iap.products({TaroProducts.readings3.id})), isEmpty);
    expect(
      expectErr(
        await iap.buy(
          TaroProducts.readings3.id,
          binding: const PurchaseBinding(),
        ),
      ),
      const Failure.productUnavailable(),
    );
    expect(iap.pending, isEmpty);
  });

  test('restore and finish are no-ops; streams are empty', () async {
    expectOk(await iap.restore());
    expectOk(await iap.finish(aStorePurchase()));
    expect(await iap.deliveries.isEmpty, isTrue);
    expect(await iap.events.isEmpty, isTrue);
  });

  test('the ownership query never answers, so nothing is revoked', () async {
    expect(
      expectErr(await iap.queryOwnership()),
      const Failure.productUnavailable(),
    );
  });
}
