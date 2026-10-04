import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:taro/common/checklist_panel.dart';
import 'package:taro/common/failure_message.dart';
import 'package:taro/common/settings_page.dart';
import 'package:taro/features/settings/controller/delete_data_controller.dart';
import 'package:taro/l10n/generated/taro_localizations.dart';
import 'package:taro/routing/routes.dart';
import 'package:taro_ui/taro_ui.dart';

/// S26 Delete all data (01 §7.10, RC37): what is erased, what is kept (the
/// readings balance and Remove Banner Ads), then a typed confirmation.
class DeleteDataScreen extends ConsumerWidget {
  /// Creates the screen.
  const DeleteDataScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(deleteDataControllerProvider.notifier);
    final word = TaroLocalizations.of(context).deleteConfirmWord;
    return DeleteDataLayout(
      state: ref.watch(deleteDataControllerProvider),
      onTyped: (typed) => controller.updateTyped(typed, word: word),
      onDelete: () => unawaited(controller.delete()),
      onRetry: controller.retry,
      onExport: () => unawaited(context.push<void>(RoutePaths.settingsExport)),
      onDone: () => context.go(RoutePaths.home),
      onBack: () => Navigator.of(context).maybePop(),
    );
  }
}

/// The S26 layout for one [state] (`docs/design/screens/S26`): what is
/// erased, what is kept (RC37), the typed confirmation (`confirm1` →
/// `confirm2`, pinned above the buttons it unlocks), then the wipe and its
/// result.
class DeleteDataLayout extends StatelessWidget {
  /// Creates the view.
  const DeleteDataLayout({
    required this.state,
    required this.onTyped,
    required this.onDelete,
    required this.onRetry,
    required this.onExport,
    required this.onDone,
    required this.onBack,
    super.key,
  });

  /// The controller state.
  final DeleteDataState state;

  /// The confirmation field changed.
  final ValueChanged<String> onTyped;

  /// "Delete all data" (enabled in `confirm2` only).
  final VoidCallback onDelete;

  /// Back to the confirmation after a failure.
  final VoidCallback onRetry;

  /// "Export a backup" first.
  final VoidCallback onExport;

  /// "Done" after the wipe (→ Home).
  final VoidCallback onDone;

  /// Back / Cancel (disabled while deleting).
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final l10n = TaroLocalizations.of(context);
    final tokens = context.tokens;
    final done = TaroButton.primary(
      label: l10n.commonDone,
      expand: true,
      onPressed: onDone,
    );
    Widget result(Widget child) => TaroScaffold(
      appBar: TaroAppBar(leadingLabel: l10n.commonBack, onLeading: onBack),
      body: child,
    );
    return switch (state) {
      DeleteDataConfirm1(:final summary) => _confirm(
        context,
        summary,
        enabled: false,
      ),
      DeleteDataConfirm2(:final summary) => _confirm(
        context,
        summary,
        enabled: true,
      ),
      DeleteDataDeleting() => _confirm(context, null, enabled: false),
      DeleteDataDone() => result(
        TaroEmptyView(
          title: l10n.deleteDoneTitle,
          body: l10n.deleteDoneBody,
          action: done,
        ),
      ),
      DeleteDataPartial() => result(
        ListView(
          padding: EdgeInsetsDirectional.only(top: tokens.space.s7),
          children: [
            TaroEmptyView(
              title: l10n.deleteDoneTitle,
              body: l10n.deleteDoneBody,
              action: done,
            ),
            SizedBox(height: tokens.space.s5),
            TaroInlineNotice(
              kind: TaroNoticeKind.warning,
              title: l10n.deletePartial,
              liveRegion: true,
            ),
          ],
        ),
      ),
      DeleteDataFailed(:final kind) => result(
        TaroErrorView(
          kind: FailureMessage.visual(kind),
          title: l10n.deleteFailed,
          body: FailureMessage.body(l10n, kind),
          onRetry: onRetry,
          retryLabel: l10n.commonRetry,
        ),
      ),
    };
  }

  /// The page; [summary] is `null` while deleting (the panels stay as they
  /// were drawn, so the last summary is not needed for the busy frame).
  Widget _confirm(
    BuildContext context,
    DeleteDataSummary? summary, {
    required bool enabled,
  }) {
    final l10n = TaroLocalizations.of(context);
    final tokens = context.tokens;
    final deleting = summary == null;
    return SettingsPage(
      title: l10n.deleteTitle,
      lead: l10n.deleteBody,
      onBack: onBack,
      busy: deleting,
      footer: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: tokens.space.s3,
        children: [
          // BUG-09: the typed confirmation is pinned with the buttons it
          // unlocks, so it is never below the fold or behind them, and the
          // scaffold lifts it above the keyboard.
          if (summary != null)
            TaroTextField(
              label: l10n.deleteConfirmLabel(l10n.deleteConfirmWord),
              textCapitalization: TextCapitalization.characters,
              onChanged: onTyped,
            ),
          TaroButton.destructive(
            label: l10n.deleteButton,
            expand: true,
            loading: deleting,
            onPressed: enabled ? onDelete : null,
          ),
          TaroButton.secondary(
            label: l10n.commonCancel,
            expand: true,
            onPressed: deleting ? null : onBack,
          ),
        ],
      ),
      children: [
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: TaroButton.tertiary(
            label: l10n.deleteExportFirst,
            expand: false,
            onPressed: deleting ? null : onExport,
          ),
        ),
        if (summary != null) ...[
          ChecklistPanel(
            title: l10n.deleteErasedHeading,
            included: false,
            items: [
              ChecklistItem(l10n.deleteErasedJournal(summary.journalEntries)),
              ChecklistItem(l10n.deleteErasedNotes),
              ChecklistItem(l10n.deleteErasedSettings),
              ChecklistItem(l10n.deleteErasedServer),
            ],
          ),
          ChecklistPanel(
            title: l10n.deleteKeptHeading,
            included: true,
            accent: true,
            footer: l10n.deleteKeptCaption,
            items: [
              ChecklistItem(
                l10n.deleteKeptBalance(
                  l10n.balanceReadings(summary.readingsKept),
                ),
              ),
              if (summary.removeAdsKept)
                ChecklistItem(l10n.deleteKeptRemoveAds),
            ],
          ),
        ],
      ],
    );
  }
}
