import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:taro/data/db/device/device_database.dart';
import 'package:taro/data/db/journal/journal_database.dart';

/// 2026-09-26T09:00:00.123456Z plus [minutes].
DateTime at(int minutes) => DateTime.utc(
  2026,
  9,
  26,
  9,
  0,
  0,
  123,
  456,
).add(Duration(minutes: minutes));

/// An in-memory journal database (closed after the test by the caller).
JournalDatabase memoryJournal() => JournalDatabase(NativeDatabase.memory());

/// An in-memory device database.
DeviceDatabase memoryDevice() => DeviceDatabase(NativeDatabase.memory());

/// A `readings` row.
ReadingsCompanion readingRow(
  String id, {
  int minute = 0,
  String status = 'complete',
  String spreadId = 'three_ppf',
  String? question,
  String? note,
  bool favourite = false,
}) => ReadingsCompanion.insert(
  id: id,
  spreadId: spreadId,
  spreadVersion: 1,
  localDate: '2026-09-26',
  question: Value(question),
  status: status,
  contentLocale: 'en',
  note: Value(note),
  favourite: Value(favourite),
  drawnAt: at(minute),
  createdAt: at(minute),
  updatedAt: at(minute),
);

/// Cards of a three-card reading [id]: `major_00`, `cups_03` (reversed),
/// `swords_10`.
List<ReadingCardsCompanion> threeCards(
  String id, {
  String first = 'major_00',
}) => [
  ReadingCardsCompanion.insert(
    readingId: id,
    positionId: 'future',
    positionOrder: 2,
    cardId: 'swords_10',
    reversed: false,
  ),
  ReadingCardsCompanion.insert(
    readingId: id,
    positionId: 'past',
    positionOrder: 0,
    cardId: first,
    reversed: false,
  ),
  ReadingCardsCompanion.insert(
    readingId: id,
    positionId: 'present',
    positionOrder: 1,
    cardId: 'cups_03',
    reversed: true,
  ),
];

/// A `daily_cards` row for [localDate].
DailyCardsCompanion dailyCardRow(
  String localDate, {
  String cardId = 'major_17',
  String? note,
  bool favourite = false,
  int minute = 0,
}) => DailyCardsCompanion.insert(
  localDate: localDate,
  cardId: cardId,
  reversed: false,
  drawnAt: at(minute),
  note: Value(note),
  favourite: Value(favourite),
  createdAt: at(minute),
  updatedAt: at(minute),
);
