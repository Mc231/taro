import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:taro_core/src/model/json.dart';
import 'package:taro_core/src/result/ids.dart';

part 'reading_content.freezed.dart';

/// The interpretation of one position (RC30).
@freezed
abstract class PositionText with _$PositionText {
  /// Creates a position text.
  const factory PositionText({
    /// The spread position.
    required PositionId positionId,

    /// The interpretation (wire `cards[].interpretation`).
    required String text,
  }) = _PositionText;
}

/// The AI reading text in the client's domain shape (RC30, 01 §10.4).
///
/// The Worker sends no disclaimer; the client renders its own footer (PR9).
@Freezed(fromJson: false, toJson: false)
abstract class ReadingContent with _$ReadingContent {
  /// Creates the content.
  const factory ReadingContent({
    /// Title.
    required String title,

    /// Overview (wire `overview`).
    required String summary,

    /// One interpretation per position (wire `cards[]`).
    required List<PositionText> positions,

    /// Synthesis across the cards.
    required String synthesis,

    /// Up to three reflection prompts.
    required List<String> reflectionPrompts,
  }) = _ReadingContent;

  const ReadingContent._();

  /// Maps the 03 §9.1 wire `reading` object
  /// (`{title, overview, cards[{positionId, interpretation, …}], synthesis,
  /// reflectionPrompts}`); throws a [FormatException].
  factory ReadingContent.fromWire(Map<String, Object?> json) => ReadingContent(
    title: req<String>(json, 'title'),
    summary: req<String>(json, 'overview'),
    positions: [
      for (final card in reqMaps(json, 'cards'))
        PositionText(
          positionId: PositionId(req<String>(card, 'positionId')),
          text: req<String>(card, 'interpretation'),
        ),
    ],
    synthesis: req<String>(json, 'synthesis'),
    reflectionPrompts: reqStrings(json, 'reflectionPrompts'),
  );

  /// Parses the domain JSON written by [toJson] (backup `content`, local
  /// `content_json`); throws a [FormatException].
  factory ReadingContent.fromJson(Map<String, Object?> json) => ReadingContent(
    title: req<String>(json, 'title'),
    summary: req<String>(json, 'summary'),
    positions: [
      for (final p in reqMaps(json, 'positions'))
        PositionText(
          positionId: PositionId(req<String>(p, 'positionId')),
          text: req<String>(p, 'text'),
        ),
    ],
    synthesis: req<String>(json, 'synthesis'),
    reflectionPrompts: reqStrings(json, 'reflectionPrompts'),
  );

  /// The domain JSON (backup schema `content`).
  Map<String, Object?> toJson() => {
    'title': title,
    'summary': summary,
    'positions': [
      for (final p in positions)
        {'positionId': p.positionId.value, 'text': p.text},
    ],
    'synthesis': synthesis,
    'reflectionPrompts': reflectionPrompts,
  };

  /// The text for [positionId], or `null`.
  String? textFor(PositionId positionId) {
    for (final p in positions) {
      if (p.positionId == positionId) return p.text;
    }
    return null;
  }
}
