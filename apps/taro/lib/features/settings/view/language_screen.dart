import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:taro/common/settings_page.dart';
import 'package:taro/features/settings/controller/language_controller.dart';
import 'package:taro/features/settings/view/language_names.dart';
import 'package:taro/l10n/generated/taro_localizations.dart';
import 'package:taro_ui/taro_ui.dart';

/// S21 Language (01 §7.10): "Use phone language" + the 12 locales; a
/// choice applies at once.
class LanguageScreen extends ConsumerWidget {
  /// Creates the screen.
  const LanguageScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => LanguageLayout(
    state: ref.watch(languageControllerProvider),
    phoneLanguage: WidgetsBinding.instance.platformDispatcher.locale
        .toLanguageTag(),
    onSelect: (locale) => unawaited(
      ref.read(languageControllerProvider.notifier).select(locale),
    ),
    onBack: () => Navigator.of(context).maybePop(),
  );
}

/// The S21 layout (`docs/design/screens/S21`): "Use phone language", the
/// 12 endonyms in one group (the "App language" radio group) and the note
/// that past readings keep their language.
class LanguageLayout extends StatelessWidget {
  /// Creates the view.
  const LanguageLayout({
    required this.state,
    required this.phoneLanguage,
    required this.onSelect,
    required this.onBack,
    super.key,
  });

  /// The controller state.
  final LanguageState state;

  /// The phone's language tag ("Deutsch, from your phone settings").
  final String phoneLanguage;

  /// Selects a locale (`null` = the phone language).
  final ValueChanged<String?> onSelect;

  /// Back.
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final l10n = TaroLocalizations.of(context);
    final LanguageContent(:localeOverride, :locales) = state as LanguageContent;
    return SettingsPage(
      title: l10n.languageTitle,
      lead: l10n.languageBody,
      onBack: onBack,
      children: [
        Semantics(
          label: l10n.languageLegend,
          container: true,
          explicitChildNodes: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: context.tokens.space.s5,
            children: [
              SettingsSection(
                children: [
                  TaroRadioTile<String?>(
                    value: null,
                    groupValue: localeOverride,
                    onChanged: onSelect,
                    title: l10n.languageUsePhone,
                    subtitle: l10n.languageFromPhone(
                      languageEndonym(phoneLanguage),
                    ),
                  ),
                ],
              ),
              ExcludeSemantics(child: SettingsPageCaption(l10n.languageChoose)),
              SettingsSection(
                children: [
                  for (final locale in locales)
                    TaroRadioTile<String?>(
                      key: ValueKey(locale),
                      value: locale,
                      groupValue: localeOverride,
                      onChanged: onSelect,
                      title: languageEndonym(locale),
                    ),
                ],
              ),
            ],
          ),
        ),
        TaroInlineNotice(kind: TaroNoticeKind.info, title: l10n.languageNote),
      ],
    );
  }
}
