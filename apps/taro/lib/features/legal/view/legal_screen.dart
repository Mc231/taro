import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:taro/common/bidi.dart';
import 'package:taro/common/failure_message.dart';
import 'package:taro/common/legal_links.dart';
import 'package:taro/common/settings_page.dart';
import 'package:taro/di/providers.dart';
import 'package:taro/features/legal/controller/legal_controller.dart';
import 'package:taro/l10n/generated/taro_localizations.dart';
import 'package:taro/routing/routes.dart';
import 'package:taro_core/taro_core.dart';
import 'package:taro_ui/taro_ui.dart';

/// S29 Legal (`/legal/:doc`, 01 §7.10 About): disclaimer, Terms of Use,
/// Privacy Policy (in the in-app browser, CS10) and the open-source
/// licences.
class LegalScreen extends ConsumerWidget {
  /// Creates the screen opened on [doc].
  const LegalScreen({required this.doc, super.key});

  /// The document of the route.
  final LegalDoc doc;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = legalControllerProvider(doc);
    final links = ref.read(urlLauncherProvider);
    return LegalLayout(
      state: ref.watch(provider),
      onSelect: ref.read(provider.notifier).select,
      onLicences: () => showLicensePage(
        context: context,
        applicationName: TaroLocalizations.of(context).appTitle,
      ),
      // In the app language (`?hl=`); no in-app browser: the system one.
      onOpenWeb: (url) =>
          unawaited(openLegalUrl(links, url, Localizations.localeOf(context))),
      onOpenBrowser: (url) => unawaited(
        links.open(localizedLegalUri(url, Localizations.localeOf(context))),
      ),
      onSupportLines: () =>
          unawaited(context.push<void>(RoutePaths.helpCrisis)),
      onBack: () => Navigator.of(context).maybePop(),
    );
  }
}

/// The version and effective date of the bundled disclaimer (05 §3).
const String kDisclaimerVersion = '1';

/// When [kDisclaimerVersion] took effect.
final DateTime kDisclaimerEffective = DateTime.utc(2026, 10);

/// The S29 layout for one [state] (`docs/design/screens/S29`): the document
/// tabs, the article panel and the footer caption.
class LegalLayout extends StatelessWidget {
  /// Creates the view.
  const LegalLayout({
    required this.state,
    required this.onSelect,
    required this.onLicences,
    required this.onOpenWeb,
    required this.onOpenBrowser,
    required this.onSupportLines,
    required this.onBack,
    super.key,
  });

  /// The controller state.
  final LegalState state;

  /// Switches the document.
  final ValueChanged<LegalDoc> onSelect;

  /// Opens the licence list.
  final VoidCallback onLicences;

  /// Opens a hosted document in the in-app browser.
  final ValueChanged<String> onOpenWeb;

  /// Opens a hosted document in the system browser (offline fallback).
  final ValueChanged<String> onOpenBrowser;

  /// "Find a support line" (S27).
  final VoidCallback onSupportLines;

  /// Back.
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final l10n = TaroLocalizations.of(context);
    final tokens = context.tokens;
    final c = tokens.color;
    final doc = switch (state) {
      LegalContent(:final doc) || LegalOffline(:final doc) => doc,
    };
    final reading = tokens.typography.bodyReading;
    final secondary = reading.copyWith(color: c.text.secondary);
    final body = switch (state) {
      LegalOffline(:final url) => TaroErrorView(
        kind: TaroErrorKind.network,
        title: FailureMessage.title(l10n, ErrorKind.network),
        body: FailureMessage.body(l10n, ErrorKind.network),
        secondaryAction: TaroButton.tertiary(
          label: l10n.legalOpenInBrowser,
          onPressed: () => onOpenBrowser(url),
        ),
      ),
      LegalContent(doc: LegalDoc.disclaimer) => _Article(
        title: l10n.disclaimerOnboardingTitle,
        caption: l10n.legalVersion(
          kDisclaimerVersion,
          DateFormat.yMMMMd(l10n.localeName).format(kDisclaimerEffective),
        ),
        children: [
          Text(
            l10n.disclaimerOnboardingBody,
            style: reading.copyWith(color: c.text.primary),
          ),
          Text(l10n.disclaimerNoticeAi, style: secondary),
          Text(l10n.legalDisclaimerBody, style: secondary),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TaroButton.tertiary(
              label: l10n.legalSupportLine,
              expand: false,
              onPressed: onSupportLines,
            ),
          ),
        ],
      ),
      LegalContent(doc: LegalDoc.licenses) => _Article(
        title: l10n.legalLicences,
        children: [
          Text(l10n.legalLicencesBody, style: secondary),
          TaroButton.secondary(
            label: l10n.legalViewLicences,
            expand: true,
            onPressed: onLicences,
          ),
        ],
      ),
      LegalContent(:final doc, :final url) => _Article(
        title: doc == LegalDoc.terms ? l10n.legalTerms : l10n.legalPrivacy,
        caption: url == null ? null : ltrIsolate(url),
        children: [
          Text(l10n.legalWebBody, style: secondary),
          TaroButton.primary(
            label: l10n.legalReadOnline,
            icon: Icons.open_in_new_rounded,
            expand: true,
            onPressed: url == null ? null : () => onOpenWeb(url),
          ),
        ],
      ),
    };
    const docs = LegalDoc.values;
    return SettingsPage(
      title: l10n.legalTitle,
      onBack: onBack,
      children: [
        TaroTabStrip(
          labels: [
            for (final d in docs)
              switch (d) {
                LegalDoc.disclaimer => l10n.legalDisclaimer,
                LegalDoc.terms => l10n.legalTerms,
                LegalDoc.privacy => l10n.legalPrivacy,
                LegalDoc.licenses => l10n.legalLicences,
              },
          ],
          selectedIndex: docs.indexOf(doc),
          onSelected: (i) => onSelect(docs[i]),
        ),
        AnimatedSwitcher(
          duration: context.reduceMotion
              ? context.motion.duration.instant
              : context.motion.duration.fast,
          child: KeyedSubtree(key: ValueKey(doc), child: body),
        ),
        Text(
          l10n.legalWebNote,
          textAlign: TextAlign.center,
          style: tokens.typography.caption.copyWith(color: c.text.secondary),
        ),
      ],
    );
  }
}

/// The S29 article panel (`color.bg.surface`, `radius.lg`): a serif
/// heading, an optional caption, then the [children]; text is capped at
/// `layout.readingMaxWidth`.
class _Article extends StatelessWidget {
  const _Article({required this.title, required this.children, this.caption});

  final String title;
  final String? caption;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final c = tokens.color;
    final caption = this.caption;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.bg.surface,
        borderRadius: BorderRadius.circular(tokens.radius.lg),
      ),
      child: Padding(
        padding: EdgeInsetsDirectional.symmetric(
          horizontal: tokens.space.s6,
          vertical: tokens.space.s6,
        ),
        child: Align(
          alignment: AlignmentDirectional.topStart,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: tokens.layout.readingMaxWidth,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: tokens.space.s4,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: tokens.space.s1,
                  children: [
                    Semantics(
                      header: true,
                      child: Text(
                        title,
                        style: tokens.typography.cardName.copyWith(
                          color: c.text.primary,
                        ),
                      ),
                    ),
                    if (caption != null)
                      Text(
                        caption,
                        style: tokens.typography.caption.copyWith(
                          color: c.text.secondary,
                        ),
                      ),
                  ],
                ),
                ...children,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
