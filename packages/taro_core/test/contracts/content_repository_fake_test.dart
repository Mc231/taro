import 'package:taro_core/taro_core.dart';
import 'package:test/test.dart';

import '../fakes/fakes.dart';
import 'contracts.dart';

void main() {
  runContentRepositoryContract(FakeContentRepository.new);

  test('locale text wins over English; missing text fails', () async {
    const id = CardId('major_00');
    final uk = aCardText(id, locale: 'uk');
    final content = FakeContentRepository(texts: {(id, 'uk'): uk});
    expect(expectOk(await content.cardText(id, 'uk')), uk);
    expect(
      expectErr(await content.cardText(const CardId('major_01'), 'uk')),
      const Failure.storage(),
    );
  });

  test('failNext fails each method', () async {
    final content = FakeContentRepository();
    for (final m in [
      'deck',
      'spreads',
      'cardText',
      'fallbackCrisisResources',
    ]) {
      content.failNext(const Failure.storage(), on: m);
    }
    expect((await content.deck()).isErr, isTrue);
    expect((await content.spreads()).isErr, isTrue);
    expect(
      (await content.cardText(const CardId('major_00'), 'en')).isErr,
      isTrue,
    );
    expect((await content.fallbackCrisisResources('DE')).isErr, isTrue);
  });
}
