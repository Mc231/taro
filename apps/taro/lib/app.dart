import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:taro/app_state/settings_controller.dart';
import 'package:taro/common/card_art.dart';
import 'package:taro/di/providers.dart';
import 'package:taro/features/consent/view/att_preprompt_view.dart';
import 'package:taro/l10n/generated/taro_localizations.dart';
import 'package:taro/routing/router.dart';
import 'package:taro_core/taro_core.dart' as core;
import 'package:taro_ui/taro_ui.dart';

/// Root widget (02 §2.2 `app.dart`): `MaterialApp.router` with the router,
/// the Taro token themes (fonts for the active locale's script, 01 §13),
/// `TaroLocalizations`, the Settings theme and language override, the
/// in-app reduce-motion and haptics settings ([TaroA11yScope]), the card
/// back art ([CardBackArtScope]) and the ATT pre-prompt host above every
/// route (RC19).
class TaroApp extends ConsumerWidget {
  /// Creates the app.
  const TaroApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final flavor = ref.watch(flavorConfigProvider);
    final override = settings.localeOverride;
    return MaterialApp.router(
      routerConfig: ref.watch(routerProvider),
      onGenerateTitle: (context) => TaroLocalizations.of(context).appTitle,
      theme: TaroTheme.light(),
      darkTheme: TaroTheme.dark(),
      themeMode: themeModeOf(settings.themeMode),
      locale: override == null ? null : Locale(override),
      debugShowCheckedModeBanner: !flavor.isProd,
      localizationsDelegates: TaroLocalizations.localizationsDelegates,
      supportedLocales: TaroLocalizations.supportedLocales,
      builder: (context, child) => TaroA11yScope(
        reduceMotion: settings.reduceMotion ?? false,
        hapticsEnabled: settings.hapticsEnabled,
        child: Theme(
          data: themeForScript(
            Theme.of(context).brightness,
            TaroScript.forLocale(Localizations.localeOf(context)),
          ),
          child: CardBackArtScope(
            child: AttPrePromptHost(child: child ?? const SizedBox.shrink()),
          ),
        ),
      ),
    );
  }
}

/// The Taro theme for [brightness] with the font families of [script].
ThemeData themeForScript(Brightness brightness, TaroScript script) =>
    brightness == Brightness.dark
    ? TaroTheme.dark(script: script)
    : TaroTheme.light(script: script);

/// The Flutter theme mode of the Settings [theme].
ThemeMode themeModeOf(core.ThemeMode theme) => switch (theme) {
  core.ThemeMode.system => ThemeMode.system,
  core.ThemeMode.light => ThemeMode.light,
  core.ThemeMode.dark => ThemeMode.dark,
};
