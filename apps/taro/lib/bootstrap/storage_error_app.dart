import 'package:flutter/material.dart';
import 'package:taro/l10n/generated/taro_localizations.dart';
import 'package:taro_ui/taro_ui.dart';

/// S01 `storageError` (02 §6.2, 01 §8.3): secure storage or a database
/// could not be opened, so the app cannot start. Blocking:
/// `TaroErrorView(storage)` on the launch canvas with **Try again**
/// (re-runs the launch, 02 §6.2) and the support address. It never
/// generates a second install ID.
class StorageErrorApp extends StatelessWidget {
  /// The blocking screen; [onRetry] re-runs bootstrap.
  const StorageErrorApp({
    required this.onRetry,
    required this.supportEmail,
    super.key,
  });

  /// Runs the launch again.
  final VoidCallback onRetry;

  /// The support e-mail address (`FlavorConfig.supportEmail`).
  final String supportEmail;

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: TaroTheme.light(),
    darkTheme: TaroTheme.dark(),
    localizationsDelegates: TaroLocalizations.localizationsDelegates,
    supportedLocales: TaroLocalizations.supportedLocales,
    home: Builder(
      builder: (context) {
        final l10n = TaroLocalizations.of(context);
        final tokens = context.tokens;
        return TaroScaffold(
          body: Center(
            child: TaroErrorView(
              kind: TaroErrorKind.storage,
              title: l10n.bootstrapStorageErrorTitle,
              body: l10n.bootstrapStorageErrorBody,
              retryLabel: l10n.bootstrapRetry,
              onRetry: onRetry,
              secondaryAction: MergeSemantics(
                child: Column(
                  spacing: tokens.space.s1,
                  children: [
                    Text(
                      l10n.bootstrapContactSupport,
                      style: tokens.typography.label.copyWith(
                        color: tokens.color.text.primary,
                      ),
                    ),
                    SelectableText(
                      supportEmail,
                      textAlign: TextAlign.center,
                      style: tokens.typography.label.copyWith(
                        color: tokens.color.accent.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    ),
  );
}
