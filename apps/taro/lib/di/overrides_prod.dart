import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:taro/di/app_graph.dart';

/// The prod graph (02 §15): the store, Crashlytics and Firebase analytics,
/// platform attestation only (no debug header), CSPRNG.
///
/// Throws [StateError] when handed a non-prod configuration.
Future<List<Override>> prodOverrides(GraphInputs inputs) {
  if (!inputs.flavor.isProd) {
    throw StateError('prodOverrides needs the prod flavor.');
  }
  return buildAppOverrides(inputs);
}
