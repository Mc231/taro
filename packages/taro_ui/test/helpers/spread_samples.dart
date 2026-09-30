import 'package:taro_ui/taro_ui.dart';

/// The v1 spread layouts (`apps/taro/assets/deck/spreads.json`), for deck
/// tests and goldens.
abstract final class SpreadSamples {
  /// Past · Present · Future.
  static const List<SpreadSlotLayout> threePpf = [
    SpreadSlotLayout(x: 0.123, y: 0.5),
    SpreadSlotLayout(x: 0.5, y: 0.5),
    SpreadSlotLayout(x: 0.877, y: 0.5),
  ];

  /// Single card.
  static const List<SpreadSlotLayout> single = [
    SpreadSlotLayout(x: 0.5, y: 0.5),
  ];

  /// Relationship.
  static const List<SpreadSlotLayout> relationship = [
    SpreadSlotLayout(x: 0.107, y: 0.207),
    SpreadSlotLayout(x: 0.893, y: 0.207),
    SpreadSlotLayout(x: 0.5, y: 0.207),
    SpreadSlotLayout(x: 0.304, y: 0.793),
    SpreadSlotLayout(x: 0.696, y: 0.793),
  ];

  /// Celtic Cross.
  static const List<SpreadSlotLayout> celticCross = [
    SpreadSlotLayout(x: 0.356, y: 0.5),
    SpreadSlotLayout(x: 0.356, y: 0.5, rotationDeg: 90),
    SpreadSlotLayout(x: 0.356, y: 0.743),
    SpreadSlotLayout(x: 0.129, y: 0.5),
    SpreadSlotLayout(x: 0.356, y: 0.257),
    SpreadSlotLayout(x: 0.582, y: 0.5),
    SpreadSlotLayout(x: 0.871, y: 0.864),
    SpreadSlotLayout(x: 0.871, y: 0.621),
    SpreadSlotLayout(x: 0.871, y: 0.379),
    SpreadSlotLayout(x: 0.871, y: 0.136),
  ];

  /// Celtic Cross position names (English).
  static const List<String> celticCrossNames = [
    'Present',
    'Challenge',
    'Foundation',
    'Recent past',
    'Potential',
    'Near future',
    'Self',
    'Environment',
    'Hopes & fears',
    'Outcome',
  ];

  /// Celtic Cross position names (Arabic).
  static const List<String> celticCrossNamesAr = [
    'الحاضر',
    'التحدي',
    'الأساس',
    'الماضي القريب',
    'الإمكان',
    'المستقبل القريب',
    'الذات',
    'المحيط',
    'الآمال والمخاوف',
    'النتيجة',
  ];
}
