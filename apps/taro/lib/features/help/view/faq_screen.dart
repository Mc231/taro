import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:taro/di/providers.dart';
import 'package:taro/features/help/controller/faq_controller.dart';
import 'package:taro/l10n/generated/taro_localizations.dart';
import 'package:taro/routing/routes.dart';
import 'package:taro_ui/taro_ui.dart';

/// S28 Help & FAQ (01 §7.10): the bundled FAQ with a local search and the
/// Contact support card (Support ID, RC43).
class FaqScreen extends ConsumerWidget {
  /// Creates the screen.
  const FaqScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(faqControllerProvider.notifier);
    return FaqLayout(
      state: ref.watch(faqControllerProvider),
      onSearch: controller.search,
      onToggle: controller.toggle,
      onCopy: (text) async {
        await Clipboard.setData(ClipboardData(text: text));
        if (context.mounted) {
          TaroToast.show(
            context,
            message: TaroLocalizations.of(context).commonCopied,
          );
        }
      },
      onSupportLines: () =>
          unawaited(context.push<void>(RoutePaths.helpCrisis)),
      onBack: () => Navigator.of(context).maybePop(),
      onRetry: () => ref.invalidate(faqControllerProvider),
    );
  }
}

/// The S28 skeleton for one [state] (Phase 13.5; restyled in Phase 16).
class FaqLayout extends StatelessWidget {
  /// Creates the view.
  const FaqLayout({
    required this.state,
    required this.onSearch,
    required this.onToggle,
    required this.onCopy,
    required this.onSupportLines,
    required this.onBack,
    required this.onRetry,
    super.key,
  });

  /// The controller state.
  final FaqState state;

  /// The search text changed.
  final ValueChanged<String> onSearch;

  /// Expands or collapses a question.
  final ValueChanged<String> onToggle;

  /// Copies the support address or the Support ID.
  final ValueChanged<String> onCopy;

  /// "Support lines" (S27).
  final VoidCallback onSupportLines;

  /// Back.
  final VoidCallback onBack;

  /// Retries after a storage error.
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = TaroLocalizations.of(context);
    final tokens = context.tokens;
    final searchable = switch (state) {
      FaqContent() || FaqSearchEmpty() => true,
      _ => false,
    };
    final children = switch (state) {
      FaqLoading() => [
        TaroLoadingView(
          semanticsLabel: l10n.commonLoading,
          layout: TaroLoadingLayout.text,
        ),
      ],
      FaqStorageError() => [
        TaroErrorView(
          kind: TaroErrorKind.storage,
          title: l10n.errorStorageTitle,
          body: l10n.errorStorageBody,
          onRetry: onRetry,
          retryLabel: l10n.commonRetry,
        ),
      ],
      FaqSearchEmpty(:final query, :final support) => [
        TaroEmptyView(title: l10n.helpSearchEmpty(query), largeTitle: false),
        _contact(context, support),
      ],
      FaqContent(:final sections, :final expanded, :final support) => [
        Semantics(
          header: true,
          child: Text(
            l10n.helpCommonQuestions,
            style: tokens.typography.titleSmall,
          ),
        ),
        for (final section in sections) ...[
          if (section.heading.isNotEmpty)
            Text(section.heading, style: tokens.typography.label),
          for (final entry in section.entries)
            TaroAccordion(
              key: ValueKey(entry.title),
              title: entry.title,
              expanded: expanded.contains(entry.title),
              onExpansionChanged: (_) => onToggle(entry.title),
              child: Text(
                entry.paragraphs.join('\n\n'),
                style: tokens.typography.body,
              ),
            ),
        ],
        _contact(context, support),
      ],
    };
    return TaroScaffold(
      appBar: TaroAppBar(
        leadingLabel: l10n.commonBack,
        onLeading: onBack,
        title: l10n.helpTitle,
      ),
      body: ListView(
        children: [
          if (searchable)
            TaroTextField(
              style: TaroTextFieldStyle.search,
              hintText: l10n.helpSearchHint,
              clearLabel: l10n.commonDismiss,
              onChanged: onSearch,
            ),
          ...children,
        ],
      ),
    );
  }

  Widget _contact(BuildContext context, SupportInfo? support) {
    final l10n = TaroLocalizations.of(context);
    return SettingsSection(
      title: l10n.helpContactHeading,
      footer: l10n.settingsSupportIdCaption,
      children: [
        if (support != null) ...[
          SettingsTile(
            title: l10n.helpEmail,
            value: support.email,
            onTap: () => onCopy(support.email),
          ),
          SettingsTile(
            title: l10n.settingsSupportId(support.supportId),
            value: l10n.settingsCopyId,
            onTap: () => onCopy(support.supportId),
          ),
        ],
        SettingsTile(title: l10n.settingsSupportLines, onTap: onSupportLines),
      ],
    );
  }
}
