import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:taro/common/failure_message.dart';
import 'package:taro/features/legal/controller/legal_controller.dart';
import 'package:taro/l10n/generated/taro_localizations.dart';
import 'package:taro_core/taro_core.dart';
import 'package:taro_ui/taro_ui.dart';

/// S29 Legal (`/legal/:doc`, 01 §7.10 About): disclaimer, Terms of Use,
/// Privacy Policy and the open-source licences.
class LegalScreen extends ConsumerWidget {
  /// Creates the screen opened on [doc].
  const LegalScreen({required this.doc, super.key});

  /// The document of the route.
  final LegalDoc doc;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = legalControllerProvider(doc);
    return LegalLayout(
      state: ref.watch(provider),
      onSelect: ref.read(provider.notifier).select,
      onLicences: () => showLicensePage(
        context: context,
        applicationName: TaroLocalizations.of(context).appTitle,
      ),
      onCopyLink: (url) async {
        await Clipboard.setData(ClipboardData(text: url));
        if (context.mounted) {
          TaroToast.show(
            context,
            message: TaroLocalizations.of(context).commonCopied,
          );
        }
      },
      onBack: () => Navigator.of(context).maybePop(),
    );
  }
}

/// The S29 skeleton for one [state] (Phase 13.5; restyled in Phase 16).
class LegalLayout extends StatelessWidget {
  /// Creates the view.
  const LegalLayout({
    required this.state,
    required this.onSelect,
    required this.onLicences,
    required this.onCopyLink,
    required this.onBack,
    super.key,
  });

  /// The controller state.
  final LegalState state;

  /// Switches the document.
  final ValueChanged<LegalDoc> onSelect;

  /// Opens the licence list.
  final VoidCallback onLicences;

  /// Copies a hosted document's link.
  final ValueChanged<String> onCopyLink;

  /// Back.
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final l10n = TaroLocalizations.of(context);
    final tokens = context.tokens;
    final doc = switch (state) {
      LegalContent(:final doc) || LegalOffline(:final doc) => doc,
    };
    final children = switch (state) {
      LegalOffline(:final url) => [
        TaroErrorView(
          kind: TaroErrorKind.network,
          title: FailureMessage.title(l10n, ErrorKind.network),
          body: l10n.legalWebNote,
          secondaryAction: TaroButton.tertiary(
            label: l10n.commonCopy,
            onPressed: () => onCopyLink(url),
          ),
        ),
      ],
      LegalContent(doc: LegalDoc.disclaimer) => [
        Text(l10n.legalDisclaimerBody, style: tokens.typography.body),
      ],
      LegalContent(doc: LegalDoc.licenses) => [
        TaroButton.secondary(label: l10n.legalLicences, onPressed: onLicences),
      ],
      LegalContent(:final url) => [
        Text(l10n.legalWebNote, style: tokens.typography.body),
        if (url != null) ...[
          SelectableText(url, style: tokens.typography.caption),
          TaroButton.tertiary(
            label: l10n.commonCopy,
            onPressed: () => onCopyLink(url),
          ),
        ],
      ],
    };
    return TaroScaffold(
      appBar: TaroAppBar(
        leadingLabel: l10n.commonBack,
        onLeading: onBack,
        title: l10n.legalTitle,
      ),
      body: ListView(
        children: [
          Wrap(
            spacing: tokens.space.s3,
            runSpacing: tokens.space.s3,
            children: [
              for (final (option, label) in [
                (LegalDoc.disclaimer, l10n.legalDisclaimer),
                (LegalDoc.terms, l10n.legalTerms),
                (LegalDoc.privacy, l10n.legalPrivacy),
                (LegalDoc.licenses, l10n.legalLicences),
              ])
                TaroChip.filter(
                  label: label,
                  selected: option == doc,
                  onSelected: (_) => onSelect(option),
                ),
            ],
          ),
          SizedBox(height: tokens.space.s5),
          ...children,
        ],
      ),
    );
  }
}
