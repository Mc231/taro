import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taro_ui/taro_ui.dart';

import '../../helpers/pump_taro_ui_widget.dart';
import 'guidelines.dart';

Widget _pad(Widget child) => SingleChildScrollView(
  padding: const EdgeInsetsDirectional.all(16),
  child: child,
);

void main() {
  group('TaroSurfaceCard', () {
    testWidgets('static, tappable, raised and highlighted', (tester) async {
      final handle = tester.ensureSemantics();
      var taps = 0;
      for (final mode in ThemeMode.values.skip(1)) {
        await pumpTaroUiWidget(
          tester,
          _pad(
            Column(
              spacing: 12,
              children: [
                const TaroSurfaceCard(child: Text('Static')),
                TaroSurfaceCard(
                  raised: true,
                  onTap: () => taps++,
                  child: const Column(
                    children: [Text('Ask the cards'), Text('Pick a spread')],
                  ),
                ),
                TaroSurfaceCard(
                  highlighted: true,
                  onTap: () => taps++,
                  semanticsLabel: 'Your daily card, not revealed yet',
                  child: const Text('Daily card'),
                ),
              ],
            ),
          ),
          themeMode: mode,
        );
        await tester.pumpAndSettle();
        await expectMeetsGuidelines(tester);
      }
      await tester.tap(find.text('Ask the cards'));
      expect(taps, 1);
      expect(
        tester.getSemantics(find.text('Ask the cards')),
        isSemantics(
          label: 'Ask the cards\nPick a spread',
          isButton: true,
          hasTapAction: true,
        ),
      );
      final daily = find.bySemanticsLabel('Your daily card, not revealed yet');
      expect(daily, findsOneWidget);
      tester.semantics.tap(
        find.semantics.byLabel(
          'Your daily card, not revealed yet',
        ),
      );
      expect(taps, 2);
      handle.dispose();
    });

    testWidgets('raised card has a shadow in light mode', (tester) async {
      await pumpTaroUiWidget(
        tester,
        const TaroSurfaceCard(raised: true, child: Text('x')),
      );
      final boxes = tester.widgetList<DecoratedBox>(
        find.descendant(
          of: find.byType(TaroSurfaceCard),
          matching: find.byType(DecoratedBox),
        ),
      );
      expect(
        boxes.any(
          (b) =>
              (b.decoration as BoxDecoration).boxShadow ==
              TaroElevationTokens.light.e1.shadow,
        ),
        isTrue,
      );
    });
  });

  group('TaroListTile', () {
    testWidgets('selected, disabled with reason, trailing action', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      final log = <String>[];
      for (final mode in ThemeMode.values.skip(1)) {
        await pumpTaroUiWidget(
          tester,
          _pad(
            Column(
              spacing: 12,
              children: [
                TaroListTile(
                  title: 'Three cards',
                  subtitle: 'Past, present, future',
                  leading: const Icon(Icons.view_week_outlined),
                  selected: true,
                  onTap: () => log.add('three'),
                ),
                const TaroListTile(
                  title: 'Watch an ad for 1 reading',
                  subtitle: 'Optional',
                  disabledReason: 'Available again in 4 min',
                ),
                TaroListTile(
                  title: 'Samaritans',
                  subtitle: '116 123 · free, 24/7',
                  trailing: TaroButton.secondary(
                    label: 'Call',
                    expand: false,
                    onPressed: () => log.add('call'),
                  ),
                ),
                TaroListTile(
                  title: 'Spreads guide',
                  showChevron: true,
                  onTap: () => log.add('guide'),
                ),
              ],
            ),
          ),
          themeMode: mode,
        );
        await tester.pumpAndSettle();
        await expectMeetsGuidelines(tester);
      }
      await tester.tap(find.text('Three cards'));
      await tester.tap(find.text('Call'));
      await tester.tap(find.text('Spreads guide'));
      await tester.tap(find.text('Watch an ad for 1 reading'));
      expect(log, ['three', 'call', 'guide']);
      expect(find.text('Optional'), findsNothing);
      expect(find.text('Available again in 4 min'), findsOneWidget);
      expect(
        tester.getSemantics(find.text('Three cards')),
        isSemantics(
          label: 'Three cards\nPast, present, future',
          isButton: true,
          isSelected: true,
        ),
      );
      expect(
        tester.getSemantics(find.text('Watch an ad for 1 reading')),
        isSemantics(
          label: 'Watch an ad for 1 reading\nAvailable again in 4 min',
          isButton: true,
          hasEnabledState: true,
          isEnabled: false,
        ),
      );
      expect(
        tester.getSemantics(find.text('Call')),
        isSemantics(label: 'Call', isButton: true),
      );
      handle.dispose();
    });
  });

  group('JournalEntryTile', () {
    testWidgets('ai with favourite and note; pending with Finish; classic', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      final log = <String>[];
      for (final mode in ThemeMode.values.skip(1)) {
        await pumpTaroUiWidget(
          tester,
          _pad(
            Column(
              spacing: 12,
              children: [
                JournalEntryTile(
                  title: 'A season of rebuilding',
                  meta: 'Past · Present · Future · Sat 26 Sep',
                  status: JournalEntryTileStatus.ai,
                  leading: const SizedBox(width: 40, height: 40),
                  favourite: true,
                  favouriteLabel: 'Favourite',
                  hasNote: true,
                  noteLabel: 'Has a note',
                  onTap: () => log.add('open'),
                ),
                JournalEntryTile(
                  title: 'What am I not seeing?',
                  meta: 'Relationship · Thu 25 Sep',
                  status: JournalEntryTileStatus.pending,
                  statusLabel: 'Pending',
                  finishLabel: 'Finish reading',
                  onFinish: () => log.add('finish'),
                  onTap: () => log.add('pending'),
                ),
                JournalEntryTile(
                  title: 'Should I take the Lisbon job?',
                  meta: 'Two paths · Tue 25 Aug',
                  status: JournalEntryTileStatus.classic,
                  statusLabel: 'Classic',
                  onTap: () {},
                ),
                const JournalEntryTile(
                  title: 'The Tower',
                  meta: 'Mon 24 Aug',
                  status: JournalEntryTileStatus.failed,
                  statusLabel: "Couldn't finish",
                  onTap: null,
                ),
              ],
            ),
          ),
          themeMode: mode,
        );
        await tester.pumpAndSettle();
        await expectMeetsGuidelines(tester);
      }
      await tester.tap(find.text('A season of rebuilding'));
      await tester.tap(find.text('Finish reading'));
      await tester.tap(find.text('What am I not seeing?'));
      expect(log, ['open', 'finish', 'pending']);
      expect(
        tester.getSemantics(find.text('A season of rebuilding')),
        isSemantics(
          label:
              'A season of rebuilding\nPast · Present · Future · Sat 26 Sep'
              '\nHas a note\nFavourite',
          isButton: true,
        ),
      );
      expect(
        find.text('Pending · Relationship · Thu 25 Sep'),
        findsOneWidget,
      );
      expect(find.text("Couldn't finish · Mon 24 Aug"), findsOneWidget);
      expect(find.byType(TaroBadge), findsOneWidget);
      expect(
        tester.getSemantics(find.text('Finish reading')),
        isSemantics(label: 'Finish reading', isButton: true),
      );
      handle.dispose();
    });

    testWidgets('daily card without extras has no indicators', (
      tester,
    ) async {
      await pumpTaroUiWidget(
        tester,
        JournalEntryTile(
          title: 'The Star',
          meta: 'Daily card · Today',
          status: JournalEntryTileStatus.dailyCard,
          onTap: () {},
        ),
      );
      expect(find.byType(Wrap), findsNothing);
      expect(find.text('Daily card · Today'), findsOneWidget);
    });

    testWidgets('meta uses color.text.tertiary; pending uses warning', (
      tester,
    ) async {
      final tokens = TaroTokens.light();
      Color? metaColor(String meta) =>
          tester.widget<Text>(find.text(meta)).style?.color;
      await pumpTaroUiWidget(
        tester,
        Column(
          children: [
            JournalEntryTile(
              title: 'The Star',
              meta: 'Daily card · Today',
              status: JournalEntryTileStatus.dailyCard,
              onTap: () {},
            ),
            JournalEntryTile(
              title: 'What am I not seeing?',
              meta: 'Thu 25 Sep',
              status: JournalEntryTileStatus.pending,
              onTap: () {},
            ),
          ],
        ),
      );
      expect(metaColor('Daily card · Today'), tokens.color.text.tertiary);
      expect(metaColor('Thu 25 Sep'), tokens.color.status.warning);
    });
  });

  group('IconBulletList', () {
    testWidgets('each statement is one node; icons by intent', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      for (final mode in ThemeMode.values.skip(1)) {
        await pumpTaroUiWidget(
          tester,
          _pad(
            const IconBulletList(
              items: [
                IconBulletItem(
                  title: 'A free reading every day',
                  body: 'No account needed.',
                  icon: Icons.auto_awesome_outlined,
                ),
                IconBulletItem(
                  title: 'Private journal',
                  icon: Icons.lock_outline_rounded,
                  intent: IconBulletIntent.accent,
                ),
                IconBulletItem(
                  title: 'Your readings and notes',
                  intent: IconBulletIntent.included,
                ),
                IconBulletItem(
                  title: 'Your balance',
                  intent: IconBulletIntent.excluded,
                ),
                IconBulletItem(title: 'Fallback glyph'),
              ],
            ),
          ),
          themeMode: mode,
        );
        await tester.pumpAndSettle();
        await expectMeetsGuidelines(tester);
      }
      expect(find.byIcon(Icons.check_rounded), findsOneWidget);
      expect(find.byIcon(Icons.remove_rounded), findsOneWidget);
      expect(find.byIcon(Icons.circle_outlined), findsOneWidget);
      expect(
        tester.getSemantics(find.text('A free reading every day')),
        isSemantics(label: 'A free reading every day\nNo account needed.'),
      );
      handle.dispose();
    });
  });

  group('NotificationPreview', () {
    testWidgets('is one node and never shows a card', (tester) async {
      final handle = tester.ensureSemantics();
      for (final mode in ThemeMode.values.skip(1)) {
        await pumpTaroUiWidget(
          tester,
          _pad(
            const NotificationPreview(
              appName: 'Taro',
              time: '8:00 PM',
              title: 'Your daily card is waiting',
              body: 'Take a quiet minute for yourself.',
              semanticsLabel: 'Notification preview',
            ),
          ),
          themeMode: mode,
        );
        await tester.pumpAndSettle();
        await expectMeetsGuidelines(tester);
      }
      expect(
        tester.getSemantics(find.text('Taro')),
        isSemantics(
          label:
              'Notification preview\nTaro\n8:00 PM\nYour daily card is '
              'waiting\nTake a quiet minute for yourself.',
        ),
      );
      expect(find.byType(Image), findsNothing);
      handle.dispose();
    });

    testWidgets('takes a custom icon', (tester) async {
      await pumpTaroUiWidget(
        tester,
        const NotificationPreview(
          appName: 'Taro',
          time: '20:00',
          title: 't',
          body: 'b',
          icon: Icon(Icons.star),
        ),
      );
      expect(find.byIcon(Icons.star), findsOneWidget);
    });
  });

  testWidgets('large text stacks the trailing action and Finish', (
    tester,
  ) async {
    await pumpTaroUiWidget(
      tester,
      _pad(
        Column(
          children: [
            TaroListTile(
              title: 'Samaritans',
              trailing: TaroButton.secondary(
                label: 'Call',
                expand: false,
                onPressed: () {},
              ),
            ),
            JournalEntryTile(
              title: 'What am I not seeing?',
              meta: 'Thu 25 Sep',
              status: JournalEntryTileStatus.pending,
              statusLabel: 'Pending',
              finishLabel: 'Finish reading',
              onFinish: () {},
              onTap: () {},
            ),
          ],
        ),
      ),
      textScale: 2,
    );
    expect(
      tester.getTopLeft(find.text('Call')).dy,
      greaterThan(tester.getBottomLeft(find.text('Samaritans')).dy),
    );
    expect(
      tester.getTopLeft(find.text('Finish reading')).dy,
      greaterThan(tester.getBottomLeft(find.text('Pending · Thu 25 Sep')).dy),
    );
  });
}
