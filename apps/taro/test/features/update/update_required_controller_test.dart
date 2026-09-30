import 'package:flutter_test/flutter_test.dart';
import 'package:taro/features/update/controller/update_required_controller.dart';
import 'package:taro_core/taro_core.dart';

import '../feature_test_support.dart';

void main() {
  test('content with the platform minimum; logged with its origin', () {
    final fakes = TaroFakes();
    fakes.config.current = RemoteConfig.defaults.copyWith(
      appMinVersionIos: '2.0.0',
      appMinVersionAndroid: '3.0.0',
    );
    final state = fakes.container().read(
      updateRequiredControllerProvider(AppNoticeOrigin.launch),
    );
    expect(
      state,
      const UpdateRequiredState.content(
        platform: AppPlatform.ios,
        installedVersion: kTestAppVersion,
        minVersion: '2.0.0',
      ),
    );
    expect(
      eventsOf<AppUpdateRequiredShownEvent>(fakes).single.origin,
      AppNoticeOrigin.launch,
    );
  });

  test('android reads its own minimum', () {
    final fakes = TaroFakes()
      ..appInfo = const FakeAppInfo(platform: AppPlatform.android);
    fakes.config.current = RemoteConfig.defaults.copyWith(
      appMinVersionAndroid: '3.0.0',
    );
    final state = fakes.container().read(
      updateRequiredControllerProvider(AppNoticeOrigin.resume),
    );
    expect((state as UpdateRequiredContent).minVersion, '3.0.0');
  });
}
