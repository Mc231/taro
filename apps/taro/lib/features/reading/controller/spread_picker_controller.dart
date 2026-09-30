import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:taro/app_state/remote_config_controller.dart';
import 'package:taro/di/providers.dart';
import 'package:taro_core/taro_core.dart';

part 'spread_picker_controller.freezed.dart';

/// S06 Spread picker (01 §8.3).
@freezed
sealed class SpreadPickerState with _$SpreadPickerState {
  /// The bundled spreads are loading.
  const factory SpreadPickerState.loading() = SpreadPickerLoading;

  /// The spreads to offer, in `kSpreadIds` order; spreads disabled by
  /// `spreads.enabled` (or the bundle) are hidden.
  const factory SpreadPickerState.content(List<SpreadDefinition> spreads) =
      SpreadPickerContent;

  /// The bundled content could not be read.
  const factory SpreadPickerState.failed(Failure failure) = SpreadPickerFailed;
}

/// S06: lists the enabled spreads; a remote-config change re-filters at
/// once.
///
/// Riverpod 3 recreates a notifier on rebuild, so this controller watches
/// only fixed port providers and follows the config with `listen`.
final class SpreadPickerController extends Notifier<SpreadPickerState> {
  List<SpreadDefinition>? _all;

  @override
  SpreadPickerState build() {
    ref.listen<RemoteConfig>(remoteConfigProvider, (previous, config) {
      final all = _all;
      if (all != null) state = SpreadPickerState.content(_visible(all, config));
    });
    unawaited(Future.microtask(_load));
    return const SpreadPickerState.loading();
  }

  static List<SpreadDefinition> _visible(
    List<SpreadDefinition> all,
    RemoteConfig config,
  ) {
    int order(SpreadDefinition s) {
      final i = kSpreadIds.indexOf(s.id);
      return i < 0 ? kSpreadIds.length : i;
    }

    return [
      for (final s in all)
        if (s.enabled && config.isSpreadEnabled(s.id)) s,
    ]..sort((a, b) => order(a).compareTo(order(b)));
  }

  Future<void> _load() async {
    final result = await ref.read(contentRepositoryProvider).spreads();
    if (!ref.mounted) return;
    switch (result) {
      case Ok(:final value):
        _all = value;
        state = SpreadPickerState.content(
          _visible(value, ref.read(remoteConfigProvider)),
        );
      case Err(:final failure):
        state = SpreadPickerState.failed(failure);
    }
  }

  /// Retry after `failed`.
  Future<void> retry() async {
    state = const SpreadPickerState.loading();
    await _load();
  }
}

/// S06 (`spreadPickerControllerProvider`).
final NotifierProvider<SpreadPickerController, SpreadPickerState>
spreadPickerControllerProvider = NotifierProvider.autoDispose(
  SpreadPickerController.new,
);
