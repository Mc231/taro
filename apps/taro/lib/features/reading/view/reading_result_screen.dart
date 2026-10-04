import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:taro/common/card_art.dart';
import 'package:taro/common/disclaimer_footer.dart';
import 'package:taro/common/failure_message.dart';
import 'package:taro/common/reading_mini_spread.dart';
import 'package:taro/common/reading_share_sheet.dart';
import 'package:taro/common/share_reading_use_case.dart';
import 'package:taro/common/spread_text.dart';
import 'package:taro/features/reading/controller/reading_result_controller.dart';
import 'package:taro/l10n/generated/taro_localizations.dart';
import 'package:taro/routing/routes.dart';
import 'package:taro_core/taro_core.dart';
import 'package:taro_ui/taro_ui.dart';

/// S09 Reading result (01 §7.4, §8.3): the AI reading with its
/// "AI-generated" label; the `DisclaimerFooter` is rendered in **every**
/// state (05 §3), and there is never a banner on a reading screen (RC18).
class ReadingResultScreen extends ConsumerWidget {
  /// Creates the screen for [args].
  const ReadingResultScreen({required this.args, super.key});

  /// The screen for the route (`/reading/:id`, query `origin`).
  factory ReadingResultScreen.fromRoute(
    Map<String, String> path,
    Map<String, String> query, {
    Key? key,
  }) => ReadingResultScreen(
    args: ReadingResultArgs(
      id: ReadingId(path['id'] ?? ''),
      origin: ReadingViewOrigin.values.firstWhere(
        (o) => o.wire == query['origin'],
        orElse: () => ReadingViewOrigin.fresh,
      ),
    ),
    key: key,
  );

  /// The reading and the origin.
  final ReadingResultArgs args;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = readingResultControllerProvider(args);
    final state = ref.watch(provider);
    final controller = ref.read(provider.notifier);
    final l10n = TaroLocalizations.of(context);
    void openNote() =>
        unawaited(context.push(RoutePaths.journalEntry(args.id.value)));
    return ReadingResultLayout(
      state: state,
      reveal: args.origin == ReadingViewOrigin.fresh,
      artSet: ref.watch(deckArtSetProvider).value ?? CardArt.defaultArtSet,
      onDone: () => context.go(RoutePaths.home),
      onOpenDisclaimer: () => context.push(RoutePaths.legal('disclaimer')),
      onRate: (rating, reason) =>
          unawaited(controller.rate(rating, reason: reason)),
      onToggleFavourite: () => unawaited(controller.toggleFavourite()),
      onReport: () => unawaited(
        TaroModals.reportReading<void>(context, readingId: args.id.value),
      ),
      onAddNote: openNote,
      onWriteAbout: (prompt) {
        unawaited(controller.useReflectionPrompt());
        unawaited(
          context.push(RoutePaths.journalEntry(args.id.value, prompt: prompt)),
        );
      },
      onShare: (view, {required includeQuestion}) => unawaited(
        controller.share(
          ShareCopy(
            disclaimerLine: l10n.disclaimerShort,
            questionLabel: l10n.shareQuestionLabel,
            reversedLabel: l10n.commonReversed,
            fallbackTitle: SpreadText.name(l10n, view.reading.spreadId),
          ),
          includeQuestion: includeQuestion,
        ),
      ),
    );
  }
}

/// The S09 layout for [state] (`docs/design/screens/S09/spec.md`): Done,
/// "Add note" and More (Report) in the top bar; the mini spread; the
/// question, the "AI-generated" badge, the title, the summary, one
/// expandable section per position, the synthesis and the reflection
/// prompts; the Favourite / Share / rating row; and the `DisclaimerFooter`
/// in every state. No banner (RC18).
class ReadingResultLayout extends StatelessWidget {
  /// Creates the view.
  const ReadingResultLayout({
    required this.state,
    required this.onDone,
    required this.onOpenDisclaimer,
    required this.onRate,
    required this.onToggleFavourite,
    required this.onReport,
    required this.onAddNote,
    required this.onWriteAbout,
    required this.onShare,
    this.reveal = false,
    this.artSet = CardArt.defaultArtSet,
    super.key,
  });

  /// The controller state.
  final ReadingResultState state;

  /// Whether the sections enter with the `motion.ritual.readingReveal`
  /// stagger (a fresh reading from S08).
  final bool reveal;

  /// The bundled art set of the card faces.
  final String artSet;

  /// "Done" / close (Home, 01 §9.1).
  final VoidCallback onDone;

  /// "Full disclaimer" (S29).
  final VoidCallback onOpenDisclaimer;

  /// 👍 / 👎 (with a reason on 👎).
  final void Function(Rating rating, RatingReason? reason) onRate;

  /// Favourite on/off.
  final VoidCallback onToggleFavourite;

  /// "Report this reading" (S33).
  final VoidCallback onReport;

  /// "Add note" (the note editor).
  final VoidCallback onAddNote;

  /// "Write about this" on a reflection prompt.
  final ValueChanged<String> onWriteAbout;

  /// Share [ReadingResultView] as text.
  final void Function(ReadingResultView view, {required bool includeQuestion})
  onShare;

  @override
  Widget build(BuildContext context) {
    final l10n = TaroLocalizations.of(context);
    final tokens = context.tokens;
    final view = switch (state) {
      ReadingResultContent(:final view) ||
      ReadingResultRatingGiven(:final view) ||
      ReadingResultSharing(:final view) => view,
      _ => null,
    };
    final footer = DisclaimerFooter(onOpenDisclaimer: onOpenDisclaimer);
    Widget framed(Widget child) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(child: child),
        footer,
      ],
    );
    final hasMenu = view != null && (view.canReport || view.reported);
    return TaroScaffold(
      appBar: TaroAppBar(
        leading: TaroAppBarLeading.close,
        leadingLabel: l10n.readingDone,
        onLeading: onDone,
        actions: [
          if (view != null)
            TaroButton.tertiary(
              label: l10n.commonAddNote,
              onPressed: onAddNote,
            ),
          if (hasMenu)
            TaroIconButton(
              icon: Icons.more_horiz,
              semanticsLabel: l10n.commonMore,
              onPressed: () => unawaited(_openMenu(context, view)),
            ),
        ],
      ),
      body: switch (state) {
        ReadingResultLoadingFromStorage() => ListView(
          padding: EdgeInsetsDirectional.only(top: tokens.space.s5),
          children: [
            ReadingTextView.loading(loadingLabel: l10n.commonLoading),
            footer,
          ],
        ),
        ReadingResultNotFound() => framed(
          TaroEmptyView(
            title: l10n.readingNotFound,
            action: TaroButton.primary(
              label: l10n.commonBackToToday,
              onPressed: onDone,
            ),
          ),
        ),
        ReadingResultFailed(:final failure) => framed(
          FailureView.of(failure),
        ),
        _ => _content(context, view!, footer),
      },
    );
  }

  Widget _content(BuildContext context, ReadingResultView view, Widget footer) {
    final l10n = TaroLocalizations.of(context);
    final tokens = context.tokens;
    final reading = view.reading;
    final names = {
      for (final card in reading.cards)
        card.cardId: view.cardTexts[card.cardId]?.name ?? card.cardId.value,
    };
    return ListView(
      padding: EdgeInsetsDirectional.only(
        top: tokens.space.s4,
        bottom: tokens.space.s7,
      ),
      children: [
        Text(
          l10n.commonItemSeparator(
            SpreadText.name(l10n, reading.spreadId),
            _date(context, reading.localDate),
          ),
          style: tokens.typography.caption.copyWith(
            color: tokens.color.text.secondary,
          ),
        ),
        SizedBox(height: tokens.space.s4),
        ReadingMiniSpread(
          spreadId: reading.spreadId,
          cards: reading.cards,
          names: names,
          positions: view.spread?.positions,
          artSet: artSet,
        ),
        SizedBox(height: tokens.space.s6),
        _text(context, view, names),
        SizedBox(height: tokens.space.s6),
        _actions(context, view),
        footer,
      ],
    );
  }

  /// `localDate` (`YYYY-MM-DD`, the install-local day) as a medium date.
  static String _date(BuildContext context, String localDate) {
    final day = DateTime.tryParse(localDate);
    return day == null
        ? localDate
        : MaterialLocalizations.of(context).formatMediumDate(day);
  }

  Widget _text(
    BuildContext context,
    ReadingResultView view,
    Map<CardId, String> names,
  ) {
    final l10n = TaroLocalizations.of(context);
    final tokens = context.tokens;
    final reading = view.reading;
    final content = reading.content;
    final question = reading.question;
    final prompts = content?.reflectionPrompts ?? const <String>[];
    return ReadingTextView(
      reveal: reveal,
      question: question == null
          ? null
          : l10n.readingQuestionQuoted(firstStrongIsolate(question)),
      sourceLabel: AiGeneratedLabel(label: l10n.aiLabel),
      title: content?.title,
      sections: [
        if (content != null) ReadingTextSection(body: content.summary),
        for (final card in reading.cards)
          ReadingTextSection(
            heading: l10n.readingPositionHeading(
              SpreadText.positionName(l10n, reading.spreadId, card.positionId),
              card.reversed
                  ? l10n.readingCardReversed(names[card.cardId]!)
                  : names[card.cardId]!,
            ),
            body: content?.textFor(card.positionId) ?? '',
            collapsible: true,
          ),
        if (content != null)
          ReadingTextSection(
            heading: l10n.readingSynthesis,
            body: content.synthesis,
          ),
      ],
      footer: prompts.isEmpty
          ? null
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: tokens.space.s3,
              children: [
                ReadingSectionHeader(title: l10n.readingReflectionPrompts),
                for (final prompt in prompts)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        prompt,
                        style: tokens.typography.bodyReading.copyWith(
                          color: tokens.color.text.primary,
                        ),
                      ),
                      TaroButton.tertiary(
                        label: l10n.readingWriteAboutThis,
                        icon: Icons.edit_note,
                        onPressed: () => onWriteAbout(prompt),
                      ),
                    ],
                  ),
              ],
            ),
    );
  }

  Widget _actions(BuildContext context, ReadingResultView view) {
    final l10n = TaroLocalizations.of(context);
    final tokens = context.tokens;
    final rating = view.reading.rating;
    void rate(Rating value, RatingReason? reason) {
      onRate(value, reason);
      TaroToast.show(context, message: l10n.readingRatingThanks);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: tokens.space.s4,
      children: [
        Wrap(
          spacing: tokens.space.s3,
          runSpacing: tokens.space.s3,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            TaroIconButton(
              icon: Icons.favorite_border,
              selectedIcon: Icons.favorite,
              toggled: view.reading.favourite,
              semanticsLabel: view.reading.favourite
                  ? l10n.commonUnfavourite
                  : l10n.commonFavourite,
              onPressed: onToggleFavourite,
            ),
            TaroIconButton(
              icon: Icons.ios_share,
              semanticsLabel: l10n.commonShare,
              onPressed: state is ReadingResultSharing
                  ? null
                  : () => unawaited(_openShare(context, view)),
            ),
          ],
        ),
        ReadingRatingControl(
          prompt: l10n.readingRatingPrompt,
          helpfulLabel: l10n.readingRateUp,
          notHelpfulLabel: l10n.readingRateDown,
          value: switch (rating) {
            Rating.up => ReadingRatingValue.up,
            Rating.down => ReadingRatingValue.down,
            null => null,
          },
          onChanged: (value) {
            if (value == null) return;
            rate(
              value == ReadingRatingValue.up ? Rating.up : Rating.down,
              null,
            );
          },
        ),
        if (rating == Rating.down)
          Wrap(
            spacing: tokens.space.s3,
            runSpacing: tokens.space.s3,
            children: [
              for (final reason in RatingReason.values)
                TaroChip.filter(
                  label: switch (reason) {
                    RatingReason.tooGeneric => l10n.readingReasonTooGeneric,
                    RatingReason.mismatch => l10n.readingReasonMismatch,
                    RatingReason.tone => l10n.readingReasonTone,
                    RatingReason.other => l10n.readingReasonOther,
                  },
                  selected: view.reading.ratingReason == reason,
                  onSelected: (_) => rate(Rating.down, reason),
                ),
            ],
          ),
      ],
    );
  }

  /// More: "Report this reading" (S33), or "Reported" (disabled) once sent.
  Future<void> _openMenu(BuildContext context, ReadingResultView view) async {
    final l10n = TaroLocalizations.of(context);
    final report = await TaroSheet.show<bool>(
      context,
      builder: (sheet) => TaroSheet(
        title: l10n.commonMore,
        child: TaroListTile(
          leading: const Icon(Icons.flag_outlined),
          title: view.reported ? l10n.readingReported : l10n.reportReadingTitle,
          onTap: view.reported ? null : () => Navigator.of(sheet).pop(true),
        ),
      ),
    );
    if (report ?? false) onReport();
  }

  Future<void> _openShare(BuildContext context, ReadingResultView view) async {
    final includeQuestion = await ReadingShareSheet.show(
      context,
      hasQuestion: view.reading.question != null,
    );
    if (includeQuestion != null) {
      onShare(view, includeQuestion: includeQuestion);
    }
  }
}
