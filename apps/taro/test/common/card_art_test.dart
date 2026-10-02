import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taro/common/card_art.dart';
import 'package:taro_ui/taro_ui.dart';

import '../helpers/pump_app.dart';

void main() {
  group('CardArt.back', () {
    test('is the card_back asset of the art set', () {
      expect(
        CardArt.back(),
        const AssetImage('assets/deck/art/codex_v1/card_back.webp'),
      );
      expect(
        CardArt.back(artSet: 'placeholder'),
        const AssetImage('assets/deck/art/placeholder/card_back.webp'),
      );
    });
  });

  group('CardBackArtScope', () {
    testWidgets('backs draw the deck art set back at the card width', (
      tester,
    ) async {
      await pumpTaro(
        tester,
        const Center(child: TaroCardBack(semanticsLabel: 'Card back')),
        overrides: [deckArtSetProvider.overrideWith((ref) async => 'codex_v1')],
      );
      await tester.pump();
      final image = tester.widget<Image>(find.byType(Image)).image;
      expect(image, isA<ResizeImage>());
      expect((image as ResizeImage).imageProvider, CardArt.back());
      expect(find.bySemanticsLabel('Card back'), findsOneWidget);
    });

    testWidgets('the default set stands in while the deck loads', (
      tester,
    ) async {
      late ImageProvider? image;
      await pumpTaro(
        tester,
        Builder(
          builder: (context) {
            image = TaroCardBackArt.maybeOf(context);
            return const SizedBox();
          },
        ),
        overrides: [
          deckArtSetProvider.overrideWith(
            (ref) => Future<String>.delayed(const Duration(days: 1)),
          ),
        ],
      );
      expect(image, CardArt.back());
    });

    testWidgets('precaches the back at the TaroCardBack decode width', (
      tester,
    ) async {
      imageCache.clear();
      late BuildContext context;
      await pumpTaro(
        tester,
        Builder(
          builder: (c) {
            context = c;
            return const SizedBox();
          },
        ),
        overrides: [deckArtSetProvider.overrideWith((ref) async => 'codex_v1')],
      );
      final width = CardArt.cacheWidthOf(
        context,
        TaroCardSize.sm.widthIn(context),
      );
      final key = await tester.runAsync(
        () => ResizeImage(CardArt.back(), width: width).obtainKey(
          createLocalImageConfiguration(context),
        ),
      );
      final status = imageCache.statusForKey(key!);
      expect(status.tracked, isTrue);
      final other = await tester.runAsync(
        () => ResizeImage(CardArt.back(), width: width + 1).obtainKey(
          createLocalImageConfiguration(context),
        ),
      );
      expect(imageCache.statusForKey(other!).tracked, isFalse);
    });

    testWidgets('a back that fails to load is tolerated', (tester) async {
      await pumpTaro(
        tester,
        const SizedBox(),
        overrides: [deckArtSetProvider.overrideWith((ref) async => 'missing')],
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  });
}
