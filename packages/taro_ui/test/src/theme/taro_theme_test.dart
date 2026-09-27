import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taro_ui/taro_ui.dart';

void main() {
  test('light theme is light', () {
    expect(TaroTheme.light().brightness, Brightness.light);
  });

  test('dark theme is dark', () {
    expect(TaroTheme.dark().brightness, Brightness.dark);
  });
}
