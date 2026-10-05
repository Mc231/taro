import 'dart:convert';
import 'dart:io';

import 'package:taro_dart_tools/tokens.dart';
import 'package:test/test.dart';

TokenSet _real() => TokenSet.parse(
  jsonDecode(File('../../$kTokensPath').readAsStringSync()),
);

Map<String, Object?> _realJson() =>
    jsonDecode(File('../../$kTokensPath').readAsStringSync())
        as Map<String, Object?>;

Map<String, Object?> _at(Map<String, Object?> doc, String path) {
  var node = doc;
  for (final key in path.split('.')) {
    node = node[key]! as Map<String, Object?>;
  }
  return node;
}

void main() {
  group('01 §14 contract', () {
    test('has the 167 names of REVIEW.md K1, without duplicates', () {
      expect(kContractTokenNames, hasLength(167));
      expect(kContractTokenNames.toSet(), hasLength(167));
    });

    test('has the 44 contrast pairs of K6–K10 plus K11', () {
      final perMode = kContrastPairs.where((p) => p.rule != 'K11').length;
      expect(perMode * 2, 44);
      expect(kContrastPairs.where((p) => p.rule == 'K11'), hasLength(3));
    });
  });

  group('docs/design/taro.tokens.json', () {
    test('passes validate_tokens', () {
      expect(validateTokens(_real(), TokenContract.product()), isEmpty);
    });

    test('every contract name exists in both modes (02 §14.1)', () {
      final set = _real();
      for (final name in kContractTokenNames) {
        for (final mode in set.modes) {
          expect(set.resolve(name, mode), isNotNull, reason: '$name/$mode');
        }
      }
      for (final token in set.tokens.values.where((t) => t.type == 'color')) {
        expect(token.isModed, isTrue, reason: token.name);
      }
    });

    test('every contrast pair passes in both modes', () {
      final set = _real();
      for (final mode in set.modes) {
        for (final pair in kContrastPairs) {
          expect(
            contrastRatio(set, pair, mode),
            greaterThanOrEqualTo(pair.minimum),
            reason: '${pair.foreground} on ${pair.background} ($mode)',
          );
        }
      }
    });
  });

  group('failures on edited copies of the real file', () {
    List<String> issuesAfter(void Function(Map<String, Object?>) edit) {
      final doc = _realJson();
      edit(doc);
      return validateTokens(TokenSet.parse(doc), TokenContract.product());
    }

    test('a missing and an unknown name', () {
      final issues = issuesAfter((d) {
        _at(d, 'space').remove('12');
        _at(d, 'space')['13'] = {r'$type': 'dimension', r'$value': '72px'};
      });
      expect(issues, contains('space.12: missing (01 §14)'));
      expect(issues, contains('space.13: unknown name (not in 01 §14)'));
    });

    test('a motion token without reduced motion', () {
      final issues = issuesAfter(
        (d) => _at(d, 'motion.duration.fast').remove(r'$extensions'),
      );
      expect(issues.single, contains('motion.duration.fast: no'));
    });

    test('a reduced-motion value that does not parse', () {
      final issues = issuesAfter((d) {
        _at(d, 'motion.duration.fast')[r'$extensions'] = {
          'taro.reducedMotion': {r'$value': 'soon'},
        };
      });
      expect(issues.single, contains('unsupported duration'));
    });

    test('a haptic value TaroHaptics cannot play', () {
      final issues = issuesAfter(
        (d) => _at(d, 'haptic.pick')[r'$value'] = 'buzz',
      );
      expect(issues.single, startsWith('haptic.pick: "buzz"'));
    });

    test('a type role without letterSpacing (K5) and a missing script', () {
      final issues = issuesAfter((d) {
        (_at(d, 'type.body')[r'$value']! as Map).remove('letterSpacing');
        _at(d, 'font.family.body').remove('hangul');
      });
      expect(issues, contains('type.body: no letterSpacing (01 §14.2)'));
      expect(issues, contains('font.family.body.hangul: missing (01 §14.2)'));
    });

    test('a type role that is not an object', () {
      final issues = issuesAfter((d) => _at(d, 'type.body')[r'$value'] = 'x');
      expect(issues, contains('type.body: value must be an object'));
    });

    test('broken constraints', () {
      final issues = issuesAfter((d) {
        (_at(d, 'type.body')[r'$value']! as Map)['fontSize'] = '15px';
        (_at(d, 'type.caption')[r'$value']! as Map)['fontSize'] = '11px';
        (_at(d, 'type.bodyReading')[r'$value']! as Map)['lineHeight'] = '20px';
        _at(d, 'space.adGap')[r'$value'] = '8px';
        _at(d, 'layout.gutter')[r'$value'] = '12px';
        _at(d, 'size.touchTarget.min')[r'$value'] = '44px';
      });
      expect(issues, contains('type.body.fontSize: 15 < 16 (01 §14.2)'));
      expect(issues, contains('type.caption.fontSize: 11 < 12 (01 §14.2)'));
      expect(issues.any((i) => i.startsWith('type.bodyReading')), isTrue);
      expect(issues, contains('space.adGap: 8 < 16 (RC59)'));
      expect(issues, contains('layout.gutter: 12 < 16 (01 §14.3)'));
      expect(issues, contains('size.touchTarget.min: must be 48 (01 §14.3)'));
    });

    test('a contrast pair that fails', () {
      final issues = issuesAfter((d) {
        (_at(d, 'color.text.secondary')[r'$extensions']! as Map)['taro.modes'] =
            {'light': '#B0B0B0', 'dark': '#B2B7CD'};
      });
      expect(
        issues,
        contains(
          startsWith('color.text.secondary on color.bg.canvas (light): '),
        ),
      );
    });

    test('a value that does not parse', () {
      final issues = issuesAfter(
        (d) => _at(d, 'radius.md')[r'$value'] = 'big',
      );
      expect(issues, contains(contains('radius.md (light): unsupported')));
    });
  });

  group('type checks on a small contract', () {
    const contract = TokenContract(names: ['x.a']);
    List<String> check(String type, Object? value, {bool moded = false}) {
      final token = <String, Object?>{r'$type': type, r'$value': value};
      if (moded) {
        token[r'$extensions'] = {
          'taro.modes': {'light': value, 'dark': value},
        };
      }
      return validateTokens(
        TokenSet.parse({
          r'$extensions': {
            'taro.modes': ['light', 'dark'],
          },
          'x': {'a': token},
        }),
        contract,
      );
    }

    test('valid values of every type pass', () {
      expect(check('color', '#FFFFFF', moded: true), isEmpty);
      expect(check('fontWeight', 400), isEmpty);
      expect(check('shadow', 'none'), isEmpty);
      expect(check('cubicBezier', [0, 0, 1, 1]), isEmpty);
      expect(check('string', 'selection'), isEmpty);
    });

    test('invalid values are reported', () {
      expect(check('string', ''), everyElement(contains('non-empty string')));
      expect(check('typography', 'x'), contains(contains('must be an object')));
      expect(
        check('typography', {'fontFamily': 1}),
        contains(contains('fontFamily must be a string')),
      );
      expect(
        check('mystery', 1),
        contains(contains(r'unsupported $type "mystery"')),
      );
    });
  });

  test('an aliased colour needs no own modes', () {
    final set = TokenSet.parse(
      jsonDecode(
        File('test/fixtures/tokens/pass.tokens.json').readAsStringSync(),
      ),
    );
    final issues = validateTokens(
      set,
      TokenContract(names: set.tokens.keys.toList()),
    );
    expect(issues, isEmpty);
  });

  test('an alias cycle is reported, not thrown (fixture)', () {
    final set = TokenSet.parse(
      jsonDecode(
        File(
          'test/fixtures/tokens/fail_alias_cycle.tokens.json',
        ).readAsStringSync(),
      ),
    );
    final issues = validateTokens(
      set,
      TokenContract(names: set.tokens.keys.toList()),
    );
    expect(issues, everyElement(contains('alias cycle')));
    expect(issues, isNotEmpty);
  });
}
