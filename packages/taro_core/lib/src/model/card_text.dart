import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:taro_core/src/result/ids.dart';

part 'card_text.freezed.dart';

/// Whether a translation was reviewed by a person (01 §10.1, §11).
enum ReviewStatus {
  /// Machine translation, not yet reviewed.
  machine,

  /// Reviewed by a person.
  reviewed,
}

/// Aspect meanings of a card, upright and reversed (01 §10.1).
@freezed
abstract class CardAspects with _$CardAspects {
  /// Creates the aspects.
  const factory CardAspects({
    /// Relationships, upright.
    required String relationshipsUpright,

    /// Relationships, reversed.
    required String relationshipsReversed,

    /// Work, upright.
    required String workUpright,

    /// Work, reversed.
    required String workReversed,

    /// Personal growth, upright.
    required String growthUpright,

    /// Personal growth, reversed.
    required String growthReversed,
  }) = _CardAspects;
}

/// The localized text of one card (01 §10.1). Built by `tools/content build`
/// and bundled; length limits are enforced by the content pipeline (Phase 5).
@freezed
abstract class CardText with _$CardText {
  /// Creates the text of [cardId] in [locale].
  const factory CardText({
    /// The card this text belongs to.
    required CardId cardId,

    /// One of the 12 app locales.
    required String locale,

    /// Glossary-locked card name.
    required String name,

    /// 3–6 upright keywords.
    required List<String> keywordsUpright,

    /// 3–6 reversed keywords.
    required List<String> keywordsReversed,

    /// ≤ 160 chars; daily card and reveal.
    required String shortUpright,

    /// ≤ 160 chars.
    required String shortReversed,

    /// 120–220 words.
    required String meaningUpright,

    /// 100–200 words.
    required String meaningReversed,

    /// Aspect meanings.
    required CardAspects aspects,

    /// Three reflection questions.
    required List<String> reflectionQuestions,

    /// Hash of the `en` source this translation came from.
    required String sourceHash,

    /// Review state of this translation.
    required ReviewStatus reviewStatus,

    /// 40–100 words on the art's symbolism.
    String? imageryNote,
  }) = _CardText;

  const CardText._();

  /// The keywords for the given orientation.
  List<String> keywords({required bool reversed}) =>
      reversed ? keywordsReversed : keywordsUpright;

  /// The short meaning for the given orientation.
  String short({required bool reversed}) =>
      reversed ? shortReversed : shortUpright;

  /// The full meaning for the given orientation.
  String meaning({required bool reversed}) =>
      reversed ? meaningReversed : meaningUpright;
}
