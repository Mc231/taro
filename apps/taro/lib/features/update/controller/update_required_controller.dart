import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show NotifierProviderFamily;
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:taro/di/providers.dart';
import 'package:taro_core/taro_core.dart';

part 'update_required_controller.freezed.dart';

/// S30 Update required (01 §8.3): blocking, store link only (RC73).
@freezed
sealed class UpdateRequiredState with _$UpdateRequiredState {
  /// The installed and the minimum version on this [platform]; the view
  /// links to that platform's store only.
  const factory UpdateRequiredState.content({
    required AppPlatform platform,
    required String installedVersion,
    required String minVersion,
  }) = UpdateRequiredContent;
}

/// S30. Shown by the router's update guard (`app.minVersion.*` or
/// `UpgradeRequiredFailure`); logs `app_update_required_shown` once.
final class UpdateRequiredController extends Notifier<UpdateRequiredState> {
  /// A controller; [origin] is `launch` on cold start, `resume` otherwise.
  UpdateRequiredController(this.origin);

  /// Where the requirement was found.
  final AppNoticeOrigin origin;

  @override
  UpdateRequiredState build() {
    final info = ref.watch(appInfoProvider);
    final config = ref.watch(remoteConfigRepositoryProvider).current;
    unawaited(
      ref
          .watch(analyticsServiceProvider)
          .log(AppUpdateRequiredShownEvent(origin: origin)),
    );
    return UpdateRequiredState.content(
      platform: info.platform,
      installedVersion: info.version,
      minVersion: switch (info.platform) {
        AppPlatform.ios => config.appMinVersionIos,
        AppPlatform.android => config.appMinVersionAndroid,
      },
    );
  }
}

/// S30 (`updateRequiredControllerProvider(origin)`).
final NotifierProviderFamily<
  UpdateRequiredController,
  UpdateRequiredState,
  AppNoticeOrigin
>
updateRequiredControllerProvider = NotifierProvider.autoDispose.family(
  UpdateRequiredController.new,
);
