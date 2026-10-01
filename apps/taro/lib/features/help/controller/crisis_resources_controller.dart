import 'dart:async';
import 'dart:ui' show PlatformDispatcher;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show NotifierProviderFamily;
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:taro/app_state/crisis_handoff.dart';
import 'package:taro/di/providers.dart';
import 'package:taro_core/taro_core.dart';

part 'crisis_resources_controller.freezed.dart';

/// The device region (ISO 3166-1 alpha-2) used to pick local crisis lines.
/// It is read on the device and never sent anywhere (RC25, RC81).
final crisisRegionProvider = Provider<String?>(
  (ref) => PlatformDispatcher.instance.locale.countryCode,
);

/// S27 Crisis resources (05 §3 `crisisTitle` / `crisisBody`; bundled, so it
/// works offline).
@freezed
sealed class CrisisResourcesState with _$CrisisResourcesState {
  /// Reading the bundled directory.
  const factory CrisisResourcesState.loading() = CrisisResourcesLoading;

  /// Up to 3 lines for `country`, always including the international entry.
  const factory CrisisResourcesState.content({
    /// The selected country, if known.
    required String? country,

    /// The lines to show (≤ 3).
    required List<CrisisResource> resources,

    /// Whether `country` has its own lines (else only the international
    /// entry: "no entry for the region").
    required bool hasLocalLines,

    /// Countries of the "Show resources for another country" picker.
    required List<String> countries,
  }) = CrisisResourcesContent;

  /// The bundled directory could not be read.
  const factory CrisisResourcesState.storageError() =
      CrisisResourcesStorageError;
}

/// Drives S27 for one [origin] (`crisis_resources_viewed.origin`).
final class CrisisResourcesController extends Notifier<CrisisResourcesState> {
  /// A controller opened from [origin].
  CrisisResourcesController(this.origin);

  /// Where S27 was opened from.
  final CrisisResourcesOrigin origin;

  CrisisDirectory? _directory;
  bool _countryChosen = false;

  @override
  CrisisResourcesState build() {
    unawaited(_load());
    return const CrisisResourcesState.loading();
  }

  /// "Show resources for another country".
  void chooseCountry(String country) {
    _countryChosen = true;
    _show(country.toUpperCase());
  }

  Future<void> _load() async {
    final directory = await ref
        .read(crisisResourcesRepositoryProvider)
        .directory();
    if (!ref.mounted) return;
    switch (directory) {
      case Err():
        state = const CrisisResourcesState.storageError();
        return;
      case Ok(:final value):
        _directory = value;
        _show(ref.read(crisisRegionProvider)?.toUpperCase());
    }
    await ref
        .read(analyticsServiceProvider)
        .log(CrisisResourcesViewedEvent(origin: origin));
  }

  void _show(String? country) {
    final directory = _directory;
    if (directory == null || !ref.mounted) return;
    final countries = directory.countries.keys.toList()..sort();
    final worker = _workerLines(directory);
    if (worker != null) {
      state = CrisisResourcesState.content(
        country: null,
        resources: worker,
        hasLocalLines: worker.length > directory.international.length,
        countries: countries,
      );
      return;
    }
    final locale = ref.read(appLocaleProvider)();
    final local =
        directory.countries[country] ??
        directory.countries[directory.localeFallback[locale]];
    state = CrisisResourcesState.content(
      country: country,
      resources: directory.select(country: country, locale: locale),
      hasLocalLines: local != null && local.isNotEmpty,
      countries: countries,
    );
  }

  /// The Worker's lines of the declined reading (S27 from a reading, before
  /// another country is chosen): at most 3, always ending with the bundled
  /// international entry. `null` when there are none.
  List<CrisisResource>? _workerLines(CrisisDirectory directory) {
    if (origin != CrisisResourcesOrigin.reading || _countryChosen) return null;
    final offered = ref.read(crisisHandoffProvider);
    if (offered.isEmpty) return null;
    final local = offered
        .where((r) => !directory.international.contains(r))
        .toList();
    final room = (CrisisDirectory.maxResults - directory.international.length)
        .clamp(0, CrisisDirectory.maxResults);
    return [
      ...local.take(room),
      ...directory.international,
    ].take(CrisisDirectory.maxResults).toList(growable: false);
  }
}

/// S27 controllers by origin.
final NotifierProviderFamily<
  CrisisResourcesController,
  CrisisResourcesState,
  CrisisResourcesOrigin
>
crisisResourcesControllerProvider = NotifierProvider.autoDispose.family(
  CrisisResourcesController.new,
);
