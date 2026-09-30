import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

/// The S21 skeleton for one [state] (Phase 13.5; restyled in Phase 16).
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
    final tokens = context.tokens;
    final LanguageContent(:localeOverride, :locales) = state as LanguageContent;
    return TaroScaffold(
      appBar: TaroAppBar(
        leadingLabel: l10n.commonBack,
        onLeading: onBack,
        title: l10n.languageTitle,
      ),
      body: ListView(
        children: [
          Text(l10n.languageBody, style: tokens.typography.body),
          SizedBox(height: tokens.space.s5),
          TaroRadioTile<String?>(
            value: null,
            groupValue: localeOverride,
            onChanged: onSelect,
            title: l10n.languageUsePhone,
            subtitle: l10n.languageFromPhone(languageEndonym(phoneLanguage)),
          ),
          SizedBox(height: tokens.space.s5),
          Semantics(
            header: true,
            child: Text(l10n.languageChoose, style: tokens.typography.label),
          ),
          for (final locale in locales)
            TaroRadioTile<String?>(
              key: ValueKey(locale),
              value: locale,
              groupValue: localeOverride,
              onChanged: onSelect,
              title: languageEndonym(locale),
            ),
          SizedBox(height: tokens.space.s5),
          Text(l10n.languageNote, style: tokens.typography.caption),
        ],
      ),
    );
  }
}
