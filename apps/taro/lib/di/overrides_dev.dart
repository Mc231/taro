import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:taro/di/app_graph.dart';

/// The dev and staging graph (02 §15): no store products (NoOp IAP), the
/// console analytics backend in dev, Crashlytics off in dev, and the
/// `DebugAttestationService` with its `X-Taro-Debug-Attestation` header
/// when a debug token is set (RC86).
///
/// Throws [StateError] when handed the prod configuration.
Future<List<Override>> devOverrides(GraphInputs inputs) {
  if (inputs.flavor.isProd) {
    throw StateError('devOverrides must not build the prod flavor.');
  }
  return buildAppOverrides(inputs);
}
