import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:taro/common/bidi.dart';
import 'package:taro/common/inline_markdown.dart';
import 'package:taro/common/settings_page.dart';
import 'package:taro/di/providers.dart';
import 'package:taro/features/help/controller/faq_controller.dart';
import 'package:taro/l10n/generated/taro_localizations.dart';
import 'package:taro/routing/routes.dart';
import 'package:taro_ui/taro_ui.dart';

/// S28 Help & FAQ (01 §7.10): the bundled FAQ with a local search and the
/// Contact support card (Support ID, RC43; mailto with app version, OS and
/// locale).
class FaqScreen extends ConsumerWidget {
  /// Creates the screen.
  const FaqScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(faqControllerProvider.notifier);
    final links = ref.read(urlLauncherProvider);
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
      onEmail: (support) {
        final l10n = TaroLocalizations.of(context);
        unawaited(
          links.open(
            support.mailto(
              subject: l10n.helpEmailSubject(support.supportId),
              body: l10n.helpEmailBody(
                '${support.appVersion} (${support.buildNumber})',
                '${support.platform.name} ${support.osVersion}',
                support.locale,
                support.supportId,
              ),
            ),
          ),
        );
      },
      onMoveReadings: () => context.go(RoutePaths.settings),
      onSupportLines: () =>
          unawaited(context.push<void>(RoutePaths.helpCrisis)),
      onBack: () => Navigator.of(context).maybePop(),
      onRetry: () => ref.invalidate(faqControllerProvider),
    );
  }
}

/// The S28 layout for one [state] (`docs/design/screens/S28`): search, the
/// FAQ accordion, Support lines and the Contact support card.
class FaqLayout extends StatelessWidget {
  /// Creates the view.
  const FaqLayout({
    required this.state,
    required this.onSearch,
    required this.onToggle,
    required this.onCopy,
    required this.onEmail,
    required this.onMoveReadings,
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

  /// Copies the Support ID.
  final ValueChanged<String> onCopy;

  /// "Email support" (mailto with the Support ID and diagnostics).
  final ValueChanged<SupportInfo> onEmail;

  /// "Move readings from another device" (the S20 row, RC84).
  final VoidCallback onMoveReadings;

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
    final search = TaroTextField(
      style: TaroTextFieldStyle.search,
      hintText: l10n.helpSearchHint,
      label: l10n.helpSearchHint,
      clearLabel: l10n.commonDismiss,
      onChanged: onSearch,
    );
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
        search,
        TaroEmptyView(
          title: l10n.helpSearchEmpty(query),
          largeTitle: false,
          action: support == null
              ? null
              : TaroButton.primary(
                  label: l10n.helpEmailSupport,
                  onPressed: () => onEmail(support),
                ),
        ),
      ],
      FaqContent(:final sections, :final expanded, :final support) => [
        search,
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: tokens.space.s3,
          children: [
            SettingsPageCaption(l10n.helpCommonQuestions),
            for (final section in sections)
              for (final entry in section.entries)
                TaroAccordion(
                  key: ValueKey(entry.title),
                  title: entry.title,
                  expanded: expanded.contains(entry.title),
                  onExpansionChanged: (_) => onToggle(entry.title),
                  child: _Answer(entry: entry, onMoveReadings: onMoveReadings),
                ),
          ],
        ),
        SettingsSection(
          children: [
            SettingsTile(
              leading: Icon(
                Icons.favorite_border_rounded,
                size: tokens.size.icon.md,
                color: tokens.color.status.error,
              ),
              title: l10n.settingsSupportLines,
              subtitle: l10n.settingsSupportLinesSubtitle,
              onTap: onSupportLines,
            ),
          ],
        ),
        if (support != null) _contact(context, support),
      ],
    };
    return SettingsPage(
      title: l10n.helpTitle,
      onBack: onBack,
      children: children,
    );
  }

  Widget _contact(BuildContext context, SupportInfo support) {
    final l10n = TaroLocalizations.of(context);
    final tokens = context.tokens;
    final c = tokens.color;
    TextStyle label() =>
        tokens.typography.caption.copyWith(color: c.text.secondary);
    TextStyle value() => tokens.typography.body.copyWith(color: c.text.primary);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: tokens.space.s3,
      children: [
        SettingsPageCaption(l10n.helpContactHeading),
        DecoratedBox(
          decoration: BoxDecoration(
            color: c.bg.surface,
            borderRadius: BorderRadius.circular(tokens.radius.lg),
          ),
          child: Padding(
            padding: EdgeInsetsDirectional.all(tokens.space.s5),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: tokens.space.s5,
              children: [
                MergeSemantics(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: tokens.space.s1,
                    children: [
                      Text(l10n.helpEmail, style: label()),
                      Text(ltrIsolate(support.email), style: value()),
                    ],
                  ),
                ),
                Row(
                  spacing: tokens.space.s4,
                  children: [
                    Expanded(
                      child: MergeSemantics(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          spacing: tokens.space.s1,
                          children: [
                            Text(l10n.helpSupportIdLabel, style: label()),
                            Text(
                              ltrIsolate(support.supportId),
                              style: value(),
                            ),
                          ],
                        ),
                      ),
                    ),
                    TaroButton.secondary(
                      label: l10n.settingsCopyId,
                      semanticsLabel: l10n.settingsCopyIdSemantics(
                        support.supportId,
                      ),
                      expand: false,
                      onPressed: () => onCopy(support.supportId),
                    ),
                  ],
                ),
                TaroButton.primary(
                  label: l10n.helpEmailSupport,
                  expand: true,
                  onPressed: () => onEmail(support),
                ),
              ],
            ),
          ),
        ),
        Text(
          l10n.settingsSupportIdCaption,
          style: tokens.typography.caption.copyWith(color: c.text.secondary),
        ),
      ],
    );
  }
}

/// One FAQ answer: its paragraphs (inline Markdown) and, when it talks
/// about moving readings, the "Move readings from another device" link.
class _Answer extends StatelessWidget {
  const _Answer({required this.entry, required this.onMoveReadings});

  final ArticleEntry entry;
  final VoidCallback onMoveReadings;

  @override
  Widget build(BuildContext context) {
    final l10n = TaroLocalizations.of(context);
    final tokens = context.tokens;
    final style = tokens.typography.label.copyWith(
      color: tokens.color.text.secondary,
    );
    final link = l10n.settingsMoveReadings;
    final mentionsTransfer = entry.paragraphs.any(
      (p) => p.toLowerCase().contains(link.toLowerCase()),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: tokens.space.s3,
      children: [
        for (final paragraph in entry.paragraphs)
          Text.rich(inlineMarkdown(paragraph, style)),
        if (mentionsTransfer)
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TaroButton.tertiary(
              label: link,
              expand: false,
              onPressed: onMoveReadings,
            ),
          ),
      ],
    );
  }
}
