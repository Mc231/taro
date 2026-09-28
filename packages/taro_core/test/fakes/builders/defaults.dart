/// Fixed defaults shared by every builder and fake (QA9): builders never
/// read the clock or a random source, so the same builder call always
/// yields the same object.
library;

import 'package:taro_core/taro_core.dart';

/// The instant every builder and `FakeClock` default uses (UTC).
final DateTime kTestNow = DateTime.utc(2026, 9, 26, 9);

/// The IANA zone of the default test device.
const String kTestTimeZone = 'Europe/Kyiv';

/// The UTC offset of [kTestTimeZone] at [kTestNow] (EEST).
const Duration kTestUtcOffset = Duration(hours: 3);

/// The device-local date at [kTestNow] in [kTestTimeZone].
const String kTestLocalDate = '2026-09-26';

/// The next local midnight after [kTestNow] in [kTestTimeZone]: the
/// default `free.resetsAt`.
final DateTime kTestResetsAt = DateTime.utc(2026, 9, 26, 21);

/// The default content and UI locale.
const String kTestLocale = 'en';

/// The default reading ID (a canonical UUIDv4).
const ReadingId kTestReadingId = ReadingId(
  '0c6e2b1e-1111-4222-8333-444455556666',
);

/// The default install ID.
const InstallId kTestInstallId = InstallId(
  '7f1c9a52-2222-4333-8444-555566667777',
);

/// The default question.
const String kTestQuestion = 'What should I focus on this week?';

/// The default app version and build.
const String kTestAppVersion = '1.0.0';

/// The default build number.
const String kTestBuildNumber = '1';

/// The default rewarded ad unit ID.
const String kTestAdUnitId = 'ca-app-pub-test/rewarded';

/// Readings per pack in the Worker's `PRODUCT_CATALOG`. Test data for the
/// fake Worker only: the client never knows credit amounts (rule 9, RC3).
final Map<ProductId, int> kTestPackCredits = {
  TaroProducts.readings3.id: 3,
  TaroProducts.readings10.id: 10,
  TaroProducts.readings30.id: 30,
};
