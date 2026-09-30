import 'package:flutter/material.dart';
import 'package:taro/l10n/generated/taro_localizations.dart';
import 'package:taro_ui/taro_ui.dart';

/// S01 `storageError` (02 §6.2, 01 §8.3): secure storage or a database
/// could not be opened, so the app cannot start. Blocking, with **Try
/// again** (re-runs the launch) and the support address. It never
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
        return Scaffold(
          body: Center(
            child: AlertDialog(
              title: Text(l10n.bootstrapStorageErrorTitle),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.bootstrapStorageErrorBody),
                  ListTile(
                    contentPadding: EdgeInsetsDirectional.zero,
                    leading: const Icon(Icons.mail_outline),
                    title: Text(l10n.bootstrapContactSupport),
                    subtitle: SelectableText(supportEmail),
                  ),
                ],
              ),
              actions: [
                FilledButton(
                  onPressed: onRetry,
                  child: Text(l10n.bootstrapRetry),
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
}
