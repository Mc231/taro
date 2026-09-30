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

const List<ArticleSection> _sections = [
  ArticleSection(
    heading: 'Readings',
    entries: [
      ArticleEntry(title: 'Is it free?', paragraphs: ['One reading a day.']),
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
          onSupportLines: () => calls.add('lines'),
          onBack: () => calls.add('back'),
          onRetry: () => calls.add('retry'),
        ),
        size: const Size(430, 1400),
      );
      await pump(const FaqState.loading());
      expect(find.byType(TaroLoadingView), findsOneWidget);
      await pump(const FaqState.storageError());
      await tapText(tester, l10n.commonRetry);
      await pump(
        const FaqState.content(
          sections: _sections,
          expanded: {'Is it free?'},
          support: _support,
        ),
      );
      expect(find.text('One reading a day.'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'free');
      await tapText(tester, 'Is it free?');
      await tapText(tester, 'support@example.com');
      await tapText(tester, l10n.settingsCopyId);
      await tapText(tester, l10n.settingsSupportLines);
      await tester.tap(find.bySemanticsLabel(l10n.commonBack));
      await pump(const FaqState.searchEmpty(query: 'zzz'));
      expect(find.text(l10n.helpSearchEmpty('zzz')), findsOneWidget);
      expect(find.text(l10n.settingsCopyId), findsNothing);
      expect(calls, [
        'retry',
        'search:free',
        'toggle:Is it free?',
        'copy:support@example.com',
        'copy:abcd1234',
        'lines',
        'back',
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
          onCopyLink: (u) => calls.add('copy:$u'),
          onBack: () => calls.add('back'),
        ),
      );
      await pump(const LegalState.content(doc: LegalDoc.disclaimer));
      expect(find.text(l10n.legalDisclaimerBody), findsOneWidget);
      await tapText(tester, l10n.legalTerms);
      await pump(
        const LegalState.content(doc: LegalDoc.terms, url: 'https://t.example'),
      );
      expect(find.text('https://t.example'), findsOneWidget);
      await tapText(tester, l10n.commonCopy);
      await pump(const LegalState.content(doc: LegalDoc.licenses));
      await tapText(tester, l10n.legalLicences);
      await pump(
        const LegalState.offline(
          doc: LegalDoc.privacy,
          url: 'https://p.example',
        ),
      );
      expect(find.text(l10n.errorNetworkTitle), findsOneWidget);
      await tapText(tester, l10n.commonCopy);
      await tester.tap(find.bySemanticsLabel(l10n.commonBack));
      expect(calls, [
        'select:terms',
        'copy:https://t.example',
        'select:licenses',
        'copy:https://p.example',
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
      await tapText(tester, l10n.settingsSupportLines);
      expectRoute('/help/crisis');
      router.pop();
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel(l10n.commonBack));
      await tester.pumpAndSettle();
      expectRoute('/');
    });

    testWidgets('S29: tabs, copy link, licences, offline, back', (
      tester,
    ) async {
      await pumpRouted(
        tester,
        const LegalScreen(doc: LegalDoc.terms),
        fakes: fakes,
        pushed: true,
      );
      await tapText(tester, l10n.commonCopy);
      expect(find.text(l10n.commonCopied), findsOneWidget);
      await tapText(tester, l10n.legalDisclaimer);
      expect(find.text(l10n.legalDisclaimerBody), findsOneWidget);
      await tapText(tester, l10n.legalLicences);
      await tester.tap(find.text(l10n.legalLicences).last);
      await tester.pumpAndSettle();
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
    });
  });
}
