// A method-channel double of the native google_mobile_ads plugin. It needs
// the plugin's own channel and codec (AdMessageCodec, `instanceManager`).

import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart' as gma;
import 'package:google_mobile_ads/src/ad_instance_manager.dart';

/// How the next ad load answers.
enum LoadMode {
  /// `onAdLoaded`.
  fill,

  /// `onAdFailedToLoad` (no fill).
  noFill,

  /// No answer (the timeout decides).
  hang,

  /// The platform call throws.
  error,
}

/// The native side of `plugins.flutter.io/google_mobile_ads`, installed on
/// the test binary messenger. Events go back through the real
/// `AdInstanceManager`, so the SDK's Dart code runs unchanged.
final class FakeAdsPlatform {
  /// Installs the double.
  FakeAdsPlatform() {
    _messenger.setMockMethodCallHandler(instanceManager.channel, _handle);
  }

  static TestDefaultBinaryMessenger get _messenger =>
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  /// Every method call, oldest first.
  final List<MethodCall> calls = [];

  /// The next loads answer like this.
  LoadMode loadMode = LoadMode.fill;

  /// `MobileAds#initialize` throws.
  bool failInitialize = false;

  /// `showAdWithoutView` throws.
  bool failShow = false;

  /// `disposeAd` throws.
  bool failDispose = false;

  /// The anchored adaptive banner height (`null`: no size).
  int? bannerHeight = 60;

  /// The ad IDs of every load, oldest first.
  final List<int> loadedIds = [];

  final List<int> _unanswered = [];
  Completer<int>? _waiting;

  /// The ID of the oldest shown ad the test has not taken yet, waiting for
  /// the next `showAdWithoutView` when there is none.
  Future<int> takeShow() {
    if (_unanswered.isNotEmpty) return Future.value(_unanswered.removeAt(0));
    return (_waiting ??= Completer<int>()).future;
  }

  /// Removes the double.
  void uninstall() =>
      _messenger.setMockMethodCallHandler(instanceManager.channel, null);

  /// The method names called, oldest first.
  List<String> get methods => [for (final c in calls) c.method];

  /// The arguments of the last call to [method].
  Map<Object?, Object?> argsOf(String method) =>
      calls.lastWhere((c) => c.method == method).arguments
          as Map<Object?, Object?>;

  Future<Object?> _handle(MethodCall call) async {
    calls.add(call);
    switch (call.method) {
      case 'MobileAds#initialize':
        if (failInitialize) throw PlatformException(code: 'init');
        return gma.InitializationStatus(const {});
      case 'loadRewardedAd':
      case 'loadBannerAd':
        final id = (call.arguments as Map<Object?, Object?>)['adId']! as int;
        loadedIds.add(id);
        switch (loadMode) {
          case LoadMode.fill:
            scheduleMicrotask(() => unawaited(loaded(id)));
          case LoadMode.noFill:
            scheduleMicrotask(() => unawaited(failLoad(id)));
          case LoadMode.hang:
            break;
          case LoadMode.error:
            throw PlatformException(code: 'load');
        }
        return null;
      case 'showAdWithoutView':
        if (failShow) throw PlatformException(code: 'show');
        final id = (call.arguments as Map<Object?, Object?>)['adId']! as int;
        final waiting = _waiting;
        _waiting = null;
        if (waiting != null) {
          waiting.complete(id);
        } else {
          _unanswered.add(id);
        }
        return null;
      case 'disposeAd':
        if (failDispose) throw PlatformException(code: 'dispose');
        return null;
      case 'AdSize#getLargeAnchoredAdaptiveBannerAdSize':
        return bannerHeight;
    }
    return null;
  }

  /// Sends `onAdEvent` [eventName] for ad [id] with [extra] arguments.
  Future<void> event(
    int id,
    String eventName, [
    Map<String, Object?> extra = const {},
  ]) async {
    final channel = instanceManager.channel;
    await _messenger.handlePlatformMessage(
      channel.name,
      channel.codec.encodeMethodCall(
        MethodCall('onAdEvent', {'adId': id, 'eventName': eventName, ...extra}),
      ),
      (_) {},
    );
  }

  /// Ad [id] loaded.
  Future<void> loaded(int id) => event(id, 'onAdLoaded');

  /// Ad [id] had no fill.
  Future<void> failLoad(int id) => event(id, 'onAdFailedToLoad', {
    'loadAdError': gma.LoadAdError(3, 'test', 'no fill', null),
  });

  /// The user watched ad [id] to the end, then closed it.
  Future<void> earnAndClose(int id) async {
    await event(id, 'onRewardedAdUserEarnedReward', {
      'rewardItem': gma.RewardItem(1, 'reading'),
    });
    await close(id);
  }

  /// The user closed ad [id].
  Future<void> close(int id) => event(id, 'onAdDismissedFullScreenContent');

  /// Ad [id] could not be shown.
  Future<void> failToShow(int id) => event(
    id,
    'onFailedToShowFullScreenContent',
    {'error': gma.AdError(1, 'test', 'show')},
  );
}
