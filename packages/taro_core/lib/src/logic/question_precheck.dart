import 'package:characters/characters.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'question_precheck.freezed.dart';

/// Why a question cannot be sent (01 §7.2).
enum QuestionProblem {
  /// More grapheme clusters than `ai.questionMaxChars` (RC45).
  tooLong,

  /// Only emoji, punctuation, symbols or marks: nothing to read.
  noText,
}

/// The outcome of the client pre-check of a question (01 §7.2). It never
/// uses the network; authoritative moderation is the Worker's (03).
@freezed
abstract class QuestionCheck with _$QuestionCheck {
  /// Creates a check result.
  const factory QuestionCheck({
    /// The trimmed question; `null` when empty (the question is optional).
    required String? question,

    /// Grapheme clusters in [question].
    required int length,

    /// Why it cannot be sent; `null` when it can.
    required QuestionProblem? problem,

    /// Whether it looks like it contains an email address or phone number:
    /// warn "Avoid sharing personal details", never block.
    required bool personalDetailsWarning,
  }) = _QuestionCheck;

  const QuestionCheck._();

  /// Whether Begin may send it.
  bool get isValid => problem == null;
}

/// Client pre-checks of the question field (01 §7.2, RC45).
abstract final class QuestionPrecheck {
  /// Grapheme count from which the field shows a counter (01 §7.2).
  static const int counterFrom = 250;

  static final RegExp _textual = RegExp(r'[\p{L}\p{N}]', unicode: true);

  static final RegExp _email = RegExp(
    r'[^\s@]+@[^\s@]+\.[^\s@]{2,}',
    unicode: true,
  );

  /// A run of digits with common phone separators.
  static final RegExp _phoneRun = RegExp(
    r'\+?\p{Nd}[\p{Nd}\s().\-]{5,}\p{Nd}',
    unicode: true,
  );

  static final RegExp _digit = RegExp(r'\p{Nd}', unicode: true);

  /// Digits a phone-like run needs.
  static const int phoneMinDigits = 7;

  /// Checks [input] against [maxChars] (`ai.questionMaxChars`, grapheme
  /// clusters).
  static QuestionCheck check(String input, {required int maxChars}) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) {
      return const QuestionCheck(
        question: null,
        length: 0,
        problem: null,
        personalDetailsWarning: false,
      );
    }
    final length = trimmed.characters.length;
    final problem = !_textual.hasMatch(trimmed)
        ? QuestionProblem.noText
        : length > maxChars
        ? QuestionProblem.tooLong
        : null;
    return QuestionCheck(
      question: trimmed,
      length: length,
      problem: problem,
      personalDetailsWarning: looksPersonal(trimmed),
    );
  }

  /// [input] cut to at most [maxChars] grapheme clusters, so the field
  /// blocks the next one without splitting an emoji or a combining mark.
  static String limit(String input, {required int maxChars}) {
    final chars = input.characters;
    return chars.length <= maxChars ? input : chars.take(maxChars).toString();
  }

  /// Whether [text] seems to contain an email address or a phone number.
  static bool looksPersonal(String text) {
    if (_email.hasMatch(text)) return true;
    for (final m in _phoneRun.allMatches(text)) {
      if (_digit.allMatches(m[0]!).length >= phoneMinDigits) return true;
    }
    return false;
  }
}
