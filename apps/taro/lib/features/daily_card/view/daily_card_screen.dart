import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:taro/common/card_art.dart';
import 'package:taro/common/failure_message.dart';
import 'package:taro/features/daily_card/controller/daily_card_controller.dart';
import 'package:taro/l10n/generated/taro_localizations.dart';
import 'package:taro/routing/routes.dart';
import 'package:taro_core/taro_core.dart';
import 'package:taro_ui/taro_ui.dart';

/// S13 Daily card (01 §7.6, §8.3): tap-to-reveal, then today's card with
/// its keywords, meaning and a reflection question; "Reflect deeper with
/// AI" opens S07 on the single spread with this card preset (PR4).
class DailyCardScreen extends ConsumerWidget {
  /// Creates the screen.
  const DailyCardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(dailyCardControllerProvider);
    final controller = ref.read(dailyCardControllerProvider.notifier);
    return DailyCardLayout(
      state: state,
      artSet: ref.watch(deckArtSetProvider).value ?? CardArt.defaultArtSet,
      onClose: () =>
          context.canPop() ? context.pop() : context.go(RoutePaths.home),
      onReveal: () => unawaited(controller.reveal()),
      onRetry: () => ref.invalidate(dailyCardControllerProvider),
      onReflectDeeper: () {
        final deeper = controller.reflectDeeper();
        if (deeper == null) return;
        unawaited(
          context.push(
            RoutePaths.readingQuestion(
              deeper.spreadId.value,
              source: ReadingFlowSource.dailyCard.wire,
              cardId: deeper.cardId.value,
              reversed: deeper.reversed,
            ),
          ),
        );
      },
      onEditNote: controller.editNote,
      onCancelNote: controller.cancelNote,
      onSaveNote: (note) => unawaited(controller.saveNote(note)),
      onToggleFavourite: () => unawaited(controller.toggleFavourite()),
      onAnswerReminder: ({required accepted}) =>
          unawaited(controller.answerReminderOffer(accepted: accepted)),
    );
  }
}

/// The S13 layout for [state].
class DailyCardLayout extends StatelessWidget {
  /// Creates the view.
  const DailyCardLayout({
    required this.state,
    required this.onClose,
    required this.onReveal,
    required this.onRetry,
    required this.onReflectDeeper,
    required this.onEditNote,
    required this.onCancelNote,
    required this.onSaveNote,
    required this.onToggleFavourite,
    required this.onAnswerReminder,
    this.artSet = CardArt.defaultArtSet,
    super.key,
  });

  /// The controller state.
  final DailyCardState state;

  /// The bundled art set.
  final String artSet;

  /// Leaves S13.
  final VoidCallback onClose;

  /// The tap-to-reveal flip.
  final VoidCallback onReveal;

  /// Reloads after `failed`.
  final VoidCallback onRetry;

  /// "Reflect deeper with AI".
  final VoidCallback onReflectDeeper;

  /// "Add a note".
  final VoidCallback onEditNote;

  /// Closes the editor without saving.
  final VoidCallback onCancelNote;

  /// Saves the note.
  final ValueChanged<String> onSaveNote;

  /// Favourite on/off.
  final VoidCallback onToggleFavourite;

  /// The reminder offer's answer.
  final void Function({required bool accepted}) onAnswerReminder;

  @override
  Widget build(BuildContext context) {
    final l10n = TaroLocalizations.of(context);
    final tokens = context.tokens;
    final view = switch (state) {
      DailyCardDrawn(:final view) ||
      DailyCardNoteEditing(:final view) ||
      DailyCardReminderOffer(:final view) => view,
      _ => null,
    };
    return TaroScaffold(
      appBar: TaroAppBar(
        leading: TaroAppBarLeading.close,
        leadingLabel: l10n.commonClose,
        onLeading: onClose,
        actions: [
          if (view != null)
            TaroIconButton(
              icon: Icons.favorite_border,
              selectedIcon: Icons.favorite,
              toggled: view.card.favourite,
              semanticsLabel: view.card.favourite
                  ? l10n.commonUnfavourite
                  : l10n.commonFavourite,
              onPressed: onToggleFavourite,
            ),
        ],
      ),
      body: switch (state) {
        DailyCardLoading() => TaroLoadingView(
          semanticsLabel: l10n.commonLoading,
          layout: TaroLoadingLayout.cards,
          itemCount: 1,
        ),
        DailyCardNotDrawn() || DailyCardRevealing() => _notDrawn(
          context,
          revealing: state is DailyCardRevealing,
        ),
        DailyCardFailed(:final failure) => FailureView.of(
          failure,
          onRetry: onRetry,
        ),
        DailyCardDrawn() ||
        DailyCardNoteEditing() ||
        DailyCardReminderOffer() => ListView(
          padding: EdgeInsetsDirectional.only(bottom: tokens.space.s7),
          children: [
            _card(context, view!),
            if (state is DailyCardReminderOffer) ...[
              SizedBox(height: tokens.space.s7),
              TaroInlineNotice(
                kind: TaroNoticeKind.info,
                title: l10n.dailyReminderOfferTitle,
                actions: [
                  TaroButton.secondary(
                    label: l10n.dailyReminderOfferYes,
                    onPressed: () => onAnswerReminder(accepted: true),
                  ),
                  TaroButton.secondary(
                    label: l10n.dailyReminderOfferNo,
                    onPressed: () => onAnswerReminder(accepted: false),
                  ),
                ],
              ),
            ],
            SizedBox(height: tokens.space.s7),
            if (state is DailyCardNoteEditing)
              _NoteEditor(
                initial: view.card.note ?? '',
                onSave: onSaveNote,
                onCancel: onCancelNote,
              )
            else ...[
              if (view.card.note case final note?) ...[
                Text(l10n.commonYourNote, style: tokens.typography.label),
                SizedBox(height: tokens.space.s2),
                Text(note, style: tokens.typography.body),
                SizedBox(height: tokens.space.s5),
              ],
              TaroButton.primary(
                label: l10n.dailyReflectDeeper,
                expand: true,
                onPressed: onReflectDeeper,
              ),
              SizedBox(height: tokens.space.s3),
              TaroButton.secondary(
                label: l10n.dailyAddNote,
                expand: true,
                onPressed: onEditNote,
              ),
            ],
            SizedBox(height: tokens.space.s5),
            Text(
              l10n.dailyCaption,
              style: tokens.typography.caption.copyWith(
                color: tokens.color.text.tertiary,
              ),
            ),
          ],
        ),
      },
    );
  }

  Widget _notDrawn(BuildContext context, {required bool revealing}) {
    final l10n = TaroLocalizations.of(context);
    final tokens = context.tokens;
    return ListView(
      children: [
        Text(
          l10n.dailyOverline,
          style: tokens.typography.caption.copyWith(
            color: tokens.color.text.tertiary,
          ),
        ),
        SizedBox(height: tokens.space.s2),
        Semantics(
          header: true,
          child: Text(
            l10n.dailyNotDrawnTitle,
            style: tokens.typography.headline,
          ),
        ),
        SizedBox(height: tokens.space.s8),
        Center(
          child: TaroCardBack(
            size: TaroCardSize.md,
            semanticsLabel: l10n.dailyReveal,
            enabled: !revealing,
            onTap: revealing ? null : onReveal,
          ),
        ),
        SizedBox(height: tokens.space.s8),
        TaroButton.primary(
          label: l10n.dailyReveal,
          expand: true,
          loading: revealing,
          loadingSemanticsHint: l10n.commonLoading,
          onPressed: revealing ? null : onReveal,
        ),
        SizedBox(height: tokens.space.s3),
        Text(
          l10n.dailyNotDrawnCaption,
          textAlign: TextAlign.center,
          style: tokens.typography.caption.copyWith(
            color: tokens.color.text.tertiary,
          ),
        ),
      ],
    );
  }

  Widget _card(BuildContext context, DailyCardView view) {
    final l10n = TaroLocalizations.of(context);
    final tokens = context.tokens;
    final orientation = view.card.reversed
        ? l10n.commonReversed
        : l10n.commonUpright;
    final question = view.reflectionQuestion;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: tokens.space.s4,
      children: [
        Text(
          l10n.dailyOverline,
          style: tokens.typography.caption.copyWith(
            color: tokens.color.text.tertiary,
          ),
        ),
        Center(
          child: TaroCardFace(
            image: CardArt.face(view.card.cardId, artSet: artSet),
            semanticsLabel: l10n.dailyCardFaceSemantics(
              view.text.name,
              orientation,
            ),
            reversed: view.card.reversed,
            reversedLabel: l10n.commonReversed,
          ),
        ),
        Semantics(
          header: true,
          child: Text(view.text.name, style: tokens.typography.cardName),
        ),
        Text(
          l10n.dailyMeta(
            switch (view.deckCard.arcana) {
              Arcana.major => l10n.learnSectionMajor,
              Arcana.minor => l10n.arcanaMinor,
            },
            '${view.deckCard.number}',
            orientation,
          ),
          style: tokens.typography.caption.copyWith(
            color: tokens.color.text.secondary,
          ),
        ),
        Wrap(
          spacing: tokens.space.s3,
          runSpacing: tokens.space.s3,
          children: [
            for (final keyword in view.keywords)
              TaroBadge(
                label: keyword,
                variant: TaroBadgeVariant.keyword,
              ),
          ],
        ),
        Text(view.shortMeaning, style: tokens.typography.bodyReading),
        if (question != null)
          Text(
            question,
            style: tokens.typography.body.copyWith(
              color: tokens.color.text.secondary,
            ),
          ),
      ],
    );
  }
}

class _NoteEditor extends StatefulWidget {
  const _NoteEditor({
    required this.initial,
    required this.onSave,
    required this.onCancel,
  });

  final String initial;
  final ValueChanged<String> onSave;
  final VoidCallback onCancel;

  @override
  State<_NoteEditor> createState() => _NoteEditorState();
}

class _NoteEditorState extends State<_NoteEditor> {
  late final TextEditingController _text = TextEditingController(
    text: widget.initial,
  );

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = TaroLocalizations.of(context);
    final tokens = context.tokens;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: tokens.space.s3,
      children: [
        TaroTextField(
          controller: _text,
          style: TaroTextFieldStyle.multiLine,
          label: l10n.commonYourNote,
          hintText: l10n.commonNoteHint,
          maxGraphemes: DailyCardController.noteMaxLength,
          counterFormatter: l10n.commonNoteCounter,
          autofocus: true,
        ),
        Wrap(
          alignment: WrapAlignment.end,
          spacing: tokens.space.s3,
          children: [
            TaroButton.tertiary(
              label: l10n.commonCancel,
              onPressed: widget.onCancel,
            ),
            TaroButton.primary(
              label: l10n.commonDone,
              onPressed: () => widget.onSave(_text.text),
            ),
          ],
        ),
      ],
    );
  }
}
