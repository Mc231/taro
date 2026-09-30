import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:taro/common/disclaimer_footer.dart';
import 'package:taro/common/spread_text.dart';
import 'package:taro/features/journal/controller/journal_entry_controller.dart';
import 'package:taro/features/journal/view/journal_labels.dart';
import 'package:taro/l10n/generated/taro_localizations.dart';
import 'package:taro/routing/routes.dart';
import 'package:taro_core/taro_core.dart';
import 'package:taro_ui/taro_ui.dart';

/// S15 Journal entry detail + note editor (01 §7.8), for the route `:id`
/// (a reading ID or a daily card's local date).
class JournalEntryScreen extends ConsumerWidget {
  /// Creates the screen for the route [id].
  const JournalEntryScreen({required this.id, super.key});

  /// The route `:id`.
  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = journalEntryControllerProvider(JournalLabels.keyOf(id));
    final state = ref.watch(provider);
    final controller = ref.read(provider.notifier);
    return JournalEntryLayout(
      state: state,
      onNoteChanged: controller.editNote,
      onToggleFavourite: () => unawaited(controller.toggleFavourite()),
      onDelete: () async {
        final l10n = TaroLocalizations.of(context);
        final confirmed = await TaroDialog.show<bool>(
          context,
          dismissible: true,
          builder: (dialog) => TaroDialog(
            title: l10n.journalDeleteTitle,
            body: l10n.journalDeleteBody,
            actions: [
              TaroButton.secondary(
                label: l10n.commonCancel,
                onPressed: () => Navigator.of(dialog).pop(false),
              ),
              TaroButton.destructive(
                label: l10n.commonDelete,
                onPressed: () => Navigator.of(dialog).pop(true),
              ),
            ],
          ),
        );
        if (confirmed ?? false) await controller.delete();
      },
      onUndo: () => unawaited(controller.undo()),
      onFinish: (readingId) => unawaited(
        context.push<void>(JournalLabels.finishLocation(readingId)),
      ),
      onFullReading: (reading) => unawaited(
        context.push<void>(
          RoutePaths.reading(
            reading.id.value,
            classic: reading.status is ReadingStatusClassic,
          ),
        ),
      ),
      onBack: () => Navigator.of(context).maybePop(),
      onRetry: () => ref.invalidate(provider),
    );
  }
}

/// The S15 skeleton for one [state] (Phase 13.5; restyled in Phase 16).
/// The short disclaimer closes every state (05 §3).
class JournalEntryLayout extends StatelessWidget {
  /// Creates the view.
  const JournalEntryLayout({
    required this.state,
    required this.onNoteChanged,
    required this.onToggleFavourite,
    required this.onDelete,
    required this.onUndo,
    required this.onFinish,
    required this.onFullReading,
    required this.onBack,
    required this.onRetry,
    super.key,
  });

  /// The controller state.
  final JournalEntryState state;

  /// The note editor changed.
  final ValueChanged<String> onNoteChanged;

  /// The favourite toggle.
  final VoidCallback onToggleFavourite;

  /// "Delete entry" (asks first).
  final VoidCallback onDelete;

  /// Undo of the deletion.
  final VoidCallback onUndo;

  /// "Finish reading" / "Try again" with the same cards.
  final ValueChanged<ReadingId> onFinish;

  /// "Full reading" (S09 / S32).
  final ValueChanged<Reading> onFullReading;

  /// Back to the list.
  final VoidCallback onBack;

  /// Retries after a storage error.
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = TaroLocalizations.of(context);
    final children = switch (state) {
      JournalEntryLoading() => [
        TaroLoadingView(
          semanticsLabel: l10n.commonLoading,
          layout: TaroLoadingLayout.text,
          itemCount: 2,
        ),
      ],
      JournalEntryContent(:final view) => _entry(context, view),
      JournalEntryPending(:final view) => [
        _finishNotice(l10n, view, l10n.entryPendingNotice),
        ..._entry(context, view),
      ],
      JournalEntryFailed(:final view) => [
        _finishNotice(l10n, view, l10n.entryFailedNotice),
        ..._entry(context, view),
      ],
      JournalEntryDeleted() => [
        TaroEmptyView(
          title: l10n.journalDeleted,
          largeTitle: false,
          action: TaroButton.secondary(
            label: l10n.commonUndo,
            onPressed: onUndo,
          ),
          secondaryAction: TaroButton.tertiary(
            label: l10n.commonBack,
            onPressed: onBack,
          ),
        ),
      ],
      JournalEntryNotFound() => [
        TaroEmptyView(
          title: l10n.readingNotFound,
          largeTitle: false,
          action: TaroButton.secondary(
            label: l10n.commonBack,
            onPressed: onBack,
          ),
        ),
      ],
      JournalEntryStorageError() => [
        TaroErrorView(
          kind: TaroErrorKind.storage,
          title: l10n.errorStorageTitle,
          body: l10n.errorStorageBody,
          onRetry: onRetry,
          retryLabel: l10n.commonRetry,
        ),
      ],
    };
    return TaroScaffold(
      appBar: TaroAppBar(
        leadingLabel: l10n.commonBack,
        onLeading: onBack,
        title: l10n.journalTitle,
      ),
      body: ListView(children: [...children, const DisclaimerFooter()]),
    );
  }

  Widget _finishNotice(
    TaroLocalizations l10n,
    JournalEntryView view,
    String title,
  ) {
    final item = view.item;
    return TaroInlineNotice(
      kind: TaroNoticeKind.warning,
      title: title,
      actions: [
        if (item case JournalReadingItem(:final reading))
          TaroButton.primary(
            label: state is JournalEntryPending
                ? l10n.journalFinishReading
                : l10n.commonRetry,
            onPressed: () => onFinish(reading.id),
          ),
      ],
    );
  }

  List<Widget> _entry(BuildContext context, JournalEntryView view) {
    final l10n = TaroLocalizations.of(context);
    final tokens = context.tokens;
    final item = view.item;
    final status = JournalLabels.status(item);
    final reading = switch (item) {
      JournalReadingItem(:final reading) => reading,
      JournalDailyCardItem() => null,
    };
    return [
      Semantics(
        header: true,
        child: Text(
          JournalLabels.title(l10n, item),
          style: tokens.typography.title,
        ),
      ),
      Text(
        l10n.commonItemSeparator(
          JournalLabels.statusLabel(l10n, status),
          JournalLabels.meta(l10n, item),
        ),
        style: tokens.typography.caption,
      ),
      SizedBox(height: tokens.space.s5),
      if (reading != null)
        for (final card in reading.cards)
          TaroListTile(
            title: SpreadText.positionName(
              l10n,
              reading.spreadId,
              card.positionId,
            ),
            subtitle: card.reversed ? l10n.commonReversed : l10n.commonUpright,
          ),
      if (reading?.content case final content?) ...[
        Text(content.title, style: tokens.typography.titleSmall),
        Text(content.summary, style: tokens.typography.body),
      ],
      if (reading != null &&
          (status == JournalEntryTileStatus.ai ||
              status == JournalEntryTileStatus.classic))
        TaroButton.secondary(
          label: l10n.entryFullReading,
          onPressed: () => onFullReading(reading),
        ),
      SizedBox(height: tokens.space.s5),
      _NoteEditor(view: view, onChanged: onNoteChanged),
      Wrap(
        spacing: tokens.space.s3,
        children: [
          TaroButton.tertiary(
            label: view.favourite
                ? l10n.commonUnfavourite
                : l10n.commonFavourite,
            onPressed: onToggleFavourite,
          ),
          if (view.canDelete)
            TaroButton.tertiary(label: l10n.entryDelete, onPressed: onDelete),
        ],
      ),
    ];
  }
}

/// The note editor: seeded once with the stored note, then owned by the
/// user's typing (autosaved by the controller).
class _NoteEditor extends StatefulWidget {
  const _NoteEditor({required this.view, required this.onChanged});

  final JournalEntryView view;
  final ValueChanged<String> onChanged;

  @override
  State<_NoteEditor> createState() => _NoteEditorState();
}

class _NoteEditorState extends State<_NoteEditor> {
  late final TextEditingController _text = TextEditingController(
    text: widget.view.note,
  );

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = TaroLocalizations.of(context);
    return TaroTextField(
      controller: _text,
      style: TaroTextFieldStyle.multiLine,
      label: l10n.commonYourNote,
      hintText: l10n.commonNoteHint,
      maxGraphemes: kJournalNoteMaxChars,
      counterFormatter: l10n.commonNoteCounter,
      statusText: switch (widget.view.noteStatus) {
        NoteStatus.saved => l10n.commonSavedOnDevice,
        NoteStatus.editing => l10n.commonSaving,
        NoteStatus.failed => l10n.failureStorage,
      },
      onChanged: widget.onChanged,
    );
  }
}
