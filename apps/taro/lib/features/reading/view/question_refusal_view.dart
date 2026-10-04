import 'package:flutter/material.dart';
import 'package:taro/features/reading/controller/question_state.dart';
import 'package:taro/l10n/generated/taro_localizations.dart';
import 'package:taro_core/taro_core.dart';
import 'package:taro_ui/taro_ui.dart';

/// The copy and actions of the S07 refusal state for one
/// [RefusalCategory] (S07 refusal spec, 01 §7.5, 03 §9.4, 05 §4.1, RC27).
///
/// A declined question is not an error: the state says calmly what Taro
/// can't read, that nothing was charged, and how to go on.
@immutable
final class RefusalCopy {
  const RefusalCopy._(this.category);

  /// The copy of [category].
  factory RefusalCopy.of(RefusalCategory category) => RefusalCopy._(category);

  /// The declined category.
  final RefusalCategory category;

  /// Whether the question may be reworded here: every category except
  /// `sexual_minors` and the crisis categories (`self_harm`,
  /// `harm_to_others` land on S27 first).
  bool get canRephrase =>
      category != RefusalCategory.sexualMinors &&
      !category.showsCrisisResources;

  /// Whether "Reflect on the cards without a question" may be offered (the
  /// moderation-blocked categories never get it, 05 §4.1).
  bool get canReflect =>
      !category.isModerationBlocked && !category.showsCrisisResources;

  /// The icon of the state's tile: gentle, never a warning sign.
  IconData get icon => switch (category) {
    RefusalCategory.health => Icons.spa_outlined,
    RefusalCategory.pregnancy => Icons.favorite_border_rounded,
    RefusalCategory.death => Icons.local_florist_outlined,
    RefusalCategory.legal => Icons.balance_outlined,
    RefusalCategory.financial => Icons.savings_outlined,
    RefusalCategory.gambling => Icons.casino_outlined,
    RefusalCategory.selfHarm ||
    RefusalCategory.harmToOthers ||
    RefusalCategory.sexualMinors ||
    RefusalCategory.hateOrHarassment ||
    RefusalCategory.other => Icons.info_outline_rounded,
  };

  /// The one-line, category-specific explanation (no judgement, no
  /// advice; the advice categories name the right professional).
  String reason(TaroLocalizations l10n) => switch (category) {
    RefusalCategory.health => l10n.questionRefusalReasonHealth,
    RefusalCategory.pregnancy => l10n.questionRefusalReasonPregnancy,
    RefusalCategory.death => l10n.questionRefusalReasonDeath,
    RefusalCategory.legal => l10n.questionRefusalReasonLegal,
    RefusalCategory.financial => l10n.questionRefusalReasonFinancial,
    RefusalCategory.gambling => l10n.questionRefusalReasonGambling,
    RefusalCategory.hateOrHarassment => l10n.questionRefusalReasonHate,
    RefusalCategory.sexualMinors => l10n.safetyDeclinedSexualMinors,
    RefusalCategory.selfHarm => l10n.safetyDeclinedSelfHarm,
    RefusalCategory.harmToOthers => l10n.safetyDeclinedHarmToOthers,
    RefusalCategory.other => l10n.questionRefusalReasonOther,
  };

  /// The reflective rewordings for the category (none when it can't be
  /// reworded or is moderation-blocked).
  List<String> ideas(TaroLocalizations l10n) => switch (category) {
    RefusalCategory.health => [
      l10n.questionRefusalIdeaHealth1,
      l10n.questionRefusalIdeaHealth2,
      l10n.questionRefusalIdeaHealth3,
    ],
    RefusalCategory.pregnancy => [
      l10n.questionRefusalIdeaPregnancy1,
      l10n.questionRefusalIdeaPregnancy2,
      l10n.questionRefusalIdeaPregnancy3,
    ],
    RefusalCategory.death => [
      l10n.questionRefusalIdeaDeath1,
      l10n.questionRefusalIdeaDeath2,
      l10n.questionRefusalIdeaDeath3,
    ],
    RefusalCategory.legal => [
      l10n.questionRefusalIdeaLegal1,
      l10n.questionRefusalIdeaLegal2,
      l10n.questionRefusalIdeaLegal3,
    ],
    RefusalCategory.financial => [
      l10n.questionRefusalIdeaFinancial1,
      l10n.questionRefusalIdeaFinancial2,
      l10n.questionRefusalIdeaFinancial3,
    ],
    RefusalCategory.gambling => [
      l10n.questionRefusalIdeaGambling1,
      l10n.questionRefusalIdeaGambling2,
      l10n.questionRefusalIdeaGambling3,
    ],
    RefusalCategory.other => [
      l10n.questionRephraseExample1,
      l10n.questionRephraseExample2,
      l10n.questionRefusalIdeaOther3,
    ],
    RefusalCategory.hateOrHarassment ||
    RefusalCategory.sexualMinors ||
    RefusalCategory.selfHarm ||
    RefusalCategory.harmToOthers => const [],
  };
}

/// The refusal category of an S07 refusal state, or `null` for any other
/// state.
RefusalCategory? refusalCategoryOf(QuestionState state) => switch (state) {
  QuestionRephrase(:final safety) => safety.category,
  QuestionRefused(:final category) => category,
  _ => null,
};

/// The S07 refusal body ("We can't read this question"): icon tile,
/// headline, category reason, the declined question, the not-charged line,
/// rewording chips and the drawn-cards note. The actions sit in the S07
/// bottom area. Announced politely when it appears.
class QuestionRefusalView extends StatelessWidget {
  /// Creates the view.
  const QuestionRefusalView({
    required this.category,
    required this.question,
    required this.notCharged,
    required this.cardsKept,
    required this.onIdea,
    super.key,
  });

  /// The declined category.
  final RefusalCategory category;

  /// The declined question (may be empty).
  final String question;

  /// Whether the Worker response says nothing was charged.
  final bool notCharged;

  /// Whether the drawn cards can be reused ("Reflect on the cards without a
  /// question" is offered).
  final bool cardsKept;

  /// A rewording chip was tapped: it fills the editor.
  final ValueChanged<String> onIdea;

  @override
  Widget build(BuildContext context) {
    final l10n = TaroLocalizations.of(context);
    final tokens = context.tokens;
    final c = tokens.color;
    final copy = RefusalCopy.of(category);
    final ideas = copy.ideas(l10n);
    final text = question.trim();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          container: true,
          liveRegion: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ExcludeSemantics(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: c.accent.subtle,
                    borderRadius: BorderRadius.circular(tokens.radius.lg),
                  ),
                  child: SizedBox.square(
                    dimension: tokens.space.s11,
                    child: Icon(
                      copy.icon,
                      size: tokens.size.icon.lg,
                      color: c.accent.primary,
                    ),
                  ),
                ),
              ),
              SizedBox(height: tokens.space.s6),
              Semantics(
                header: true,
                child: Text(
                  l10n.questionRefusalTitle,
                  style: tokens.typography.headline,
                ),
              ),
              SizedBox(height: tokens.space.s3),
              Text(
                copy.reason(l10n),
                style: tokens.typography.body.copyWith(
                  color: c.text.secondary,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: tokens.space.s7),
        TaroSurfaceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (text.isNotEmpty) ...[
                Text(
                  l10n.questionRefusalYourQuestion,
                  style: tokens.typography.caption.copyWith(
                    color: c.text.tertiary,
                  ),
                ),
                SizedBox(height: tokens.space.s2),
                Text(
                  text,
                  style: tokens.typography.bodyReading.copyWith(
                    color: c.text.primary,
                  ),
                ),
                if (notCharged) ...[
                  SizedBox(height: tokens.space.s5),
                  Divider(height: tokens.space.s0, color: c.border.subtle),
                  SizedBox(height: tokens.space.s5),
                ],
              ],
              if (notCharged)
                _NotCharged(label: l10n.questionRefusalNotCharged),
            ],
          ),
        ),
        if (ideas.isNotEmpty) ...[
          SizedBox(height: tokens.space.s7),
          Text(
            l10n.questionRefusalIdeasCaption,
            style: tokens.typography.label.copyWith(color: c.text.tertiary),
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
                  child: TaroChip.suggestion(
                    label: idea,
                    onPressed: () => onIdea(idea),
                  ),
                ),
            ],
          ),
        ],
        if (cardsKept) ...[
          SizedBox(height: tokens.space.s6),
          Text(
            l10n.questionRefusalCardsKept,
            style: tokens.typography.caption.copyWith(color: c.text.secondary),
          ),
        ],
      ],
    );
  }
}

/// "✓ Not charged. Your reading is still available." (the Worker refunded
/// the declined reading).
class _NotCharged extends StatelessWidget {
  const _NotCharged({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final c = tokens.color;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: tokens.space.s3,
      children: [
        ExcludeSemantics(
          child: Icon(
            Icons.check_circle_outline_rounded,
            size: tokens.size.icon.md,
            color: c.status.success,
          ),
        ),
        Expanded(
          child: Text(
            label,
            style: tokens.typography.label.copyWith(color: c.text.primary),
          ),
        ),
      ],
    );
  }
}
