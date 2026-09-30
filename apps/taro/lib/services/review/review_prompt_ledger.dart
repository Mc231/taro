import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:taro_core/taro_core.dart';

/// What the review policy remembers between launches (01 §6.1).
@immutable
final class ReviewPromptState {
  /// A state; the default is a fresh install.
  const ReviewPromptState({
    this.positiveRatings = 0,
    this.lastPromptAt,
    this.refused = false,
  });

  /// Parses [toJson]; throws a [FormatException] or a [TypeError] on a
  /// malformed value.
  factory ReviewPromptState.fromJson(Map<String, Object?> json) {
    final last = json['lastPromptAt'] as String?;
    return ReviewPromptState(
      positiveRatings: json['positiveRatings']! as int,
      lastPromptAt: last == null ? null : DateTime.parse(last).toUtc(),
      refused: json['refused']! as bool,
    );
  }

  /// Positively rated AI readings since the last prompt.
  final int positiveRatings;

  /// When the prompt was last requested (UTC), if ever.
  final DateTime? lastPromptAt;

  /// The user refused to review; the app never asks again.
  final bool refused;

  /// A copy with the given fields replaced.
  ReviewPromptState copyWith({
    int? positiveRatings,
    DateTime? lastPromptAt,
    bool? refused,
  }) => ReviewPromptState(
    positiveRatings: positiveRatings ?? this.positiveRatings,
    lastPromptAt: lastPromptAt ?? this.lastPromptAt,
    refused: refused ?? this.refused,
  );

  /// The stored JSON.
  Map<String, Object?> toJson() => {
    'positiveRatings': positiveRatings,
    'lastPromptAt': lastPromptAt?.toUtc().toIso8601String(),
    'refused': refused,
  };

  @override
  bool operator ==(Object other) =>
      other is ReviewPromptState &&
      other.positiveRatings == positiveRatings &&
      other.lastPromptAt == lastPromptAt &&
      other.refused == refused;

  @override
  int get hashCode => Object.hash(positiveRatings, lastPromptAt, refused);
}

/// Persists the [ReviewPromptState]. `null` from [read] means it could not
/// be read, and the prompter then stays silent.
abstract interface class ReviewPromptLedger {
  /// The stored state; a fresh state when nothing is stored.
  Future<ReviewPromptState?> read();

  /// Stores [state]; `false` when it could not be stored.
  Future<bool> write(ReviewPromptState state);
}

/// A [ReviewPromptLedger] in memory (tests, screenshot mode).
final class InMemoryReviewPromptLedger implements ReviewPromptLedger {
  /// A ledger holding [state].
  InMemoryReviewPromptLedger([this.state = const ReviewPromptState()]);

  /// The stored state.
  ReviewPromptState state;

  @override
  Future<ReviewPromptState?> read() async => state;

  @override
  Future<bool> write(ReviewPromptState state) async {
    this.state = state;
    return true;
  }
}

/// A [ReviewPromptLedger] stored as JSON under the secure-storage key
/// `taro.review_prompt` (GLOSSARY §12): device-local and never exported,
/// like every secure-storage key.
final class SecureStoreReviewPromptLedger implements ReviewPromptLedger {
  /// A ledger over the secure store.
  const SecureStoreReviewPromptLedger(this._store);

  /// The secure-storage key.
  static const String key = 'taro.review_prompt';

  final SecureStore _store;

  @override
  Future<ReviewPromptState?> read() async {
    switch (await _store.read(key)) {
      case Err():
        return null;
      case Ok(:final value):
        if (value == null) return const ReviewPromptState();
        try {
          final json = jsonDecode(value);
          if (json is! Map<String, Object?>) return const ReviewPromptState();
          return ReviewPromptState.fromJson(json);
        } on Object {
          // A corrupt value starts over rather than blocking forever.
          return const ReviewPromptState();
        }
    }
  }

  @override
  Future<bool> write(ReviewPromptState state) async =>
      (await _store.write(key, jsonEncode(state.toJson()))).isOk;
}
