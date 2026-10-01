import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:taro/common/card_art.dart';
import 'package:taro/common/failure_message.dart';
import 'package:taro/di/providers.dart';
import 'package:taro/features/daily_card/controller/daily_card_controller.dart';
import 'package:taro/l10n/generated/taro_localizations.dart';
import 'package:taro/routing/routes.dart';
import 'package:taro_core/taro_core.dart';
import 'package:taro_ui/taro_ui.dart';

/// Text scales above this switch to the stacked large-text layout (01
/// §12: the 200% layouts).
const double _largeTextThreshold = 1.5;

bool _largeText(BuildContext context) =>
    MediaQuery.textScalerOf(context).scale(1) > _largeTextThreshold;

/// S13 Daily card (01 §7.6, §8.3; canvas `DailyCard`, `DailyCardNotDrawn`):
/// tap-to-reveal, then today's card with its keywords, meaning and a
/// reflection question; "Reflect deeper with AI" opens S07 on the single
/// spread with this card preset (PR4). No banner.
class DailyCardScreen extends ConsumerWidget {
  /// Creates the screen.
  const DailyCardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(dailyCardControllerProvider);
    final controller = ref.read(dailyCardControllerProvider.notifier);
    return DailyCardLayout(
      state: state,
      today: ref.watch(clockProvider).now(),
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
///
/// The card slot keeps one `TaroCardFlip` across `notDrawn` → `revealing`
/// → `drawn`, so the reveal is a `motion.ritual.flip` turn (a cross-fade in
/// reduced motion); the texts then fade in with a
/// `motion.ritual.readingReveal` stagger and "Card revealed: …" is
/// announced.
class DailyCardLayout extends StatefulWidget {
  /// Creates the view.
  const DailyCardLayout({
    required this.state,
    required this.today,
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

  /// The install-local day (the `Clock`), shown in the top bar.
  final DateTime today;

  /// The bundled art set.
  final String artSet;

  /// Leaves S13 ("Back", "Back to Today").
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
  State<DailyCardLayout> createState() => _DailyCardLayoutState();
}

class _DailyCardLayoutState extends State<DailyCardLayout>
    with SingleTickerProviderStateMixin {
  static const ValueKey<String> _cardSlotKey = ValueKey('dailyCardSlot');

  /// The text stagger: each section starts this share of the reveal later.
  static const double _staggerStep = 0.15;

  /// Each section fades over this share of the reveal.
  static const double _fadeShare = 0.4;

  late final AnimationController _texts;

  /// A reveal is under way: the face is not fully shown yet.
  bool _flipPending = false;

  @override
  void initState() {
    super.initState();
    _texts = AnimationController(vsync: this, value: 1);
  }

  @override
  void didUpdateWidget(DailyCardLayout oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_viewOf(oldWidget.state) == null &&
        _faceDown(oldWidget.state) &&
        _viewOf(widget.state) != null) {
      _flipPending = true;
      _texts.value = 0;
    }
  }

  @override
  void dispose() {
    _texts.dispose();
    super.dispose();
  }

  static DailyCardView? _viewOf(DailyCardState state) => switch (state) {
    DailyCardDrawn(:final view) ||
    DailyCardNoteEditing(:final view) ||
    DailyCardReminderOffer(:final view) => view,
    _ => null,
  };

  static bool _faceDown(DailyCardState state) =>
      state is DailyCardNotDrawn || state is DailyCardRevealing;

  void _onFlipped(String name) {
    if (!mounted) return;
    setState(() => _flipPending = false);
    _texts.duration = context.motion.ritual.readingReveal;
    unawaited(_texts.forward(from: 0));
    unawaited(
      SemanticsService.sendAnnouncement(
        View.of(context),
        TaroLocalizations.of(context).dailyRevealedAnnouncement(name),
        Directionality.of(context),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = TaroLocalizations.of(context);
    final state = widget.state;
    final view = _viewOf(state);
    final date = view == null
        ? widget.today
        : DateTime.parse(view.card.localDate);
    return TaroScaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _TopBar(
            date: DateFormat.MMMMEEEEd(l10n.localeName).format(date),
            onBack: widget.onClose,
            favourite: view?.card.favourite,
            onToggleFavourite: widget.onToggleFavourite,
          ),
          Expanded(
            child: switch (state) {
              DailyCardLoading() => TaroLoadingView(
                semanticsLabel: l10n.commonLoading,
                layout: TaroLoadingLayout.cards,
                itemCount: 1,
              ),
              DailyCardFailed(:final failure) => FailureView.of(
                failure,
                onRetry: widget.onRetry,
              ),
              _ => _body(context, view),
            },
          ),
        ],
      ),
    );
  }

  Widget _body(BuildContext context, DailyCardView? view) {
    final tokens = context.tokens;
    final revealing = widget.state is DailyCardRevealing;
    // The actions sit at the bottom of the viewport (flexible spacer in the
    // canvas) and scroll with the content when it is taller.
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: tokens.space.s5,
                children: [
                  SizedBox(height: tokens.space.s3),
                  Center(
                    key: _cardSlotKey,
                    child: _cardSlot(context, view, revealing: revealing),
                  ),
                  if (view == null)
                    ..._notDrawnTexts(context)
                  else if (!_flipPending)
                    ..._drawnTexts(context, view),
                ],
              ),
              Padding(
                padding: EdgeInsetsDirectional.only(
                  top: tokens.space.s7,
                  bottom: tokens.space.s7,
                ),
                child: view == null
                    ? TaroButton.secondary(
                        label: TaroLocalizations.of(context).dailyBackToToday,
                        expand: true,
                        onPressed: widget.onClose,
                      )
                    : _flipPending
                    ? const SizedBox.shrink()
                    : _fade(5, _actions(context, view)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _cardSlot(
    BuildContext context,
    DailyCardView? view, {
    required bool revealing,
  }) {
    final l10n = TaroLocalizations.of(context);
    final large = _largeText(context);
    final settled = view != null && !_flipPending;
    final backSize = settled || large ? TaroCardSize.md : TaroCardSize.lg;
    return TaroCardFlip(
      revealed: view != null,
      onFlipped: view == null ? null : () => _onFlipped(view.text.name),
      back: TaroCardBack(
        size: backSize,
        semanticsLabel: l10n.dailyCardBackSemantics,
        enabled: !revealing,
        onTap: revealing ? null : widget.onReveal,
      ),
      face: view == null
          ? const SizedBox.shrink()
          : TaroCardFace(
              image: CardArt.face(view.card.cardId, artSet: widget.artSet),
              semanticsLabel: l10n.dailyCardFaceSemantics(
                view.text.name,
                _orientation(l10n, view),
              ),
              reversed: view.card.reversed,
              reversedLabel: l10n.commonReversed,
              highlighted: true,
            ),
    );
  }

  List<Widget> _notDrawnTexts(BuildContext context) {
    final l10n = TaroLocalizations.of(context);
    final tokens = context.tokens;
    final c = tokens.color;
    return [
      Semantics(
        header: true,
        child: Text(
          l10n.dailyNotDrawnPrompt,
          textAlign: TextAlign.center,
          style: tokens.typography.headline.copyWith(color: c.text.primary),
        ),
      ),
      Text(
        l10n.dailyNotDrawnBody,
        textAlign: TextAlign.center,
        style: tokens.typography.body.copyWith(color: c.text.secondary),
      ),
      Center(
        child: TaroBadge(
          label: l10n.dailyNotDrawnBadge,
          variant: TaroBadgeVariant.keyword,
        ),
      ),
    ];
  }

  Widget _fade(int index, Widget child) {
    final start = math.min(index * _staggerStep, 1 - _fadeShare);
    return FadeTransition(
      opacity: CurvedAnimation(
        parent: _texts,
        curve: Interval(start, start + _fadeShare),
      ),
      child: child,
    );
  }

  List<Widget> _drawnTexts(BuildContext context, DailyCardView view) {
    final l10n = TaroLocalizations.of(context);
    final tokens = context.tokens;
    final c = tokens.color;
    final question = view.reflectionQuestion;
    final number = view.deckCard.arcana == Arcana.major
        ? _roman(view.deckCard.number)
        : '${view.deckCard.number}';
    Widget reading(Widget child) => Align(
      alignment: AlignmentDirectional.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: tokens.layout.readingMaxWidth),
        child: SizedBox(width: double.infinity, child: child),
      ),
    );
    return [
      _fade(
        0,
        Column(
          spacing: tokens.space.s2,
          children: [
            Text(
              l10n.dailyMeta(
                switch (view.deckCard.arcana) {
                  Arcana.major => l10n.learnSectionMajor,
                  Arcana.minor => l10n.arcanaMinor,
                },
                number,
                _orientation(l10n, view),
              ),
              textAlign: TextAlign.center,
              style: tokens.typography.caption.copyWith(
                color: c.text.secondary,
              ),
            ),
            Semantics(
              header: true,
              child: Text(
                view.text.name,
                textAlign: TextAlign.center,
                style: tokens.typography.headline.copyWith(
                  color: c.text.primary,
                ),
              ),
            ),
          ],
        ),
      ),
      _fade(
        1,
        Semantics(
          label: l10n.dailyKeywordsSemantics(view.keywords.join(', ')),
          excludeSemantics: true,
          child: Wrap(
            alignment: WrapAlignment.center,
            spacing: tokens.space.s3,
            runSpacing: tokens.space.s3,
            children: [
              for (final keyword in view.keywords)
                TaroBadge(label: keyword, variant: TaroBadgeVariant.keyword),
            ],
          ),
        ),
      ),
      _fade(
        2,
        reading(
          Text(
            view.shortMeaning,
            style: tokens.typography.bodyReading.copyWith(
              color: c.text.primary,
            ),
          ),
        ),
      ),
      if (question != null)
        _fade(
          3,
          reading(
            Text(
              question,
              style: tokens.typography.bodyReading.copyWith(
                color: c.text.secondary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ),
    ];
  }

  Widget _actions(BuildContext context, DailyCardView view) {
    final l10n = TaroLocalizations.of(context);
    final tokens = context.tokens;
    final c = tokens.color;
    final note = view.card.note;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      spacing: tokens.space.s4,
      children: [
        if (widget.state is DailyCardNoteEditing)
          _NoteEditor(
            initial: note ?? '',
            onSave: widget.onSaveNote,
            onCancel: widget.onCancelNote,
          )
        else ...[
          if (note != null)
            TaroSurfaceCard(
              onTap: widget.onEditNote,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: tokens.space.s2,
                children: [
                  Text(
                    l10n.commonYourNote,
                    style: tokens.typography.label.copyWith(
                      color: c.text.secondary,
                    ),
                  ),
                  Text(
                    note,
                    style: tokens.typography.bodyReading.copyWith(
                      color: c.text.primary,
                    ),
                  ),
                  Text(
                    l10n.commonSavedOnDevice,
                    style: tokens.typography.caption.copyWith(
                      color: c.text.tertiary,
                    ),
                  ),
                ],
              ),
            ),
          TaroButton.primary(
            label: l10n.dailyReflectDeeper,
            expand: true,
            onPressed: widget.onReflectDeeper,
          ),
          if (note == null)
            TaroButton.secondary(
              label: l10n.dailyAddNote,
              expand: true,
              onPressed: widget.onEditNote,
            ),
        ],
        Text(
          l10n.dailyCaption,
          textAlign: TextAlign.center,
          style: tokens.typography.caption.copyWith(color: c.text.secondary),
        ),
        if (widget.state is DailyCardReminderOffer)
          TaroSurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: tokens.space.s4,
              children: [
                Semantics(
                  header: true,
                  child: Text(
                    l10n.dailyReminderOfferTitle,
                    style: tokens.typography.titleSmall.copyWith(
                      color: c.text.primary,
                    ),
                  ),
                ),
                // Equal weight, nothing pre-selected (rule 11).
                TaroButton.secondary(
                  label: l10n.dailyReminderOfferYes,
                  expand: true,
                  onPressed: () => widget.onAnswerReminder(accepted: true),
                ),
                TaroButton.secondary(
                  label: l10n.dailyReminderOfferNo,
                  expand: true,
                  onPressed: () => widget.onAnswerReminder(accepted: false),
                ),
              ],
            ),
          ),
      ],
    );
  }

  static String _orientation(TaroLocalizations l10n, DailyCardView view) =>
      view.card.reversed ? l10n.commonReversed : l10n.commonUpright;

  static const List<(int, String)> _numerals = [
    (10, 'X'),
    (9, 'IX'),
    (5, 'V'),
    (4, 'IV'),
    (1, 'I'),
  ];

  /// Major Arcana numerals stay Latin in every locale ("XVII"; 0 is "0").
  static String _roman(int number) {
    if (number <= 0) return '0';
    final out = StringBuffer();
    var rest = number;
    for (final (value, symbol) in _numerals) {
      while (rest >= value) {
        out.write(symbol);
        rest -= value;
      }
    }
    return out.toString();
  }
}

/// Back at the start; "YOUR DAILY CARD" over the date, centred; the
/// favourite toggle (once drawn) or a 48 spacer at the end.
class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.date,
    required this.onBack,
    required this.favourite,
    required this.onToggleFavourite,
  });

  final String date;
  final VoidCallback onBack;
  final bool? favourite;
  final VoidCallback onToggleFavourite;

  @override
  Widget build(BuildContext context) {
    final l10n = TaroLocalizations.of(context);
    final tokens = context.tokens;
    final c = tokens.color;
    final on = favourite;
    return Padding(
      padding: EdgeInsetsDirectional.only(top: tokens.space.s3),
      child: Row(
        children: [
          TaroIconButton(
            icon: Icons.arrow_back_ios_new_rounded,
            semanticsLabel: l10n.commonBack,
            onPressed: onBack,
          ),
          Expanded(
            child: Semantics(
              label: l10n.dailyHeaderSemantics(date),
              excludeSemantics: true,
              child: Column(
                spacing: tokens.space.s1,
                children: [
                  Text(
                    l10n.dailyOverline,
                    textAlign: TextAlign.center,
                    style: tokens.typography.caption.copyWith(
                      color: c.card.frame,
                    ),
                  ),
                  Text(
                    date,
                    textAlign: TextAlign.center,
                    style: tokens.typography.caption.copyWith(
                      color: c.text.tertiary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (on == null)
            SizedBox(width: tokens.size.touchTarget.min)
          else
            TaroIconButton(
              icon: Icons.favorite_border,
              selectedIcon: Icons.favorite,
              toggled: on,
              semanticsLabel: on
                  ? l10n.commonUnfavourite
                  : l10n.commonFavourite,
              onPressed: onToggleFavourite,
            ),
        ],
      ),
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
