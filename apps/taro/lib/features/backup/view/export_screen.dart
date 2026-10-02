import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:taro/common/bidi.dart';
import 'package:taro/common/checklist_panel.dart';
import 'package:taro/common/failure_message.dart';
import 'package:taro/common/settings_page.dart';
import 'package:taro/di/providers.dart';
import 'package:taro/features/backup/controller/export_controller.dart';
import 'package:taro/l10n/generated/taro_localizations.dart';
import 'package:taro_core/taro_core.dart';
import 'package:taro_ui/taro_ui.dart';

/// S24 Export backup (01 §7.11, F5): what is and is not in the file, then
/// the OS share sheet. Works offline.
class ExportScreen extends ConsumerWidget {
  /// Creates the screen.
  const ExportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => ExportLayout(
    state: ref.watch(exportControllerProvider),
    fileName: BackupV1.fileName(
      LocalDates.format(ref.read(clockProvider).nowLocal()),
    ),
    onExport: () =>
        unawaited(ref.read(exportControllerProvider.notifier).export()),
    onBack: () => Navigator.of(context).maybePop(),
  );
}

/// The S24 layout for one [state] (`docs/design/screens/S24`): the
/// Included and Not included panels, the file name, the `done` / `failed`
/// notice and the pinned Export button.
class ExportLayout extends StatelessWidget {
  /// Creates the view.
  const ExportLayout({
    required this.state,
    required this.fileName,
    required this.onExport,
    required this.onBack,
    super.key,
  });

  /// The controller state.
  final ExportState state;

  /// `taro-backup-YYYY-MM-DD.json` for today.
  final String fileName;

  /// "Export backup" / Retry.
  final VoidCallback onExport;

  /// Back.
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final l10n = TaroLocalizations.of(context);
    final tokens = context.tokens;
    final c = tokens.color;
    final busy = state is ExportPreparing || state is ExportShareSheetOpen;
    final failed = state is ExportFailed;
    return SettingsPage(
      title: l10n.exportTitle,
      lead: l10n.exportBody,
      onBack: onBack,
      footer: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: tokens.space.s3,
        children: [
          TaroButton.primary(
            label: switch (state) {
              ExportPreparing() => l10n.exportPreparing,
              _ => l10n.exportButton,
            },
            expand: true,
            loading: state is ExportPreparing,
            onPressed: busy ? null : onExport,
          ),
          Text(
            l10n.exportButtonCaption,
            textAlign: TextAlign.center,
            style: tokens.typography.caption.copyWith(color: c.text.secondary),
          ),
        ],
      ),
      children: [
        ChecklistPanel(
          title: l10n.exportIncluded,
          included: true,
          items: [
            ChecklistItem(
              l10n.exportJournal,
              value: switch (state) {
                ExportDone(:final entries) => l10n.exportJournalCount(entries),
                _ => null,
              },
            ),
            ChecklistItem(l10n.exportNotes),
            ChecklistItem(l10n.exportFavourites),
            ChecklistItem(l10n.exportSettings),
          ],
        ),
        ChecklistPanel(
          title: l10n.exportNotIncluded,
          included: false,
          items: [
            ChecklistItem(
              l10n.exportBalance,
              caption: l10n.exportBalanceCaption,
            ),
            ChecklistItem(
              l10n.exportConsent,
              caption: l10n.exportConsentCaption,
            ),
          ],
        ),
        _FileNameChip(fileName: fileName),
        if (state is ExportDone)
          TaroInlineNotice(
            kind: TaroNoticeKind.success,
            title: l10n.exportDoneTitle,
            body: l10n.exportDoneBody,
            liveRegion: true,
          ),
        if (state case ExportFailed(:final kind))
          TaroInlineNotice(
            kind: TaroNoticeKind.error,
            title: l10n.exportFailed,
            body: FailureMessage.body(l10n, kind),
            liveRegion: true,
            actions: [
              TaroButton.tertiary(
                label: l10n.commonRetry,
                onPressed: failed ? onExport : null,
              ),
            ],
          ),
      ],
    );
  }
}

/// The export file name (`color.bg.sunken`, `radius.md`, a file icon); the
/// name is bidi-isolated LTR.
class _FileNameChip extends StatelessWidget {
  const _FileNameChip({required this.fileName});

  final String fileName;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final c = tokens.color;
    return Container(
      constraints: BoxConstraints(
        minHeight: tokens.size.touchTarget.min + tokens.space.s1,
      ),
      padding: EdgeInsetsDirectional.symmetric(
        horizontal: tokens.space.s5,
        vertical: tokens.space.s3,
      ),
      decoration: BoxDecoration(
        color: c.bg.sunken,
        borderRadius: BorderRadius.circular(tokens.radius.md),
      ),
      child: Row(
        spacing: tokens.space.s4,
        children: [
          ExcludeSemantics(
            child: Icon(
              Icons.description_outlined,
              size: tokens.size.icon.md,
              color: c.text.secondary,
            ),
          ),
          Expanded(
            child: Text(
              ltrIsolate(fileName),
              style: tokens.typography.label.copyWith(color: c.text.primary),
            ),
          ),
        ],
      ),
    );
  }
}
