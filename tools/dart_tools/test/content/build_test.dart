import 'dart:convert';
import 'dart:io';

import 'package:taro_dart_tools/content.dart';
import 'package:test/test.dart';

import 'fixture.dart';

Map<String, Object?> _json(FixtureRepo repo, String path) =>
    jsonDecode(repo.read(path)) as Map<String, Object?>;

void main() {
  late FixtureRepo repo;
  setUp(() => repo = FixtureRepo.create(locales: ['de']));
  tearDown(() => repo.dispose());

  test('writes every output, then is idempotent', () {
    final first = run(runContentBuild, repo);
    expect(first.err, isEmpty);
    expect(first.code, 0);
    for (final path in [
      kDeckMetaPath,
      appLocalePath('en'),
      appLocalePath('de'),
      kAppSpreadsPath,
      kAppCrisisPath,
      kWorkerCardsPath,
      kWorkerSpreadsPath,
      workerPromptPath('en'),
      workerPromptPath('de'),
      kWorkerCrisisPath,
    ]) {
      expect(first.out, contains('wrote $path'));
      expect(repo.read(path), endsWith('}\n'));
    }
    expect(first.out, contains('10 written, 0 deleted, 0 unchanged'));
    final second = run(runContentBuild, repo);
    expect(second.out, contains('0 written, 0 deleted, 10 unchanged'));
    expect(run(runContentBuild, repo, ['--check']).out, contains('up to date'));
  });

  test('output is deterministic across checkouts', () {
    final other = FixtureRepo.create(locales: ['de']);
    addTearDown(other.dispose);
    run(runContentBuild, repo);
    run(runContentBuild, other);
    for (final path in ownedPaths()) {
      final a = File('${repo.root.path}/$path');
      if (!a.existsSync()) continue;
      expect(other.read(path), a.readAsStringSync(), reason: path);
    }
  });

  test('deck_meta: DeckCard fields, locales and checksums', () {
    run(runContentBuild, repo);
    final meta = _json(repo, kDeckMetaPath);
    expect(meta['id'], 'rws_original');
    expect(meta['version'], 1);
    expect(meta['artSet'], 'placeholder');
    expect(meta['locales'], ['en', 'de']);
    final cards = (meta['cards']! as List).cast<Map<String, Object?>>();
    expect(cards, hasLength(78));
    expect(cards.first, {
      'arcana': 'major',
      'artKey': 'major_00',
      'astrology': 'uranus',
      'element': null,
      'id': 'major_00',
      'number': 0,
      'suit': null,
    });
    expect(cards[24], containsPair('suit', 'wands'));
    expect(cards[24], containsPair('element', 'fire'));
    expect(cards[24], containsPair('number', 3));
    final checksums = meta['checksums']! as Map<String, Object?>;
    expect(checksums.keys, [
      'crisis_resources.json',
      'de.json',
      'en.json',
      'spreads.json',
    ]);
    for (final MapEntry(key: name, value: sum) in checksums.entries) {
      expect(sha256Hex(repo.read('$kAppDeckDir/$name')), sum);
    }
    expect(repo.read(kDeckMetaPath), startsWith('{\n  "artSet"'));
  });

  test('locale texts match taro_core CardText', () {
    run(runContentBuild, repo);
    final en = _json(repo, appLocalePath('en'));
    final card = (en['cards']! as List).first as Map<String, Object?>;
    expect(card.keys.toSet(), {
      'cardId',
      'locale',
      'name',
      'keywordsUpright',
      'keywordsReversed',
      'shortUpright',
      'shortReversed',
      'meaningUpright',
      'meaningReversed',
      'aspects',
      'reflectionQuestions',
      'imageryNote',
      'sourceHash',
      'reviewStatus',
    });
    expect(card['sourceHash'], cardSourceHash(enCard('major_00')));
    final de = _json(repo, appLocalePath('de'));
    final deCard = (de['cards']! as List).first as Map<String, Object?>;
    expect(deCard['sourceHash'], card['sourceHash']);
    expect(deCard['locale'], 'de');
    expect((de['spreads']! as Map)['single'], contains('whenToUse'));
    final about = (en['articles']! as Map)['about'] as Map<String, Object?>;
    expect(about['markdown'], startsWith('# About about'));
    expect(about['reviewStatus'], 'machine');
    expect(
      about['sourceHash'],
      articleSourceHash(about['markdown']! as String),
    );
  });

  test('spreads and Worker feeds', () {
    run(runContentBuild, repo);
    final spreads = (_json(repo, kAppSpreadsPath)['spreads']! as List)
        .cast<Map<String, Object?>>();
    expect([for (final s in spreads) s['id']], kSpreadPositions.keys);
    final celtic = spreads.last;
    final challenge = (celtic['positions']! as List)[1] as Map;
    expect(challenge, {
      'id': 'challenge',
      'order': 2,
      'rotationDeg': 90.0,
      'x': 2 / 11,
      'y': 0.5,
    });
    expect(celtic['questionSuggestionKeys'], hasLength(3));
    final worker = _json(repo, kWorkerSpreadsPath);
    final position =
        ((worker['spreads']! as List).first as Map)['positions'] as List;
    expect(position.single, containsPair('meaning', isA<String>()));
    final cards = _json(repo, kWorkerCardsPath);
    expect(cards['deckId'], 'rws_original');
    final fool = (cards['cards']! as List).first as Map;
    expect(fool['name'], 'Card major_00');
    expect(fool['keywordsUpright'], hasLength(3));
    final prompt = _json(repo, workerPromptPath('de'));
    expect(prompt['locale'], 'de');
    expect(
      ((prompt['cards']! as Map)['cups_03']! as Map).keys,
      containsAll(['name', 'shortUpright', 'shortReversed']),
    );
  });

  test('crisis directory: canonical shape in app and Worker', () {
    run(runContentBuild, repo);
    expect(repo.read(kAppCrisisPath), repo.read(kWorkerCrisisPath));
    final crisis = _json(repo, kAppCrisisPath);
    expect((crisis['localeFallback']! as Map)['ar'], isNull);
    final intl = (crisis['international']! as List).single as Map;
    expect(intl, {
      'languages': <Object?>[],
      'name': 'Find A Helpline',
      'url': 'https://findahelpline.com',
      'verifiedAt': '2026-09-01',
    });
  });

  test('--check reports out-of-date and stale files', () {
    run(runContentBuild, repo);
    repo
      ..edit('$kSourceDir/en/cards/cups_03.yaml', (d) {
        d['shortUpright'] = 'A new calm line.';
      })
      ..write(workerPromptPath('fr'), '{}\n');
    final r = run(runContentBuild, repo, ['--check']);
    expect(r.code, 1);
    expect(r.err, contains('out of date: ${appLocalePath('en')}'));
    expect(r.err, contains('stale: ${workerPromptPath('fr')}'));
    expect(
      File('${repo.root.path}/${workerPromptPath('fr')}').existsSync(),
      isTrue,
    );
  });

  test('a locale that becomes incomplete is deleted', () {
    run(runContentBuild, repo);
    repo.delete(repo.cardPath('de', 'cups_03'));
    final r = run(runContentBuild, repo);
    expect(r.code, 0);
    expect(r.out, contains('deleted ${appLocalePath('de')}'));
    expect(r.out, contains('deleted ${workerPromptPath('de')}'));
    expect(_json(repo, kDeckMetaPath)['locales'], ['en']);
  });

  test('validation errors stop the build before writing', () {
    repo.edit('$kSourceDir/en/cards/cups_03.yaml', (d) => d['name'] = 'X');
    final r = run(runContentBuild, repo);
    expect(r.code, 1);
    expect(r.err, contains('validation error(s); nothing written'));
    expect(File('${repo.root.path}/$kDeckMetaPath').existsSync(), isFalse);
  });

  test('command line errors', () {
    final err = StringBuffer();
    expect(runContentBuild(['--x'], io: ContentIo(err: err)), 64);
    expect(
      runContentBuild(
        [],
        io: ContentIo(err: err, cwd: Directory.systemTemp),
      ),
      1,
    );
    repo.delete(kBannedPhrasesPath);
    expect(run(runContentBuild, repo).code, 1);
  });
}
