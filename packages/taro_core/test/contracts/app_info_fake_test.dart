import 'package:taro_core/taro_core.dart';

import '../fakes/fakes.dart';
import 'contracts.dart';

void main() {
  runAppInfoContract(FakeAppInfo.new);
  runAppInfoContract(
    () => const FakeAppInfo(
      version: '2.3.4',
      buildNumber: '99',
      platform: AppPlatform.android,
    ),
  );
}
