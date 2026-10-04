import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taro_ui/taro_ui.dart';

void main() {
  // BUG-11: user text takes the direction of its first strong character.
  test('firstStrongDirection reads the first strong character', () {
    expect(firstStrongDirection('What now?'), TextDirection.ltr);
    expect(firstStrongDirection('  ¿42 qué?'), TextDirection.ltr);
    expect(firstStrongDirection('ماذا الآن؟'), TextDirection.rtl);
    expect(firstStrongDirection('3. מה עכשיו'), TextDirection.rtl);
    expect(firstStrongDirection('«今日は»'), TextDirection.ltr);
    expect(firstStrongDirection('123 ?! 🙂'), isNull);
    expect(firstStrongDirection(''), isNull);
  });

  test('firstStrongIsolate wraps text in U+2068 … U+2069', () {
    expect(firstStrongIsolate('Why?'), '\u2068Why?\u2069');
  });
}
