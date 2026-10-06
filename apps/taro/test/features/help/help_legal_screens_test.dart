import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taro/di/providers.dart'
    show Article, ArticleEntry, ArticleSection, SupportInfo;
import 'package:taro/features/help/controller/faq_controller.dart';
import 'package:taro/features/help/view/faq_screen.dart';
import 'package:taro/features/legal/controller/legal_controller.dart';
import 'package:taro/features/legal/view/legal_screen.dart';
import 'package:taro/l10n/generated/taro_localizations.dart';
import 'package:taro_core/taro_core.dart';
import 'package:taro_ui/taro_ui.dart';

import '../skeleton_support.dart';

const SupportInfo _support = SupportInfo(
  email: 'support@example.com',
  supportId: 'abcd1234',
  appVersion: '1.0.0',
  buildNumber: '7',
  platform: AppPlatform.ios,
  osVersion: '18.0',
  locale: 'en',
);

const String _transferAnswer =
    'Open **Settings → Move readings from another device**, see '
    '[support](https://example.com).';

const List<ArticleSection> _sections = [
  ArticleSection(
    heading: 'Readings',
    entries: [
      ArticleEntry(title: 'Is it free?', paragraphs: ['One reading a day.']),
      ArticleEntry(
        title: 'New phone?',
        paragraphs: [_transferAnswer],
      ),
    ],
  ),
];

void main() {
  late TaroLocalizations l10n;

  setUpAll(() async => l10n = await enL10n());

  group('S28 FAQ view', () {
    testWidgets('every state', (tester) async {
      final calls = <String>[];
      Future<void> pump(FaqState state) => pumpTaroWidget(
        tester,
        FaqLayout(
          state: state,
          onSearch: (q) => calls.add('search:$q'),
          onToggle: (t) => calls.add('toggle:$t'),
          onCopy: (v) => calls.add('copy:$v'),
          onEmail: (s) => calls.add('email:${s.supportId}'),
          onMoveReadings: () => calls.add('move'),
          onSupportLines: () => calls.add('lines'),
          onBack: () => calls.add('back'),
          onRetry: () => calls.add('retry'),
        ),
        size: const Size(430, 1800),
      );
      await pump(const FaqState.loading());
      expect(find.byType(TaroLoadingView), findsOneWidget);
      await pump(const FaqState.storageError());
      await tapText(tester, l10n.commonRetry);
      await pump(
        const FaqState.content(
          sections: _sections,
          expanded: {'Is it free?', 'New phone?'},
          support: _support,
        ),
      );
      expect(find.text('One reading a day.'), findsOneWidget);
      // Inline Markdown: bold kept as a span, the link reduced to its label.
      expect(
        find.text(
          'Open Settings → Move readings from another device, see support.',
          findRichText: true,
        ),
        findsOneWidget,
      );
      await tester.enterText(find.byType(TextField), 'free');
      await tapText(tester, 'Is it free?');
      await tester.tap(
        find.widgetWithText(TaroButton, l10n.settingsMoveReadings),
      );
      await tapText(tester, l10n.settingsCopyId);
      await tapText(tester, l10n.helpEmailSupport);
      await tapText(tester, l10n.settingsSupportLines);
      await tester.tap(find.bySemanticsLabel(l10n.commonBack));
      await pump(const FaqState.searchEmpty(query: 'zzz', support: _support));
      expect(find.text(l10n.helpSearchEmpty('zzz')), findsOneWidget);
      expect(find.text(l10n.settingsCopyId), findsNothing);
      await tapText(tester, l10n.helpEmailSupport);
      await pump(const FaqState.searchEmpty(query: 'zzz'));
      expect(find.text(l10n.helpEmailSupport), findsNothing);
      await pump(const FaqState.content(sections: _sections));
      expect(find.text(l10n.helpContactHeading), findsNothing);
      expect(calls, [
        'retry',
        'search:free',
        'toggle:Is it free?',
        'move',
        'copy:abcd1234',
        'email:abcd1234',
        'lines',
        'back',
        'email:abcd1234',
      ]);
    });
  });

  group('S29 legal view', () {
    testWidgets('disclaimer, web docs, licences, offline', (tester) async {
      final calls = <String>[];
      Future<void> pump(LegalState state) => pumpTaroWidget(
        tester,
        LegalLayout(
          state: state,
          onSelect: (d) => calls.add('select:${d.name}'),
          onLicences: () => calls.add('licences'),
          onOpenWeb: (u) => calls.add('web:$u'),
          onOpenBrowser: (u) => calls.add('browser:$u'),
          onSupportLines: () => calls.add('lines'),
          onBack: () => calls.add('back'),
        ),
        size: const Size(430, 1400),
      );
      await pump(const LegalState.content(doc: LegalDoc.disclaimer));
      expect(find.text(l10n.legalDisclaimerBody), findsOneWidget);
      expect(find.text(l10n.disclaimerOnboardingTitle), findsOneWidget);
      await tapText(tester, l10n.legalSupportLine);
      await tapText(tester, l10n.legalTerms);
      await pump(
        const LegalState.content(doc: LegalDoc.terms, url: 'https://t.example'),
      );
      expect(find.textContaining('https://t.example'), findsOneWidget);
      await tapText(tester, l10n.legalReadOnline);
      await pump(const LegalState.content(doc: LegalDoc.terms));
      expect(
        tester
            .widget<TaroButton>(
              find.widgetWithText(TaroButton, l10n.legalReadOnline),
            )
            .onPressed,
        isNull,
      );
      await pump(const LegalState.content(doc: LegalDoc.licenses));
      await tapText(tester, l10n.legalViewLicences);
      await pump(
        const LegalState.offline(
          doc: LegalDoc.privacy,
          url: 'https://p.example',
        ),
      );
      expect(find.text(l10n.errorNetworkTitle), findsOneWidget);
      await tapText(tester, l10n.legalOpenInBrowser);
      await tester.tap(find.bySemanticsLabel(l10n.commonBack));
      expect(calls, [
        'lines',
        'select:terms',
        'web:https://t.example',
        'licences',
        'browser:https://p.example',
        'back',
      ]);
    });
  });

  group('help and legal screens with fakes', () {
    late TaroFakes fakes;

    setUp(() => fakes = TaroFakes());

    testWidgets('S28: search, expand, copy, support lines, retry, back', (
      tester,
    ) async {
      var fail = true;
      fakes.articles = (id, locale) async {
        if (fail) {
          fail = false;
          return const Result.err(Failure.storage());
        }
        return const Result.ok(Article(title: 'FAQ', sections: _sections));
      };
      final router = await pumpRouted(
        tester,
        const FaqScreen(),
        fakes: fakes,
        pushed: true,
        size: const Size(430, 1400),
      );
      await tapText(tester, l10n.commonRetry);
      await tapText(tester, 'Is it free?');
      expect(find.text('One reading a day.'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'zzz');
      await tester.pumpAndSettle();
      expect(find.text(l10n.helpSearchEmpty('zzz')), findsOneWidget);
      await tester.enterText(find.byType(TextField), '');
      await tester.pumpAndSettle();
      await tapText(tester, l10n.settingsCopyId);
      expect(find.text(l10n.commonCopied), findsOneWidget);
      await tapText(tester, l10n.helpEmailSupport);
      final mail = fakes.links.opened.single;
      expect(mail.scheme, 'mailto');
      expect(mail.toString(), contains('Support%20ID'));

      await tapText(tester, l10n.settingsSupportLines);
      expectRoute('/help/crisis');
      router.pop();
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel(l10n.commonBack));
      await tester.pumpAndSettle();
      expectRoute('/');
    });

    testWidgets('S28: the transfer link goes to Settings', (tester) async {
      fakes.articles = (id, locale) async =>
          const Result.ok(Article(title: 'FAQ', sections: _sections));
      await pumpRouted(
        tester,
        const FaqScreen(),
        fakes: fakes,
        size: const Size(430, 1400),
      );
      await tapText(tester, 'New phone?');
      await tester.tap(
        find.widgetWithText(TaroButton, l10n.settingsMoveReadings),
      );
      await tester.pumpAndSettle();
      expectRoute('/settings');
    });

    testWidgets('S29: tabs, in-app browser, licences, offline, back', (
      tester,
    ) async {
      final router = await pumpRouted(
        tester,
        const LegalScreen(doc: LegalDoc.terms),
        fakes: fakes,
        pushed: true,
        size: const Size(430, 1400),
      );
      await tapText(tester, l10n.legalReadOnline);
      // The hosted page in the app language (`?hl=`).
      expect(fakes.links.openedInApp, [
        Uri.parse('https://taro.vshyrochuk.com/terms?hl=en'),
      ]);
      fakes.links.failNext(const Failure.storage(), on: 'openInApp');
      await tapText(tester, l10n.legalReadOnline);
      expect(fakes.links.opened, [
        Uri.parse('https://taro.vshyrochuk.com/terms?hl=en'),
      ]);
      await tapText(tester, l10n.legalDisclaimer);
      expect(find.text(l10n.legalDisclaimerBody), findsOneWidget);
      await tapText(tester, l10n.legalSupportLine);
      expectRoute('/help/crisis');
      router.pop();
      await tester.pumpAndSettle();
      await tapText(tester, l10n.legalLicences);
      await tapText(tester, l10n.legalViewLicences);
      expect(find.byType(LicensePage), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel(l10n.commonBack));
      await tester.pumpAndSettle();
      expectRoute('/');

      fakes.connectivity.setOnline(online: false);
      await pumpRouted(
        tester,
        const LegalScreen(doc: LegalDoc.privacy),
        fakes: fakes,
      );
      expect(find.text(l10n.errorNetworkTitle), findsOneWidget);
      await tapText(tester, l10n.legalOpenInBrowser);
      expect(
        fakes.links.opened.last,
        Uri.parse('https://taro.vshyrochuk.com/privacy?hl=en'),
      );
    });
  });
}
