import 'package:taro_core/taro_core.dart';

import 'credit_balance_builder.dart';
import 'defaults.dart';

/// A registered, high-trust install by default.
InstallIdentity anInstallIdentity({
  bool registered = true,
  Trust trust = Trust.high,
  String? registeredTimezone = kTestTimeZone,
  PurchaseBinding? binding = const PurchaseBinding(
    appleAccountToken: '5b0d6c1e-3333-5444-8555-666677778888',
  ),
}) => InstallIdentity(
  installId: kTestInstallId,
  registeredAt: registered ? kTestNow : null,
  registeredTimezone: registered ? registeredTimezone : null,
  trust: registered ? trust : null,
  purchaseBinding: registered ? binding : null,
);

/// A delivered App Store transaction of [productId].
StorePurchase aStorePurchase({
  String txnKey = 'txn-1',
  ProductId? productId,
  StorePlatform platform = StorePlatform.ios,
  bool isRestored = false,
}) => StorePurchase(
  txnKey: txnKey,
  productId: productId ?? TaroProducts.readings3.id,
  platform: platform,
  transactionId: platform == StorePlatform.ios ? txnKey : null,
  purchaseToken: platform == StorePlatform.android ? 'token-$txnKey' : null,
  orderId: platform == StorePlatform.android ? 'GPA.$txnKey' : null,
  isRestored: isRestored,
);

/// The store listing of [product] (USD).
StoreProduct aStoreProduct(TaroProduct product) {
  final price = switch (product.alias) {
    'pack_s' => 2.99,
    'pack_m' => 7.99,
    'pack_l' => 19.99,
    _ => 3.99,
  };
  return StoreProduct(
    id: product.id,
    title: product.alias,
    price: '\$$price',
    rawPrice: price,
    currencyCode: 'USD',
  );
}

/// A pre-draw hold that expires [validFor] after [kTestNow] (server time
/// equals device time in the default balance).
ReadingHold aReadingHold({
  ReadingId readingId = kTestReadingId,
  ChargeSource chargeSource = ChargeSource.free,
  Duration validFor = const Duration(minutes: 10),
  CreditBalance? balance,
}) => ReadingHold(
  readingId: readingId,
  chargeSource: chargeSource,
  expiresAt: kTestNow.add(validFor),
  balance: balance ?? aCreditBalance().build(),
);

/// A crisis helpline.
CrisisResource aCrisisResource({
  String name = 'Telefonseelsorge',
  String? phone = '0800 111 0 111',
  String? url,
  List<String> languages = const ['de'],
}) => CrisisResource(
  name: name,
  phone: phone,
  url: url,
  languages: languages,
  verifiedAt: DateTime.utc(2026, 9),
);

/// A small crisis directory: Germany (two lines), the United States (one
/// line), `de` → DE and `en` → international only, plus one international
/// entry.
CrisisDirectory aCrisisDirectory() => CrisisDirectory(
  countries: {
    'DE': [
      aCrisisResource(),
      aCrisisResource(name: 'Nummer gegen Kummer', phone: '116 111'),
    ],
    'US': [
      aCrisisResource(name: '988 Lifeline', phone: '988', languages: ['en']),
    ],
  },
  localeFallback: const {'de': 'DE', 'en': null},
  international: [
    aCrisisResource(
      name: 'Find A Helpline',
      phone: null,
      url: 'https://findahelpline.com',
      languages: const [],
    ),
  ],
);
