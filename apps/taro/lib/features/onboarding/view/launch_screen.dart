import 'package:flutter/widgets.dart';
import 'package:taro/l10n/generated/taro_localizations.dart';
import 'package:taro_ui/taro_ui.dart';

/// S01 Launch (01 §8.3 `bootstrapping`): the Flutter continuation of the
/// native splash while the router's guards pick the first screen (S30,
/// onboarding or Home). `storageError` is `StorageErrorApp` (bootstrap).
class LaunchScreen extends StatelessWidget {
  /// Creates the screen.
  const LaunchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = TaroLocalizations.of(context);
    return TaroScaffold(
      body: Center(
        child: TaroBrandMark(
          semanticsLabel: l10n.launchSemantics,
          wordmark: l10n.appTitle,
        ),
      ),
    );
  }
}
