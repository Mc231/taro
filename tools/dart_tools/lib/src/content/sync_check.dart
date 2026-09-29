/// `tools/content sync_check`: parity between the app assets and the Worker
/// feeds (replaces `tools/sync_deck`, RC26). It reads only generated files,
/// so it needs no source and runs in `reusable-static.yml`.
library;

import 'dart:convert';
import 'dart:io';

import 'package:taro_dart_tools/src/content/builder.dart';
import 'package:taro_dart_tools/src/content/common.dart';

const _deckCardKeys = [
  'id',
  'arcana',
  'suit',
  'number',
  'element',
  'astrology',
  'artKey',
];

const _promptKeys = [
  'name',
  'keywordsUpright',
  'keywordsReversed',
  'shortUpright',
  'shortReversed',
];

bool _same(Object? a, Object? b) => compactJson(a) == compactJson(b);

/// Runs every parity check under [root]; returns the problems.
List<Issue> syncCheck(Directory root) {
  final issues = <Issue>[];
  final cache = <String, Object?>{};
  Object? read(String path) {
    if (cache.containsKey(path)) return cache[path];
    final file = File('${root.path}/$path');
    Object? value;
    if (!file.existsSync()) {
      issues.add(Issue.error(path, 'missing (run tools/content/build)'));
    } else {
      try {
        value = jsonDecode(file.readAsStringSync());
        if (value is! Map<String, Object?>) {
          issues.add(Issue.error(path, 'must be a JSON object'));
          value = null;
        }
      } on FormatException catch (e) {
        issues.add(Issue.error(path, 'invalid JSON: ${e.message}'));
      }
    }
    return cache[path] = value;
  }

  void fail(String path, String message) =>
      issues.add(Issue.error(path, message));

  List<Map<String, Object?>> list(Object? doc, String key, String path) {
    final value = doc is Map ? doc[key] : null;
    if (value is List && value.every((e) => e is Map<String, Object?>)) {
      return value.cast<Map<String, Object?>>();
    }
    if (doc != null) fail(path, '"$key" must be a list of objects');
    return const [];
  }

  final meta = read(kDeckMetaPath) as Map<String, Object?>?;
  final workerCards = read(kWorkerCardsPath) as Map<String, Object?>?;
  final appSpreads = read(kAppSpreadsPath);
  final workerSpreads = read(kWorkerSpreadsPath);
  final appCrisis = read(kAppCrisisPath);
  final workerCrisis = read(kWorkerCrisisPath);

  // Cards: deck_meta vs worker cards.json.
  final metaCards = list(meta, 'cards', kDeckMetaPath);
  final feedCards = list(workerCards, 'cards', kWorkerCardsPath);
  if (meta != null && workerCards != null) {
    if (meta['version'] != workerCards['version'] ||
        meta['id'] != workerCards['deckId']) {
      fail(
        kWorkerCardsPath,
        'deckId/version ${workerCards['deckId']}/${workerCards['version']} '
        '!= deck_meta ${meta['id']}/${meta['version']}',
      );
    }
    final metaIds = [for (final c in metaCards) c['id']];
    final feedIds = [for (final c in feedCards) c['id']];
    if (!_same(metaIds, feedIds)) {
      fail(kWorkerCardsPath, 'card IDs differ from deck_meta.json');
    } else {
      for (final (i, card) in metaCards.indexed) {
        for (final k in _deckCardKeys) {
          if (!_same(card[k], feedCards[i][k])) {
            fail(kWorkerCardsPath, '${card['id']}.$k differs from deck_meta');
          }
        }
      }
    }
  }

  // Checksums and locale files.
  final locales = meta?['locales'];
  final checksums = meta?['checksums'];
  if (meta != null && (locales is! List || checksums is! Map)) {
    fail(kDeckMetaPath, '"locales" and "checksums" are required');
  } else if (meta != null) {
    final names = {
      'spreads.json',
      'crisis_resources.json',
      for (final l in locales! as List) '$l.json',
    };
    final sums = checksums! as Map;
    if (!_same(sums.keys.toList()..sort(), names.toList()..sort())) {
      fail(kDeckMetaPath, 'checksums must cover exactly ${names.join(', ')}');
    }
    for (final name in names) {
      final file = File('${root.path}/$kAppDeckDir/$name');
      if (file.existsSync() &&
          sums[name] != sha256Bytes(file.readAsBytesSync())) {
        fail('$kAppDeckDir/$name', 'checksum differs from deck_meta.json');
      }
    }
    final enFeed = {for (final c in feedCards) c['id']: c};
    for (final locale in locales as List) {
      final texts = read(appLocalePath('$locale'));
      final prompt = read(workerPromptPath('$locale'));
      if (texts == null || prompt == null) continue;
      final byId = {
        for (final c in list(texts, 'cards', appLocalePath('$locale')))
          c['cardId']: c,
      };
      final promptCards = (prompt as Map)['cards'];
      if (promptCards is! Map) {
        fail(workerPromptPath('$locale'), '"cards" must be an object');
        continue;
      }
      final promptIds = promptCards.keys.map((k) => '$k').toList()..sort();
      final metaIds = [for (final c in metaCards) '${c['id']}']..sort();
      if (!_same(promptIds, metaIds)) {
        fail(workerPromptPath('$locale'), 'card IDs differ from deck_meta');
      }
      for (final MapEntry(key: id, value: entry) in promptCards.entries) {
        final text = byId[id];
        for (final k in _promptKeys) {
          if (text == null || entry is! Map || !_same(entry[k], text[k])) {
            fail(
              workerPromptPath('$locale'),
              '$id.$k differs from $locale.json',
            );
          }
        }
        if (locale == 'en') {
          for (final k in _promptKeys.take(3)) {
            if (text != null && !_same(enFeed[id]?[k], text[k])) {
              fail(kWorkerCardsPath, '$id.$k differs from en.json');
            }
          }
        }
      }
    }
    final generated = Directory('${root.path}/$kWorkerGeneratedDir');
    final built = [for (final l in locales) '$l'];
    final extra =
        (generated.existsSync()
                ? generated.listSync()
                : const <FileSystemEntity>[])
            .map((e) => e.path.split('/').last)
            .where((n) => n.startsWith('deck_prompt.'))
            .where((n) => !built.contains(n.split('.')[1]));
    for (final name in extra) {
      fail('$kWorkerGeneratedDir/$name', 'locale not in deck_meta.locales');
    }
  }

  // Spreads.
  final app = list(appSpreads, 'spreads', kAppSpreadsPath);
  final worker = list(workerSpreads, 'spreads', kWorkerSpreadsPath);
  if (appSpreads != null && workerSpreads != null) {
    String shape(List<Map<String, Object?>> spreads) => compactJson([
      for (final s in spreads)
        {
          'id': s['id'],
          'version': s['version'],
          'allowsReversals': s['allowsReversals'],
          'positions': [
            if (s['positions'] is List)
              for (final p in s['positions']! as List)
                if (p is Map) {'id': p['id'], 'order': p['order']},
          ],
        },
    ]);
    if (shape(app) != shape(worker)) {
      fail(
        kWorkerSpreadsPath,
        'spread IDs, versions, reversals or positions differ from the app',
      );
    }
  }

  // Crisis resources: identical documents.
  if (appCrisis != null &&
      workerCrisis != null &&
      !_same(appCrisis, workerCrisis)) {
    fail(kWorkerCrisisPath, 'differs from $kAppCrisisPath');
  }
  return issues;
}
