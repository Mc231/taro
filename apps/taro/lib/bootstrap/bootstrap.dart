import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:taro/app.dart';
import 'package:taro/bootstrap/flavor_config.dart';
import 'package:taro/di/providers.dart';

/// Signature of [runApp], injectable for tests.
typedef AppRunner = void Function(Widget app);

/// Composition root: builds the [FlavorConfig] for [flavor] and runs the app.
Future<void> bootstrap(
  Flavor flavor, {
  AppRunner runner = runApp,
  Map<String, String> defines = FlavorConfig.dartDefines,
}) async {
  WidgetsFlutterBinding.ensureInitialized();
  final config = FlavorConfig.fromDefines(flavor, defines: defines);
  runner(
    ProviderScope(
      overrides: [flavorConfigProvider.overrideWithValue(config)],
      child: const TaroApp(),
    ),
  );
}
