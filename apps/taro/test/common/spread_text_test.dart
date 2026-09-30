import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taro/common/spread_text.dart';
import 'package:taro/l10n/generated/taro_localizations.dart';
import 'package:taro_core/taro_core.dart';

void main() {
  late TaroLocalizations l10n;
  late Map<String, Object?> arb;

  setUpAll(() async {
    l10n = await TaroLocalizations.delegate.load(const Locale('en'));
    arb =
        jsonDecode(File('lib/l10n/arb/app_en.arb').readAsStringSync())
            as Map<String, Object?>;
  });

  test('every spread_ ARB key resolves to its English text', () {
    final keys = arb.keys.where((k) => k.startsWith('spread_')).toList();
    expect(keys, isNotEmpty);
    for (final key in keys) {
      expect(SpreadText.lookup(l10n, key), arb[key], reason: key);
    }
    expect(SpreadText.lookup(l10n, 'spread_nope_name'), isNull);
  });

  test('names, meta, when-to-use and positions; unknown IDs fall back', () {
    const spread = SpreadId('three_ppf');
    const past = PositionId('past');
    expect(SpreadText.name(l10n, spread), l10n.spread_three_ppf_name);
    expect(SpreadText.meta(l10n, spread), l10n.spread_three_ppf_meta);
    expect(SpreadText.whenToUse(l10n, spread), l10n.spread_three_ppf_whenToUse);
    expect(
      SpreadText.positionName(l10n, spread, past),
      l10n.spread_three_ppf_pos_past_name,
    );
    expect(
      SpreadText.positionDescription(l10n, spread, past),
      l10n.spread_three_ppf_pos_past_desc,
    );
    expect(SpreadText.name(l10n, const SpreadId('x')), 'x');
    expect(
      SpreadText.positionName(l10n, spread, const PositionId('y')),
      'y',
    );
  });
}
