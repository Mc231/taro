import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:taro_core/taro_core.dart';

/// The crisis lines of the last declined reading (`SafetyInfo
/// .crisisResources`, chosen by the Worker from `cf.country`, 03 §9.5),
/// handed from S08 to S27 (`origin=reading`). In memory only: nothing is
/// stored, and S27 opened from Help ignores it (01 §7.5).
final class CrisisHandoff extends Notifier<List<CrisisResource>> {
  @override
  List<CrisisResource> build() => const [];

  /// Offers [resources] to the next S27 opened from a reading.
  void offer(List<CrisisResource> resources) =>
      state = List.unmodifiable(resources);
}

/// `crisisHandoffProvider` (S08 → S27).
final crisisHandoffProvider =
    NotifierProvider<CrisisHandoff, List<CrisisResource>>(CrisisHandoff.new);
