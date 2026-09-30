import 'package:flutter_test/flutter_test.dart';
import 'package:taro/features/legal/controller/legal_controller.dart';

import '../../helpers/pump_app.dart';

void main() {
  test('documents, URLs from config, the offline variant and tabs', () async {
    final fakes = TaroFakes();
    final container = fakes.container();
    final provider = legalControllerProvider(LegalDoc.disclaimer);
    container.listen(provider, (_, _) {});
    expect(
      container.read(provider),
      const LegalState.content(doc: LegalDoc.disclaimer),
    );
    final controller = container.read(provider.notifier)
      ..select(LegalDoc.terms);
    expect(
      container.read(provider),
      const LegalState.content(
        doc: LegalDoc.terms,
        url: 'https://taro.vshyrochuk.com/terms',
      ),
    );
    await pumpEventQueue();
    fakes.connectivity.setOnline(online: false);
    await pumpEventQueue();
    controller.select(LegalDoc.privacy);
    expect(
      container.read(provider),
      const LegalState.offline(
        doc: LegalDoc.privacy,
        url: 'https://taro.vshyrochuk.com/privacy',
      ),
    );
    controller.select(LegalDoc.licenses);
    expect(
      container.read(provider),
      const LegalState.content(doc: LegalDoc.licenses),
    );
    fakes.config.current = fakes.config.current.copyWith(
      legalTermsUrl: 'https://example.com/terms',
    );
    await pumpEventQueue();
    controller.select(LegalDoc.terms);
    expect(
      container.read(provider),
      const LegalState.offline(
        doc: LegalDoc.terms,
        url: 'https://example.com/terms',
      ),
    );
  });

  test('route segments', () {
    expect(LegalDoc.fromSegment('terms'), LegalDoc.terms);
    expect(LegalDoc.fromSegment('nope'), isNull);
  });
}
