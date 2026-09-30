import 'package:flutter_test/flutter_test.dart';
import 'package:taro/routing/deep_link_policy.dart';

void main() {
  const policy = DeepLinkPolicy(universalLinkHost: 'taro.vshyrochuk.com');
  String go(String link) => policy.sanitize(Uri.parse(link));

  group('allowlist (01 §9.1, 02 §8.2)', () {
    final cases = {
      'taro://daily': '/daily',
      'taro://daily/': '/daily',
      'taro://store': '/store',
      'taro://reading/new?spread=three_ppf':
          '/reading/question?spread=three_ppf',
      'taro://journal/0f8fad5b-d9cb-469f-a165-70867728950e':
          '/journal/0f8fad5b-d9cb-469f-a165-70867728950e',
      'taro://journal/2026-09-26': '/journal/2026-09-26',
      'taro://learn/card/major_00': '/learn/card/major_00',
      'taro://learn/card/pentacles_14': '/learn/card/pentacles_14',
      'https://taro.vshyrochuk.com/app/daily': '/daily',
      'https://taro.vshyrochuk.com/app/learn/card/cups_01':
          '/learn/card/cups_01',
      'https://taro.vshyrochuk.com/app/reading/new?spread=single':
          '/reading/question?spread=single',
    };
    for (final MapEntry(key: link, value: location) in cases.entries) {
      test(link, () => expect(go(link), location));
    }
  });

  group('malicious and unknown links → /home', () {
    for (final link in [
      'taro://',
      'taro://unknown',
      'taro://reading/draw',
      'taro://reading/new',
      'taro://reading/new?spread=../../etc',
      'taro://reading/new?spread=SINGLE',
      'taro://journal/not-an-id',
      'taro://journal/1;drop',
      'taro://learn/card/major_22',
      'taro://learn/card/wands_15',
      'taro://settings/delete',
      'https://evil.example.com/app/daily',
      'https://taro.vshyrochuk.com/daily',
      'https://taro.vshyrochuk.com/',
      'http://taro.vshyrochuk.com/app/daily',
    ]) {
      test(link, () => expect(go(link), '/home'));
    }
  });

  test('a store link never carries a product', () {
    expect(go('taro://store?productId=x'), '/store');
    expect(
      go('taro://store?product=com.vshyrochuk.taro.readings_30&buy=1'),
      '/store',
    );
  });

  test('isExternal', () {
    expect(policy.isExternal(Uri.parse('taro://daily')), isTrue);
    expect(
      policy.isExternal(Uri.parse('https://taro.vshyrochuk.com/app/x')),
      isTrue,
    );
    expect(policy.isExternal(Uri.parse('/home')), isFalse);
  });
}
