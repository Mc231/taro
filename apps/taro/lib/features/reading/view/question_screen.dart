import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:taro/common/balance_chip.dart';
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

/// The S07 / S31 layout for [state].
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
    super.key,
  });

  /// The controller state.
  final QuestionState state;

  /// The question field's text.
  final TextEditingController text;

  /// The question changed.
  final ValueChanged<String> onChanged;

  /// A suggestion chip was tapped.
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = TaroLocalizations.of(context);
    final tokens = context.tokens;
    final draft = state.draft;
    final spread = draft.spread;
    final checking = state is QuestionChecking || state is QuestionReady;
    final editable = switch (state) {
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
    final beginEnabled =
        draft.canBegin &&
        switch (state) {
          QuestionEditing() ||
          QuestionRephrase() ||
          QuestionRefused() ||
          QuestionRateLimited() => true,
          _ => false,
        };
    final chip = ref.watch(balanceChipProvider);
    final notice = _notice(context);
    return TaroScaffold(
      appBar: TaroAppBar(
        onLeading: onBack,
        leadingLabel: l10n.commonBack,
        title: spread == null ? null : SpreadText.name(l10n, spread.id),
      ),
      topBanner: const OfflineBanner(),
      body: ListView(
        padding: EdgeInsetsDirectional.only(bottom: tokens.space.s7),
        children: [
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: BalanceChip(today: true, onTap: onOpenOptions),
          ),
          SizedBox(height: tokens.space.s5),
          Semantics(
            header: true,
            child: Text(l10n.questionTitle, style: tokens.typography.headline),
          ),
          SizedBox(height: tokens.space.s5),
          TaroTextField(
            controller: text,
            style: TaroTextFieldStyle.multiLine,
            label: l10n.questionLabel,
            hintText: l10n.questionHint,
            maxGraphemes: draft.maxChars,
            counterFormatter: l10n.commonNoteCounter,
            errorText: draft.check.problem == QuestionProblem.noText
                ? l10n.questionOnlySymbols
                : null,
            helperText: draft.check.personalDetailsWarning
                ? l10n.questionPersonalDetails
                : null,
            enabled: editable,
            onChanged: onChanged,
          ),
          if (spread != null && editable) ...[
            SizedBox(height: tokens.space.s5),
            Text(l10n.questionIdeas, style: tokens.typography.label),
            SizedBox(height: tokens.space.s3),
            Wrap(
              spacing: tokens.space.s3,
              runSpacing: tokens.space.s3,
              children: [
                for (final key in spread.questionSuggestionKeys)
                  if (SpreadText.lookup(l10n, key) case final suggestion?)
                    Semantics(
                      label: l10n.questionSuggestionSemantics(suggestion),
                      excludeSemantics: true,
                      button: true,
                      child: TaroChip.suggestion(
                        label: suggestion,
                        onPressed: () => onSuggestion(suggestion),
                      ),
                    ),
              ],
            ),
          ],
          if (notice != null) ...[
            SizedBox(height: tokens.space.s7),
            notice,
          ],
        ],
      ),
      bottom: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: tokens.space.s3,
        children: [
          TaroButton.primary(
            label: l10n.questionBegin,
            expand: true,
            loading: checking,
            loadingSemanticsHint: l10n.commonLoading,
            onPressed: beginEnabled ? onBegin : null,
          ),
          if (_chargeLine(l10n, chip) case final line?)
            Text(
              line,
              style: tokens.typography.caption.copyWith(
                color: tokens.color.text.tertiary,
              ),
            ),
        ],
      ),
    );
  }

  static String? _chargeLine(TaroLocalizations l10n, BalanceChipView chip) {
    if (chip.balance == null || chip.sync == BalanceChipSync.unavailable) {
      return null;
    }
    if (chip.free > 0) return l10n.questionChargeFree;
    if (chip.credits > 0) return l10n.questionChargeCredits(chip.credits);
    return null;
  }

  Widget? _notice(BuildContext context) {
    final l10n = TaroLocalizations.of(context);
    Widget action(String label, VoidCallback onPressed) =>
        TaroButton.tertiary(label: label, onPressed: onPressed);
    final classic = action(l10n.questionTryClassic, onClassic);
    return switch (state) {
      QuestionEditing() || QuestionChecking() || QuestionReady() => null,
      QuestionOffline() => TaroInlineNotice(
        kind: TaroNoticeKind.warning,
        title: l10n.questionOfflineNotice,
        liveRegion: true,
      ),
      QuestionConsentRequired() => TaroInlineNotice(
        kind: TaroNoticeKind.info,
        title: l10n.questionConsentDeclinedNotice,
        body: l10n.questionClassicCaption,
        actions: [action(l10n.aiConsentAccept, onOpenConsent), classic],
      ),
      QuestionDeviceUnverified() => TaroInlineNotice(
        kind: TaroNoticeKind.warning,
        title: l10n.questionDeviceUnverified,
        body: l10n.errorDeviceUnverifiedBody,
        actions: [action(l10n.commonRetry, onRetry)],
      ),
      QuestionReadingsPaused(:final freePaused) => TaroInlineNotice(
        kind: TaroNoticeKind.info,
        prominent: true,
        title: freePaused ? l10n.pausedFreeTitle : l10n.pausedTitle,
        body: l10n.pausedBody,
        actions: [
          action(l10n.commonDailyCard, onDailyCard),
          action(l10n.commonLearn, onLearn),
          classic,
        ],
      ),
      QuestionAiUnavailableRegion() => TaroInlineNotice(
        kind: TaroNoticeKind.info,
        title: l10n.pausedRegionTitle,
        body: l10n.pausedRegionBody,
        actions: [classic],
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
      QuestionDailyLimitReached() => TaroInlineNotice(
        kind: TaroNoticeKind.info,
        title: l10n.questionDailyLimitTitle,
        body: l10n.questionDailyLimitBody,
        actions: [
          action(l10n.commonDailyCard, onDailyCard),
          action(l10n.commonLearn, onLearn),
        ],
      ),
      QuestionRephrase(:final safety) => TaroInlineNotice(
        kind: TaroNoticeKind.info,
        title: l10n.questionRephraseTitle,
        body: [
          FailureMessage.forKey(l10n, safety.messageKey),
          l10n.questionRephraseExamples,
          l10n.questionRephraseExample1,
          l10n.questionRephraseExample2,
        ].join('\n'),
        actions: [
          action(l10n.questionReflectWithoutQuestion, onReflectWithoutQuestion),
        ],
      ),
      QuestionRefused(:final category) => TaroInlineNotice(
        kind: TaroNoticeKind.info,
        title: l10n.questionRefusedTitle,
        body:
            '${FailureMessage.refusal(l10n, category)}\n'
            '${l10n.questionRefusedProfessional}',
        onDismiss: onDismiss,
        dismissLabel: l10n.commonDismiss,
      ),
      QuestionRateLimited() => TaroInlineNotice(
        kind: TaroNoticeKind.warning,
        title: l10n.questionRateLimited,
        onDismiss: onDismiss,
        dismissLabel: l10n.commonDismiss,
      ),
      QuestionSpreadDisabled() => TaroInlineNotice(
        kind: TaroNoticeKind.warning,
        title: l10n.questionSpreadDisabled,
        actions: [action(l10n.spreadsTitle, onChooseSpread)],
      ),
      QuestionFailed(:final failure) => TaroInlineNotice(
        kind: TaroNoticeKind.error,
        title: FailureMessage.of(context, failure),
        actions: [action(l10n.commonRetry, onRetry)],
      ),
    };
  }
}
