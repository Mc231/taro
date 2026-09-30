import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taro_ui/taro_ui.dart';

import '../../helpers/golden/golden_sizes.dart';
import '../../helpers/pump_taro_ui_widget.dart';
import 'guidelines.dart';

void main() {
  group('TaroLoadingView', () {
    for (final layout in TaroLoadingLayout.values) {
      testWidgets('$layout: one labelled live region, no spinner', (
        tester,
      ) async {
        final handle = tester.ensureSemantics();
        await pumpTaroUiWidget(
          tester,
          TaroLoadingView(
            semanticsLabel: 'Loading your journal',
            layout: layout,
          ),
        );
        expect(find.byType(SkeletonBlock), findsWidgets);
        expect(find.byType(CircularProgressIndicator), findsNothing);
        expect(
          tester.getSemantics(find.byType(TaroLoadingView)),
          isSemantics(label: 'Loading your journal', isLiveRegion: true),
        );
        await expectMeetsGuidelines(tester);
        handle.dispose();
      });
    }

    testWidgets('a custom skeleton', (tester) async {
      await pumpTaroUiWidget(
        tester,
        const TaroLoadingView(
          semanticsLabel: 'Loading',
          skeleton: SkeletonBlock(shape: SkeletonShape.rect),
        ),
      );
      expect(find.byType(SkeletonBlock), findsOneWidget);
    });

    testWidgets('the shimmer animates without reduced motion', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: TaroTheme.light(),
          home: const Scaffold(
            body: TaroLoadingView(semanticsLabel: 'Loading'),
          ),
        ),
      );
      Color colour() =>
          ((tester
                      .widget<DecoratedBox>(
                        find
                            .descendant(
                              of: find.byType(SkeletonBlock),
                              matching: find.byType(DecoratedBox),
                            )
                            .first,
                      )
                      .decoration)
                  as BoxDecoration)
              .color!;
      final start = colour();
      expect(start, TaroColorTokens.light.skeleton.base);
      await tester.pump(TaroMotionTokens.light.duration.slow);
      expect(colour(), isNot(start));
      // Switching reduced motion on stops it at the base colour.
      await tester.pumpWidget(
        MaterialApp(
          theme: TaroTheme.light(),
          home: const Scaffold(
            body: TaroA11yScope(
              reduceMotion: true,
              child: TaroLoadingView(semanticsLabel: 'Loading'),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(colour(), TaroColorTokens.light.skeleton.base);
    });
  });

  testWidgets('SkeletonBlock shapes use the token sizes', (tester) async {
    await pumpTaroUiWidget(
      tester,
      const Column(
        children: [
          SkeletonBlock(),
          SkeletonBlock(shape: SkeletonShape.rect, width: 100),
          SkeletonBlock(shape: SkeletonShape.card),
          SkeletonBlock(shape: SkeletonShape.card, width: 40),
          SkeletonBlock(shape: SkeletonShape.circle),
        ],
      ),
    );
    final sizes = [
      for (final e in find.byType(SkeletonBlock).evaluate())
        tester.getSize(find.byWidget(e.widget)),
    ];
    const t = TaroSizeTokens.light;
    expect(sizes[0].height, TaroSpaceTokens.light.s5);
    expect(sizes[1], Size(100, t.touchTarget.min));
    expect(sizes[2].width, t.card.md);
    expect(sizes[2].height, closeTo(t.card.md / t.card.aspectRatio, 0.01));
    expect(sizes[3].width, 40);
    expect(sizes[4], Size.square(t.card.thumb));
  });

  group('TaroEmptyView', () {
    testWidgets('title is a header; body, actions and illustration show', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      var started = 0;
      await pumpTaroUiWidget(
        tester,
        TaroEmptyView(
          illustration: const Icon(Icons.auto_stories_outlined, size: 48),
          title: 'Your readings will live here',
          body: 'Start a reading and it appears in your journal.',
          action: TaroButton.primary(
            label: 'Start a reading',
            onPressed: () => started++,
          ),
          secondaryAction: TaroButton.tertiary(
            label: 'Learn the cards',
            onPressed: () {},
          ),
        ),
      );
      expect(
        tester.getSemantics(find.text('Your readings will live here')),
        isSemantics(label: 'Your readings will live here', isHeader: true),
      );
      await tester.tap(find.text('Start a reading'));
      expect(started, 1);
      await expectMeetsGuidelines(tester);
      final style = tester
          .widget<Text>(find.text('Your readings will live here'))
          .style!;
      expect(style.fontSize, TaroTypeTokens.light.headline.fontSize);
      handle.dispose();
    });

    testWidgets('small title variant, no optional parts, 200 % text scrolls', (
      tester,
    ) async {
      await pumpTaroUiWidget(
        tester,
        const TaroEmptyView(title: 'No results', largeTitle: false),
        textScale: 2,
      );
      final style = tester.widget<Text>(find.text('No results')).style!;
      expect(style.fontSize, TaroTypeTokens.light.title.fontSize);
      expect(tester.takeException(), isNull);
    });

    testWidgets('works without bounded height', (tester) async {
      await pumpTaroUiWidget(
        tester,
        const SingleChildScrollView(child: TaroEmptyView(title: 'Empty')),
      );
      expect(find.text('Empty'), findsOneWidget);
    });
  });

  group('TaroErrorView', () {
    testWidgets('icon per kind, live region, retry', (tester) async {
      final handle = tester.ensureSemantics();
      for (final kind in TaroErrorKind.values) {
        var retries = 0;
        await pumpTaroUiWidget(
          tester,
          TaroErrorView(
            kind: kind,
            title: 'No connection',
            body: 'Check your connection and try again.',
            retryLabel: 'Try again',
            onRetry: () => retries++,
            secondaryAction: TaroButton.tertiary(
              label: 'Back to Today',
              onPressed: () {},
            ),
          ),
          themeMode: ThemeMode.dark,
        );
        expect(find.byIcon(kind.icon), findsOneWidget);
        await tester.tap(find.text('Try again'));
        expect(retries, 1);
        expect(
          tester.getSemantics(find.text('No connection')),
          isSemantics(isHeader: true, label: 'No connection'),
        );
        await expectMeetsGuidelines(tester);
      }
      expect(
        TaroErrorKind.values.map((k) => k.icon).toSet(),
        hasLength(TaroErrorKind.values.length),
      );
      handle.dispose();
    });

    testWidgets('no retry button without a label or callback', (
      tester,
    ) async {
      await pumpTaroUiWidget(
        tester,
        TaroErrorView(
          kind: TaroErrorKind.invalidFile,
          title: "This file isn't a Taro backup",
          body: 'Choose another file.',
          onRetry: () {},
        ),
      );
      expect(find.byType(TaroButton), findsNothing);
    });
  });

  group('TaroOfflineBanner', () {
    testWidgets('message and optional action', (tester) async {
      final handle = tester.ensureSemantics();
      var retried = 0;
      await pumpTaroUiWidget(
        tester,
        Column(
          children: [
            const TaroOfflineBanner(message: "You're offline."),
            TaroOfflineBanner(
              message: "You're offline. Your journal still works.",
              actionLabel: 'Retry',
              onAction: () => retried++,
            ),
          ],
        ),
        locale: const Locale('ar'),
      );
      await tester.tap(find.text('Retry'));
      expect(retried, 1);
      expect(find.byType(TaroButton), findsOneWidget);
      expect(
        tester.getSemantics(find.byType(TaroOfflineBanner).first),
        isSemantics(isLiveRegion: true),
      );
      await expectMeetsGuidelines(tester);
      handle.dispose();
    });
  });

  group('TaroInlineNotice', () {
    testWidgets('every kind, body, actions, dismiss', (tester) async {
      final handle = tester.ensureSemantics();
      var dismissed = 0;
      await pumpTaroUiWidget(
        tester,
        SingleChildScrollView(
          child: Column(
            children: [
              for (final kind in TaroNoticeKind.values)
                TaroInlineNotice(
                  kind: kind,
                  title: 'Notice ${kind.name}',
                  body: 'Body',
                  actions: [
                    TaroButton.tertiary(label: 'Act', onPressed: () {}),
                  ],
                  onDismiss: () => dismissed++,
                  dismissLabel: 'Dismiss',
                  liveRegion: kind == TaroNoticeKind.error,
                ),
            ],
          ),
        ),
      );
      for (final kind in TaroNoticeKind.values) {
        expect(find.byIcon(kind.icon), findsOneWidget);
      }
      await tester.tap(find.byTooltip('Dismiss').first);
      expect(dismissed, 1);
      await expectMeetsGuidelines(tester);
      handle.dispose();
    });

    testWidgets('prominent layout centres and stacks actions', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpTaroUiWidget(
        tester,
        TaroInlineNotice(
          kind: TaroNoticeKind.info,
          prominent: true,
          title: 'AI readings are paused for now',
          body: 'Your journal, daily card and Learn still work.',
          actions: [
            TaroButton.primary(
              label: 'Try a classic reading',
              onPressed: () {},
            ),
            TaroButton.secondary(label: 'Back to Today', onPressed: () {}),
          ],
        ),
        themeMode: ThemeMode.dark,
      );
      final title = tester.widget<Text>(
        find.text('AI readings are paused for now'),
      );
      expect(title.textAlign, TextAlign.center);
      expect(title.style!.fontSize, TaroTypeTokens.light.title.fontSize);
      final primary = tester.getRect(find.text('Try a classic reading'));
      final secondary = tester.getRect(find.text('Back to Today'));
      expect(secondary.top, greaterThan(primary.bottom));
      await expectMeetsGuidelines(tester);
      handle.dispose();
    });

    testWidgets('title only', (tester) async {
      await pumpTaroUiWidget(
        tester,
        const TaroInlineNotice(
          kind: TaroNoticeKind.success,
          title: 'Nothing was changed in your journal.',
        ),
      );
      expect(find.byType(IconButton), findsNothing);
    });
  });

  group('TaroScaffold', () {
    testWidgets('slots, gutter and adGap', (tester) async {
      applyTestViewSize(tester, kPhoneSmall);
      await tester.pumpWidget(
        MaterialApp(
          theme: TaroTheme.light(),
          home: TaroScaffold(
            appBar: AppBar(title: const Text('Journal')),
            topBanner: const TaroOfflineBanner(message: 'Offline'),
            body: const Text('Body'),
            bottom: TaroButton.primary(label: 'Begin', onPressed: () {}),
            banner: const SizedBox(key: Key('banner'), height: 50),
            bottomNavigationBar: const SizedBox(
              height: 56,
              child: Text('Tabs'),
            ),
          ),
        ),
      );
      const tokens = TaroLayoutTokens.light;
      expect(tester.getTopLeft(find.text('Body')).dx, tokens.gutter);
      final button = tester.getRect(find.byType(TaroButton));
      final banner = tester.getRect(find.byKey(const Key('banner')));
      expect(
        banner.top - button.bottom,
        greaterThanOrEqualTo(TaroSpaceTokens.light.adGap),
      );
      expect(
        banner.width,
        tester.view.physicalSize.width / tester.view.devicePixelRatio,
      );
      expect(find.text('Offline'), findsOneWidget);
      expect(find.text('Tabs'), findsOneWidget);
    });

    testWidgets('caps content at layout.maxContentWidth on a tablet', (
      tester,
    ) async {
      applyTestViewSize(tester, kTabletIpad13);
      await tester.pumpWidget(
        MaterialApp(
          theme: TaroTheme.dark(),
          home: const TaroScaffold(
            padded: false,
            body: SizedBox.expand(key: Key('content')),
          ),
        ),
      );
      final content = tester.getRect(find.byKey(const Key('content')));
      expect(content.width, TaroLayoutTokens.light.maxContentWidth);
      expect(content.center.dx, kTabletIpad13.width / 2);
      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, TaroColorTokens.dark.bg.canvas);
    });

    testWidgets('background override', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: TaroTheme.light(),
          home: TaroScaffold(
            backgroundColor: TaroColorTokens.light.bg.surface,
            body: const SizedBox(),
          ),
        ),
      );
      expect(
        tester.widget<Scaffold>(find.byType(Scaffold)).backgroundColor,
        TaroColorTokens.light.bg.surface,
      );
    });
  });
}
