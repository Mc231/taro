import 'dart:convert';

import 'package:taro_core/src/logic/backup_checksum.dart';
import 'package:taro_core/src/model/backup.dart';
import 'package:taro_core/src/model/deck.dart';
import 'package:taro_core/src/model/spread.dart';
import 'package:taro_core/src/model/user_settings.dart';
import 'package:taro_core/src/result/failure.dart';
import 'package:taro_core/src/result/ids.dart';
import 'package:taro_core/src/result/result.dart';

/// Keys that must never appear anywhere in a backup (01 §7.11, 06 §2.5).
/// `additionalProperties: false` already rejects them; this list names them
/// so the rejection is explicit and tested.
const Set<String> kForbiddenBackupKeys = {
  'credits',
  'balance',
  'installId',
  'entitlements',
  'consent',
};

/// The constraints of `docs/specs/backup_schema_v1.json` mirrored in Dart
/// (RC70). A test reads the schema file and fails if they drift.
abstract final class BackupSchemaV1 {
  /// Maximum file size before parsing: 20 MB (01 §7.11).
  static const int maxFileBytes = 20 * 1024 * 1024;

  /// `maxItems` of `data.readings` and of `data.dailyCards`.
  static const int maxEntries = 50000;

  /// `appVersion` pattern.
  static final RegExp appVersionPattern = RegExp(r'^\d+\.\d+\.\d+\+\d+$');

  /// `appVersion` `maxLength`.
  static const int appVersionMaxLength = 32;

  /// `checksum` pattern.
  static final RegExp checksumPattern = RegExp(r'^[0-9a-f]{64}$');

  /// `instant` `maxLength`.
  static const int instantMaxLength = 40;

  /// `localDate` pattern.
  static final RegExp localDatePattern = RegExp(r'^\d{4}-\d{2}-\d{2}$');

  /// `positionId` pattern.
  static final RegExp positionIdPattern = RegExp(r'^[a-z][a-z0-9_]{0,31}$');

  /// `reminder.time` pattern.
  static final RegExp reminderTimePattern = RegExp(
    r'^([01]\d|2[0-3]):[0-5]\d$',
  );

  /// `note` `maxLength`.
  static const int noteMaxLength = 5000;

  /// `question` `maxLength`.
  static const int questionMaxLength = 1200;

  /// `promptVersion` `maxLength`.
  static const int promptVersionMaxLength = 16;

  /// `cards` `minItems`.
  static const int cardsMinItems = 1;

  /// `cards` `maxItems`.
  static const int cardsMaxItems = 12;

  /// `content.title` `maxLength`.
  static const int titleMaxLength = 200;

  /// `content.summary` `maxLength`.
  static const int summaryMaxLength = 2000;

  /// `content.positions` `maxItems`.
  static const int positionsMaxItems = 12;

  /// `content.positions[].text` `maxLength`.
  static const int positionTextMaxLength = 3000;

  /// `content.synthesis` `maxLength`.
  static const int synthesisMaxLength = 4000;

  /// `content.reflectionPrompts` `maxItems`.
  static const int reflectionPromptsMaxItems = 3;

  /// `content.reflectionPrompts[]` `maxLength`.
  static const int reflectionPromptMaxLength = 300;

  /// `settings.theme` enum.
  static const List<String> themes = ['system', 'light', 'dark'];

  /// `reading.status` enum.
  static const List<String> statuses = ['complete', 'refused', 'classic'];

  /// `reading.rating` enum (plus `null`).
  static const List<String> ratings = ['up', 'down'];

  /// `reading.ratingReason` enum (plus `null`).
  static const List<String> ratingReasons = [
    'too_generic',
    'mismatch',
    'tone',
    'other',
  ];

  /// The member names of every object; each object requires all of them
  /// and allows no other (`additionalProperties: false`).
  static const Map<String, List<String>> objectKeys = {
    'root': [
      'format',
      'schemaVersion',
      'exportedAt',
      'appVersion',
      'data',
      'checksum',
    ],
    'data': ['settings', 'readings', 'dailyCards'],
    'settings': [
      'theme',
      'reversalsEnabled',
      'hapticsEnabled',
      'reminder',
      'localeOverride',
    ],
    'reminder': ['enabled', 'time'],
    'drawnCard': ['positionId', 'cardId', 'reversed'],
    'content': [
      'title',
      'summary',
      'positions',
      'synthesis',
      'reflectionPrompts',
    ],
    'contentPosition': ['positionId', 'text'],
    'reading': [
      'id',
      'createdAt',
      'updatedAt',
      'localDate',
      'spreadId',
      'question',
      'cards',
      'status',
      'content',
      'contentLocale',
      'promptVersion',
      'note',
      'favourite',
      'rating',
      'ratingReason',
    ],
    'dailyCard': [
      'localDate',
      'cardId',
      'reversed',
      'drawnAt',
      'createdAt',
      'updatedAt',
      'note',
      'favourite',
    ],
  };
}

/// Validates a backup file before import (01 §7.11, 02 §12, RC70).
///
/// Order: size → JSON → `format` → `schemaVersion` ≤ current → forbidden
/// keys → entry limits → schema (types, enums, formats, lengths,
/// `additionalProperties: false`) → card IDs in the deck → checksum → typed
/// model. The first failing step decides the [BackupInvalidReason].
final class BackupValidator {
  /// Creates a validator; when [deck] is given every card ID must be in it.
  const BackupValidator({this.deck, this.currentSchemaVersion = 1});

  /// The bundled deck.
  final Deck? deck;

  /// The newest `schemaVersion` this app reads.
  final int currentSchemaVersion;

  /// Validates raw file bytes.
  Result<BackupV1> validateBytes(List<int> bytes, {bool? reduceMotion}) {
    if (bytes.length > BackupSchemaV1.maxFileBytes) {
      return _fail(BackupInvalidReason.tooLarge);
    }
    final Object? json;
    try {
      var text = utf8.decode(bytes);
      if (text.startsWith('﻿')) text = text.substring(1);
      json = jsonDecode(text);
    } on FormatException {
      return _fail(BackupInvalidReason.notJson);
    }
    return validateJson(json, reduceMotion: reduceMotion);
  }

  /// Validates an already decoded document.
  Result<BackupV1> validateJson(Object? json, {bool? reduceMotion}) {
    if (json is! Map<String, Object?> || json['format'] != BackupV1.format) {
      return _fail(BackupInvalidReason.wrongFormat);
    }
    final version = json['schemaVersion'];
    if (version is num && version > currentSchemaVersion) {
      return _fail(BackupInvalidReason.unsupportedVersion);
    }
    if (forbiddenKeyPaths(json).isNotEmpty) {
      return _fail(BackupInvalidReason.schema);
    }
    if (_exceedsEntryLimit(json)) return _fail(BackupInvalidReason.tooLarge);
    if (issues(json).isNotEmpty) return _fail(BackupInvalidReason.schema);
    final data = json['data']! as Map<String, Object?>;
    if (!BackupChecksum.matches(data, json['checksum']! as String)) {
      return _fail(BackupInvalidReason.checksum);
    }
    try {
      return Result.ok(BackupV1.fromJson(json, reduceMotion: reduceMotion));
    } on FormatException {
      return _fail(BackupInvalidReason.schema);
    }
  }

  /// Every schema violation of [json] as `path: message`, plus card IDs
  /// missing from [deck]; empty when the document is valid. Limits on the
  /// entry count are included.
  List<String> issues(Object? json) {
    return (_Checker(deck)..root(json)).issues;
  }

  /// JSON paths of every [kForbiddenBackupKeys] member, at any depth.
  static List<String> forbiddenKeyPaths(Object? json, [String path = r'$']) {
    return switch (json) {
      Map<String, Object?>() => [
        for (final e in json.entries) ...[
          if (kForbiddenBackupKeys.contains(e.key)) '$path.${e.key}',
          ...forbiddenKeyPaths(e.value, '$path.${e.key}'),
        ],
      ],
      List<Object?>() => [
        for (var i = 0; i < json.length; i++)
          ...forbiddenKeyPaths(json[i], '$path[$i]'),
      ],
      _ => const [],
    };
  }

  static bool _exceedsEntryLimit(Map<String, Object?> json) {
    final data = json['data'];
    if (data is! Map<String, Object?>) return false;
    bool over(Object? list) =>
        list is List<Object?> && list.length > BackupSchemaV1.maxEntries;
    return over(data['readings']) || over(data['dailyCards']);
  }

  static Result<BackupV1> _fail(BackupInvalidReason reason) =>
      Result.err(Failure.backupInvalid(reason: reason));
}

/// Walks a document against the v1 schema and collects issues.
final class _Checker {
  _Checker(this._deck);

  final Deck? _deck;
  final List<String> issues = [];

  static final RegExp _uuid = RegExp(
    '^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-'
    r'[0-9a-fA-F]{12}$',
  );

  static final RegExp _dateTime = RegExp(
    r'^(\d{4})-(\d{2})-(\d{2})[Tt](\d{2}):(\d{2}):(\d{2})(\.\d+)?Z$',
  );

  void _issue(String path, String message) => issues.add('$path: $message');

  /// Checks that [value] is an object with exactly the members of [def];
  /// returns it, or `null` after recording an issue.
  Map<String, Object?>? _object(Object? value, String path, String def) {
    if (value is! Map<String, Object?>) {
      _issue(path, 'must be an object');
      return null;
    }
    final keys = BackupSchemaV1.objectKeys[def]!;
    for (final k in keys) {
      if (!value.containsKey(k)) _issue('$path.$k', 'is required');
    }
    for (final k in value.keys) {
      if (!keys.contains(k)) _issue('$path.$k', 'is not allowed');
    }
    return value;
  }

  List<Object?>? _array(
    Object? value,
    String path, {
    required int max,
    int min = 0,
  }) {
    if (value is! List<Object?>) {
      _issue(path, 'must be an array');
      return null;
    }
    if (value.length < min) _issue(path, 'needs at least $min items');
    if (value.length > max) _issue(path, 'allows at most $max items');
    return value;
  }

  void _string(
    Object? value,
    String path, {
    int? maxLength,
    RegExp? pattern,
    bool nullable = false,
  }) {
    if (value == null && nullable) return;
    if (value is! String) {
      _issue(path, nullable ? 'must be a string or null' : 'must be a string');
      return;
    }
    // JSON Schema counts code points.
    if (maxLength != null && value.runes.length > maxLength) {
      _issue(path, 'is longer than $maxLength');
    }
    if (pattern != null && !pattern.hasMatch(value)) {
      _issue(path, 'does not match ${pattern.pattern}');
    }
  }

  void _bool(Object? value, String path) {
    if (value is! bool) _issue(path, 'must be a boolean');
  }

  void _enum(
    Object? value,
    String path,
    Iterable<String> allowed, {
    bool nullable = false,
  }) {
    if (value == null && nullable) return;
    if (value is! String || !allowed.contains(value)) {
      _issue(path, 'must be one of ${allowed.join('|')}');
    }
  }

  void _instant(Object? value, String path) {
    _string(value, path, maxLength: BackupSchemaV1.instantMaxLength);
    if (value is! String) return;
    final m = _dateTime.firstMatch(value);
    if (m == null || !_validDateTime(m)) {
      _issue(path, 'must be an RFC 3339 UTC date-time ending in Z');
    }
  }

  static bool _validDateTime(RegExpMatch m) {
    final p = [for (var i = 1; i <= 6; i++) int.parse(m.group(i)!)];
    final dt = DateTime.utc(p[0], p[1], p[2], p[3], p[4], p[5]);
    return dt.year == p[0] &&
        dt.month == p[1] &&
        dt.day == p[2] &&
        dt.hour == p[3] &&
        dt.minute == p[4] &&
        dt.second == p[5];
  }

  void _cardId(Object? value, String path) {
    if (value is! String || !CardId.isValid(value)) {
      _issue(path, 'must be an RC1 card ID');
      return;
    }
    final deck = _deck;
    if (deck != null && !deck.contains(CardId(value))) {
      _issue(path, 'is not in the deck');
    }
  }

  void root(Object? json) {
    final o = _object(json, r'$', 'root');
    if (o == null) return;
    if (o['format'] != BackupV1.format) {
      _issue(r'$.format', 'must be ${BackupV1.format}');
    }
    final version = o['schemaVersion'];
    if (version is! num || version != BackupV1.schemaVersion) {
      _issue(r'$.schemaVersion', 'must be ${BackupV1.schemaVersion}');
    }
    _instant(o['exportedAt'], r'$.exportedAt');
    _string(
      o['appVersion'],
      r'$.appVersion',
      maxLength: BackupSchemaV1.appVersionMaxLength,
      pattern: BackupSchemaV1.appVersionPattern,
    );
    _string(
      o['checksum'],
      r'$.checksum',
      pattern: BackupSchemaV1.checksumPattern,
    );
    _data(o['data'], r'$.data');
  }

  void _data(Object? json, String path) {
    final o = _object(json, path, 'data');
    if (o == null) return;
    _settings(o['settings'], '$path.settings');
    final readings = _array(
      o['readings'],
      '$path.readings',
      max: BackupSchemaV1.maxEntries,
    );
    for (var i = 0; i < (readings?.length ?? 0); i++) {
      _reading(readings![i], '$path.readings[$i]');
    }
    final daily = _array(
      o['dailyCards'],
      '$path.dailyCards',
      max: BackupSchemaV1.maxEntries,
    );
    for (var i = 0; i < (daily?.length ?? 0); i++) {
      _dailyCard(daily![i], '$path.dailyCards[$i]');
    }
  }

  void _settings(Object? json, String path) {
    final o = _object(json, path, 'settings');
    if (o == null) return;
    _enum(o['theme'], '$path.theme', BackupSchemaV1.themes);
    _bool(o['reversalsEnabled'], '$path.reversalsEnabled');
    _bool(o['hapticsEnabled'], '$path.hapticsEnabled');
    _enum(
      o['localeOverride'],
      '$path.localeOverride',
      kSupportedLocales,
      nullable: true,
    );
    final r = _object(o['reminder'], '$path.reminder', 'reminder');
    if (r == null) return;
    _bool(r['enabled'], '$path.reminder.enabled');
    _string(
      r['time'],
      '$path.reminder.time',
      pattern: BackupSchemaV1.reminderTimePattern,
    );
  }

  void _drawnCard(Object? json, String path) {
    final o = _object(json, path, 'drawnCard');
    if (o == null) return;
    _string(
      o['positionId'],
      '$path.positionId',
      pattern: BackupSchemaV1.positionIdPattern,
    );
    _cardId(o['cardId'], '$path.cardId');
    _bool(o['reversed'], '$path.reversed');
  }

  void _content(Object? json, String path) {
    if (json == null) return;
    final o = _object(json, path, 'content');
    if (o == null) return;
    _string(
      o['title'],
      '$path.title',
      maxLength: BackupSchemaV1.titleMaxLength,
    );
    _string(
      o['summary'],
      '$path.summary',
      maxLength: BackupSchemaV1.summaryMaxLength,
    );
    _string(
      o['synthesis'],
      '$path.synthesis',
      maxLength: BackupSchemaV1.synthesisMaxLength,
    );
    final positions = _array(
      o['positions'],
      '$path.positions',
      max: BackupSchemaV1.positionsMaxItems,
    );
    for (var i = 0; i < (positions?.length ?? 0); i++) {
      final p = _object(
        positions![i],
        '$path.positions[$i]',
        'contentPosition',
      );
      if (p == null) continue;
      _string(
        p['positionId'],
        '$path.positions[$i].positionId',
        pattern: BackupSchemaV1.positionIdPattern,
      );
      _string(
        p['text'],
        '$path.positions[$i].text',
        maxLength: BackupSchemaV1.positionTextMaxLength,
      );
    }
    final prompts = _array(
      o['reflectionPrompts'],
      '$path.reflectionPrompts',
      max: BackupSchemaV1.reflectionPromptsMaxItems,
    );
    for (var i = 0; i < (prompts?.length ?? 0); i++) {
      _string(
        prompts![i],
        '$path.reflectionPrompts[$i]',
        maxLength: BackupSchemaV1.reflectionPromptMaxLength,
      );
    }
  }

  void _reading(Object? json, String path) {
    final o = _object(json, path, 'reading');
    if (o == null) return;
    _string(o['id'], '$path.id', pattern: _uuid);
    _instant(o['createdAt'], '$path.createdAt');
    _instant(o['updatedAt'], '$path.updatedAt');
    _string(
      o['localDate'],
      '$path.localDate',
      pattern: BackupSchemaV1.localDatePattern,
    );
    _enum(o['spreadId'], '$path.spreadId', [
      for (final s in kSpreadIds) s.value,
    ]);
    _string(
      o['question'],
      '$path.question',
      maxLength: BackupSchemaV1.questionMaxLength,
      nullable: true,
    );
    final cards = _array(
      o['cards'],
      '$path.cards',
      min: BackupSchemaV1.cardsMinItems,
      max: BackupSchemaV1.cardsMaxItems,
    );
    for (var i = 0; i < (cards?.length ?? 0); i++) {
      _drawnCard(cards![i], '$path.cards[$i]');
    }
    _enum(o['status'], '$path.status', BackupSchemaV1.statuses);
    _content(o['content'], '$path.content');
    _enum(o['contentLocale'], '$path.contentLocale', kSupportedLocales);
    _string(
      o['promptVersion'],
      '$path.promptVersion',
      maxLength: BackupSchemaV1.promptVersionMaxLength,
      nullable: true,
    );
    _string(
      o['note'],
      '$path.note',
      maxLength: BackupSchemaV1.noteMaxLength,
      nullable: true,
    );
    _bool(o['favourite'], '$path.favourite');
    _enum(o['rating'], '$path.rating', BackupSchemaV1.ratings, nullable: true);
    _enum(
      o['ratingReason'],
      '$path.ratingReason',
      BackupSchemaV1.ratingReasons,
      nullable: true,
    );
  }

  void _dailyCard(Object? json, String path) {
    final o = _object(json, path, 'dailyCard');
    if (o == null) return;
    _string(
      o['localDate'],
      '$path.localDate',
      pattern: BackupSchemaV1.localDatePattern,
    );
    _cardId(o['cardId'], '$path.cardId');
    _bool(o['reversed'], '$path.reversed');
    _instant(o['drawnAt'], '$path.drawnAt');
    _instant(o['createdAt'], '$path.createdAt');
    _instant(o['updatedAt'], '$path.updatedAt');
    _string(
      o['note'],
      '$path.note',
      maxLength: BackupSchemaV1.noteMaxLength,
      nullable: true,
    );
    _bool(o['favourite'], '$path.favourite');
  }
}
