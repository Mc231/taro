import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:taro/common/failure_message.dart';
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

/// The S26 skeleton for one [state] (Phase 13.5; restyled in Phase 16).
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

  /// Back (disabled while deleting).
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final l10n = TaroLocalizations.of(context);
    final deleting = state is DeleteDataDeleting;
    final done = TaroButton.primary(label: l10n.commonDone, onPressed: onDone);
    final body = switch (state) {
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
      DeleteDataDeleting() => TaroLoadingView(
        semanticsLabel: l10n.commonLoading,
        layout: TaroLoadingLayout.text,
        itemCount: 1,
      ),
      DeleteDataDone() => TaroEmptyView(
        title: l10n.deleteDoneTitle,
        body: l10n.deleteDoneBody,
        action: done,
      ),
      DeleteDataPartial() => TaroEmptyView(
        title: l10n.deleteDoneTitle,
        body: '${l10n.deletePartial}\n${l10n.deleteDoneBody}',
        action: done,
      ),
      DeleteDataFailed(:final kind) => TaroErrorView(
        kind: FailureMessage.visual(kind),
        title: l10n.deleteFailed,
        body: FailureMessage.body(l10n, kind),
        onRetry: onRetry,
        retryLabel: l10n.commonRetry,
      ),
    };
    return PopScope(
      canPop: !deleting,
      child: TaroScaffold(
        appBar: TaroAppBar(
          leading: deleting ? TaroAppBarLeading.none : TaroAppBarLeading.back,
          leadingLabel: l10n.commonBack,
          onLeading: onBack,
          title: l10n.deleteTitle,
        ),
        body: body,
      ),
    );
  }

  Widget _confirm(
    BuildContext context,
    DeleteDataSummary summary, {
    required bool enabled,
  }) {
    final l10n = TaroLocalizations.of(context);
    final tokens = context.tokens;
    return ListView(
      children: [
        Text(l10n.deleteBody, style: tokens.typography.body),
        TaroButton.tertiary(label: l10n.deleteExportFirst, onPressed: onExport),
        SizedBox(height: tokens.space.s5),
        Semantics(
          header: true,
          child: Text(
            l10n.deleteErasedHeading,
            style: tokens.typography.titleSmall,
          ),
        ),
        Text(l10n.deleteErasedJournal(summary.journalEntries)),
        Text(l10n.deleteErasedNotes),
        Text(l10n.deleteErasedSettings),
        Text(l10n.deleteErasedServer),
        SizedBox(height: tokens.space.s5),
        Semantics(
          header: true,
          child: Text(
            l10n.deleteKeptHeading,
            style: tokens.typography.titleSmall,
          ),
        ),
        Text(
          l10n.deleteKeptBalance(l10n.balanceReadings(summary.readingsKept)),
        ),
        if (summary.removeAdsKept) Text(l10n.deleteKeptRemoveAds),
        Text(l10n.deleteKeptCaption, style: tokens.typography.caption),
        SizedBox(height: tokens.space.s5),
        TaroTextField(
          label: l10n.deleteConfirmLabel(l10n.deleteConfirmWord),
          textCapitalization: TextCapitalization.characters,
          onChanged: onTyped,
        ),
        SizedBox(height: tokens.space.s5),
        TaroButton.destructive(
          label: l10n.deleteButton,
          onPressed: enabled ? onDelete : null,
        ),
      ],
    );
  }
}
