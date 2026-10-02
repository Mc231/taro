import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:taro/common/bidi.dart';
import 'package:taro/common/failure_message.dart';
import 'package:taro/common/settings_page.dart';
import 'package:taro/di/providers.dart';
import 'package:taro/features/backup/controller/import_controller.dart';
import 'package:taro/l10n/generated/taro_localizations.dart';
import 'package:taro/routing/routes.dart';
import 'package:taro_core/taro_core.dart';
import 'package:taro_ui/taro_ui.dart';

/// S25 Import backup (01 §7.11, F5): pick → validate → preview (with the
/// "balance not included" line) → Merge or Replace (Replace asks first in
/// a dialog) → progress → result.
class ImportScreen extends ConsumerWidget {
  /// Creates the screen.
  const ImportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(importControllerProvider.notifier);
    final listing = ref.watch(storeLinksProvider).listing;
    ref.listen(importControllerProvider, (previous, next) async {
      if (next is! ImportConfirmReplace || previous is ImportConfirmReplace) {
        return;
      }
      final l10n = TaroLocalizations.of(context);
      final replace = await TaroDialog.show<bool>(
        context,
        dismissible: true,
        builder: (dialog) => TaroDialog(
          title: l10n.importConfirmReplaceTitle,
          body: l10n.importConfirmReplaceBody(next.localEntries),
          actions: [
            TaroButton.destructive(
              label: l10n.importConfirmReplaceAction,
              onPressed: () => Navigator.of(dialog).pop(true),
            ),
            TaroButton.secondary(
              label: l10n.commonCancel,
              onPressed: () => Navigator.of(dialog).pop(false),
            ),
          ],
        ),
      );
      if (replace ?? false) {
        await controller.confirmReplace();
      } else {
        controller.cancelReplace();
      }
    });
    return ImportLayout(
      state: ref.watch(importControllerProvider),
      onPick: () => unawaited(controller.pick()),
      onReset: controller.reset,
      onMode: controller.setMode,
      onConfirm: () => unawaited(controller.confirm()),
      onOpenJournal: () => context.go(RoutePaths.journal),
      onBack: () => Navigator.of(context).maybePop(),
      onUpdateApp: listing == null
          ? null
          : () => unawaited(ref.read(urlLauncherProvider).open(listing)),
    );
  }
}

/// The S25 layout for one [state] (`docs/design/screens/S25`).
class ImportLayout extends StatelessWidget {
  /// Creates the view.
  const ImportLayout({
    required this.state,
    required this.onPick,
    required this.onReset,
    required this.onMode,
    required this.onConfirm,
    required this.onOpenJournal,
    required this.onBack,
    this.onUpdateApp,
    super.key,
  });

  /// The controller state.
  final ImportState state;

  /// "Choose a file" / "Choose another file" (the OS picker).
  final VoidCallback onPick;

  /// Retry after a failure (back to `picking`).
  final VoidCallback onReset;

  /// Merge or Replace.
  final ValueChanged<MergeMode> onMode;

  /// "Import".
  final VoidCallback onConfirm;

  /// "Open Journal" after the import.
  final VoidCallback onOpenJournal;

  /// Back / "Back to Settings" (disabled while importing).
  final VoidCallback onBack;

  /// Opens the store listing (`invalid(newerVersion)`); `null` hides it.
  final VoidCallback? onUpdateApp;

  @override
  Widget build(BuildContext context) {
    final l10n = TaroLocalizations.of(context);
    final tokens = context.tokens;
    final c = tokens.color;
    Widget caption(String text) => Text(
      text,
      textAlign: TextAlign.center,
      style: tokens.typography.caption.copyWith(color: c.text.secondary),
    );
    Widget footer(Widget primary, Widget below) => Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: tokens.space.s3,
      children: [primary, below],
    );
    final chooseFile = TaroButton.primary(
      label: l10n.importChooseFile,
      expand: true,
      onPressed: onPick,
    );
    final (List<Widget> children, Widget? bottom) = switch (state) {
      ImportPicking() => (
        const <Widget>[],
        footer(chooseFile, caption(l10n.importBalanceNote)),
      ),
      ImportValidating() => (
        [
          _FileCard(
            title: l10n.importChosenFile,
            status: _CardStatus.checking(l10n.importValidating),
          ),
        ],
        null,
      ),
      ImportInvalid(:final reason) => (
        [
          _FileCard(
            title: l10n.importChosenFile,
            status: _CardStatus.error(
              switch (reason) {
                ImportInvalidReason.notTaro => l10n.importInvalidNotTaro,
                ImportInvalidReason.newerVersion =>
                  l10n.importInvalidNewerVersion,
                ImportInvalidReason.corrupt => l10n.importInvalidCorrupt,
                ImportInvalidReason.tooLarge => l10n.importInvalidTooLarge,
              },
              switch (reason) {
                ImportInvalidReason.notTaro => l10n.importInvalidNotTaroBody,
                ImportInvalidReason.newerVersion =>
                  l10n.importInvalidNewerVersionBody,
                ImportInvalidReason.corrupt => l10n.importInvalidCorruptBody,
                ImportInvalidReason.tooLarge => l10n.importInvalidTooLargeBody,
              },
            ),
            action: reason == ImportInvalidReason.newerVersion
                ? onUpdateApp
                : null,
            actionLabel: l10n.updateButton,
          ),
          Semantics(
            header: true,
            child: Text(
              l10n.importTryHeading,
              style: tokens.typography.titleSmall.copyWith(
                color: c.text.primary,
              ),
            ),
          ),
          for (final tip in [l10n.importTry1, l10n.importTry2, l10n.importTry3])
            _Bullet(tip),
          TaroInlineNotice(
            kind: TaroNoticeKind.success,
            title: l10n.importNothingChanged,
          ),
        ],
        footer(
          TaroButton.primary(
            label: l10n.importChooseAnother,
            expand: true,
            onPressed: onPick,
          ),
          TaroButton.secondary(
            label: l10n.importBackToSettings,
            expand: true,
            onPressed: onBack,
          ),
        ),
      ),
      ImportPreviewing(:final preview, :final mode) => _preview(
        context,
        preview,
        mode,
      ),
      ImportConfirmReplace(:final preview) => _preview(
        context,
        preview,
        MergeMode.replace,
      ),
      ImportImporting(:final progress) => (
        [
          Semantics(
            label: l10n.importImporting,
            value: NumberFormat.percentPattern(
              l10n.localeName,
            ).format(progress),
            liveRegion: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: tokens.space.s3,
              children: [
                ExcludeSemantics(
                  child: Text(
                    l10n.importImporting,
                    style: tokens.typography.titleSmall.copyWith(
                      color: c.text.primary,
                    ),
                  ),
                ),
                ClipRRect(
                  borderRadius: BorderRadius.circular(tokens.radius.full),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: tokens.space.s2,
                    color: c.accent.primary,
                    backgroundColor: c.bg.sunken,
                  ),
                ),
              ],
            ),
          ),
        ],
        null,
      ),
      ImportDone(:final readings, :final dailyCards) => (
        [
          TaroEmptyView(
            title: l10n.importDone(readings, dailyCards),
            largeTitle: false,
            action: TaroButton.primary(
              label: l10n.importOpenJournal,
              onPressed: onOpenJournal,
            ),
          ),
        ],
        null,
      ),
      ImportFailed(:final kind) => (
        [
          TaroErrorView(
            kind: FailureMessage.visual(kind),
            title: l10n.importFailed,
            body: FailureMessage.body(l10n, kind),
            onRetry: onReset,
            retryLabel: l10n.commonRetry,
          ),
        ],
        null,
      ),
    };
    return SettingsPage(
      title: l10n.importTitle,
      lead: l10n.importBody,
      onBack: onBack,
      busy: state is ImportImporting,
      footer: bottom,
      children: children,
    );
  }

  (List<Widget>, Widget?) _preview(
    BuildContext context,
    ImportPreview preview,
    MergeMode mode,
  ) {
    final l10n = TaroLocalizations.of(context);
    final tokens = context.tokens;
    final exported = preview.backup.exportedAt.toLocal();
    return (
      [
        _FileCard(
          title: BackupV1.fileName(LocalDates.format(exported)),
          subtitle: l10n.importExportedOn(
            DateFormat.yMMMMd(l10n.localeName).format(exported),
          ),
          summary: l10n.importSummary(preview.readings, preview.dailyCards),
          status: _CardStatus.ok(l10n.importChecked),
        ),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: TaroButton.tertiary(
            label: l10n.importChooseAnother,
            expand: false,
            onPressed: onPick,
          ),
        ),
        Semantics(
          label: l10n.importModeLegend,
          container: true,
          explicitChildNodes: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: tokens.space.s3,
            children: [
              ExcludeSemantics(
                child: SettingsPageCaption(l10n.importModeLegend),
              ),
              TaroRadioTile<MergeMode>(
                value: MergeMode.merge,
                groupValue: mode,
                onChanged: onMode,
                style: TaroRadioTileStyle.card,
                title: l10n.importMerge,
                subtitle: l10n.importMergeBody,
              ),
              TaroRadioTile<MergeMode>(
                value: MergeMode.replace,
                groupValue: mode,
                onChanged: onMode,
                style: TaroRadioTileStyle.card,
                title: l10n.importReplace,
                subtitle: l10n.importReplaceBody,
              ),
            ],
          ),
        ),
      ],
      Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: tokens.space.s3,
        children: [
          TaroButton.primary(
            label: l10n.importButton,
            expand: true,
            onPressed: onConfirm,
          ),
          Text(
            l10n.importBalanceNote,
            textAlign: TextAlign.center,
            style: tokens.typography.caption.copyWith(
              color: tokens.color.text.secondary,
            ),
          ),
        ],
      ),
    );
  }
}

enum _StatusKind { checking, ok, error }

/// The status row of a [_FileCard].
final class _CardStatus {
  const _CardStatus.checking(this.title)
    : body = null,
      kind = _StatusKind.checking;
  const _CardStatus.ok(this.title) : body = null, kind = _StatusKind.ok;
  const _CardStatus.error(this.title, this.body) : kind = _StatusKind.error;

  final String title;
  final String? body;
  final _StatusKind kind;
}

/// The S25 file summary card (`FileSummaryCard`): an icon tile, the file
/// name (bidi-isolated LTR), the export date and the summary, a divider,
/// then the check status (`role=status`). One screen-reader node.
class _FileCard extends StatelessWidget {
  const _FileCard({
    required this.title,
    required this.status,
    this.subtitle,
    this.summary,
    this.action,
    this.actionLabel,
  });

  final String title;
  final String? subtitle;
  final String? summary;
  final _CardStatus status;
  final VoidCallback? action;
  final String? actionLabel;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final c = tokens.color;
    final error = status.kind == _StatusKind.error;
    final iconSide = tokens.space.s10;
    final subtitle = this.subtitle;
    final summary = this.summary;
    final action = this.action;
    final statusColor = switch (status.kind) {
      _StatusKind.ok => c.status.success,
      _StatusKind.error => c.status.error,
      _StatusKind.checking => c.text.secondary,
    };
    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.bg.surface,
        borderRadius: BorderRadius.circular(tokens.radius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MergeSemantics(
            child: Padding(
              padding: EdgeInsetsDirectional.all(tokens.space.s5),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: tokens.space.s4,
                children: [
                  ExcludeSemantics(
                    child: Container(
                      width: iconSide,
                      height: iconSide,
                      decoration: BoxDecoration(
                        color: error ? c.bg.sunken : c.accent.subtle,
                        borderRadius: BorderRadius.circular(tokens.radius.card),
                      ),
                      child: Icon(
                        Icons.description_outlined,
                        size: tokens.size.icon.md,
                        color: error ? c.text.secondary : c.accent.primary,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: tokens.space.s1,
                      children: [
                        Text(
                          ltrIsolate(title),
                          style: tokens.typography.label.copyWith(
                            color: c.text.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (subtitle != null)
                          Text(
                            subtitle,
                            style: tokens.typography.caption.copyWith(
                              color: c.text.secondary,
                            ),
                          ),
                        if (summary != null) ...[
                          SizedBox(height: tokens.space.s2),
                          Text(
                            summary,
                            style: tokens.typography.label.copyWith(
                              color: c.text.primary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Divider(
            height: TaroStrokes.hairline,
            thickness: TaroStrokes.hairline,
            color: c.border.subtle,
          ),
          Semantics(
            liveRegion: true,
            container: true,
            child: Padding(
              padding: EdgeInsetsDirectional.all(tokens.space.s5),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: tokens.space.s4,
                children: [
                  ExcludeSemantics(
                    child: Icon(
                      switch (status.kind) {
                        _StatusKind.ok => Icons.check_rounded,
                        _StatusKind.error => Icons.error_outline_rounded,
                        _StatusKind.checking => Icons.hourglass_empty_rounded,
                      },
                      size: tokens.size.icon.md,
                      color: statusColor,
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      spacing: tokens.space.s2,
                      children: [
                        Text(
                          status.title,
                          style: tokens.typography.label.copyWith(
                            color: statusColor,
                            fontWeight: error ? FontWeight.w600 : null,
                          ),
                        ),
                        if (status.body case final body?)
                          Text(
                            body,
                            style: tokens.typography.label.copyWith(
                              color: c.text.secondary,
                            ),
                          ),
                        if (status.kind == _StatusKind.checking)
                          LinearProgressIndicator(
                            minHeight: tokens.space.s1,
                            color: c.accent.primary,
                            backgroundColor: c.bg.sunken,
                          ),
                        if (action != null)
                          Align(
                            alignment: AlignmentDirectional.centerStart,
                            child: TaroButton.tertiary(
                              label: actionLabel ?? '',
                              expand: false,
                              onPressed: action,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A tip of the invalid state: an accent dot and the text.
class _Bullet extends StatelessWidget {
  const _Bullet(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final c = tokens.color;
    final dot = tokens.space.s2;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: tokens.space.s4,
      children: [
        Padding(
          padding: EdgeInsetsDirectional.only(top: tokens.space.s3),
          child: ExcludeSemantics(
            child: Container(
              width: dot,
              height: dot,
              decoration: BoxDecoration(
                color: c.accent.primary,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
        Expanded(
          child: Text(
            text,
            style: tokens.typography.body.copyWith(color: c.text.secondary),
          ),
        ),
      ],
    );
  }
}
