// Fluent builders (Phase 4.5: `aRemoteConfig().withRewardedEnabled(false)`,
// `aCard('major_00').reversed()`) return `this` and take positional flags.
// ignore_for_file: avoid_returning_this

import 'package:taro_core/taro_core.dart';

/// The position IDs of every v1 spread, in order (GLOSSARY §2).
const Map<String, List<String>> kSpreadPositions = {
  'single': ['focus'],
  'three_ppf': ['past', 'present', 'future'],
  'three_sao': ['situation', 'action', 'outcome'],
  'relationship': ['you', 'other', 'connection', 'challenge', 'potential'],
  'two_paths': [
    'situation',
    'path_a',
    'path_a_outcome',
    'path_b',
    'path_b_outcome',
  ],
  'celtic_cross': [
    'present',
    'challenge',
    'foundation',
    'recent_past',
    'potential',
    'near_future',
    'self',
    'environment',
    'hopes_fears',
    'outcome',
  ],
};

/// `aSpread('celtic_cross').build()`: a v1 spread with its canonical
/// positions.
SpreadBuilder aSpread([String id = 'three_ppf']) => SpreadBuilder(id);

/// Every v1 spread.
List<SpreadDefinition> allSpreads() => [
  for (final id in kSpreadIds) aSpread(id.value).build(),
];

/// Builds a [SpreadDefinition].
final class SpreadBuilder {
  /// Starts a builder for `id`; throws an [ArgumentError] for an unknown
  /// spread.
  SpreadBuilder(this._id) {
    if (!kSpreadPositions.containsKey(_id)) {
      throw ArgumentError.value(_id, 'id', 'not a v1 spread');
    }
  }

  final String _id;
  int _version = 1;
  bool _enabled = true;
  bool _allowsReversals = true;

  /// With content version [version].
  SpreadBuilder withVersion(int version) {
    _version = version;
    return this;
  }

  /// Not offered (`enabled: false`).
  SpreadBuilder disabled() {
    _enabled = false;
    return this;
  }

  /// Cards are never reversed in this spread.
  SpreadBuilder withoutReversals() {
    _allowsReversals = false;
    return this;
  }

  /// The spread.
  SpreadDefinition build() {
    final ids = kSpreadPositions[_id]!;
    return SpreadDefinition(
      id: SpreadId(_id),
      version: _version,
      positions: [
        for (var i = 0; i < ids.length; i++)
          SpreadPosition(
            id: PositionId(ids[i]),
            order: i + 1,
            x: (i + 1) / (ids.length + 1),
            y: 0.5,
            rotationDeg: _id == 'celtic_cross' && ids[i] == 'challenge'
                ? 90
                : 0,
          ),
      ],
      questionSuggestionKeys: ['spread_${_id}_suggestion_1'],
      allowsReversals: _allowsReversals,
      enabled: _enabled,
    );
  }
}
