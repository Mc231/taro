import 'package:taro/l10n/generated/taro_localizations.dart';
import 'package:taro_core/taro_core.dart';

/// Localised spread text by ARB key (`spread_{id}_name`, `_meta`,
/// `_whenToUse`, `_pos_{pos}_name` / `_desc`, `_suggestion_{n}`; 01 §10.2,
/// GLOSSARY). Spread definitions carry IDs, never text, so views resolve
/// the text here; an unknown key yields `null` (never a raw key).
abstract final class SpreadText {
  /// The text of the ARB [key], or `null` when no such key exists.
  static String? lookup(TaroLocalizations l10n, String key) =>
      _byKey[key]?.call(l10n);

  /// The spread name ("Celtic Cross"); the ID when unknown.
  static String name(TaroLocalizations l10n, SpreadId id) =>
      lookup(l10n, 'spread_${id.value}_name') ?? id.value;

  /// The spread's one-line meta ("10 cards · deep dive").
  static String? meta(TaroLocalizations l10n, SpreadId id) =>
      lookup(l10n, 'spread_${id.value}_meta');

  /// "When to use it" of the spread.
  static String? whenToUse(TaroLocalizations l10n, SpreadId id) =>
      lookup(l10n, 'spread_${id.value}_whenToUse');

  /// The name of [position] in [spread]; the position ID when unknown.
  static String positionName(
    TaroLocalizations l10n,
    SpreadId spread,
    PositionId position,
  ) =>
      lookup(l10n, 'spread_${spread.value}_pos_${position.value}_name') ??
      position.value;

  /// The description of [position] in [spread].
  static String? positionDescription(
    TaroLocalizations l10n,
    SpreadId spread,
    PositionId position,
  ) => lookup(l10n, 'spread_${spread.value}_pos_${position.value}_desc');

  static final Map<String, String Function(TaroLocalizations)> _byKey = {
    'spread_single_name': (l) => l.spread_single_name,
    'spread_single_meta': (l) => l.spread_single_meta,
    'spread_single_whenToUse': (l) => l.spread_single_whenToUse,
    'spread_three_ppf_name': (l) => l.spread_three_ppf_name,
    'spread_three_ppf_meta': (l) => l.spread_three_ppf_meta,
    'spread_three_ppf_whenToUse': (l) => l.spread_three_ppf_whenToUse,
    'spread_three_sao_name': (l) => l.spread_three_sao_name,
    'spread_three_sao_meta': (l) => l.spread_three_sao_meta,
    'spread_three_sao_whenToUse': (l) => l.spread_three_sao_whenToUse,
    'spread_relationship_name': (l) => l.spread_relationship_name,
    'spread_relationship_meta': (l) => l.spread_relationship_meta,
    'spread_relationship_whenToUse': (l) => l.spread_relationship_whenToUse,
    'spread_two_paths_name': (l) => l.spread_two_paths_name,
    'spread_two_paths_meta': (l) => l.spread_two_paths_meta,
    'spread_two_paths_whenToUse': (l) => l.spread_two_paths_whenToUse,
    'spread_celtic_cross_name': (l) => l.spread_celtic_cross_name,
    'spread_celtic_cross_meta': (l) => l.spread_celtic_cross_meta,
    'spread_celtic_cross_whenToUse': (l) => l.spread_celtic_cross_whenToUse,
    'spread_single_pos_focus_name': (l) => l.spread_single_pos_focus_name,
    'spread_single_pos_focus_desc': (l) => l.spread_single_pos_focus_desc,
    'spread_three_ppf_pos_past_name': (l) => l.spread_three_ppf_pos_past_name,
    'spread_three_ppf_pos_past_desc': (l) => l.spread_three_ppf_pos_past_desc,
    'spread_three_ppf_pos_present_name': (l) =>
        l.spread_three_ppf_pos_present_name,
    'spread_three_ppf_pos_present_desc': (l) =>
        l.spread_three_ppf_pos_present_desc,
    'spread_three_ppf_pos_future_name': (l) =>
        l.spread_three_ppf_pos_future_name,
    'spread_three_ppf_pos_future_desc': (l) =>
        l.spread_three_ppf_pos_future_desc,
    'spread_three_sao_pos_situation_name': (l) =>
        l.spread_three_sao_pos_situation_name,
    'spread_three_sao_pos_situation_desc': (l) =>
        l.spread_three_sao_pos_situation_desc,
    'spread_three_sao_pos_action_name': (l) =>
        l.spread_three_sao_pos_action_name,
    'spread_three_sao_pos_action_desc': (l) =>
        l.spread_three_sao_pos_action_desc,
    'spread_three_sao_pos_outcome_name': (l) =>
        l.spread_three_sao_pos_outcome_name,
    'spread_three_sao_pos_outcome_desc': (l) =>
        l.spread_three_sao_pos_outcome_desc,
    'spread_relationship_pos_you_name': (l) =>
        l.spread_relationship_pos_you_name,
    'spread_relationship_pos_you_desc': (l) =>
        l.spread_relationship_pos_you_desc,
    'spread_relationship_pos_other_name': (l) =>
        l.spread_relationship_pos_other_name,
    'spread_relationship_pos_other_desc': (l) =>
        l.spread_relationship_pos_other_desc,
    'spread_relationship_pos_connection_name': (l) =>
        l.spread_relationship_pos_connection_name,
    'spread_relationship_pos_connection_desc': (l) =>
        l.spread_relationship_pos_connection_desc,
    'spread_relationship_pos_challenge_name': (l) =>
        l.spread_relationship_pos_challenge_name,
    'spread_relationship_pos_challenge_desc': (l) =>
        l.spread_relationship_pos_challenge_desc,
    'spread_relationship_pos_potential_name': (l) =>
        l.spread_relationship_pos_potential_name,
    'spread_relationship_pos_potential_desc': (l) =>
        l.spread_relationship_pos_potential_desc,
    'spread_two_paths_pos_situation_name': (l) =>
        l.spread_two_paths_pos_situation_name,
    'spread_two_paths_pos_situation_desc': (l) =>
        l.spread_two_paths_pos_situation_desc,
    'spread_two_paths_pos_path_a_name': (l) =>
        l.spread_two_paths_pos_path_a_name,
    'spread_two_paths_pos_path_a_desc': (l) =>
        l.spread_two_paths_pos_path_a_desc,
    'spread_two_paths_pos_path_a_outcome_name': (l) =>
        l.spread_two_paths_pos_path_a_outcome_name,
    'spread_two_paths_pos_path_a_outcome_desc': (l) =>
        l.spread_two_paths_pos_path_a_outcome_desc,
    'spread_two_paths_pos_path_b_name': (l) =>
        l.spread_two_paths_pos_path_b_name,
    'spread_two_paths_pos_path_b_desc': (l) =>
        l.spread_two_paths_pos_path_b_desc,
    'spread_two_paths_pos_path_b_outcome_name': (l) =>
        l.spread_two_paths_pos_path_b_outcome_name,
    'spread_two_paths_pos_path_b_outcome_desc': (l) =>
        l.spread_two_paths_pos_path_b_outcome_desc,
    'spread_celtic_cross_pos_present_name': (l) =>
        l.spread_celtic_cross_pos_present_name,
    'spread_celtic_cross_pos_present_desc': (l) =>
        l.spread_celtic_cross_pos_present_desc,
    'spread_celtic_cross_pos_challenge_name': (l) =>
        l.spread_celtic_cross_pos_challenge_name,
    'spread_celtic_cross_pos_challenge_desc': (l) =>
        l.spread_celtic_cross_pos_challenge_desc,
    'spread_celtic_cross_pos_foundation_name': (l) =>
        l.spread_celtic_cross_pos_foundation_name,
    'spread_celtic_cross_pos_foundation_desc': (l) =>
        l.spread_celtic_cross_pos_foundation_desc,
    'spread_celtic_cross_pos_recent_past_name': (l) =>
        l.spread_celtic_cross_pos_recent_past_name,
    'spread_celtic_cross_pos_recent_past_desc': (l) =>
        l.spread_celtic_cross_pos_recent_past_desc,
    'spread_celtic_cross_pos_potential_name': (l) =>
        l.spread_celtic_cross_pos_potential_name,
    'spread_celtic_cross_pos_potential_desc': (l) =>
        l.spread_celtic_cross_pos_potential_desc,
    'spread_celtic_cross_pos_near_future_name': (l) =>
        l.spread_celtic_cross_pos_near_future_name,
    'spread_celtic_cross_pos_near_future_desc': (l) =>
        l.spread_celtic_cross_pos_near_future_desc,
    'spread_celtic_cross_pos_self_name': (l) =>
        l.spread_celtic_cross_pos_self_name,
    'spread_celtic_cross_pos_self_desc': (l) =>
        l.spread_celtic_cross_pos_self_desc,
    'spread_celtic_cross_pos_environment_name': (l) =>
        l.spread_celtic_cross_pos_environment_name,
    'spread_celtic_cross_pos_environment_desc': (l) =>
        l.spread_celtic_cross_pos_environment_desc,
    'spread_celtic_cross_pos_hopes_fears_name': (l) =>
        l.spread_celtic_cross_pos_hopes_fears_name,
    'spread_celtic_cross_pos_hopes_fears_desc': (l) =>
        l.spread_celtic_cross_pos_hopes_fears_desc,
    'spread_celtic_cross_pos_outcome_name': (l) =>
        l.spread_celtic_cross_pos_outcome_name,
    'spread_celtic_cross_pos_outcome_desc': (l) =>
        l.spread_celtic_cross_pos_outcome_desc,
    'spread_single_suggestion_1': (l) => l.spread_single_suggestion_1,
    'spread_single_suggestion_2': (l) => l.spread_single_suggestion_2,
    'spread_single_suggestion_3': (l) => l.spread_single_suggestion_3,
    'spread_three_ppf_suggestion_1': (l) => l.spread_three_ppf_suggestion_1,
    'spread_three_ppf_suggestion_2': (l) => l.spread_three_ppf_suggestion_2,
    'spread_three_ppf_suggestion_3': (l) => l.spread_three_ppf_suggestion_3,
    'spread_three_sao_suggestion_1': (l) => l.spread_three_sao_suggestion_1,
    'spread_three_sao_suggestion_2': (l) => l.spread_three_sao_suggestion_2,
    'spread_three_sao_suggestion_3': (l) => l.spread_three_sao_suggestion_3,
    'spread_relationship_suggestion_1': (l) =>
        l.spread_relationship_suggestion_1,
    'spread_relationship_suggestion_2': (l) =>
        l.spread_relationship_suggestion_2,
    'spread_relationship_suggestion_3': (l) =>
        l.spread_relationship_suggestion_3,
    'spread_relationship_suggestion_4': (l) =>
        l.spread_relationship_suggestion_4,
    'spread_two_paths_suggestion_1': (l) => l.spread_two_paths_suggestion_1,
    'spread_two_paths_suggestion_2': (l) => l.spread_two_paths_suggestion_2,
    'spread_two_paths_suggestion_3': (l) => l.spread_two_paths_suggestion_3,
    'spread_celtic_cross_suggestion_1': (l) =>
        l.spread_celtic_cross_suggestion_1,
    'spread_celtic_cross_suggestion_2': (l) =>
        l.spread_celtic_cross_suggestion_2,
    'spread_celtic_cross_suggestion_3': (l) =>
        l.spread_celtic_cross_suggestion_3,
    'spread_celtic_cross_suggestion_4': (l) =>
        l.spread_celtic_cross_suggestion_4,
  };
}
