import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:taro_core/taro_core.dart';

part 'share_reading_use_case.freezed.dart';

/// Sends plain text through the system share sheet (PR19).
typedef ShareText = Future<Result<void>> Function(String text);

/// The localized lines of a shared reading that are not reading content
/// (ARB strings, resolved by the caller).
@freezed
abstract class ShareCopy with _$ShareCopy {
  /// Creates the copy.
  const factory ShareCopy({
    /// The disclaimer line (05 §3 `disclaimerShort`).
    required String disclaimerLine,

    /// The label before the question, e.g. "My question".
    required String questionLabel,

    /// The orientation label appended to a reversed card, e.g. "Reversed".
    required String reversedLabel,

    /// The title when the reading has none (Classic): the spread name.
    required String fallbackTitle,
  }) = _ShareCopy;
}

/// Share a reading as text (PR19): the localized card names, the summary,
/// a short excerpt and the disclaimer line. The question is included only
/// when [call]'s `includeQuestion` is on; the note never is.
final class ShareReadingUseCase {
  /// Creates the use case.
  ShareReadingUseCase({
    required ContentRepository content,
    required ShareText share,
  }) : _content = content,
       _share = share;

  /// The excerpt limit in characters (UTF-16 code units are close enough
  /// for a trimmed preview; the cut never splits a surrogate pair).
  static const int excerptMaxChars = 280;

  final ContentRepository _content;
  final ShareText _share;

  /// Builds the text of [reading] with card names in [locale].
  Future<Result<String>> buildText(
    Reading reading,
    ShareCopy copy, {
    required String locale,
    required bool includeQuestion,
  }) async {
    final names = <String>[];
    for (final card in reading.cards) {
      final text = await _content.cardText(card.cardId, locale);
      switch (text) {
        case Ok(:final value):
          names.add(
            card.reversed
                ? '${value.name} (${copy.reversedLabel})'
                : value.name,
          );
        case Err(:final failure):
          return Result.err(failure);
      }
    }
    final content = reading.content;
    final question = reading.question;
    final excerpt = content == null ? null : _excerpt(content.synthesis);
    final lines = [
      content?.title ?? copy.fallbackTitle,
      if (includeQuestion && question != null)
        '${copy.questionLabel}: $question',
      names.join(' · '),
      if (content != null) content.summary,
      ?excerpt,
      copy.disclaimerLine,
    ];
    return Result.ok(lines.where((l) => l.trim().isNotEmpty).join('\n\n'));
  }

  /// Builds the text and opens the share sheet.
  Future<Result<void>> call(
    Reading reading,
    ShareCopy copy, {
    required String locale,
    required bool includeQuestion,
  }) async {
    final text = await buildText(
      reading,
      copy,
      locale: locale,
      includeQuestion: includeQuestion,
    );
    return text.then(_share);
  }

  static String? _excerpt(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return null;
    if (trimmed.length <= excerptMaxChars) return trimmed;
    var end = excerptMaxChars;
    final unit = trimmed.codeUnitAt(end - 1);
    if (unit >= 0xD800 && unit <= 0xDBFF) end--;
    final cut = trimmed.substring(0, end);
    final space = cut.lastIndexOf(' ');
    return '${(space > 0 ? cut.substring(0, space) : cut).trimRight()}…';
  }
}
