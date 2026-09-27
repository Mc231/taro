import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taro/l10n/generated/taro_localizations.dart';

void main() {
  test('supports the 12 v1 locales', () {
    expect(
      TaroLocalizations.supportedLocales.map((l) => l.languageCode).toSet(),
      {'en', 'ar', 'de', 'es', 'fr', 'it', 'ja', 'ko', 'nl', 'pt', 'tr', 'uk'},
    );
  });

  for (final locale in TaroLocalizations.supportedLocales) {
    test('loads $locale', () async {
      final l10n = await TaroLocalizations.delegate.load(locale);
      expect(l10n.appTitle, isNotEmpty);
    });
  }

  test('delegate rejects unsupported locales', () {
    expect(
      TaroLocalizations.delegate.isSupported(const Locale('xx')),
      isFalse,
    );
    expect(
      TaroLocalizations.delegate.shouldReload(TaroLocalizations.delegate),
      isFalse,
    );
  });

  testWidgets('of(context) resolves inside Localizations', (tester) async {
    late String title;
    await tester.pumpWidget(
      Localizations(
        locale: const Locale('en'),
        delegates: TaroLocalizations.localizationsDelegates,
        child: Builder(
          builder: (context) {
            title = TaroLocalizations.of(context).appTitle;
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    expect(title, 'Taro');
  });
}
