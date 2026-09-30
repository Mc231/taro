import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show NotifierProviderFamily;
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:taro/app_state/remote_config_controller.dart';
import 'package:taro/di/providers.dart';
import 'package:taro_core/taro_core.dart';

part 'spread_guide_controller.freezed.dart';

/// One spread of the guide. Names, position meanings and "when to use it"
/// are ARB strings (`spread_{id}_…`); the layout comes from the definition.
@freezed
abstract class SpreadGuideEntry with _$SpreadGuideEntry {
  /// Creates an entry.
  const factory SpreadGuideEntry({
    required SpreadDefinition spread,

    /// "Start this spread" is offered (not disabled by `spreads.enabled`).
    required bool startable,
  }) = _SpreadGuideEntry;
}

/// S18 Learn spreads guide + spread detail (01 §7.9).
@freezed
sealed class SpreadGuideState with _$SpreadGuideState {
  /// Reading the bundled spreads.
  const factory SpreadGuideState.loading() = SpreadGuideLoading;

  /// The spreads; [selected] is the open spread detail, if any.
  const factory SpreadGuideState.content({
    required List<SpreadGuideEntry> spreads,
    SpreadId? selected,
  }) = SpreadGuideContent;

  /// The bundled content could not be read.
  const factory SpreadGuideState.storageError() = SpreadGuideStorageError;
}

/// Drives S18 (`/learn/spreads[/:spreadId]`): the list and the detail of
/// [initial] when the route names one.
final class SpreadGuideController extends Notifier<SpreadGuideState> {
  /// A controller opened on [initial] (`null` = the list).
  SpreadGuideController(this.initial);

  /// The spread of the route, if any.
  final SpreadId? initial;

  List<SpreadDefinition>? _spreads;
  SpreadId? _selected;
  late ProviderSubscription<RemoteConfig> _config;

  @override
  SpreadGuideState build() {
    _selected = initial;
    _config = ref.listen(remoteConfigProvider, (_, _) => _update());
    unawaited(_load());
    return const SpreadGuideState.loading();
  }

  /// Opens the detail of [spreadId] (`learn_spread_viewed`).
  Future<void> select(SpreadId spreadId) async {
    _selected = spreadId;
    _update();
    await _logViewed(spreadId);
  }

  /// Back from a detail to the list.
  void closeDetail() {
    _selected = null;
    _update();
  }

  Future<void> _load() async {
    final spreads = await ref.read(contentRepositoryProvider).spreads();
    if (!ref.mounted) return;
    switch (spreads) {
      case Err():
        state = const SpreadGuideState.storageError();
      case Ok(:final value):
        _spreads = value;
        _update();
        final selected = _selected;
        if (selected != null) await _logViewed(selected);
    }
  }

  Future<void> _logViewed(SpreadId spreadId) => ref
      .read(analyticsServiceProvider)
      .log(LearnSpreadViewedEvent(spread: AnalyticsSpread.fromId(spreadId)));

  void _update() {
    final spreads = _spreads;
    if (spreads == null || !ref.mounted) return;
    final config = _config.read();
    state = SpreadGuideState.content(
      spreads: [
        for (final spread in spreads)
          SpreadGuideEntry(
            spread: spread,
            startable: spread.enabled && config.isSpreadEnabled(spread.id),
          ),
      ],
      selected: _selected,
    );
  }
}

/// S18 controllers by the route's spread.
final NotifierProviderFamily<SpreadGuideController, SpreadGuideState, SpreadId?>
spreadGuideControllerProvider = NotifierProvider.autoDispose.family(
  SpreadGuideController.new,
);
