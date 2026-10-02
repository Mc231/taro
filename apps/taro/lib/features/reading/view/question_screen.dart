import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:taro/common/balance_chip.dart';
import 'package:taro/common/card_art.dart';
import 'package:taro/common/failure_message.dart';
import 'package:taro/common/offline_banner.dart';
import 'package:taro/common/spread_text.dart';
import 'package:taro/features/reading/controller/question_controller.dart';
import 'package:taro/features/reading/controller/question_state.dart';
import 'package:taro/features/reading/controller/reading_session.dart';
import 'package:taro/l10n/generated/taro_localizations.dart';
import 'package:taro/routing/routes.dart';
import 'package:taro_core/taro_core.dart';
import 'package:taro_ui/taro_ui.dart';

/// S07 Question input + **Begin**, with S31 as its `readingsPaused` state
/// (01 §7.2, §8.3; RC44, RC47, RC50, RC58, RC64, RC74).
///
/// Begin runs the gate and the pre-draw hold; only `ready` (a hold, or a
/// Classic reading) opens S08, so no card face exists before the gate
/// allows. `consentRequired` opens S04, `outOfReadings` / `lowTrustLimited`
/// open S10; on return the question is kept and nothing auto-starts.
class QuestionScreen extends ConsumerStatefulWidget {
  /// Creates the screen for [args].
  const QuestionScreen({required this.args, super.key});

  /// The screen for the route query (`spread`, `source`, `card`,
  /// `reversed`; RoutePaths.readingQuestion).
  factory QuestionScreen.fromQuery(Map<String, String> query, {Key? key}) {
    final card = CardId.tryParse(query['card'] ?? '');
    return QuestionScreen(
      args: QuestionArgs(
        spreadId: SpreadId(query['spread'] ?? ''),
        source: ReadingFlowSource.values.firstWhere(
          (s) => s.wire == query['source'],
          orElse: () => ReadingFlowSource.home,
        ),
        presetCards: [
          if (card != null)
            PresetCard(cardId: card, reversed: query['reversed'] == '1'),
        ],
      ),
      key: key,
    );
  }

  /// The spread, flow source and preset cards.
  final QuestionArgs args;

  @override
  ConsumerState<QuestionScreen> createState() => _QuestionScreenState();
}

class _QuestionScreenState extends ConsumerState<QuestionScreen> {
  final TextEditingController _text = TextEditingController();
  bool _precached = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 02 §17: the art S08 shows first is decoded while the user types (a
    // preset card from the daily card's "Reflect deeper").
    if (_precached) return;
    _precached = true;
    final preset = widget.args.presetCards;
    if (preset.isEmpty) return;
    unawaited(
      CardArt.precacheFaces(
        context,
        [for (final c in preset) c.cardId],
        logicalWidth: TaroCardSize.md.widthIn(context),
        artSet: ref.read(deckArtSetProvider).value ?? CardArt.defaultArtSet,
      ),
    );
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  QuestionController get _controller =>
      ref.read(questionControllerProvider(widget.args).notifier);

  @override
  Widget build(BuildContext context) {
    final provider = questionControllerProvider(widget.args);
    ref.listen(provider, _onState);
    final state = ref.watch(provider);
    return QuestionLayout(
      state: state,
      text: _text,
      onChanged: _controller.updateText,
      onSuggestion: (text) {
        _text.text = text;
        _controller.useSuggestion(text);
      },
      onBegin: () => unawaited(_controller.begin()),
      onRetry: () {
        _controller.dismissNotice();
        unawaited(_controller.begin());
      },
      onDismiss: _controller.dismissNotice,
      onClassic: () => unawaited(_controller.startClassic()),
      onReflectWithoutQuestion: () =>
          unawaited(_controller.reflectWithoutQuestion()),
      onOpenConsent: _openConsent,
      onOpenOptions: () => unawaited(_openOptions(state)),
      onBack: () =>
          context.canPop() ? context.pop() : context.go(RoutePaths.home),
      onDailyCard: () => context.go(RoutePaths.daily),
      onJournal: () => context.go(RoutePaths.journal),
      onHome: () => context.go(RoutePaths.home),
      onLearn: () => context.go(RoutePaths.learn),
      onChooseSpread: () => context.go(RoutePaths.readingSpreads),
    );
  }

  void _onState(QuestionState? previous, QuestionState next) {
    if (_text.text != next.draft.text) _text.text = next.draft.text;
    final entered =
        previous == null || previous.runtimeType != next.runtimeType;
    if (!entered) return;
    switch (next) {
      case QuestionReady():
        unawaited(_openDraw());
      case QuestionConsentRequired() when previous is QuestionChecking:
        _openConsent();
      case QuestionOutOfReadings() || QuestionLowTrustLimited():
        unawaited(_openOptions(next));
      default:
        break;
    }
  }

  Future<void> _openDraw() async {
    await context.push<void>(RoutePaths.readingDraw);
    if (!mounted) return;
    // Back from S08 without an outcome for S07: editable again.
    if (ref.read(questionControllerProvider(widget.args)) is QuestionReady) {
      _controller.dismissNotice();
    }
  }

  void _openConsent() => unawaited(
    context.push(
      RoutePaths.consentAiFrom(AiConsentOrigin.readingGate.wire),
    ),
  );

  Future<void> _openOptions(QuestionState state) async {
    final source = switch (state) {
      QuestionOutOfReadings(:final source) => source,
      QuestionLowTrustLimited() => OutOfReadingsSource.lowTrust,
      _ => OutOfReadingsSource.questionGate,
    };
    await TaroModals.outOfReadings<void>(context, source: source.wire);
    if (!mounted) return;
    final current = ref.read(questionControllerProvider(widget.args));
    if (current is QuestionOutOfReadings ||
        current is QuestionLowTrustLimited) {
      // Back to editing with Begin enabled; nothing auto-starts (RC58).
      _controller.dismissNotice();
    }
  }
}

/// The S07 / S31 layout for [state] (`Question.dc.html`,
/// `QuestionRefused.dc.html`, `ReadingsPaused.dc.html`).
class QuestionLayout extends ConsumerWidget {
  /// Creates the view.
  const QuestionLayout({
    required this.state,
    required this.text,
    required this.onChanged,
    required this.onSuggestion,
    required this.onBegin,
    required this.onRetry,
    required this.onDismiss,
    required this.onClassic,
    required this.onReflectWithoutQuestion,
    required this.onOpenConsent,
    required this.onOpenOptions,
    required this.onBack,
    required this.onDailyCard,
    required this.onLearn,
    required this.onChooseSpread,
    this.onJournal,
    this.onHome,
    super.key,
  });

  /// The controller state.
  final QuestionState state;

  /// The question field's text.
  final TextEditingController text;

  /// The question changed.
  final ValueChanged<String> onChanged;

  /// A suggestion chip (or an example rewording) was tapped.
  final ValueChanged<String> onSuggestion;

  /// **Begin**.
  final VoidCallback onBegin;

  /// Retry after a failure (Begin again).
  final VoidCallback onRetry;

  /// Dismisses a notice (back to `editing`).
  final VoidCallback onDismiss;

  /// "Try a classic reading" (F8).
  final VoidCallback onClassic;

  /// "Reflect on the cards without a question".
  final VoidCallback onReflectWithoutQuestion;

  /// Opens S04 (reading-gate re-entry).
  final VoidCallback onOpenConsent;

  /// Opens S10.
  final VoidCallback onOpenOptions;

  /// Leaves S07.
  final VoidCallback onBack;

  /// S31 link: the daily card.
  final VoidCallback onDailyCard;

  /// S31 link: Learn.
  final VoidCallback onLearn;

  /// Back to the spread picker.
  final VoidCallback onChooseSpread;

  /// S31 link: the Journal (hidden when null).
  final VoidCallback? onJournal;

  /// S31 "Back to Today" (falls back to [onBack]).
  final VoidCallback? onHome;

  /// Whether the field takes input in this state.
  bool get _editable => switch (state) {
    QuestionEditing() ||
    QuestionRephrase() ||
    QuestionRefused() ||
    QuestionRateLimited() ||
    QuestionOffline() ||
    QuestionFailed() ||
    QuestionConsentRequired() ||
    QuestionDeviceUnverified() => true,
    _ => false,
  };

  bool get _checking => state is QuestionChecking || state is QuestionReady;

  /// Whether "Reflect on the cards without a question" is offered: a
  /// declined draw exists and the category allows it.
  bool get _canReflect => switch (state) {
    QuestionRephrase() => true,
    QuestionRefused(:final draw, :final category) =>
      draw != null && !category.isModerationBlocked,
    _ => false,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = TaroLocalizations.of(context);
    final tokens = context.tokens;
    final chip = ref.watch(balanceChipProvider);
    final status = _statusCard(context);
    final notice = _notice(context);
    final balance = BalanceChip(today: true, onTap: onOpenOptions);
    // At large text, or when a long translation does not fit, the chip
    // leaves the bar for the body (01 §12).
    final chipInBody =
        MediaQuery.textScalerOf(context).scale(1) > kSpreadReflowTextScale ||
        !BalanceChip.fitsAppBar(context, chip, today: true);
    return TaroScaffold(
      appBar: TaroAppBar(
        onLeading: onBack,
        leadingLabel: l10n.commonBack,
        actions: [if (!chipInBody) balance],
      ),
      topBanner: const OfflineBanner(),
      body: SingleChildScrollView(
        padding: EdgeInsetsDirectional.only(
          top: tokens.space.s4,
          bottom: tokens.space.s7,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (chipInBody) ...[
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: balance,
              ),
              SizedBox(height: tokens.space.s5),
            ],
            ..._header(context),
            SizedBox(height: tokens.space.s6),
            _field(context),
            if (status != null) ...[SizedBox(height: tokens.space.s6), status],
            if (notice != null) ...[SizedBox(height: tokens.space.s6), notice],
            ..._ideas(context),
          ],
        ),
      ),
      bottom: _bottom(context, chip),
    );
  }

  List<Widget> _header(BuildContext context) {
    final l10n = TaroLocalizations.of(context);
    final tokens = context.tokens;
    final spread = state.draft.spread;
    if (state case QuestionRefused(:final category)) {
      final advice =
          !category.isModerationBlocked && category != RefusalCategory.other;
      return [
        Semantics(
          header: true,
          child: Text(
            l10n.questionRefusedHeadline,
            style: tokens.typography.headline,
          ),
        ),
        SizedBox(height: tokens.space.s6),
        _StatusCard(
          icon: Icons.info_outline_rounded,
          title: l10n.questionRefusedTitle,
          body: [
            FailureMessage.refusal(l10n, category),
            if (advice) l10n.questionRefusedProfessional,
          ].join('\n'),
          footer: _NoReadingUsed(label: l10n.questionNoReadingUsed),
        ),
      ];
    }
    return [
      if (spread != null)
        Text(
          SpreadText.name(l10n, spread.id),
          style: tokens.typography.caption.copyWith(
            color: tokens.color.text.tertiary,
          ),
        ),
      SizedBox(height: tokens.space.s2),
      Semantics(
        header: true,
        child: Text(l10n.questionTitle, style: tokens.typography.headline),
      ),
    ];
  }

  Widget _field(BuildContext context) {
    final l10n = TaroLocalizations.of(context);
    final tokens = context.tokens;
    final draft = state.draft;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: tokens.space.s3,
      children: [
        TaroTextField(
          controller: text,
          style: TaroTextFieldStyle.multiLine,
          label: l10n.questionLabel,
          maxGraphemes: draft.maxChars,
          counterFormatter: l10n.commonNoteCounter,
          errorText: draft.check.problem == QuestionProblem.noText
              ? l10n.questionOnlySymbols
              : null,
          helperText: draft.check.personalDetailsWarning
              ? l10n.questionPersonalDetails
              : null,
          enabled: _editable || _checking,
          readOnly: _checking,
          onChanged: onChanged,
        ),
        // The inline guidance (01 §7.2, copy owned by 05).
        Text(
          l10n.questionHint,
          style: tokens.typography.caption.copyWith(
            color: tokens.color.text.secondary,
          ),
        ),
      ],
    );
  }

  /// Suggestion chips, or the example rewordings after a decline.
  List<Widget> _ideas(BuildContext context) {
    final l10n = TaroLocalizations.of(context);
    final tokens = context.tokens;
    final spread = state.draft.spread;
    final (String caption, List<String> ideas) = switch (state) {
      QuestionRefused(:final category) when category.isModerationBlocked => (
        '',
        const <String>[],
      ),
      QuestionRephrase() || QuestionRefused() => (
        l10n.questionRephraseTry,
        [l10n.questionRephraseExample1, l10n.questionRephraseExample2],
      ),
      _ when spread != null && (_editable || _checking) => (
        l10n.questionIdeas,
        [
          for (final key in spread.questionSuggestionKeys)
            ?SpreadText.lookup(l10n, key),
        ],
      ),
      _ => ('', const <String>[]),
    };
    if (ideas.isEmpty) return const [];
    return [
      SizedBox(height: tokens.space.s6),
      Text(
        caption,
        style: tokens.typography.label.copyWith(
          color: tokens.color.text.tertiary,
        ),
      ),
      SizedBox(height: tokens.space.s3),
      Wrap(
        spacing: tokens.space.s3,
        runSpacing: tokens.space.s3,
        children: [
          for (final idea in ideas)
            Semantics(
              label: l10n.questionSuggestionSemantics(idea),
              excludeSemantics: true,
              button: true,
              enabled: !_checking,
              child: TaroChip.suggestion(
                label: idea,
                onPressed: _checking ? null : () => onSuggestion(idea),
              ),
            ),
        ],
      ),
    ];
  }

  /// The S31-style status cards: paused, region, daily limit.
  Widget? _statusCard(BuildContext context) {
    final l10n = TaroLocalizations.of(context);
    Widget link(String label, VoidCallback onPressed) =>
        TaroChip.suggestion(label: label, onPressed: onPressed);
    final links = [
      link(l10n.commonDailyCard, onDailyCard),
      link(l10n.commonLearn, onLearn),
      if (onJournal case final journal?) link(l10n.commonJournal, journal),
    ];
    return switch (state) {
      QuestionReadingsPaused(:final freePaused) => _StatusCard(
        icon: Icons.bedtime_outlined,
        title: freePaused ? l10n.pausedFreeTitle : l10n.pausedTitle,
        body: l10n.pausedBody,
        links: links,
      ),
      QuestionAiUnavailableRegion() => _StatusCard(
        icon: Icons.public_off_outlined,
        title: l10n.pausedRegionTitle,
        body: l10n.pausedRegionBody,
      ),
      QuestionDailyLimitReached() => _StatusCard(
        icon: Icons.bedtime_outlined,
        title: l10n.questionDailyLimitTitle,
        body: l10n.questionDailyLimitBody,
        links: links,
      ),
      _ => null,
    };
  }

  Widget? _notice(BuildContext context) {
    final l10n = TaroLocalizations.of(context);
    Widget action(String label, VoidCallback onPressed) =>
        TaroButton.tertiary(label: label, onPressed: onPressed);
    return switch (state) {
      QuestionConsentRequired() => TaroInlineNotice(
        kind: TaroNoticeKind.info,
        title: l10n.questionConsentDeclinedNotice,
        body: l10n.questionClassicCaption,
        liveRegion: true,
        actions: [
          action(l10n.aiConsentAccept, onOpenConsent),
          action(l10n.questionTryClassic, onClassic),
        ],
      ),
      QuestionDeviceUnverified() => TaroInlineNotice(
        kind: TaroNoticeKind.warning,
        title: l10n.questionDeviceUnverified,
        body: l10n.errorDeviceUnverifiedBody,
        liveRegion: true,
        actions: [action(l10n.commonRetry, onRetry)],
      ),
      QuestionOutOfReadings() => TaroInlineNotice(
        kind: TaroNoticeKind.info,
        title: l10n.outOfReadingsTitle,
        body: l10n.outOfReadingsBody,
        actions: [action(l10n.outOfReadingsGetMore, onOpenOptions)],
      ),
      QuestionLowTrustLimited() => TaroInlineNotice(
        kind: TaroNoticeKind.info,
        title: l10n.outOfReadingsLowTrustTitle,
        body: l10n.outOfReadingsBody,
        actions: [action(l10n.outOfReadingsGetMore, onOpenOptions)],
      ),
      QuestionRephrase(:final safety) => TaroInlineNotice(
        kind: TaroNoticeKind.info,
        title: l10n.questionRephraseTitle,
        body: FailureMessage.forKey(l10n, safety.messageKey),
        liveRegion: true,
      ),
      QuestionRateLimited() => TaroInlineNotice(
        kind: TaroNoticeKind.warning,
        title: l10n.questionRateLimited,
        liveRegion: true,
        onDismiss: onDismiss,
        dismissLabel: l10n.commonDismiss,
      ),
      QuestionSpreadDisabled() => TaroInlineNotice(
        kind: TaroNoticeKind.warning,
        title: l10n.questionSpreadDisabled,
        liveRegion: true,
        actions: [action(l10n.spreadsTitle, onChooseSpread)],
      ),
      QuestionFailed(:final failure) => TaroInlineNotice(
        kind: TaroNoticeKind.error,
        title: FailureMessage.of(context, failure),
        liveRegion: true,
        actions: [action(l10n.commonRetry, onRetry)],
      ),
      _ => null,
    };
  }

  Widget _bottom(BuildContext context, BalanceChipView chip) {
    final l10n = TaroLocalizations.of(context);
    final tokens = context.tokens;
    Text caption(String text) => Text(
      text,
      textAlign: TextAlign.center,
      style: tokens.typography.caption.copyWith(
        color: tokens.color.text.tertiary,
      ),
    );
    final home = TaroButton.secondary(
      label: l10n.commonBackToToday,
      expand: true,
      onPressed: onHome ?? onBack,
    );
    final children = switch (state) {
      QuestionReadingsPaused() || QuestionAiUnavailableRegion() => [
        TaroButton.primary(
          label: l10n.questionTryClassic,
          expand: true,
          onPressed: onClassic,
        ),
        caption(l10n.questionClassicCaption),
        home,
      ],
      QuestionDailyLimitReached() => [home],
      _ => [
        if (state is QuestionOffline)
          TaroInlineNotice(
            kind: TaroNoticeKind.warning,
            title: l10n.questionOfflineNotice,
            liveRegion: true,
          ),
        TaroButton.primary(
          label: l10n.questionBegin,
          expand: true,
          loading: _checking,
          loadingSemanticsHint: l10n.commonLoading,
          onPressed: _beginEnabled ? onBegin : null,
        ),
        if (_canReflect)
          TaroButton.tertiary(
            label: l10n.questionReflectWithoutQuestion,
            onPressed: onReflectWithoutQuestion,
          )
        else if (_chargeLine(l10n, chip) case final line?)
          caption(line),
      ],
    };
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: tokens.space.s3,
      children: children,
    );
  }

  bool get _beginEnabled =>
      state.draft.canBegin &&
      switch (state) {
        QuestionEditing() ||
        QuestionRephrase() ||
        QuestionRefused() ||
        QuestionRateLimited() => true,
        _ => false,
      };

  static String? _chargeLine(TaroLocalizations l10n, BalanceChipView chip) {
    if (chip.balance == null || chip.sync == BalanceChipSync.unavailable) {
      return null;
    }
    if (chip.free > 0) return l10n.questionChargeFree;
    if (chip.credits > 0) return l10n.questionChargeCredits(chip.credits);
    return null;
  }
}

/// The S31-style card (`ReadingsPaused.dc.html`, `QuestionRefused.dc.html`):
/// icon tile, serif title, body, optional link chips and footer. Announced
/// politely when it appears.
class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.icon,
    required this.title,
    required this.body,
    this.links = const [],
    this.footer,
  });

  final IconData icon;
  final String title;
  final String body;
  final List<Widget> links;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final c = tokens.color;
    final tile = tokens.size.touchTarget.min;
    return Semantics(
      container: true,
      liveRegion: true,
      child: TaroSurfaceCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ExcludeSemantics(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: c.accent.subtle,
                      borderRadius: BorderRadius.circular(tokens.radius.md),
                    ),
                    child: SizedBox.square(
                      dimension: tile,
                      child: Icon(
                        icon,
                        size: tokens.size.icon.md,
                        color: c.status.info,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: tokens.space.s5),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: tokens.space.s2,
                    children: [
                      Semantics(
                        header: true,
                        child: Text(title, style: tokens.typography.cardName),
                      ),
                      Text(
                        body,
                        style: tokens.typography.body.copyWith(
                          color: c.text.secondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (links.isNotEmpty) ...[
              SizedBox(height: tokens.space.s5),
              Wrap(
                spacing: tokens.space.s3,
                runSpacing: tokens.space.s3,
                children: links,
              ),
            ],
            if (footer case final footer?) ...[
              SizedBox(height: tokens.space.s5),
              footer,
            ],
          ],
        ),
      ),
    );
  }
}

/// "✓ No reading was used" under the refusal card.
class _NoReadingUsed extends StatelessWidget {
  const _NoReadingUsed({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final color = tokens.color.status.info;
    return Row(
      spacing: tokens.space.s3,
      children: [
        Icon(Icons.check_rounded, size: tokens.size.icon.md, color: color),
        Expanded(
          child: Text(
            label,
            style: tokens.typography.label.copyWith(color: color),
          ),
        ),
      ],
    );
  }
}
