import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:taro/common/disclaimer_footer.dart';
import 'package:taro/di/providers.dart';
import 'package:taro/features/learn/controller/about_controller.dart';
import 'package:taro/features/learn/view/learn_top_bar.dart';
import 'package:taro/l10n/generated/taro_localizations.dart';
import 'package:taro/routing/routes.dart';
import 'package:taro_ui/taro_ui.dart';

/// S19 About tarot & Taro (01 §7.9): the bundled article, the support
/// lines link and the disclaimer.
class AboutScreen extends ConsumerWidget {
  /// Creates the screen.
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => AboutLayout(
    state: ref.watch(aboutControllerProvider),
    onBack: () => Navigator.of(context).maybePop(),
    onSupport: () => unawaited(context.push<void>(RoutePaths.helpCrisis)),
    onRetry: () => ref.invalidate(aboutControllerProvider),
  );
}

/// The S19 view for one [state].
class AboutLayout extends StatelessWidget {
  /// Creates the view.
  const AboutLayout({
    required this.state,
    required this.onBack,
    required this.onSupport,
    required this.onRetry,
    super.key,
  });

  /// The controller state.
  final AboutState state;

  /// Back.
  final VoidCallback onBack;

  /// "Support and crisis lines" (→ S27).
  final VoidCallback onSupport;

  /// Retries after a storage error.
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = TaroLocalizations.of(context);
    final tokens = context.tokens;
    final body = switch (state) {
      AboutLoading() => TaroLoadingView(
        semanticsLabel: l10n.commonLoading,
        layout: TaroLoadingLayout.text,
      ),
      AboutStorageError() => TaroErrorView(
        kind: TaroErrorKind.storage,
        title: l10n.errorStorageTitle,
        body: l10n.errorStorageBody,
        onRetry: onRetry,
        retryLabel: l10n.commonRetry,
      ),
      AboutContent(:final article) => ListView(
        padding: EdgeInsetsDirectional.only(
          top: tokens.space.s3,
          bottom: tokens.space.s7,
        ),
        children: [
          Align(
            alignment: AlignmentDirectional.topStart,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: tokens.layout.readingMaxWidth,
              ),
              child: ArticleBody(
                article: article,
                fallbackTitle: l10n.learnAbout,
              ),
            ),
          ),
          SizedBox(height: tokens.space.s6),
          SettingsSection(
            children: [
              SettingsTile(
                leading: Icon(
                  Icons.favorite_border_rounded,
                  size: tokens.size.icon.md,
                  color: tokens.color.accent.primary,
                ),
                title: l10n.aboutSupportLines,
                onTap: onSupport,
              ),
            ],
          ),
          const DisclaimerFooter(centered: true),
        ],
      ),
    };
    return TaroScaffold(
      appBar: LearnTopBar(onBack: onBack, caption: l10n.learnTitle),
      body: body,
    );
  }
}

/// A bundled [Article]: the title (`type.headline`), then each section's
/// heading (`type.titleSmall`, a header) and paragraphs (`type.bodyReading`).
class ArticleBody extends StatelessWidget {
  /// Creates the body.
  const ArticleBody({
    required this.article,
    this.fallbackTitle,
    super.key,
  });

  /// The article.
  final Article article;

  /// The title when the article has none.
  final String? fallbackTitle;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final c = tokens.color;
    final title = article.title.isNotEmpty ? article.title : fallbackTitle;
    final paragraph = tokens.typography.bodyReading.copyWith(
      color: c.text.primary,
    );
    final heading = tokens.typography.titleSmall.copyWith(
      color: c.text.primary,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: tokens.space.s3,
      children: [
        if (title != null) TaroLargeTitle(title),
        for (final section in article.sections) ...[
          if (section.heading.isNotEmpty)
            Padding(
              padding: EdgeInsetsDirectional.only(top: tokens.space.s3),
              child: Semantics(
                header: true,
                child: Text(section.heading, style: heading),
              ),
            ),
          for (final text in section.paragraphs) Text(text, style: paragraph),
          for (final entry in section.entries) ...[
            Semantics(
              header: true,
              child: Text(
                entry.title,
                style: tokens.typography.label.copyWith(
                  color: c.text.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            for (final text in entry.paragraphs) Text(text, style: paragraph),
          ],
        ],
      ],
    );
  }
}
