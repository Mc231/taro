import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taro/data/content/asset_content_repository.dart';
import 'package:taro/l10n/generated/taro_localizations.dart';
import 'package:taro/routing/screen_builders.dart';
import 'package:taro_core/taro_core.dart';

import '../data/content/disk_asset_bundle.dart';
import '../features/skeleton_support.dart';

/// The route arguments each skeleton screen needs to render.
const Map<ScreenId, ScreenArgs> _args = {
  ScreenId.s07: ScreenArgs(query: {'spread': 'three_ppf'}),
  ScreenId.s09: ScreenArgs(path: {'id': 'smoke-reading'}),
  ScreenId.s15: ScreenArgs(path: {'id': 'smoke-reading'}),
  ScreenId.s17: ScreenArgs(path: {'cardId': 'major_00'}),
  ScreenId.s18: ScreenArgs(path: {'spreadId': 'three_ppf'}),
  ScreenId.s29: ScreenArgs(path: {'doc': 'terms'}),
  ScreenId.s32: ScreenArgs(
    path: {'id': 'smoke-reading'},
    query: {'mode': 'classic'},
  ),
  ScreenId.s33: ScreenArgs(path: {'id': 'smoke-reading'}),
};

/// The modal screens (`TaroModals`).
const Set<ScreenId> _modals = {ScreenId.s10, ScreenId.s12, ScreenId.s33};

/// Three sample cards whose deck content must load in every locale.
const List<CardId> _sampleCards = [
  CardId('major_00'),
  CardId('cups_03'),
  CardId('pentacles_14'),
];

/// The screens of the smoke (06 §3.1 "each key screen"): every S-ID.
Iterable<ScreenId> get _screens => screenBuilders.keys;

void main() {
  final keys = {
    for (final key
        in (jsonDecode(
                  File('lib/l10n/arb/app_en.arb').readAsStringSync(),
                )
                as Map<String, Object?>)
            .keys)
      if (!key.startsWith('@')) key,
  };
  final keyLike = RegExp(r'^[a-z][A-Za-z0-9_]+$');

  // The 12-locale smoke (06 §3.1): every skeleton screen in every locale at
  // kPhoneSmall and text scale 1.3 renders without a FlutterError (an
  // overflow fails the test), shows no empty or raw-key text, and lays out
  // right-to-left in `ar` only.
  for (final locale in TaroLocalizations.supportedLocales) {
    final code = locale.languageCode;
    testWidgets('locale smoke: $code', (tester) async {
      final content = AssetContentRepository.fromBundle(
        DiskAssetBundle(),
        runner: inlineRunner,
      );
      for (final id in _sampleCards) {
        final text = await tester.runAsync(
          () => content.cardText(id, code),
        );
        expect(text?.valueOrNull?.name, isNotEmpty, reason: '$code $id');
      }
      for (final screen in _screens) {
        final fakes = TaroFakes()
          ..journal.putReading(aReading().withId('smoke-reading').build());
        await pumpRouted(
          tester,
          Builder(
            builder: (context) {
              final built = buildScreen(
                context,
                screen,
                _args[screen] ?? const ScreenArgs(),
              );
              // Modals get their Material from the sheet / dialog route.
              return _modals.contains(screen) ? Scaffold(body: built) : built;
            },
          ),
          fakes: fakes,
          locale: locale,
          textScale: 1.3,
        );
        final reason = '$code ${screen.wire}';
        expect(tester.takeException(), isNull, reason: reason);
        final direction = Directionality.of(
          tester.element(find.byType(Builder).first),
        );
        expect(
          direction,
          code == 'ar' ? TextDirection.rtl : TextDirection.ltr,
          reason: reason,
        );
        for (final text in tester.widgetList<Text>(find.byType(Text))) {
          final data = text.data ?? text.textSpan?.toPlainText() ?? '';
          expect(data.trim(), isNotEmpty, reason: reason);
          expect(
            keyLike.hasMatch(data) && keys.contains(data),
            isFalse,
            reason: '$reason shows the raw key "$data"',
          );
        }
        // Unmount before the next screen so timers and streams end.
        await tester.pumpWidget(const SizedBox.shrink());
      }
    });
  }
}
