import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taro/common/spread_text.dart';
import 'package:taro/features/journal/controller/journal_list_controller.dart';
import 'package:taro/features/journal/view/journal_list_screen.dart';
import 'package:taro/features/learn/controller/deck_browser_controller.dart';
import 'package:taro/features/learn/view/deck_browser_screen.dart';
import 'package:taro/features/reading/controller/draw_state.dart';
import 'package:taro/features/reading/view/draw_screen.dart';
import 'package:taro/features/settings/controller/delete_data_controller.dart';
import 'package:taro/features/settings/controller/privacy_controller.dart';
import 'package:taro/features/settings/view/delete_data_screen.dart';
import 'package:taro/features/settings/view/privacy_screen.dart';
import 'package:taro/l10n/generated/taro_localizations.dart';
import 'package:taro_core/taro_core.dart';
import 'package:taro_ui/taro_ui.dart';

import '../features/flow_view_support.dart';

/// QA round 2 (docs/qa/round2/REPORT.md): S08 on the real spread layouts,
/// rows and chip rows at 200 % text, S26.

/// [id] with the bundled layout (`assets/deck/spreads.json`), not the
/// fake single row of the test builder.
SpreadDefinition _realSpread(String id) {
  final json =
      jsonDecode(File('assets/deck/spreads.json').readAsStringSync())
          as Map<String, Object?>;
  final spread = (json['spreads']! as List<Object?>)
      .cast<Map<String, Object?>>()
      .firstWhere((s) => s['id'] == id);
  return aSpread(id).build().copyWith(
    positions: [
      for (final p
          in (spread['positions']! as List<Object?>)
              .cast<Map<String, Object?>>())
        SpreadPosition(
          id: PositionId(p['id']! as String),
          order: p['order']! as int,
          x: (p['x']! as num).toDouble(),
          y: (p['y']! as num).toDouble(),
          rotationDeg: (p['rotationDeg']! as num).toDouble(),
        ),
    ],
  );
}

Widget _reveal(String spread, {required int cards}) => DrawLayout(
  state: DrawState.revealing(
    DrawView(
      spread: _realSpread(spread),
      draw: aDraw(spreadId: spread),
      classic: false,
      placed: cards,
      reducedMotion: true,
      readingId: const ReadingId('r-1'),
      question: 'What should I focus on this week?',
    ),
  ),
  onClose: noop,
  onShuffled: noop,
  onPick: noop,
  onDrawForMe: noop,
  onReveal: noop,
  onRevealAll: noop,
  onRetry: noop,
  onFinishLater: noop,
  onOpenOptions: noop,
);

double _drawn(RenderParagraph p) =>
    p.textScaler.scale(p.text.style?.fontSize ?? 14);

void main() {
  group('V2-01: Celtic Cross labels on the real layout', () {
    final sizes = {
      'phone': const Size(360, 780),
      'tablet': const Size(1280, 800),
    };
    for (final locale in ['en', 'de', 'uk', 'ja', 'ar']) {
      for (final MapEntry(key: name, value: size) in sizes.entries) {
        testWidgets('$locale $name: every position named, readable', (
          tester,
        ) async {
          await pumpTaro(
            tester,
            _reveal('celtic_cross', cards: 10),
            fakes: aiReadyFakes(),
            locale: Locale(locale),
            size: size,
          );
          await tester.pumpAndSettle();
          final l10n = await TaroLocalizations.delegate.load(Locale(locale));
          final min = tester
              .element(find.byType(SpreadCanvas))
              .tokens
              .typography
              .caption
              .fontSize!;
          final canvas = find.byType(SpreadCanvas);
          for (final p in tester.renderObjectList<RenderParagraph>(
            find.descendant(of: canvas, matching: find.byType(RichText)),
          )) {
            expect(
              _drawn(p),
              greaterThanOrEqualTo(min - 0.01),
              reason: p.text.toPlainText(),
            );
          }
          for (final id in kSpreadPositions['celtic_cross']!) {
            final label = SpreadText.positionName(
              l10n,
              const SpreadId('celtic_cross'),
              PositionId(id),
            );
            expect(
              find.descendant(of: canvas, matching: find.text(label)),
              findsOneWidget,
              reason: label,
            );
          }
          expect(tester.takeException(), isNull);
        });
      }
    }
  });

  group('V2-12: "Tap to reveal" keeps a readable size', () {
    for (final locale in TaroLocalizations.supportedLocales) {
      testWidgets('${locale.languageCode}: three cards', (tester) async {
        await pumpTaro(
          tester,
          _reveal('three_ppf', cards: 3),
          fakes: aiReadyFakes(),
          locale: locale,
          size: const Size(360, 780),
        );
        await tester.pumpAndSettle();
        final l10n = await TaroLocalizations.delegate.load(locale);
        final hint = find.text(l10n.drawTapToReveal);
        expect(hint, findsOneWidget);
        final min = tester.element(hint).tokens.typography.caption.fontSize!;
        expect(
          _drawn(tester.renderObject<RenderParagraph>(hint)),
          greaterThanOrEqualTo(min - 0.01),
        );
      });
    }
  });

  group('V2-04: S23 "Withdraw" at 200 % text', () {
    for (final scale in [1.0, 2.0]) {
      testWidgets('${scale}x', (tester) async {
        await pumpTaroWidget(
          tester,
          PrivacyLayout(
            state: const PrivacyState.content(
              PrivacyView(
                aiGranted: true,
                adsPrivacyOptionsRequired: false,
                tracking: null,
                analyticsEnabled: true,
              ),
            ),
            onWithdrawAi: noop,
            onAllowAi: noop,
            onReviewAdChoices: noop,
            onTracking: noop,
            onAnalytics: (_) {},
            onPolicy: noop,
            onBack: noop,
          ),
          textScale: scale,
          size: const Size(411, 2400),
        );
        final l10n = await enL10n();
        final status = tester.getRect(find.text(l10n.settingsAiAllowed));
        final button = tester.getRect(find.text(l10n.privacyAiWithdraw));
        if (scale > kSpreadReflowTextScale) {
          // Under the whole text, which keeps the row's width.
          final subtitle = tester.getRect(
            find.text(l10n.privacyAiAllowedSubtitle),
          );
          expect(button.top, greaterThanOrEqualTo(subtitle.bottom));
          expect(button.left, lessThan(status.right));
        } else {
          expect(button.left, greaterThan(status.right));
        }
      });
    }
  });

  group('V2-05: chip rows at 200 % text show they scroll', () {
    testWidgets('S14 journal filters', (tester) async {
      await pumpTaroWidget(
        tester,
        JournalListLayout(
          state: const JournalListState.filteredEmpty(
            filters: JournalFilters(type: JournalTypeFilter.favourites),
          ),
          filters: const JournalFilters(type: JournalTypeFilter.favourites),
          now: () => DateTime.utc(2026, 10, 4),
          onType: (_) {},
          onSpread: (_) {},
          onClearCard: noop,
          onSearch: (_) {},
          onClearFilters: noop,
          onOpen: (_) {},
          onFinish: (_) {},
          onDelete: (_) {},
          onOpenCard: (_) {},
          onRange: (_) {},
          onStartReading: noop,
          onOpenDaily: noop,
          onRetry: noop,
        ),
        textScale: 2,
      );
      await tester.pump();
      final l10n = await enL10n();
      final row = find.ancestor(
        of: find.text(l10n.journalFilterFavourites),
        matching: find.byType(TaroScrollRow),
      );
      expect(row, findsOneWidget);
      final fade = find.descendant(
        of: row,
        matching: find.byType(TaroEdgeFade),
      );
      expect(tester.widget<TaroEdgeFade>(fade).end, isTrue);
    });
  });

  group('V2-05: S16 section chips at 200 % text', () {
    testWidgets('the anchors fade at the edge', (tester) async {
      final deck = aDeck().build();
      await pumpTaroWidget(
        tester,
        DeckBrowserLayout(
          state: DeckBrowserState.content(
            sections: [
              for (final (kind, id) in [
                (DeckSectionKind.majorArcana, 'major_00'),
                (DeckSectionKind.cups, 'cups_03'),
                (DeckSectionKind.wands, 'wands_03'),
                (DeckSectionKind.swords, 'swords_03'),
                (DeckSectionKind.pentacles, 'pentacles_03'),
              ])
                DeckSection(
                  kind: kind,
                  tiles: [DeckTile(card: deck.card(CardId(id))!, name: id)],
                ),
            ],
          ),
          onSearch: (_) {},
          onCard: (_) {},
          onSpreads: noop,
          onAbout: noop,
          onRetry: noop,
        ),
        textScale: 2,
      );
      await tester.pump();
      final row = find.ancestor(
        of: find.byKey(const ValueKey('anchor-cups')),
        matching: find.byType(TaroScrollRow),
      );
      expect(row, findsOneWidget);
      final fade = find.descendant(
        of: row,
        matching: find.byType(TaroEdgeFade),
      );
      expect(tester.widget<TaroEdgeFade>(fade).end, isTrue);
    });
  });

  group('V2-06: S26 at 200 % text', () {
    testWidgets('the confirmation scrolls with the lists, not pinned', (
      tester,
    ) async {
      final l10n = await enL10n();
      for (final scale in [1.0, 2.0]) {
        await pumpTaroWidget(
          tester,
          DeleteDataLayout(
            state: const DeleteDataState.confirm1(
              DeleteDataSummary(
                journalEntries: 4,
                readingsKept: 3,
                removeAdsKept: true,
              ),
            ),
            onTyped: (_) {},
            onDelete: noop,
            onRetry: noop,
            onExport: noop,
            onDone: noop,
            onBack: noop,
          ),
          textScale: scale,
        );
        final pinned =
            tester.widget<TaroScaffold>(find.byType(TaroScaffold)).bottom !=
            null;
        if (scale > kSpreadReflowTextScale) {
          // The field scrolls after the lists, right above its buttons.
          await tester.scrollUntilVisible(find.byType(TaroTextField), 200);
          final field = tester.getRect(find.byType(TaroTextField));
          final delete = tester.getRect(find.text(l10n.deleteButton));
          expect(delete.top, greaterThan(field.bottom));
        }
        final scrolls = !pinned;
        expect(scrolls, scale > kSpreadReflowTextScale, reason: '${scale}x');
      }
    });
  });
}
