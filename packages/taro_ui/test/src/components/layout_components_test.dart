import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taro_ui/taro_ui.dart';

import '../../helpers/pump_taro_ui_widget.dart';
import 'guidelines.dart';

Widget _pad(Widget child) => Padding(
  padding: const EdgeInsetsDirectional.all(16),
  child: child,
);

const _tabs = [
  TaroTabItem(icon: Icons.wb_sunny_outlined, label: 'Today'),
  TaroTabItem(
    icon: Icons.article_outlined,
    selectedIcon: Icons.article_rounded,
    label: 'Journal',
  ),
  TaroTabItem(icon: Icons.menu_book_outlined, label: 'Learn'),
  TaroTabItem(icon: Icons.settings_outlined, label: 'Settings'),
];

void main() {
  group('TaroAppBar', () {
    testWidgets('back pops by default; title is a header; live status', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pumpTaroUiWidget(
        tester,
        Builder(
          builder: (context) => TextButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => Scaffold(
                  appBar: TaroAppBar(
                    leadingLabel: 'Back',
                    title: 'The Star',
                    status: '2 of 3 picked',
                    actions: [
                      TaroIconButton(
                        icon: Icons.more_horiz_rounded,
                        semanticsLabel: 'More',
                        onPressed: () {},
                      ),
                    ],
                  ),
                  body: const SizedBox.expand(),
                ),
              ),
            ),
            child: const Text('open'),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.text('The Star'), findsOneWidget);
      await expectMeetsGuidelines(tester);
      expect(
        tester.getSemantics(find.text('The Star')),
        isSemantics(isHeader: true),
      );
      expect(
        tester.getSemantics(find.text('2 of 3 picked')),
        isSemantics(isLiveRegion: true),
      );
      expect(TaroAppBar.height, 64);
      expect(const TaroAppBar(leadingLabel: 'Back').preferredSize.height, 64);
      await tester.tap(find.bySemanticsLabel('Back'));
      await tester.pumpAndSettle();
      expect(find.text('The Star'), findsNothing);
      handle.dispose();
    });

    testWidgets('close calls onLeading; scrolled tints the bar', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      var closed = 0;
      await pumpTaroUiWidget(
        tester,
        TaroAppBar(
          leading: TaroAppBarLeading.close,
          leadingLabel: 'Close',
          onLeading: () => closed++,
          scrolled: true,
        ),
        themeMode: ThemeMode.dark,
      );
      await tester.tap(find.bySemanticsLabel('Close'));
      expect(closed, 1);
      expect(
        tester.widget<Material>(find.byType(Material).at(1)).color,
        TaroColorTokens.dark.bg.surface,
      );
      handle.dispose();
    });

    testWidgets('no leading control on tab roots', (tester) async {
      await pumpTaroUiWidget(
        tester,
        const Column(
          children: [
            TaroAppBar(leading: TaroAppBarLeading.none),
            TaroLargeTitle('Settings'),
          ],
        ),
      );
      expect(find.byType(TaroIconButton), findsNothing);
      final handle = tester.ensureSemantics();
      expect(
        tester.getSemantics(find.text('Settings')),
        isSemantics(isHeader: true),
      );
      handle.dispose();
    });
  });

  group('TaroTabBar', () {
    testWidgets('tabs select with tab semantics and meet the guidelines', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      final taps = <int>[];
      for (final mode in ThemeMode.values.skip(1)) {
        await pumpTaroUiWidget(
          tester,
          Align(
            alignment: AlignmentDirectional.bottomCenter,
            child: TaroTabBar(
              items: _tabs,
              currentIndex: 1,
              onSelected: taps.add,
            ),
          ),
          themeMode: mode,
        );
        await tester.pumpAndSettle();
        await expectMeetsGuidelines(tester);
      }
      await tester.tap(find.text('Settings'));
      expect(taps, [3]);
      final journal = tester.getSemantics(find.text('Journal'));
      expect(journal.getSemanticsData().role, SemanticsRole.tab);
      expect(journal, isSemantics(isSelected: true, hasTapAction: true));
      expect(find.byIcon(Icons.article_rounded), findsOneWidget);
      expect(
        tester.getSemantics(find.text('Today')),
        isSemantics(hasSelectedState: true, isSelected: false),
      );
      handle.dispose();
    });

    testWidgets('mirrors in RTL', (tester) async {
      await pumpTaroUiWidget(
        tester,
        Align(
          alignment: AlignmentDirectional.bottomCenter,
          child: TaroTabBar(items: _tabs, currentIndex: 0, onSelected: (_) {}),
        ),
        locale: const Locale('ar'),
      );
      expect(
        tester.getCenter(find.text('Today')).dx,
        greaterThan(tester.getCenter(find.text('Settings')).dx),
      );
    });
  });

  group('TaroSheet', () {
    testWidgets('shows with title and actions; scrim dismisses', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      Future<String?>? result;
      await pumpTaroUiWidget(
        tester,
        Builder(
          builder: (context) => TextButton(
            onPressed: () => result = TaroSheet.show<String>(
              context,
              builder: (context) => TaroSheet(
                title: 'Out of readings',
                actions: [
                  TaroButton.secondary(
                    label: 'Not now',
                    onPressed: () => Navigator.pop(context, 'no'),
                  ),
                ],
                child: const Text('Your next free reading is at midnight.'),
              ),
            ),
            child: const Text('open'),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.text('Out of readings'), findsOneWidget);
      expect(
        tester.getSemantics(find.text('Out of readings')),
        isSemantics(isHeader: true),
      );
      await expectMeetsGuidelines(tester);
      await tester.tap(find.text('Not now'));
      await tester.pumpAndSettle();
      expect(await result, 'no');
      handle.dispose();
    });

    testWidgets('a non-dismissible sheet ignores the scrim', (tester) async {
      await pumpTaroUiWidget(
        tester,
        Builder(
          builder: (context) => TextButton(
            onPressed: () => TaroSheet.show<void>(
              context,
              dismissible: false,
              builder: (context) => const TaroSheet(child: Text('Body')),
            ),
            child: const Text('open'),
          ),
        ),
        size: const Size(1032, 1376),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();
      expect(find.text('Body'), findsOneWidget);
      // Capped at layout.maxContentWidth on a tablet.
      expect(tester.getSize(find.byType(TaroSheet)).width, 600);
    });
  });

  group('TaroDialog', () {
    testWidgets('confirm dialog: header, actions, pop result', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      Future<bool?>? result;
      await pumpTaroUiWidget(
        tester,
        Builder(
          builder: (context) => TextButton(
            onPressed: () => result = TaroDialog.show<bool>(
              context,
              dismissible: true,
              builder: (context) => TaroDialog(
                title: 'Delete this entry?',
                body: 'This cannot be undone.',
                actions: [
                  TaroButton.destructive(
                    label: 'Delete',
                    onPressed: () => Navigator.pop(context, true),
                  ),
                  TaroButton.secondary(
                    label: 'Cancel',
                    onPressed: () => Navigator.pop(context, false),
                  ),
                ],
              ),
            ),
            child: const Text('open'),
          ),
        ),
        themeMode: ThemeMode.dark,
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(
        tester.getSemantics(find.text('Delete this entry?')),
        isSemantics(isHeader: true),
      );
      await expectMeetsGuidelines(tester);
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();
      expect(await result, isTrue);
      handle.dispose();
    });

    testWidgets('progress dialog: spinner, live text, still arc', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pumpTaroUiWidget(
        tester,
        const TaroDialog.progress(title: 'Adding your reading…'),
      );
      expect(
        tester.getSemantics(find.text('Adding your reading…')),
        isSemantics(isLiveRegion: true),
      );
      expect(
        tester
            .widget<CircularProgressIndicator>(
              find.byType(CircularProgressIndicator),
            )
            .value,
        isNotNull,
      );
      handle.dispose();
    });

    testWidgets('progress spinner animates without reduced motion', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: TaroTheme.light(),
          home: const TaroDialog.progress(
            title: 'Loading ad…',
            body: 'One moment.',
          ),
        ),
      );
      expect(
        tester
            .widget<CircularProgressIndicator>(
              find.byType(CircularProgressIndicator),
            )
            .value,
        isNull,
      );
      expect(find.text('One moment.'), findsOneWidget);
    });
  });

  group('SettingsTile and SettingsSection', () {
    testWidgets('navigation, value, toggle, action, destructive', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      final log = <String>[];
      var haptics = true;
      for (final mode in ThemeMode.values.skip(1)) {
        await pumpTaroUiWidget(
          tester,
          SingleChildScrollView(
            child: _pad(
              StatefulBuilder(
                builder: (context, setState) => Column(
                  children: [
                    SettingsSection(
                      title: 'Experience',
                      footer: 'Changes apply right away.',
                      children: [
                        SettingsTile(
                          title: 'Language',
                          value: 'English',
                          onTap: () => log.add('language'),
                        ),
                        SettingsTile.toggle(
                          title: 'Haptics',
                          subtitle: 'Gentle taps while drawing',
                          switchValue: haptics,
                          onChanged: (v) => setState(() => haptics = v),
                        ),
                        SettingsTile(
                          title: 'Copy ID',
                          showChevron: false,
                          onTap: () => log.add('copy'),
                        ),
                        SettingsTile(
                          title: 'Delete all data',
                          destructive: true,
                          leading: const Icon(Icons.delete_outline_rounded),
                          onTap: () => log.add('delete'),
                        ),
                        const SettingsTile(title: 'Unavailable', onTap: null),
                        const SettingsTile.toggle(
                          title: 'Locked',
                          switchValue: false,
                          onChanged: null,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          themeMode: mode,
        );
        await tester.pumpAndSettle();
        await expectMeetsGuidelines(tester);
      }
      await tester.tap(find.text('Language'));
      await tester.tap(find.text('Copy ID'));
      await tester.tap(find.text('Delete all data'));
      await tester.tap(find.text('Haptics'));
      await tester.pump();
      expect(log, ['language', 'copy', 'delete']);
      expect(haptics, isFalse);
      expect(find.byType(Divider), findsNWidgets(5));
      expect(
        tester.getSemantics(find.text('Experience')),
        isSemantics(isHeader: true),
      );
      expect(
        tester.getSemantics(find.text('Haptics')),
        isSemantics(
          label: 'Haptics\nGentle taps while drawing',
          hasToggledState: true,
          isToggled: false,
          hasTapAction: true,
        ),
      );
      expect(
        tester.getSemantics(find.text('Language')),
        isSemantics(label: 'Language\nEnglish', isButton: true),
      );
      expect(
        tester.getSemantics(find.text('Unavailable')),
        isSemantics(hasEnabledState: true, isEnabled: false),
      );
      expect(
        tester.widget<Text>(find.text('Delete all data')).style!.color,
        TaroColorTokens.dark.status.error,
      );
      expect(find.byIcon(Icons.chevron_right_rounded), findsOneWidget);
      handle.dispose();
    });
  });

  group('SegmentedChoice', () {
    const segments = [
      TaroSegment(value: ThemeMode.system, label: 'System'),
      TaroSegment(value: ThemeMode.light, label: 'Light'),
      TaroSegment(value: ThemeMode.dark, label: 'Dark'),
    ];

    testWidgets('selects a segment with group semantics', (tester) async {
      final handle = tester.ensureSemantics();
      var mode = ThemeMode.system;
      for (final theme in ThemeMode.values.skip(1)) {
        await pumpTaroUiWidget(
          tester,
          _pad(
            StatefulBuilder(
              builder: (context, setState) => SegmentedChoice<ThemeMode>(
                segments: segments,
                selected: mode,
                onChanged: (v) => setState(() => mode = v),
              ),
            ),
          ),
          themeMode: theme,
        );
        await tester.pumpAndSettle();
        await expectMeetsGuidelines(tester);
      }
      await tester.tap(find.text('Dark'));
      await tester.pump();
      expect(mode, ThemeMode.dark);
      expect(
        tester.getSemantics(find.text('Dark')),
        isSemantics(
          isButton: true,
          isSelected: true,
          isInMutuallyExclusiveGroup: true,
        ),
      );
      handle.dispose();
    });

    testWidgets('large text falls back to filter chips', (tester) async {
      var mode = ThemeMode.system;
      await pumpTaroUiWidget(
        tester,
        _pad(
          StatefulBuilder(
            builder: (context, setState) => SegmentedChoice<ThemeMode>(
              segments: segments,
              selected: mode,
              onChanged: (v) => setState(() => mode = v),
            ),
          ),
        ),
        textScale: 2,
      );
      expect(find.byType(TaroChip), findsNWidgets(3));
      await tester.tap(find.text('Light'));
      await tester.pump();
      expect(mode, ThemeMode.light);
    });

    testWidgets('disabled is dimmed', (tester) async {
      await pumpTaroUiWidget(
        tester,
        const SegmentedChoice<ThemeMode>(
          segments: segments,
          selected: ThemeMode.light,
          onChanged: null,
        ),
      );
      expect(find.byType(Opacity), findsOneWidget);
      await pumpTaroUiWidget(
        tester,
        const SegmentedChoice<ThemeMode>(
          segments: segments,
          selected: ThemeMode.light,
          onChanged: null,
        ),
        textScale: 2,
      );
      expect(find.byType(Opacity), findsNWidgets(3));
    });
  });

  group('TaroBadge', () {
    testWidgets('every variant renders its text with enough contrast', (
      tester,
    ) async {
      for (final mode in ThemeMode.values.skip(1)) {
        await pumpTaroUiWidget(
          tester,
          _pad(
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final v in TaroBadgeVariant.values)
                  TaroBadge(label: v.name, variant: v),
              ],
            ),
          ),
          themeMode: mode,
        );
        await tester.pumpAndSettle();
        await expectLater(tester, meetsGuideline(textContrastGuideline));
      }
      for (final v in TaroBadgeVariant.values) {
        expect(find.text(v.name), findsOneWidget);
      }
      expect(const TaroBadge(label: 'x').variant, TaroBadgeVariant.status);
    });
  });

  testWidgets('large text moves a settings value under the title', (
    tester,
  ) async {
    await pumpTaroUiWidget(
      tester,
      SettingsSection(
        children: [
          SettingsTile(title: 'Language', value: 'English', onTap: () {}),
        ],
      ),
      textScale: 2,
    );
    expect(
      tester.getTopLeft(find.text('English')).dy,
      greaterThan(tester.getBottomLeft(find.text('Language')).dy),
    );
  });

  testWidgets('a settings value and chevron sit at the row end', (
    tester,
  ) async {
    for (final direction in TextDirection.values) {
      await pumpTaroUiWidget(
        tester,
        SettingsSection(
          children: [
            SettingsTile(title: 'Language', value: 'English', onTap: () {}),
          ],
        ),
        locale: direction == TextDirection.rtl
            ? const Locale('ar')
            : const Locale('en'),
      );
      final row = tester.getRect(find.byType(SettingsTile));
      final value = tester.getRect(find.text('English'));
      final chevron = tester.getRect(find.byIcon(Icons.chevron_right_rounded));
      final tokens = TaroTokens.light();
      // The value ends right before the chevron (space.s3), whatever its
      // length, and the chevron sits against the row padding.
      if (direction == TextDirection.ltr) {
        expect(chevron.left - value.right, closeTo(tokens.space.s3, 0.5));
        expect(row.right - chevron.right, closeTo(tokens.space.s5, 0.5));
      } else {
        expect(value.left - chevron.right, closeTo(tokens.space.s3, 0.5));
        expect(chevron.left - row.left, closeTo(tokens.space.s5, 0.5));
      }
    }
  });
}
