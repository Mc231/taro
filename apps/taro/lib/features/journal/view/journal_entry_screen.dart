import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:taro/common/card_art.dart';
import 'package:taro/common/disclaimer_footer.dart';
import 'package:taro/common/reading_mini_spread.dart';
import 'package:taro/common/reading_share_sheet.dart';
import 'package:taro/common/share_reading_use_case.dart';
import 'package:taro/common/spread_text.dart';
import 'package:taro/features/journal/controller/journal_content.dart';
import 'package:taro/features/journal/controller/journal_entry_controller.dart';
import 'package:taro/features/journal/view/journal_dialogs.dart';
import 'package:taro/features/journal/view/journal_labels.dart';
import 'package:taro/l10n/generated/taro_localizations.dart';
import 'package:taro/routing/routes.dart';
import 'package:taro_core/taro_core.dart';
import 'package:taro_ui/taro_ui.dart';

/// S15 Journal entry detail + note editor (01 §7.8; canvas
/// `JournalEntry`), for the route `:id` (a reading ID or a daily card's
/// local date). [prompt] (query `prompt`) is the S09 reflection prompt that
/// "Write about this" adds to the note as a heading.
///
/// Delete asks first, then pops back with an "Entry deleted" toast whose
/// Undo works for 5 s (the controller is kept alive while the toast shows).
/// No banner (04 §8).
class JournalEntryScreen extends ConsumerStatefulWidget {
  /// Creates the screen for the route [id].
  const JournalEntryScreen({required this.id, this.prompt, super.key});

  /// The route `:id`.
  final String id;

  /// The reflection prompt to pre-fill into the note.
  final String? prompt;

  @override
  ConsumerState<JournalEntryScreen> createState() => _JournalEntryScreenState();
}

class _JournalEntryScreenState extends ConsumerState<JournalEntryScreen> {
  bool _prompted = false;

  @override
  Widget build(BuildContext context) {
    final provider = journalEntryControllerProvider(
      JournalLabels.keyOf(widget.id),
    );
    ref.listen<JournalEntryState>(provider, (previous, next) {
      final prompt = widget.prompt;
      if (prompt != null && !_prompted && _viewOf(next) != null) {
        _prompted = true;
        ref.read(provider.notifier).writeAbout(prompt);
      }
      if (next is JournalEntryDeleted && previous is! JournalEntryDeleted) {
        _onDeleted(provider);
      }
    });
    final state = ref.watch(provider);
    final controller = ref.read(provider.notifier);
    final view = _viewOf(state);
    final reading = switch (view?.item) {
      JournalReadingItem(:final reading) => reading,
      _ => null,
    };
    final cards = switch (view?.item) {
      JournalReadingItem(:final reading) => [
        for (final card in reading.cards) card.cardId,
      ],
      JournalDailyCardItem(:final card) => [card.cardId],
      null => const <CardId>[],
    };
    final l10n = TaroLocalizations.of(context);
    return JournalEntryLayout(
      state: state,
      cardTexts: {
        for (final id in cards) id: ?ref.watch(cardTextProvider(id)).value,
      },
      spread: reading == null
          ? null
          : ref.watch(journalSpreadProvider(reading.spreadId)).value,
      artSet: ref.watch(deckArtSetProvider).value ?? CardArt.defaultArtSet,
      autofocusNote: widget.prompt != null,
      onNoteChanged: controller.editNote,
      onNoteDone: () => unawaited(controller.flushNote()),
      onToggleFavourite: () => unawaited(controller.toggleFavourite()),
      onShare: (includeQuestion) => unawaited(
        controller.share(
          ShareCopy(
            disclaimerLine: l10n.disclaimerShort,
            questionLabel: l10n.shareQuestionLabel,
            reversedLabel: l10n.commonReversed,
            fallbackTitle: reading == null
                ? l10n.commonDailyCard
                : SpreadText.name(l10n, reading.spreadId),
          ),
          includeQuestion: includeQuestion,
        ),
      ),
      onReport: (id) => unawaited(
        TaroModals.reportReading<void>(context, readingId: id.value),
      ),
      onDelete: () async {
        if (await confirmJournalDelete(context)) await controller.delete();
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
      onOpenDisclaimer: () =>
          unawaited(context.push(RoutePaths.legal('disclaimer'))),
      onBack: () => Navigator.of(context).maybePop(),
      onRetry: () => ref.invalidate(provider),
    );
  }

  /// Deleted: the toast offers Undo (keeping the controller alive until it
  /// goes), and the screen pops back; opened from a link with nothing to pop
  /// to, it stays on the `deleted` view.
  void _onDeleted(
    NotifierProvider<JournalEntryController, JournalEntryState> provider,
  ) {
    final container = ProviderScope.containerOf(context, listen: false);
    late final JournalUndoToast toast;
    final keepAlive = container.listen<JournalEntryState>(provider, (_, next) {
      if (next is! JournalEntryDeleted) toast.close();
    });
    toast = JournalUndoToast.show(
      context,
      onUndo: () => unawaited(container.read(provider.notifier).undo()),
    );
    unawaited(toast.closed.whenComplete(keepAlive.close));
    unawaited(Navigator.of(context).maybePop());
  }

  static JournalEntryView? _viewOf(JournalEntryState state) => switch (state) {
    JournalEntryContent(:final view) ||
    JournalEntryPending(:final view) ||
    JournalEntryFailed(:final view) => view,
    _ => null,
  };
}

/// The S15 layout for [state] (`docs/design/screens/S15/spec.md`): Back,
/// Favourite, Share and More (Report, AI readings only) in the top bar; the
/// date and spread; the mini spread (face-down while pending); the question,
/// the "AI-generated" or "Classic reading" label, title and summary with
/// "Full reading" (S09 / S32); a daily card's short meaning and reflection
/// question; the note editor (5,000 chars, autosaved); "Delete entry". The
/// short disclaimer closes every state (05 §3).
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
    this.cardTexts = const {},
    this.spread,
    this.artSet = CardArt.defaultArtSet,
    this.autofocusNote = false,
    this.onNoteDone,
    this.onShare,
    this.onReport,
    this.onOpenDisclaimer,
    super.key,
  });

  /// The controller state.
  final JournalEntryState state;

  /// The card texts of the entry (names, a daily card's meaning).
  final Map<CardId, CardText> cardTexts;

  /// The reading's spread (mini spread geometry).
  final SpreadDefinition? spread;

  /// The bundled art set.
  final String artSet;

  /// Focuses the note editor (opened by "Write about this").
  final bool autofocusNote;

  /// The note editor changed.
  final ValueChanged<String> onNoteChanged;

  /// The note editor lost focus (save now).
  final VoidCallback? onNoteDone;

  /// The favourite toggle.
  final VoidCallback onToggleFavourite;

  /// Share, with "include my question" (readings only).
  final ValueChanged<bool>? onShare;

  /// More → "Report this reading" (S33; AI readings only).
  final ValueChanged<ReadingId>? onReport;

  /// "Delete entry" (asks first).
  final VoidCallback onDelete;

  /// Undo of the deletion.
  final VoidCallback onUndo;

  /// "Finish reading" / "Try again" with the same cards.
  final ValueChanged<ReadingId> onFinish;

  /// "Full reading" (S09 / S32).
  final ValueChanged<Reading> onFullReading;

  /// The disclaimer link.
  final VoidCallback? onOpenDisclaimer;

  /// Back to the list.
  final VoidCallback onBack;

  /// Retries after a storage error.
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = TaroLocalizations.of(context);
    final tokens = context.tokens;
    final footer = DisclaimerFooter(onOpenDisclaimer: onOpenDisclaimer);
    Widget framed(Widget child) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(child: child),
        footer,
        SizedBox(height: tokens.space.s5),
      ],
    );
    final view = switch (state) {
      JournalEntryContent(:final view) ||
      JournalEntryPending(:final view) ||
      JournalEntryFailed(:final view) => view,
      _ => null,
    };
    return TaroScaffold(
      appBar: TaroAppBar(
        leadingLabel: l10n.commonBack,
        onLeading: onBack,
        actions: view == null ? const [] : _actions(context, view),
      ),
      body: switch (state) {
        JournalEntryLoading() => ListView(
          padding: EdgeInsetsDirectional.only(top: tokens.space.s4),
          children: [
            ReadingTextView.loading(loadingLabel: l10n.commonLoading),
            footer,
          ],
        ),
        JournalEntryDeleted() => framed(
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
        ),
        JournalEntryNotFound() => framed(
          TaroEmptyView(
            title: l10n.readingNotFound,
            largeTitle: false,
            action: TaroButton.secondary(
              label: l10n.commonBack,
              onPressed: onBack,
            ),
          ),
        ),
        JournalEntryStorageError() => framed(
          TaroErrorView(
            kind: TaroErrorKind.storage,
            title: l10n.errorStorageTitle,
            body: l10n.errorStorageBody,
            onRetry: onRetry,
            retryLabel: l10n.commonRetry,
          ),
        ),
        _ => _entry(context, view!, footer),
      },
    );
  }

  List<Widget> _actions(BuildContext context, JournalEntryView view) {
    final l10n = TaroLocalizations.of(context);
    final reading = switch (view.item) {
      JournalReadingItem(:final reading) => reading,
      JournalDailyCardItem() => null,
    };
    final shareable =
        reading != null &&
        state is JournalEntryContent &&
        onShare != null &&
        reading.status is! ReadingStatusRefused;
    final reportable =
        reading != null &&
        onReport != null &&
        reading.status is ReadingStatusComplete;
    return [
      TaroIconButton(
        icon: Icons.star_border_rounded,
        selectedIcon: Icons.star_rounded,
        toggled: view.favourite,
        semanticsLabel: view.favourite
            ? l10n.commonUnfavourite
            : l10n.commonFavourite,
        onPressed: onToggleFavourite,
      ),
      if (shareable)
        TaroButton.tertiary(
          label: l10n.commonShare,
          icon: Icons.ios_share,
          onPressed: () => unawaited(_share(context, reading)),
        ),
      if (reportable)
        TaroIconButton(
          icon: Icons.more_horiz,
          semanticsLabel: l10n.commonMore,
          onPressed: () => unawaited(_openMenu(context, reading)),
        ),
    ];
  }

  Future<void> _share(BuildContext context, Reading reading) async {
    final includeQuestion = await ReadingShareSheet.show(
      context,
      hasQuestion: reading.question != null,
    );
    if (includeQuestion != null) onShare?.call(includeQuestion);
  }

  /// More: "Report this reading" (S33), or "Reported" (disabled) once sent.
  Future<void> _openMenu(BuildContext context, Reading reading) async {
    final l10n = TaroLocalizations.of(context);
    final report = await TaroSheet.show<bool>(
      context,
      builder: (sheet) => TaroSheet(
        title: l10n.commonMore,
        child: TaroListTile(
          leading: const Icon(Icons.flag_outlined),
          title: reading.reported
              ? l10n.readingReported
              : l10n.reportReadingTitle,
          onTap: reading.reported ? null : () => Navigator.of(sheet).pop(true),
        ),
      ),
    );
    if (report ?? false) onReport?.call(reading.id);
  }

  Widget _entry(BuildContext context, JournalEntryView view, Widget footer) {
    final l10n = TaroLocalizations.of(context);
    final tokens = context.tokens;
    final c = tokens.color;
    final gap = SizedBox(height: tokens.space.s5);
    final item = view.item;
    final names = {
      for (final entry in cardTexts.entries) entry.key: entry.value.name,
    };
    return ListView(
      padding: EdgeInsetsDirectional.only(
        top: tokens.space.s3,
        bottom: tokens.space.s7,
      ),
      children: [
        Text(
          _meta(context, item),
          style: tokens.typography.caption.copyWith(color: c.text.tertiary),
        ),
        gap,
        ...switch (item) {
          JournalReadingItem(:final reading) => _reading(
            context,
            reading,
            names,
          ),
          JournalDailyCardItem(:final card) => _dailyCard(context, card),
        },
        footer,
        SizedBox(height: tokens.space.s7),
        _NoteEditor(
          view: view,
          autofocus: autofocusNote,
          onChanged: onNoteChanged,
          onDone: onNoteDone,
        ),
        if (view.canDelete) ...[
          SizedBox(height: tokens.space.s9),
          Center(
            child: TaroButton.tertiary(
              label: l10n.entryDelete,
              icon: Icons.delete_outline,
              onPressed: onDelete,
            ),
          ),
        ],
      ],
    );
  }

  List<Widget> _reading(
    BuildContext context,
    Reading reading,
    Map<CardId, String> names,
  ) {
    final l10n = TaroLocalizations.of(context);
    final tokens = context.tokens;
    final c = tokens.color;
    final gap = SizedBox(height: tokens.space.s4);
    final content = reading.content;
    final question = reading.question?.trim();
    final status = reading.status;
    final pending = state is JournalEntryPending;
    final failed = state is JournalEntryFailed;
    return [
      ReadingMiniSpread(
        spreadId: reading.spreadId,
        cards: reading.cards,
        names: names,
        positions: spread?.positions,
        artSet: artSet,
        cardSize: TaroCardSize.sm,
        faceDown: pending,
      ),
      gap,
      if (pending || failed) ...[
        TaroInlineNotice(
          kind: pending ? TaroNoticeKind.info : TaroNoticeKind.error,
          title: pending ? l10n.entryPendingNotice : l10n.entryFailedNotice,
          liveRegion: true,
          actions: [
            TaroButton.primary(
              label: pending ? l10n.journalFinishReading : l10n.commonRetry,
              onPressed: () => onFinish(reading.id),
            ),
          ],
        ),
        gap,
      ],
      if (question != null && question.isNotEmpty) ...[
        Text(
          l10n.readingQuestionQuoted(question),
          style: tokens.typography.caption.copyWith(color: c.text.tertiary),
        ),
        SizedBox(height: tokens.space.s3),
      ],
      if (status is ReadingStatusClassic)
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: AiGeneratedLabel.classic(
            label: l10n.classicLabel,
            explanation: l10n.classicCaption,
          ),
        )
      else if (content != null)
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: AiGeneratedLabel(label: l10n.aiLabel),
        ),
      if (content != null) ...[
        gap,
        Semantics(
          header: true,
          child: Text(
            content.title,
            style: tokens.typography.cardName.copyWith(color: c.text.primary),
          ),
        ),
        SizedBox(height: tokens.space.s3),
        Text(
          content.summary,
          style: tokens.typography.bodyReading.copyWith(
            color: c.text.primary,
          ),
        ),
      ] else if (status is ReadingStatusClassic) ...[
        gap,
        Semantics(
          header: true,
          child: Text(
            SpreadText.name(l10n, reading.spreadId),
            style: tokens.typography.cardName.copyWith(color: c.text.primary),
          ),
        ),
      ],
      if (status is ReadingStatusComplete ||
          status is ReadingStatusClassic ||
          (status is ReadingStatusRefused && content != null))
        Align(
          alignment: AlignmentDirectional.centerEnd,
          child: TaroButton.tertiary(
            label: l10n.entryFullReading,
            onPressed: () => onFullReading(reading),
          ),
        ),
    ];
  }

  List<Widget> _dailyCard(BuildContext context, DailyCard card) {
    final l10n = TaroLocalizations.of(context);
    final tokens = context.tokens;
    final c = tokens.color;
    final text = cardTexts[card.cardId];
    final name = text?.name ?? l10n.commonDailyCard;
    final question = text?.reflectionQuestions.firstOrNull;
    return [
      Center(
        child: TaroCardFace(
          image: CardArt.face(card.cardId, artSet: artSet),
          semanticsLabel: card.reversed ? l10n.readingCardReversed(name) : name,
          size: TaroCardSize.sm,
          reversed: card.reversed,
          reversedLabel: l10n.commonReversed,
        ),
      ),
      SizedBox(height: tokens.space.s5),
      Semantics(
        header: true,
        child: Text(
          name,
          style: tokens.typography.cardName.copyWith(color: c.text.primary),
        ),
      ),
      if (text != null) ...[
        SizedBox(height: tokens.space.s3),
        Text(
          card.reversed ? text.shortReversed : text.shortUpright,
          style: tokens.typography.bodyReading.copyWith(
            color: c.text.primary,
          ),
        ),
      ],
      if (question != null) ...[
        SizedBox(height: tokens.space.s5),
        Text(
          l10n.entryReflectionQuestion,
          style: tokens.typography.caption.copyWith(color: c.text.tertiary),
        ),
        SizedBox(height: tokens.space.s2),
        Text(
          question,
          style: tokens.typography.bodyReading.copyWith(
            color: c.text.secondary,
          ),
        ),
      ],
    ];
  }

  /// "Saturday, 26 September 2026 · 21:40 · Past · Present · Future" (a
  /// daily card: the date and "Daily card").
  String _meta(BuildContext context, JournalItem item) {
    final l10n = TaroLocalizations.of(context);
    final materialL10n = MaterialLocalizations.of(context);
    String day(String localDate) => DateFormat.yMMMMEEEEd(
      l10n.localeName,
    ).format(DateTime.parse(localDate));
    switch (item) {
      case JournalReadingItem(:final reading):
        final time = materialL10n.formatTimeOfDay(
          TimeOfDay.fromDateTime(reading.createdAt.toLocal()),
          alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
        );
        return [
          day(reading.localDate),
          time,
          for (final card in reading.cards)
            SpreadText.positionName(l10n, reading.spreadId, card.positionId),
        ].reduce(l10n.commonItemSeparator);
      case JournalDailyCardItem(:final card):
        return l10n.commonItemSeparator(
          day(card.localDate),
          l10n.commonDailyCard,
        );
    }
  }
}

/// The note editor: seeded with the stored note, then owned by the user's
/// typing (autosaved by the controller). A note changed by the app ("Write
/// about this", a save from elsewhere) is copied in; the user's own
/// keystrokes are not echoed back.
class _NoteEditor extends StatefulWidget {
  const _NoteEditor({
    required this.view,
    required this.autofocus,
    required this.onChanged,
    required this.onDone,
  });

  final JournalEntryView view;
  final bool autofocus;
  final ValueChanged<String> onChanged;
  final VoidCallback? onDone;

  @override
  State<_NoteEditor> createState() => _NoteEditorState();
}

class _NoteEditorState extends State<_NoteEditor> {
  late final TextEditingController _text = TextEditingController(
    text: widget.view.note,
  );
  final FocusNode _focus = FocusNode();
  String? _typed;

  @override
  void initState() {
    super.initState();
    _focus.addListener(() {
      if (!_focus.hasFocus) widget.onDone?.call();
    });
  }

  @override
  void didUpdateWidget(_NoteEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    final note = widget.view.note;
    if (note != _text.text && note != _typed) {
      _text.value = TextEditingValue(
        text: note,
        selection: TextSelection.collapsed(offset: note.length),
      );
    }
  }

  @override
  void dispose() {
    _focus.dispose();
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = TaroLocalizations.of(context);
    return TaroTextField(
      controller: _text,
      focusNode: _focus,
      autofocus: widget.autofocus,
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
      onChanged: (text) {
        _typed = text;
        widget.onChanged(text);
      },
    );
  }
}
