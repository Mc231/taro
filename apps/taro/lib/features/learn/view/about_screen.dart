import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:taro/common/disclaimer_footer.dart';
import 'package:taro/di/providers.dart';
import 'package:taro/features/learn/controller/about_controller.dart';
import 'package:taro/l10n/generated/taro_localizations.dart';
import 'package:taro_ui/taro_ui.dart';

/// S19 About tarot & Taro (01 §7.9): the bundled article and the
/// disclaimer.
class AboutScreen extends ConsumerWidget {
  /// Creates the screen.
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => AboutLayout(
    state: ref.watch(aboutControllerProvider),
    onBack: () => Navigator.of(context).maybePop(),
    onRetry: () => ref.invalidate(aboutControllerProvider),
  );
}

/// The S19 skeleton for one [state] (Phase 13.5; restyled in Phase 16).
class AboutLayout extends StatelessWidget {
  /// Creates the view.
  const AboutLayout({
    required this.state,
    required this.onBack,
    required this.onRetry,
    super.key,
  });

  /// The controller state.
  final AboutState state;

  /// Back.
  final VoidCallback onBack;

  /// Retries after a storage error.
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = TaroLocalizations.of(context);
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
        children: [
          ArticleBody(article: article),
          const DisclaimerFooter(),
        ],
      ),
    };
    return TaroScaffold(
      appBar: TaroAppBar(
        leadingLabel: l10n.commonBack,
        onLeading: onBack,
        title: l10n.learnAbout,
      ),
      body: body,
    );
  }
}

/// A bundled [Article] as plain text blocks (the inline Markdown is kept
/// as authored until Phase 16 renders it).
class ArticleBody extends StatelessWidget {
  /// Creates the body.
  const ArticleBody({required this.article, super.key});

  /// The article.
  final Article article;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (article.title.isNotEmpty)
          Semantics(
            header: true,
            child: Text(article.title, style: tokens.typography.title),
          ),
        for (final section in article.sections) ...[
          if (section.heading.isNotEmpty)
            Padding(
              padding: EdgeInsetsDirectional.only(top: tokens.space.s5),
              child: Semantics(
                header: true,
                child: Text(
                  section.heading,
                  style: tokens.typography.titleSmall,
                ),
              ),
            ),
          for (final paragraph in section.paragraphs)
            Text(paragraph, style: tokens.typography.body),
          for (final entry in section.entries) ...[
            Text(entry.title, style: tokens.typography.label),
            for (final paragraph in entry.paragraphs)
              Text(paragraph, style: tokens.typography.body),
          ],
        ],
      ],
    );
  }
}
