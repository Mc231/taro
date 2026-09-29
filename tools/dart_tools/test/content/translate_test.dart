import 'dart:convert';
import 'dart:io';

import 'package:taro_dart_tools/content.dart';
import 'package:test/test.dart';

import 'fixture.dart';

/// Answers like a model would, in German, and records every request.
final class FakeClaude implements ClaudeClient {
  FakeClaude({this.failOn, this.mutate});

  final List<ClaudeRequest> requests = [];

  /// Throw a [ClaudeException] on the request with this index.
  final int? failOn;

  /// Changes a card answer (to produce invalid output).
  final void Function(Map<String, Object?> answer)? mutate;

  @override
  Future<Map<String, Object?>> complete(ClaudeRequest request) async {
    requests.add(request);
    if (failOn == requests.length - 1) {
      throw const ClaudeException('HTTP 529: overloaded');
    }
    final props = (request.schema['properties']! as Map).keys;
    if (props.contains('name')) {
      final id = (jsonDecode(request.user) as Map)['cardId'] as String;
      final answer = {
        ...cardTexts(id, 'de'),
        'name': ' Falscher Name ',
      };
      mutate?.call(answer);
      return answer;
    }
    if (props.contains('whenToUse')) {
      return {
        'whenToUse': {
          for (final id in kSpreadPositions.keys)
            id: words(20, locale: 'de', seed: id.length),
        },
      };
    }
    return {'markdown': articleBody('x', locale: 'de')};
  }
}

void main() {
  late FixtureRepo repo;
  setUp(() {
    repo = FixtureRepo.create()
      ..edit('$kSourceDir/glossary.yaml', (g) {
        (g['review']! as Map)['de'] = 'reviewed';
        for (final section in [
          'cards',
          'suits',
          'arcana',
          'positions',
          'terms',
        ]) {
          for (final MapEntry(key: id, value: names)
              in (g[section]! as Map).entries) {
            (names as Map)['de'] = section == 'cards'
                ? cardName('$id', 'de')
                : '$id de';
          }
        }
      });
  });
  tearDown(() => repo.dispose());

  Future<RunResult> translateRun(
    List<String> args, {
    FakeClaude? client,
    Map<String, String> env = const {'ANTHROPIC_API_KEY': 'test-key'},
  }) async {
    final out = StringBuffer();
    final err = StringBuffer();
    final code = await runContentTranslate(
      ['--repo-root', repo.root.path, ...args],
      io: ContentIo(
        out: out,
        err: err,
        clock: () => fixtureToday,
        environment: env,
      ),
      clientFactory: client == null ? null : (_) => client,
    );
    return (code: code, out: out.toString(), err: err.toString());
  }

  test('--dry-run plans every missing file without a key', () async {
    final r = await translateRun(['--locale', 'de', '--dry-run'], env: {});
    expect(r.code, 0);
    expect(r.out, contains('de/cards/major_00.yaml (missing)'));
    expect(r.out, contains('de/spreads.yaml (missing)'));
    expect(r.out, contains('de/articles/faq.md (missing)'));
    expect(r.out, contains('dry run, 81 file(s) planned'));
  });

  test('translates cards, spreads and articles into valid files', () async {
    final client = FakeClaude();
    final r = await translateRun(['--locale', 'de'], client: client);
    expect(r.err, isEmpty);
    expect(r.code, 0);
    expect(r.out, contains('81 file(s) written, valid'));
    expect(client.requests, hasLength(81));
    final request = client.requests.first;
    expect(request.model, 'claude-opus-5');
    expect(request.system, contains('German'));
    expect(request.system, contains('Card major_00 → Karte major_00'));
    expect(request.system, contains('hellseher*'));
    final card = repo.readYamlMap(repo.cardPath('de', 'cups_03'));
    expect(card['reviewStatus'], 'machine');
    expect(card['name'], 'Karte cups_03');
    expect(card['sourceHash'], cardSourceHash(enCard('cups_03')));
    expect(repo.read(repo.cardPath('de', 'cups_03')), startsWith('# Machine'));
    final article = repo.read('$kSourceDir/de/articles/about.md');
    expect(article, startsWith('---\nreviewStatus: machine\nsourceHash: '));
    final validated = run(runContentValidate, repo);
    expect(validated.code, 0);
    expect(validated.out, contains('complete locales: en, de;'));

    final again = await translateRun(['--locale', 'de'], client: client);
    expect(again.out, contains('nothing to do'));
    expect(client.requests, hasLength(81));
  });

  test('--cards translates only those cards, stale ones again', () async {
    final client = FakeClaude();
    var r = await translateRun([
      '--locale',
      'de',
      '--cards',
      'cups_03, major_00',
    ], client: client);
    expect(r.code, 0);
    expect(client.requests, hasLength(2));
    repo.edit(repo.cardPath('en', 'cups_03'), (d) {
      d['shortUpright'] = 'A new calm line.';
    });
    r = await translateRun(
      ['--locale', 'de', '--cards', 'cups_03,major_00', '--dry-run'],
      client: client,
    );
    expect(r.out, contains('cups_03.yaml (stale)'));
    expect(r.out, isNot(contains('major_00.yaml')));
    r = await translateRun(
      ['--locale', 'de', '--cards', 'major_00', '--force', '--dry-run'],
      client: client,
    );
    expect(r.out, contains('major_00.yaml (current)'));
  });

  test('--parts and --model', () async {
    final client = FakeClaude();
    final r = await translateRun([
      '--locale',
      'de',
      '--parts',
      'spreads',
      '--model',
      'claude-sonnet-5',
    ], client: client);
    expect(r.code, 0);
    expect(client.requests.single.model, 'claude-sonnet-5');
    final spreads = repo.readYamlMap('$kSourceDir/de/spreads.yaml');
    expect(spreads['sourceHash'], spreadsSourceHash(enSpreads()));
  });

  test('no API key', () async {
    final r = await translateRun(['--locale', 'de'], env: {});
    expect(r.code, 1);
    expect(r.err, contains('ANTHROPIC_API_KEY is not set'));
  });

  test('an API error stops the run', () async {
    final client = FakeClaude(failOn: 1);
    final r = await translateRun(['--locale', 'de'], client: client);
    expect(r.code, 1);
    expect(r.err, contains('major_01.yaml: HTTP 529: overloaded'));
    expect(client.requests, hasLength(2));
    expect(
      File('${repo.root.path}/${repo.cardPath('de', 'major_00')}').existsSync(),
      isTrue,
    );
  });

  test('invalid model output is written but fails', () async {
    final client = FakeClaude(
      mutate: (a) => a['shortUpright'] = 'Das ist garantiert.',
    );
    final r = await translateRun([
      '--locale',
      'de',
      '--cards',
      'cups_03',
    ], client: client);
    expect(r.code, 1);
    expect(r.err, contains('banned phrase "garantiert*"'));
    expect(r.err, contains('2 validation error(s) in the written files'));
  });

  test('the glossary must be reviewed for the locale', () async {
    repo.edit('$kSourceDir/glossary.yaml', (g) {
      (g['review']! as Map)['de'] = 'machine';
    });
    final r = await translateRun(['--locale', 'de', '--dry-run']);
    expect(r.code, 1);
    expect(r.err, contains('review.de is "machine"'));
    final allowed = await translateRun([
      '--locale',
      'de',
      '--dry-run',
      '--allow-unreviewed-glossary',
    ]);
    expect(allowed.code, 0);
  });

  test('en errors block translation', () async {
    repo.edit(repo.cardPath('en', 'cups_03'), (d) => d['name'] = 'X');
    final r = await translateRun(['--locale', 'de', '--dry-run']);
    expect(r.code, 1);
    expect(r.err, contains('fix the 1 en/glossary error(s) first'));
  });

  test('usage errors', () async {
    expect((await translateRun([])).code, 64);
    expect((await translateRun(['--locale', 'en'])).code, 64);
    final unknown = await translateRun(['--locale', 'de', '--cards', 'x_1']);
    expect(unknown.code, 64);
    expect(unknown.err, contains('unknown card ID(s): x_1'));
    expect((await translateRun(['--locale', 'de', '--cards', ','])).code, 64);
    final help = await translateRun(['--help']);
    expect(help.out, contains('--dry-run'));
    final err = StringBuffer();
    expect(
      await runContentTranslate(
        ['--locale', 'de'],
        io: ContentIo(err: err, cwd: Directory.systemTemp),
      ),
      1,
    );
    repo.delete(kBannedPhrasesPath);
    expect((await translateRun(['--locale', 'de'])).code, 1);
  });

  test('the default client factory builds the HTTP client', () {
    expect(defaultClaudeClient('k'), isA<AnthropicHttpClient>());
  });

  test('the card answer schema is strict', () {
    final schema = cardAnswerSchema();
    expect(schema['additionalProperties'], false);
    expect(schema['required'], containsAll(kCardTextKeys));
  });
}
