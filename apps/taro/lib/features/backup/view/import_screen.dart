import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:taro/common/failure_message.dart';
import 'package:taro/features/backup/controller/import_controller.dart';
import 'package:taro/l10n/generated/taro_localizations.dart';
import 'package:taro/routing/routes.dart';
import 'package:taro_core/taro_core.dart';
import 'package:taro_ui/taro_ui.dart';

/// S25 Import backup (01 §7.11, F5): pick → validate → preview (with the
/// "balance not included" line) → Merge or Replace → progress → result.
class ImportScreen extends ConsumerWidget {
  /// Creates the screen.
  const ImportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(importControllerProvider.notifier);
    return ImportLayout(
      state: ref.watch(importControllerProvider),
      onPick: () => unawaited(controller.pick()),
      onReset: controller.reset,
      onMode: controller.setMode,
      onConfirm: () => unawaited(controller.confirm()),
      onConfirmReplace: () => unawaited(controller.confirmReplace()),
      onCancelReplace: controller.cancelReplace,
      onOpenJournal: () => context.go(RoutePaths.journal),
      onBack: () => Navigator.of(context).maybePop(),
    );
  }
}

/// The S25 skeleton for one [state] (Phase 13.5; restyled in Phase 16).
class ImportLayout extends StatelessWidget {
  /// Creates the view.
  const ImportLayout({
    required this.state,
    required this.onPick,
    required this.onReset,
    required this.onMode,
    required this.onConfirm,
    required this.onConfirmReplace,
    required this.onCancelReplace,
    required this.onOpenJournal,
    required this.onBack,
    super.key,
  });

  /// The controller state.
  final ImportState state;

  /// "Choose a file".
  final VoidCallback onPick;

  /// "Choose another file" / Retry.
  final VoidCallback onReset;

  /// Merge or Replace.
  final ValueChanged<MergeMode> onMode;

  /// "Import".
  final VoidCallback onConfirm;

  /// "Replace" in the confirmation.
  final VoidCallback onConfirmReplace;

  /// "Cancel" in the confirmation.
  final VoidCallback onCancelReplace;

  /// "Open Journal" after the import.
  final VoidCallback onOpenJournal;

  /// Back (disabled while importing).
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final l10n = TaroLocalizations.of(context);
    final tokens = context.tokens;
    final importing = state is ImportImporting;
    final chooseAnother = TaroButton.secondary(
      label: l10n.importChooseAnother,
      onPressed: onReset,
    );
    final children = switch (state) {
      ImportPicking() => [
        TaroButton.primary(label: l10n.importChooseFile, onPressed: onPick),
      ],
      ImportValidating() => [
        TaroLoadingView(
          semanticsLabel: l10n.importValidating,
          layout: TaroLoadingLayout.text,
          itemCount: 1,
        ),
      ],
      ImportInvalid(:final reason) => [
        TaroErrorView(
          kind: TaroErrorKind.invalidFile,
          title: switch (reason) {
            ImportInvalidReason.notTaro => l10n.importInvalidNotTaro,
            ImportInvalidReason.newerVersion => l10n.importInvalidNewerVersion,
            ImportInvalidReason.corrupt => l10n.importInvalidCorrupt,
            ImportInvalidReason.tooLarge => l10n.importInvalidTooLarge,
          },
          body: l10n.errorInvalidFileBody,
          secondaryAction: chooseAnother,
        ),
      ],
      ImportPreviewing(:final preview, :final mode) => [
        TaroInlineNotice(
          kind: TaroNoticeKind.success,
          title: l10n.importChecked,
        ),
        Text(
          l10n.importSummary(preview.readings, preview.dailyCards),
          style: tokens.typography.titleSmall,
        ),
        Text(
          l10n.importExportedOn(
            DateFormat.yMMMd(
              l10n.localeName,
            ).format(preview.backup.exportedAt.toLocal()),
          ),
          style: tokens.typography.caption,
        ),
        TaroInlineNotice(
          kind: TaroNoticeKind.info,
          title: l10n.importBalanceNote,
        ),
        Semantics(
          header: true,
          child: Text(l10n.importModeLegend, style: tokens.typography.label),
        ),
        TaroRadioTile<MergeMode>(
          value: MergeMode.merge,
          groupValue: mode,
          onChanged: onMode,
          title: l10n.importMerge,
          subtitle: l10n.importMergeBody,
        ),
        TaroRadioTile<MergeMode>(
          value: MergeMode.replace,
          groupValue: mode,
          onChanged: onMode,
          title: l10n.importReplace,
          subtitle: l10n.importReplaceBody,
        ),
        TaroButton.primary(label: l10n.importButton, onPressed: onConfirm),
        chooseAnother,
      ],
      ImportConfirmReplace(:final localEntries) => [
        TaroDialog(
          title: l10n.importConfirmReplaceTitle,
          body: l10n.importConfirmReplaceBody(localEntries),
          actions: [
            TaroButton.secondary(
              label: l10n.commonCancel,
              onPressed: onCancelReplace,
            ),
            TaroButton.destructive(
              label: l10n.importConfirmReplaceAction,
              onPressed: onConfirmReplace,
            ),
          ],
        ),
      ],
      ImportImporting(:final progress) => [
        Text(l10n.importImporting, style: tokens.typography.titleSmall),
        Semantics(
          label: l10n.importImporting,
          value: NumberFormat.percentPattern(
            l10n.localeName,
          ).format(progress),
          child: LinearProgressIndicator(value: progress),
        ),
      ],
      ImportDone(:final readings, :final dailyCards) => [
        TaroEmptyView(
          title: l10n.importDone(readings, dailyCards),
          largeTitle: false,
          action: TaroButton.primary(
            label: l10n.importOpenJournal,
            onPressed: onOpenJournal,
          ),
        ),
      ],
      ImportFailed(:final kind) => [
        TaroErrorView(
          kind: FailureMessage.visual(kind),
          title: l10n.importFailed,
          body: FailureMessage.body(l10n, kind),
          onRetry: onReset,
          retryLabel: l10n.commonRetry,
        ),
      ],
    };
    return PopScope(
      canPop: !importing,
      child: TaroScaffold(
        appBar: TaroAppBar(
          leading: importing ? TaroAppBarLeading.none : TaroAppBarLeading.back,
          leadingLabel: l10n.commonBack,
          onLeading: onBack,
          title: l10n.importTitle,
        ),
        body: ListView(
          children: [
            Text(l10n.importBody, style: tokens.typography.body),
            SizedBox(height: tokens.space.s5),
            ...children,
          ],
        ),
      ),
    );
  }
}
