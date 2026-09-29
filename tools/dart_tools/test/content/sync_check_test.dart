import 'dart:convert';
import 'dart:io';

import 'package:taro_dart_tools/content.dart';
import 'package:test/test.dart';

import 'fixture.dart';

void _editJson(
  FixtureRepo repo,
  String path,
  void Function(Map<String, Object?> doc) edit,
) {
  final doc = jsonDecode(repo.read(path)) as Map<String, Object?>;
  edit(doc);
  repo.write(path, canonicalJson(doc));
}

Map<String, Object?> _first(Map<String, Object?> doc, String key) =>
    (doc[key]! as List).first as Map<String, Object?>;

final Map<String, (void Function(FixtureRepo), String)> _failures = {
  'missing Worker cards': (
    (r) => r.delete(kWorkerCardsPath),
    'deck/cards.json: missing (run tools/content/build)',
  ),
  'invalid JSON': (
    (r) => r.write(kWorkerSpreadsPath, '{'),
    'deck/spreads.json: invalid JSON',
  ),
  'not an object': (
    (r) => r.write(kWorkerCrisisPath, '[]'),
    'crisis_resources.json: must be a JSON object',
  ),
  'deck version differs': (
    (r) => _editJson(r, kWorkerCardsPath, (d) => d['version'] = 2),
    'deckId/version rws_original/2 != deck_meta rws_original/1',
  ),
  'card IDs differ': (
    (r) => _editJson(r, kWorkerCardsPath, (d) {
      (d['cards']! as List).removeLast();
    }),
    'card IDs differ from deck_meta.json',
  ),
  'DeckCard field differs': (
    (r) =>
        _editJson(r, kWorkerCardsPath, (d) => _first(d, 'cards')['number'] = 9),
    'major_00.number differs from deck_meta',
  ),
  'cards not a list': (
    (r) => _editJson(r, kWorkerCardsPath, (d) => d['cards'] = {}),
    '"cards" must be a list of objects',
  ),
  'en name differs': (
    (r) =>
        _editJson(r, kWorkerCardsPath, (d) => _first(d, 'cards')['name'] = 'X'),
    'major_00.name differs from en.json',
  ),
  'prompt text differs': (
    (r) => _editJson(r, workerPromptPath('de'), (d) {
      ((d['cards']! as Map)['cups_03']! as Map)['shortUpright'] = 'x';
    }),
    'cups_03.shortUpright differs from de.json',
  ),
  'prompt card IDs differ': (
    (r) => _editJson(r, workerPromptPath('de'), (d) {
      (d['cards']! as Map).remove('cups_03');
    }),
    'deck_prompt.de.json: card IDs differ from deck_meta',
  ),
  'prompt cards not an object': (
    (r) => _editJson(r, workerPromptPath('en'), (d) => d['cards'] = []),
    '"cards" must be an object',
  ),
  'missing locale prompt': (
    (r) => r.delete(workerPromptPath('de')),
    'deck_prompt.de.json: missing',
  ),
  'extra locale prompt': (
    (r) => r.write(workerPromptPath('fr'), '{}'),
    'deck_prompt.fr.json: locale not in deck_meta.locales',
  ),
  'checksum differs': (
    (r) => r.write(appLocalePath('de'), '${r.read(appLocalePath('de'))} '),
    'de.json: checksum differs from deck_meta.json',
  ),
  'checksums cover other files': (
    (r) => _editJson(r, kDeckMetaPath, (d) => d['locales'] = ['en']),
    'checksums must cover exactly',
  ),
  'meta without locales': (
    (r) => _editJson(r, kDeckMetaPath, (d) => d.remove('locales')),
    '"locales" and "checksums" are required',
  ),
  'spreads differ': (
    (r) => _editJson(
      r,
      kWorkerSpreadsPath,
      (d) => _first(d, 'spreads')['version'] = 2,
    ),
    'spread IDs, versions, reversals or positions differ from the app',
  ),
  'crisis differs': (
    (r) => _editJson(r, kWorkerCrisisPath, (d) => d['international'] = []),
    'crisis_resources.json: differs from',
  ),
};

void main() {
  late FixtureRepo repo;
  setUp(() {
    repo = FixtureRepo.create(locales: ['de']);
    expect(run(runContentBuild, repo).code, 0);
  });
  tearDown(() => repo.dispose());

  test('a fresh build is in sync', () {
    final r = run(runContentSyncCheck, repo);
    expect(r.err, isEmpty);
    expect(r.out, contains('content sync_check: OK'));
    expect(r.code, 0);
  });

  for (final MapEntry(key: name, value: (mutate, expected))
      in _failures.entries) {
    test(name, () {
      mutate(repo);
      final r = run(runContentSyncCheck, repo);
      expect(r.err, contains(expected));
      expect(r.code, 1);
    });
  }

  test('nothing built at all', () {
    Directory('${repo.root.path}/$kAppDeckDir').deleteSync(recursive: true);
    Directory(
      '${repo.root.path}/$kWorkerGeneratedDir',
    ).deleteSync(recursive: true);
    final r = run(runContentSyncCheck, repo);
    expect(r.code, 1);
    expect(r.err, contains('deck_meta.json: missing'));
  });

  test('Worker feeds not built', () {
    Directory(
      '${repo.root.path}/$kWorkerGeneratedDir',
    ).deleteSync(recursive: true);
    final r = run(runContentSyncCheck, repo);
    expect(r.code, 1);
    expect(r.err, contains('deck/cards.json: missing'));
  });

  test('command line errors', () {
    final err = StringBuffer();
    expect(runContentSyncCheck(['--x'], io: ContentIo(err: err)), 64);
    expect(
      runContentSyncCheck(
        [],
        io: ContentIo(err: err, cwd: Directory.systemTemp),
      ),
      1,
    );
  });
}
