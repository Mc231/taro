import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:taro/common/failure_message.dart';
import 'package:taro/features/backup/controller/export_controller.dart';
import 'package:taro/l10n/generated/taro_localizations.dart';
import 'package:taro_ui/taro_ui.dart';

/// S24 Export backup (01 §7.11, F5): what is and is not in the file, then
/// the OS share sheet. Works offline.
class ExportScreen extends ConsumerWidget {
  /// Creates the screen.
  const ExportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => ExportLayout(
    state: ref.watch(exportControllerProvider),
    onExport: () =>
        unawaited(ref.read(exportControllerProvider.notifier).export()),
    onBack: () => Navigator.of(context).maybePop(),
  );
}

/// The S24 skeleton for one [state] (Phase 13.5; restyled in Phase 16).
class ExportLayout extends StatelessWidget {
  /// Creates the view.
  const ExportLayout({
    required this.state,
    required this.onExport,
    required this.onBack,
    super.key,
  });

  /// The controller state.
  final ExportState state;

  /// "Export backup" / Retry.
  final VoidCallback onExport;

  /// Back.
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final l10n = TaroLocalizations.of(context);
    final tokens = context.tokens;
    final busy = state is ExportPreparing || state is ExportShareSheetOpen;
    return TaroScaffold(
      appBar: TaroAppBar(
        leadingLabel: l10n.commonBack,
        onLeading: onBack,
        title: l10n.exportTitle,
      ),
      body: ListView(
        children: [
          Text(l10n.exportBody, style: tokens.typography.body),
          SizedBox(height: tokens.space.s5),
          Semantics(
            header: true,
            child: Text(
              l10n.exportIncluded,
              style: tokens.typography.titleSmall,
            ),
          ),
          Text(l10n.exportJournal),
          Text(l10n.exportNotes),
          Text(l10n.exportFavourites),
          Text(l10n.exportSettings),
          SizedBox(height: tokens.space.s5),
          Semantics(
            header: true,
            child: Text(
              l10n.exportNotIncluded,
              style: tokens.typography.titleSmall,
            ),
          ),
          TaroListTile(
            title: l10n.exportBalance,
            subtitle: l10n.exportBalanceCaption,
          ),
          TaroListTile(
            title: l10n.exportConsent,
            subtitle: l10n.exportConsentCaption,
          ),
          SizedBox(height: tokens.space.s5),
          ...switch (state) {
            ExportIdle() ||
            ExportPreparing() ||
            ExportShareSheetOpen() => const <Widget>[],
            ExportDone(:final entries) => [
              TaroInlineNotice(
                kind: TaroNoticeKind.success,
                title: l10n.exportDoneTitle,
                body: l10n.commonItemSeparator(
                  l10n.exportJournalCount(entries),
                  l10n.exportDoneBody,
                ),
                liveRegion: true,
              ),
            ],
            ExportFailed(:final kind) => [
              TaroInlineNotice(
                kind: TaroNoticeKind.warning,
                title: l10n.exportFailed,
                body: FailureMessage.body(l10n, kind),
                liveRegion: true,
              ),
            ],
          },
          TaroButton.primary(
            label: switch (state) {
              ExportPreparing() => l10n.exportPreparing,
              ExportFailed() => l10n.commonRetry,
              _ => l10n.exportButton,
            },
            loading: state is ExportPreparing,
            onPressed: busy ? null : onExport,
          ),
          Text(l10n.exportButtonCaption, style: tokens.typography.caption),
        ],
      ),
    );
  }
}
