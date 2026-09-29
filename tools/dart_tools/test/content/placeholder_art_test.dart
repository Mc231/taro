import 'dart:io';

import 'package:image/image.dart' as img;
import 'package:taro_dart_tools/content.dart';
import 'package:test/test.dart';

import 'fixture.dart';

/// A minimal repository: the specs marker and an en glossary.
Directory _repo() {
  final root = Directory.systemTemp.createTempSync('taro_art_');
  Directory('${root.path}/docs/specs').createSync(recursive: true);
  File('${root.path}/$kSourceDir/glossary.yaml')
    ..parent.createSync(recursive: true)
    ..writeAsStringSync(toYaml(glossaryDoc()));
  return root;
}

RunResult _run(Directory root, [List<String> args = const []]) {
  final out = StringBuffer();
  final err = StringBuffer();
  final code = runPlaceholderArt(
    ['--repo-root', root.path, ...args],
    io: ContentIo(out: out, err: err),
  );
  return (code: code, out: out.toString(), err: err.toString());
}

Map<String, String> get _names => {for (final id in kCardIds) id: 'Card $id'};

void main() {
  group('numerals and wrapping', () {
    test('roman numerals', () {
      expect(
        [0, 1, 4, 9, 14, 19, 21].map(romanNumeral),
        ['0', 'I', 'IV', 'IX', 'XIV', 'XIX', 'XXI'],
      );
    });

    test('numeralOf covers majors, pips and courts', () {
      expect(numeralOf('major_00'), '0');
      expect(numeralOf('major_21'), 'XXI');
      expect(numeralOf('cups_01'), 'ACE');
      expect(numeralOf('cups_07'), 'VII');
      expect(numeralOf('wands_10'), 'X');
      expect(
        ['11', '12', '13', '14'].map((n) => numeralOf('swords_$n')),
        ['PAGE', 'KNIGHT', 'QUEEN', 'KING'],
      );
    });

    test('wrapWords upper-cases and keeps long words whole', () {
      expect(wrapWords('Wheel of Fortune', 12), ['WHEEL OF', 'FORTUNE']);
      expect(wrapWords('  The   Fool ', 12), ['THE FOOL']);
      expect(wrapWords('Extraordinarily long', 5), [
        'EXTRAORDINARILY',
        'LONG',
      ]);
      expect(wrapWords('', 5), isEmpty);
    });

    test('the pixel font covers every English card name', () {
      final names = englishCardNames(
        readYaml(realRepo, '$kSourceDir/glossary.yaml'),
      );
      for (final name in names.values) {
        for (final char in name.split('')) {
          expect(
            kPixelGlyphs.containsKey(char.toUpperCase()),
            isTrue,
            reason: '"$char" in $name',
          );
        }
      }
      for (final rows in [...kPixelGlyphs.values, kUnknownGlyph]) {
        expect(rows, hasLength(kGlyphHeight));
        expect(rows.every((r) => r.length == kGlyphWidth), isTrue);
      }
      expect(glyphOf('~'), same(kUnknownGlyph));
      expect(glyphOf('a'), kPixelGlyphs['A']);
      expect(textWidth(''), 0);
      expect(textWidth('AB'), 2 * kGlyphAdvance - 1);
    });
  });

  group('rendering', () {
    test('every card and the back decode as 480 x 800 WebP', () {
      final files = generatePlaceholderArt(_names);
      expect(files.keys, [
        for (final key in placeholderArtKeys()) placeholderArtPath(key),
      ]);
      expect(files, hasLength(79));
      for (final MapEntry(key: path, value: bytes) in files.entries) {
        expect(String.fromCharCodes(bytes.sublist(8, 12)), 'WEBP');
        final image = img.decodeWebP(bytes);
        expect(image, isNotNull, reason: path);
        expect((image!.width, image.height), (kArtWidth, kArtHeight));
      }
    });

    test('output is byte-identical across runs', () {
      expect(renderCard('major_10', 'Wheel of Fortune'), [
        ...renderCard('major_10', 'Wheel of Fortune'),
      ]);
      expect(renderCardBack(), [...renderCardBack()]);
    });

    test('cards differ by name, suit and numeral', () {
      final a = renderCard('cups_02', 'Two of Cups');
      expect(renderCard('cups_02', 'Other'), isNot(a));
      expect(renderCard('wands_02', 'Two of Cups'), isNot(a));
      expect(renderCard('cups_03', 'Two of Cups'), isNot(a));
    });

    test('the card back is point-symmetric', () {
      final back = img.decodeWebP(renderCardBack())!;
      var differing = 0;
      for (var y = 1; y < kArtHeight; y++) {
        for (var x = 1; x < kArtWidth; x++) {
          final mirrored = back.getPixel(kArtWidth - x, kArtHeight - y);
          if (back.getPixel(x, y) != mirrored) differing++;
        }
      }
      // Exact except for a pixel of polygon rasterisation along the star
      // edges (under 1 % of the card).
      expect(differing, lessThan(kArtWidth * kArtHeight ~/ 100));
    });

    test('a very long name shrinks instead of overflowing', () {
      final image = img.decodeWebP(
        renderCard('major_00', 'Incomprehensibilities'),
      )!;
      expect(image.width, kArtWidth);
    });
  });

  group('englishCardNames', () {
    test('reads the glossary', () {
      final names = englishCardNames(glossaryDoc());
      expect(names, hasLength(78));
      expect(names['major_00'], cardName('major_00', 'en'));
    });

    test('fails on a missing name', () {
      for (final doc in <Object?>[
        null,
        {'cards': <String, Object?>{}},
        {
          'cards': {
            'major_00': {'en': ' '},
          },
        },
      ]) {
        expect(
          () => englishCardNames(doc),
          throwsA(isA<ContentFormatException>()),
        );
      }
    });
  });

  group('runPlaceholderArt', () {
    late Directory root;
    setUp(() => root = _repo());
    tearDown(() => root.deleteSync(recursive: true));

    File art(String key) => File('${root.path}/${placeholderArtPath(key)}');

    test('writes the set, then is idempotent and --check passes', () {
      final check0 = _run(root, ['--check']);
      expect(check0.code, 1);
      expect(
        check0.err,
        contains('out of date: ${placeholderArtPath('major_00')}'),
      );

      final first = _run(root);
      expect(first.code, 0, reason: first.err);
      expect(first.out, contains('79 written, 0 deleted, 0 unchanged'));
      expect(art(kCardBackKey).existsSync(), isTrue);

      final second = _run(root);
      expect(second.out, contains('0 written, 0 deleted, 79 unchanged'));
      final check = _run(root, ['--check']);
      expect(check.code, 0);
      expect(check.out, contains('up to date'));
    });

    test('rewrites changed files and deletes stale ones', () {
      _run(root);
      art('cups_01').writeAsBytesSync([1, 2, 3]);
      art('swords_02').writeAsBytesSync(art('swords_03').readAsBytesSync());
      File('${root.path}/$kPlaceholderArtDir/old.webp').writeAsStringSync('x');

      final check = _run(root, ['--check']);
      expect(check.code, 1);
      expect(
        check.err,
        contains('out of date: ${placeholderArtPath('cups_01')}'),
      );
      expect(
        check.err,
        contains('out of date: ${placeholderArtPath('swords_02')}'),
      );
      expect(check.err, contains('stale: $kPlaceholderArtDir/old.webp'));
      expect(check.err, contains('run tools/content/placeholder_art'));

      final fix = _run(root);
      expect(fix.out, contains('2 written, 1 deleted, 77 unchanged'));
      expect(fix.out, contains('deleted $kPlaceholderArtDir/old.webp'));
      expect(_run(root, ['--check']).code, 0);
    });

    test('fails on a broken or missing glossary', () {
      File('${root.path}/$kSourceDir/glossary.yaml').writeAsStringSync(
        'cards: {}\n',
      );
      final broken = _run(root);
      expect(broken.code, 1);
      expect(broken.err, contains('no en name for major_00'));

      File('${root.path}/$kSourceDir/glossary.yaml').deleteSync();
      final missing = _run(root);
      expect(missing.code, 1);
      expect(missing.err, contains('glossary.yaml'));
    });

    test('command line errors and help', () {
      final err = StringBuffer();
      expect(runPlaceholderArt(['--x'], io: ContentIo(err: err)), 64);
      expect(
        runPlaceholderArt(
          [],
          io: ContentIo(err: err, cwd: Directory.systemTemp),
        ),
        1,
      );
      final out = StringBuffer();
      expect(runPlaceholderArt(['--help'], io: ContentIo(out: out)), 0);
      expect(out.toString(), contains('placeholder_art'));
    });

    test('the committed placeholder set is up to date', () {
      final r = runPlaceholderArt(
        ['--repo-root', realRepo.path, '--check'],
        io: ContentIo(out: StringBuffer(), err: StringBuffer()),
      );
      expect(r, 0);
    });
  });
}
