import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:test/test.dart';

import 'logic_support.dart';

final String _fixtureText = File(
  'test/src/logic/fixtures/backup_v1_sample.json',
).readAsStringSync();

typedef _Json = Map<String, Object?>;

_Json _doc() => jsonDecode(_fixtureText) as _Json;

_Json _data(_Json doc) => doc['data']! as _Json;

_Json _reading(_Json doc, [int i = 0]) =>
    (_data(doc)['readings']! as List<Object?>)[i]! as _Json;

_Json _daily(_Json doc, [int i = 0]) =>
    (_data(doc)['dailyCards']! as List<Object?>)[i]! as _Json;

_Json _content(_Json doc) => _reading(doc)['content']! as _Json;

_Json _settings(_Json doc) => _data(doc)['settings']! as _Json;

/// Re-signs [doc] so only the schema decides.
_Json _resign(_Json doc) {
  doc['checksum'] = BackupChecksum.ofJson(doc['data']);
  return doc;
}

BackupInvalidReason? _reason(Result<BackupV1> r) => switch (r.failureOrNull) {
  BackupInvalidFailure(:final reason) => reason,
  _ => null,
};

const _validator = BackupValidator();

void main() {
  group('BackupValidator accepts', () {
    test('the golden fixture (bytes and JSON)', () {
      final r = _validator.validateBytes(utf8.encode(_fixtureText));
      final backup = r.valueOrNull!;
      expect(backup.data.readings, hasLength(3));
      expect(backup.data.dailyCards, hasLength(2));
      expect(backup.appVersion, '1.0.0+1');
      expect(_validator.issues(_doc()), isEmpty);
    });

    test('a UTF-8 BOM', () {
      final r = _validator.validateBytes(utf8.encode('﻿$_fixtureText'));
      expect(r.isOk, isTrue);
    });

    test('reduceMotion is passed to the settings', () {
      final r = _validator.validateJson(_doc(), reduceMotion: true);
      expect(r.valueOrNull!.data.settings.reduceMotion, isTrue);
    });

    test('an export of the model validates', () {
      final backup = _validator.validateJson(_doc()).valueOrNull!;
      final again = _validator.validateJson(
        jsonDecode(jsonEncode(backup.toJson())) as _Json,
      );
      expect(again.valueOrNull, backup);
    });

    test('with the full deck', () {
      expect(BackupValidator(deck: deck).validateJson(_doc()).isOk, isTrue);
    });
  });

  group('BackupValidator pipeline reasons', () {
    test('size > 20 MB → tooLarge, before parsing', () {
      final big = Uint8List(BackupSchemaV1.maxFileBytes + 1);
      expect(
        _reason(_validator.validateBytes(big)),
        BackupInvalidReason.tooLarge,
      );
    });

    test('not UTF-8 or not JSON → notJson', () {
      expect(
        _reason(_validator.validateBytes([0xff, 0xfe, 0x00])),
        BackupInvalidReason.notJson,
      );
      expect(
        _reason(_validator.validateBytes(utf8.encode('{"format": '))),
        BackupInvalidReason.notJson,
      );
    });

    test('not a Taro backup → wrongFormat', () {
      for (final json in <Object?>[
        [1, 2],
        'taro.backup',
        null,
        <String, Object?>{},
        {'format': 'other.backup'},
      ]) {
        expect(
          _reason(_validator.validateJson(json)),
          BackupInvalidReason.wrongFormat,
          reason: '$json',
        );
      }
    });

    test('newer schemaVersion → unsupportedVersion', () {
      final doc = _doc()..['schemaVersion'] = 2;
      expect(
        _reason(_validator.validateJson(doc)),
        BackupInvalidReason.unsupportedVersion,
      );
      expect(
        _reason(
          const BackupValidator(currentSchemaVersion: 2).validateJson(doc),
        ),
        BackupInvalidReason.schema,
        reason: 'a v2 app still needs a v2 schema to accept it',
      );
    });

    test('schemaVersion 0, "1" or null → schema', () {
      for (final v in <Object?>[0, '1', null]) {
        final doc = _doc()..['schemaVersion'] = v;
        expect(
          _reason(_validator.validateJson(doc)),
          BackupInvalidReason.schema,
          reason: '$v',
        );
      }
    });

    test('schemaVersion 1.0 is the number 1', () {
      final doc = _doc()..['schemaVersion'] = 1.0;
      expect(_validator.validateJson(doc).isOk, isTrue);
    });

    test('more than 50,000 readings or daily cards → tooLarge', () {
      for (final key in ['readings', 'dailyCards']) {
        final doc = _doc();
        final list = _data(doc)[key]! as List<Object?>;
        _data(doc)[key] = List.filled(BackupSchemaV1.maxEntries + 1, list[0]);
        expect(
          _reason(_validator.validateJson(_resign(doc))),
          BackupInvalidReason.tooLarge,
          reason: key,
        );
        expect(
          _validator.issues(doc),
          contains(
            r'$.data.'
            '$key: allows at most 50000 items',
          ),
        );
      }
    });

    test('exactly 50,000 entries is within the limit', () {
      final doc = _doc();
      _data(doc)['dailyCards'] = List.filled(
        BackupSchemaV1.maxEntries,
        _daily(doc),
      );
      expect(
        _validator.issues(doc).where((i) => i.contains('at most')),
        isEmpty,
      );
    });

    test('a changed file → checksum', () {
      final doc = _doc();
      _reading(doc)['note'] = 'edited by hand';
      expect(
        _reason(_validator.validateJson(doc)),
        BackupInvalidReason.checksum,
      );
    });

    test('a card missing from the deck → schema', () {
      final partial = Deck(
        id: 'rws_original',
        version: 1,
        cards: [
          for (final c in deck.cards)
            if (c.id.value != 'major_17') c,
        ],
        artSet: 'rws',
      );
      final v = BackupValidator(deck: partial);
      expect(_reason(v.validateJson(_doc())), BackupInvalidReason.schema);
      expect(
        v.issues(_doc()),
        [r'$.data.dailyCards[0].cardId: is not in the deck'],
      );
    });
  });

  group('forbidden keys are rejected, never imported (06 §2.5)', () {
    final placements = <String, void Function(_Json doc, String key)>{
      'root': (doc, k) => doc[k] = 3,
      'data': (doc, k) => _data(doc)[k] = 3,
      'settings': (doc, k) => _settings(doc)[k] = {'a': 1},
      'reading': (doc, k) => _reading(doc)[k] = null,
      'dailyCard': (doc, k) => _daily(doc, 1)[k] = true,
      'content': (doc, k) => _content(doc)[k] = 'x',
    };
    for (final key in kForbiddenBackupKeys) {
      for (final MapEntry(key: where, value: put) in placements.entries) {
        test('$key in $where', () {
          final doc = _doc();
          put(doc, key);
          expect(
            _reason(_validator.validateJson(_resign(doc))),
            BackupInvalidReason.schema,
          );
          expect(BackupValidator.forbiddenKeyPaths(doc), hasLength(1));
          expect(BackupValidator.forbiddenKeyPaths(doc).single, endsWith(key));
        });
      }
    }

    test('paths name the location', () {
      final doc = _doc();
      _reading(doc, 2)['credits'] = 1;
      expect(BackupValidator.forbiddenKeyPaths(doc), [
        r'$.data.readings[2].credits',
      ]);
      expect(BackupValidator.forbiddenKeyPaths(_doc()), isEmpty);
    });
  });

  group('schema rules (backup_schema_v1.json)', () {
    String emoji(int n) => '🔮' * n;

    // (description, mutation, expected issue prefix)
    final cases = <(String, void Function(_Json), String)>[
      ('unknown root key', (d) => d['extra'] = 1, r'$.extra: is not allowed'),
      (
        'missing root key',
        (d) => d.remove('exportedAt'),
        r'$.exportedAt: is required',
      ),
      (
        'exportedAt without Z',
        (d) => d['exportedAt'] = '2026-09-26T08:15:00+00:00',
        r'$.exportedAt: must be an RFC 3339',
      ),
      (
        'exportedAt not a date',
        (d) => d['exportedAt'] = '2026-02-30T08:15:00Z',
        r'$.exportedAt: must be an RFC 3339',
      ),
      (
        'exportedAt 24:00',
        (d) => d['exportedAt'] = '2026-02-03T24:00:00Z',
        r'$.exportedAt: must be an RFC 3339',
      ),
      (
        'exportedAt a number',
        (d) => d['exportedAt'] = 5,
        r'$.exportedAt: must be a string',
      ),
      (
        'exportedAt longer than 40',
        (d) => d['exportedAt'] = '2026-09-26T08:15:00.${'1' * 25}Z',
        r'$.exportedAt: is longer than 40',
      ),
      (
        'appVersion without build',
        (d) => d['appVersion'] = '1.0.0',
        r'$.appVersion: does not match',
      ),
      (
        'appVersion too long',
        (d) => d['appVersion'] = '1.0.0+${'1' * 30}',
        r'$.appVersion: is longer than 32',
      ),
      (
        'checksum upper case',
        (d) => d['checksum'] = 'A' * 64,
        r'$.checksum: does not match',
      ),
      (
        'format wrong inside issues',
        (d) => d['format'] = 'x',
        r'$.format: must be taro.backup',
      ),
      (
        'data not an object',
        (d) => d['data'] = [],
        r'$.data: must be an object',
      ),
      (
        'data extra key',
        (d) => _data(d)['journal'] = [],
        r'$.data.journal: is not allowed',
      ),
      (
        'settings not an object',
        (d) => _data(d)['settings'] = 1,
        r'$.data.settings: must be an object',
      ),
      (
        'theme',
        (d) => _settings(d)['theme'] = 'sepia',
        r'$.data.settings.theme: must be one of',
      ),
      (
        'reversalsEnabled',
        (d) => _settings(d)['reversalsEnabled'] = 'yes',
        r'$.data.settings.reversalsEnabled: must be a boolean',
      ),
      (
        'localeOverride',
        (d) => _settings(d)['localeOverride'] = 'ru',
        r'$.data.settings.localeOverride: must be one of',
      ),
      (
        'reminder not an object',
        (d) => _settings(d)['reminder'] = null,
        r'$.data.settings.reminder: must be an object',
      ),
      (
        'reminder time',
        (d) => (_settings(d)['reminder']! as _Json)['time'] = '24:00',
        r'$.data.settings.reminder.time: does not match',
      ),
      (
        'reminder enabled',
        (d) => (_settings(d)['reminder']! as _Json)['enabled'] = 1,
        r'$.data.settings.reminder.enabled: must be a boolean',
      ),
      (
        'readings not an array',
        (d) => _data(d)['readings'] = {},
        r'$.data.readings: must be an array',
      ),
      (
        'dailyCards not an array',
        (d) => _data(d)['dailyCards'] = null,
        r'$.data.dailyCards: must be an array',
      ),
      (
        'reading not an object',
        (d) => (_data(d)['readings']! as List<Object?>)[0] = 'r',
        r'$.data.readings[0]: must be an object',
      ),
      (
        'reading id not a UUID',
        (d) => _reading(d)['id'] = 'uuid',
        r'$.data.readings[0].id: does not match',
      ),
      (
        'reading missing key',
        (d) => _reading(d).remove('ratingReason'),
        r'$.data.readings[0].ratingReason: is required',
      ),
      (
        'localDate',
        (d) => _reading(d)['localDate'] = '2026-9-25',
        r'$.data.readings[0].localDate: does not match',
      ),
      (
        'spreadId',
        (d) => _reading(d)['spreadId'] = 'horseshoe',
        r'$.data.readings[0].spreadId: must be one of',
      ),
      (
        'question too long',
        (d) => _reading(d)['question'] = emoji(1201),
        r'$.data.readings[0].question: is longer than 1200',
      ),
      (
        'question a number',
        (d) => _reading(d)['question'] = 1,
        r'$.data.readings[0].question: must be a string or null',
      ),
      (
        'cards empty',
        (d) => _reading(d)['cards'] = <Object?>[],
        r'$.data.readings[0].cards: needs at least 1 items',
      ),
      (
        'cards > 12',
        (d) => _reading(d)['cards'] = List.filled(
          13,
          (_reading(d)['cards']! as List<Object?>)[0],
        ),
        r'$.data.readings[0].cards: allows at most 12 items',
      ),
      (
        'drawn card not an object',
        (d) => (_reading(d)['cards']! as List<Object?>)[0] = 1,
        r'$.data.readings[0].cards[0]: must be an object',
      ),
      (
        'cardId',
        (d) =>
            ((_reading(d)['cards']! as List<Object?>)[0]! as _Json)['cardId'] =
                'major_22',
        r'$.data.readings[0].cards[0].cardId: must be an RC1 card ID',
      ),
      (
        'positionId',
        (d) =>
            ((_reading(d)['cards']! as List<Object?>)[0]!
                    as _Json)['positionId'] =
                'Past',
        r'$.data.readings[0].cards[0].positionId: does not match',
      ),
      (
        'reversed',
        (d) =>
            ((_reading(d)['cards']! as List<Object?>)[0]!
                    as _Json)['reversed'] =
                null,
        r'$.data.readings[0].cards[0].reversed: must be a boolean',
      ),
      (
        'status pending',
        (d) => _reading(d)['status'] = 'pending',
        r'$.data.readings[0].status: must be one of',
      ),
      (
        'content not an object',
        (d) => _reading(d)['content'] = 'text',
        r'$.data.readings[0].content: must be an object',
      ),
      (
        'content extra key',
        (d) => _content(d)['disclaimer'] = 'x',
        r'$.data.readings[0].content.disclaimer: is not allowed',
      ),
      (
        'title too long',
        (d) => _content(d)['title'] = emoji(201),
        r'$.data.readings[0].content.title: is longer than 200',
      ),
      (
        'summary too long',
        (d) => _content(d)['summary'] = 'a' * 2001,
        r'$.data.readings[0].content.summary: is longer than 2000',
      ),
      (
        'synthesis too long',
        (d) => _content(d)['synthesis'] = 'a' * 4001,
        r'$.data.readings[0].content.synthesis: is longer than 4000',
      ),
      (
        'positions > 12',
        (d) => _content(d)['positions'] = List.filled(
          13,
          (_content(d)['positions']! as List<Object?>)[0],
        ),
        r'$.data.readings[0].content.positions: allows at most 12 items',
      ),
      (
        'position not an object',
        (d) => (_content(d)['positions']! as List<Object?>)[1] = [],
        r'$.data.readings[0].content.positions[1]: must be an object',
      ),
      (
        'position text too long',
        (d) =>
            ((_content(d)['positions']! as List<Object?>)[0]!
                    as _Json)['text'] =
                'a' * 3001,
        r'$.data.readings[0].content.positions[0].text: is longer than 3000',
      ),
      (
        'position id',
        (d) =>
            ((_content(d)['positions']! as List<Object?>)[0]!
                    as _Json)['positionId'] =
                '1st',
        r'$.data.readings[0].content.positions[0].positionId: does not match',
      ),
      (
        'reflectionPrompts > 3',
        (d) => _content(d)['reflectionPrompts'] = ['a', 'b', 'c', 'd'],
        r'$.data.readings[0].content.reflectionPrompts: allows at most 3 items',
      ),
      (
        'reflection prompt too long',
        (d) => _content(d)['reflectionPrompts'] = ['a' * 301],
        r'$.data.readings[0].content.reflectionPrompts[0]: is longer than 300',
      ),
      (
        'reflection prompt not a string',
        (d) => _content(d)['reflectionPrompts'] = [null],
        r'$.data.readings[0].content.reflectionPrompts[0]: must be a string',
      ),
      (
        'contentLocale',
        (d) => _reading(d)['contentLocale'] = 'en-US',
        r'$.data.readings[0].contentLocale: must be one of',
      ),
      (
        'promptVersion too long',
        (d) => _reading(d)['promptVersion'] = 'v' * 17,
        r'$.data.readings[0].promptVersion: is longer than 16',
      ),
      (
        'note too long',
        (d) => _reading(d)['note'] = emoji(5001),
        r'$.data.readings[0].note: is longer than 5000',
      ),
      (
        'favourite',
        (d) => _reading(d)['favourite'] = 0,
        r'$.data.readings[0].favourite: must be a boolean',
      ),
      (
        'rating',
        (d) => _reading(d)['rating'] = 'meh',
        r'$.data.readings[0].rating: must be one of',
      ),
      (
        'ratingReason',
        (d) => _reading(d)['ratingReason'] = 'boring',
        r'$.data.readings[0].ratingReason: must be one of',
      ),
      (
        'updatedAt',
        (d) => _reading(d)['updatedAt'] = 'yesterday',
        r'$.data.readings[0].updatedAt: must be an RFC 3339',
      ),
      (
        'daily not an object',
        (d) => (_data(d)['dailyCards']! as List<Object?>)[1] = 7,
        r'$.data.dailyCards[1]: must be an object',
      ),
      (
        'daily extra key',
        (d) => _daily(d)['mood'] = 'calm',
        r'$.data.dailyCards[0].mood: is not allowed',
      ),
      (
        'daily localDate',
        (d) => _daily(d)['localDate'] = 20260925,
        r'$.data.dailyCards[0].localDate: must be a string',
      ),
      (
        'daily cardId',
        (d) => _daily(d)['cardId'] = 'cups_15',
        r'$.data.dailyCards[0].cardId: must be an RC1 card ID',
      ),
      (
        'daily reversed',
        (d) => _daily(d)['reversed'] = 'no',
        r'$.data.dailyCards[0].reversed: must be a boolean',
      ),
      (
        'daily drawnAt',
        (d) => _daily(d)['drawnAt'] = '2026-09-25 07:00:00Z',
        r'$.data.dailyCards[0].drawnAt: must be an RFC 3339',
      ),
      (
        'daily note too long',
        (d) => _daily(d)['note'] = 'a' * 5001,
        r'$.data.dailyCards[0].note: is longer than 5000',
      ),
      (
        'daily favourite',
        (d) => _daily(d)['favourite'] = null,
        r'$.data.dailyCards[0].favourite: must be a boolean',
      ),
    ];

    for (final (name, mutate, expected) in cases) {
      test(name, () {
        final doc = _doc();
        final signed = doc['checksum'];
        mutate(doc);
        final issues = _validator.issues(doc);
        expect(
          issues.any((i) => i.startsWith(expected)),
          isTrue,
          reason: 'issues: $issues',
        );
        // Re-sign unless the checksum itself is the mutation, so the schema
        // (not the checksum) must reject the file.
        if (doc['checksum'] == signed) _resign(doc);
        final r = _validator.validateJson(doc);
        expect(r.isErr, isTrue);
        expect(_reason(r), isNot(BackupInvalidReason.checksum));
      });
    }

    test('lengths count code points: 5000 emoji notes are valid', () {
      final doc = _doc();
      _reading(doc)['note'] = emoji(5000);
      _reading(doc)['question'] = emoji(1200);
      expect(_validator.issues(doc), isEmpty);
      expect(_validator.validateJson(_resign(doc)).isOk, isTrue);
    });

    test('nullable fields accept null; content may be null', () {
      final doc = _doc();
      final r = _reading(doc)
        ..['question'] = null
        ..['content'] = null
        ..['promptVersion'] = null
        ..['note'] = null
        ..['rating'] = null
        ..['ratingReason'] = null;
      _settings(doc)['localeOverride'] = null;
      expect(r, isNotEmpty);
      expect(_validator.issues(doc), isEmpty);
    });

    test('a fraction and lowercase t are valid RFC 3339', () {
      final doc = _doc();
      _daily(doc)['drawnAt'] = '2026-09-25t07:00:00.123456Z';
      expect(_validator.issues(doc), isEmpty);
      // The model parser (DateTime.parse) rejects a lowercase `t`, so such
      // a file still fails as `schema` instead of throwing.
      expect(
        _reason(_validator.validateJson(_resign(doc))),
        BackupInvalidReason.schema,
      );
      _daily(doc)['drawnAt'] = '2026-09-25T07:00:00.123456Z';
      expect(_validator.validateJson(_resign(doc)).isOk, isTrue);
    });
  });

  group('BackupSchemaV1 mirrors docs/specs/backup_schema_v1.json', () {
    final schema =
        jsonDecode(
              File('../../docs/specs/backup_schema_v1.json').readAsStringSync(),
            )
            as _Json;
    final defs = schema[r'$defs']! as _Json;
    _Json props(_Json o) => o['properties']! as _Json;
    _Json def(String name) => defs[name]! as _Json;
    final data = props(schema)['data']! as _Json;
    final reading = props(def('reading'));
    final content = props(def('content'));
    final contentPosition = (content['positions']! as _Json)['items']! as _Json;

    test('every object requires exactly its properties', () {
      final objects = <String, _Json>{
        'root': schema,
        'data': data,
        'settings': def('settings'),
        'reminder': props(def('settings'))['reminder']! as _Json,
        'drawnCard': def('drawnCard'),
        'content': def('content'),
        'contentPosition': contentPosition,
        'reading': def('reading'),
        'dailyCard': def('dailyCard'),
      };
      expect(
        objects.keys.toSet(),
        BackupSchemaV1.objectKeys.keys.toSet(),
      );
      for (final MapEntry(key: name, value: o) in objects.entries) {
        expect(o['additionalProperties'], isFalse, reason: name);
        expect(
          (o['required']! as List<Object?>).toSet(),
          props(o).keys.toSet(),
          reason: name,
        );
        expect(
          BackupSchemaV1.objectKeys[name]!.toSet(),
          props(o).keys.toSet(),
          reason: name,
        );
      }
    });

    test('limits, patterns and enums', () {
      Object? at(_Json o, String k) => o[k];
      final root = props(schema);
      expect(
        at(root['appVersion']! as _Json, 'pattern'),
        BackupSchemaV1.appVersionPattern.pattern,
      );
      expect(
        at(root['appVersion']! as _Json, 'maxLength'),
        BackupSchemaV1.appVersionMaxLength,
      );
      expect(
        at(root['checksum']! as _Json, 'pattern'),
        BackupSchemaV1.checksumPattern.pattern,
      );
      expect(at(def('instant'), 'maxLength'), BackupSchemaV1.instantMaxLength);
      expect(at(def('instant'), 'pattern'), r'Z$');
      expect(
        at(def('localDate'), 'pattern'),
        BackupSchemaV1.localDatePattern.pattern,
      );
      expect(at(def('cardId'), 'pattern'), cardIdPattern.pattern);
      expect(at(def('locale'), 'enum'), kSupportedLocales);
      expect(at(def('spreadId'), 'enum'), [
        for (final s in kSpreadIds) s.value,
      ]);
      expect(at(def('note'), 'maxLength'), BackupSchemaV1.noteMaxLength);
      for (final k in ['readings', 'dailyCards']) {
        expect(
          at(props(data)[k]! as _Json, 'maxItems'),
          BackupSchemaV1.maxEntries,
        );
      }
      final settings = props(def('settings'));
      expect(at(settings['theme']! as _Json, 'enum'), BackupSchemaV1.themes);
      expect(
        at(props(settings['reminder']! as _Json)['time']! as _Json, 'pattern'),
        BackupSchemaV1.reminderTimePattern.pattern,
      );
      final drawn = props(def('drawnCard'));
      expect(
        at(drawn['positionId']! as _Json, 'pattern'),
        BackupSchemaV1.positionIdPattern.pattern,
      );
      expect(
        at(content['title']! as _Json, 'maxLength'),
        BackupSchemaV1.titleMaxLength,
      );
      expect(
        at(content['summary']! as _Json, 'maxLength'),
        BackupSchemaV1.summaryMaxLength,
      );
      expect(
        at(content['synthesis']! as _Json, 'maxLength'),
        BackupSchemaV1.synthesisMaxLength,
      );
      expect(
        at(content['positions']! as _Json, 'maxItems'),
        BackupSchemaV1.positionsMaxItems,
      );
      expect(
        at(props(contentPosition)['text']! as _Json, 'maxLength'),
        BackupSchemaV1.positionTextMaxLength,
      );
      final prompts = content['reflectionPrompts']! as _Json;
      expect(at(prompts, 'maxItems'), BackupSchemaV1.reflectionPromptsMaxItems);
      expect(
        at(prompts['items']! as _Json, 'maxLength'),
        BackupSchemaV1.reflectionPromptMaxLength,
      );
      expect(
        at(reading['question']! as _Json, 'maxLength'),
        BackupSchemaV1.questionMaxLength,
      );
      expect(
        at(reading['promptVersion']! as _Json, 'maxLength'),
        BackupSchemaV1.promptVersionMaxLength,
      );
      final cards = reading['cards']! as _Json;
      expect(at(cards, 'minItems'), BackupSchemaV1.cardsMinItems);
      expect(at(cards, 'maxItems'), BackupSchemaV1.cardsMaxItems);
      expect(at(reading['status']! as _Json, 'enum'), BackupSchemaV1.statuses);
      expect(at(reading['rating']! as _Json, 'enum'), [
        ...BackupSchemaV1.ratings,
        null,
      ]);
      expect(at(reading['ratingReason']! as _Json, 'enum'), [
        ...BackupSchemaV1.ratingReasons,
        null,
      ]);
      expect(at(props(schema)['format']! as _Json, 'const'), BackupV1.format);
      expect(
        at(props(schema)['schemaVersion']! as _Json, 'const'),
        BackupV1.schemaVersion,
      );
    });
  });
}
