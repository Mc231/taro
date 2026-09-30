import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:taro/common/disclaimer_footer.dart';
import 'package:taro/common/failure_message.dart';
import 'package:taro/common/spread_text.dart';
import 'package:taro/features/reading/controller/reading_result_controller.dart';
import 'package:taro/features/reading/share/share_reading_use_case.dart';
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
    return ReadingResultLayout(
      state: state,
      onDone: () => context.go(RoutePaths.home),
      onOpenDisclaimer: () => context.push(RoutePaths.legal('disclaimer')),
      onRate: (rating, reason) =>
          unawaited(controller.rate(rating, reason: reason)),
      onToggleFavourite: () => unawaited(controller.toggleFavourite()),
      onReport: () => unawaited(
        TaroModals.reportReading<void>(context, readingId: args.id.value),
      ),
      onWriteAbout: () {
        unawaited(controller.useReflectionPrompt());
        unawaited(context.push(RoutePaths.journalEntry(args.id.value)));
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

/// The S09 layout for [state].
class ReadingResultLayout extends StatelessWidget {
  /// Creates the view.
  const ReadingResultLayout({
    required this.state,
    required this.onDone,
    required this.onOpenDisclaimer,
    required this.onRate,
    required this.onToggleFavourite,
    required this.onReport,
    required this.onWriteAbout,
    required this.onShare,
    super.key,
  });

  /// The controller state.
  final ReadingResultState state;

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

  /// "Write about this".
  final VoidCallback onWriteAbout;

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
    return TaroScaffold(
      appBar: TaroAppBar(
        leading: TaroAppBarLeading.close,
        leadingLabel: l10n.readingDone,
        onLeading: onDone,
        actions: [
          if (view != null) ...[
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
            if (view.canReport)
              TaroIconButton(
                icon: Icons.flag_outlined,
                semanticsLabel: l10n.reportReadingTitle,
                onPressed: onReport,
              ),
          ],
        ],
      ),
      body: switch (state) {
        ReadingResultLoadingFromStorage() => ListView(
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
        _ => ListView(
          padding: EdgeInsetsDirectional.only(bottom: tokens.space.s7),
          children: [
            _text(context, view!, footer),
            if (view.reported) ...[
              SizedBox(height: tokens.space.s5),
              TaroBadge(label: l10n.readingReported),
            ],
            SizedBox(height: tokens.space.s7),
            _rating(context, view),
            SizedBox(height: tokens.space.s7),
            TaroButton.primary(
              label: l10n.readingDone,
              expand: true,
              onPressed: onDone,
            ),
          ],
        ),
      },
    );
  }

  Widget _text(BuildContext context, ReadingResultView view, Widget footer) {
    final l10n = TaroLocalizations.of(context);
    final reading = view.reading;
    final content = reading.content;
    final question = reading.question;
    final prompts = content?.reflectionPrompts ?? const <String>[];
    return ReadingTextView(
      question: question == null ? null : l10n.readingQuestionQuoted(question),
      sourceLabel: AiGeneratedLabel(label: l10n.aiLabel),
      title: content?.title,
      sections: [
        if (content != null)
          ReadingTextSection(
            heading: l10n.readingSummary,
            body: content.summary,
          ),
        for (final card in reading.cards)
          ReadingTextSection(
            heading: l10n.readingPositionHeading(
              SpreadText.positionName(l10n, reading.spreadId, card.positionId),
              _cardName(l10n, view, card),
            ),
            body: content?.textFor(card.positionId) ?? '',
          ),
        if (content != null)
          ReadingTextSection(
            heading: l10n.readingSynthesis,
            body: content.synthesis,
          ),
        if (prompts.isNotEmpty)
          ReadingTextSection(
            heading: l10n.readingReflectionPrompts,
            body: prompts.join('\n\n'),
          ),
      ],
      footer: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (prompts.isNotEmpty)
            TaroButton.tertiary(
              label: l10n.readingWriteAboutThis,
              onPressed: onWriteAbout,
            ),
          footer,
        ],
      ),
    );
  }

  static String _cardName(
    TaroLocalizations l10n,
    ReadingResultView view,
    DrawnCard card,
  ) {
    final name = view.cardTexts[card.cardId]?.name ?? card.cardId.value;
    return card.reversed ? l10n.readingCardReversed(name) : name;
  }

  Widget _rating(BuildContext context, ReadingResultView view) {
    final l10n = TaroLocalizations.of(context);
    final tokens = context.tokens;
    final rating = view.reading.rating;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: tokens.space.s3,
      children: [
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
            onRate(
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
                  onSelected: (_) => onRate(Rating.down, reason),
                ),
            ],
          ),
        if (state is ReadingResultRatingGiven)
          Semantics(
            liveRegion: true,
            child: Text(
              l10n.readingRatingThanks,
              style: tokens.typography.caption.copyWith(
                color: tokens.color.text.secondary,
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _openShare(BuildContext context, ReadingResultView view) async {
    final includeQuestion = await TaroSheet.show<bool>(
      context,
      builder: (sheet) =>
          _ShareSheet(hasQuestion: view.reading.question != null),
    );
    if (includeQuestion != null) {
      onShare(view, includeQuestion: includeQuestion);
    }
  }
}

/// The share options: "Include my question" is off by default (PR19).
class _ShareSheet extends StatefulWidget {
  const _ShareSheet({required this.hasQuestion});

  final bool hasQuestion;

  @override
  State<_ShareSheet> createState() => _ShareSheetState();
}

class _ShareSheetState extends State<_ShareSheet> {
  bool _includeQuestion = false;

  @override
  Widget build(BuildContext context) {
    final l10n = TaroLocalizations.of(context);
    return TaroSheet(
      title: l10n.shareTitle,
      actions: [
        TaroButton.primary(
          label: l10n.commonShare,
          expand: true,
          onPressed: () => Navigator.of(context).pop(_includeQuestion),
        ),
      ],
      child: widget.hasQuestion
          ? Align(
              alignment: AlignmentDirectional.centerStart,
              child: TaroChip.filter(
                label: l10n.shareIncludeQuestion,
                selected: _includeQuestion,
                onSelected: (on) => setState(() => _includeQuestion = on),
              ),
            )
          : const SizedBox.shrink(),
    );
  }
}
