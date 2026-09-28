// Fluent builders (Phase 4.5: `aRemoteConfig().withRewardedEnabled(false)`,
// `aCard('major_00').reversed()`) return `this` and take positional flags.
// ignore_for_file: avoid_returning_this

import 'dart:convert';
import 'dart:typed_data';

import 'package:taro_core/taro_core.dart';

import 'defaults.dart';
import 'reading_builders.dart';

/// `aBackup().withVersion(1).build()`: a valid v1 backup with one reading
/// and one daily card, and a correct checksum.
BackupBuilder aBackup() => BackupBuilder();

/// Builds a [BackupV1], its file JSON or its bytes.
///
/// [withVersion], [withFormat], [withChecksum] and [withExtraKey] only
/// change the JSON and bytes, so invalid files can be built; [build]
/// always returns the typed (v1) backup.
final class BackupBuilder {
  UserSettings _settings = const UserSettings();
  List<Reading> _readings = [aReading().build()];
  List<DailyCard> _dailyCards = [aDailyCard().build()];
  DateTime _exportedAt = kTestNow;
  String _appVersion = '$kTestAppVersion+$kTestBuildNumber';
  int _version = BackupV1.schemaVersion;
  String _format = BackupV1.format;
  String? _checksum;
  final Map<String, Object?> _extraRoot = {};
  final Map<String, Object?> _extraData = {};

  /// `schemaVersion` in the JSON.
  BackupBuilder withVersion(int version) {
    _version = version;
    return this;
  }

  /// `format` in the JSON.
  BackupBuilder withFormat(String format) {
    _format = format;
    return this;
  }

  /// Exported settings.
  BackupBuilder withSettings(UserSettings settings) {
    _settings = settings;
    return this;
  }

  /// Readings (only exportable ones are allowed in a valid file).
  BackupBuilder withReadings(List<Reading> readings) {
    _readings = readings;
    return this;
  }

  /// Daily cards.
  BackupBuilder withDailyCards(List<DailyCard> dailyCards) {
    _dailyCards = dailyCards;
    return this;
  }

  /// No readings and no daily cards.
  BackupBuilder empty() {
    _readings = [];
    _dailyCards = [];
    return this;
  }

  /// Exported at [at].
  BackupBuilder exportedAt(DateTime at) {
    _exportedAt = at;
    return this;
  }

  /// `appVersion`.
  BackupBuilder withAppVersion(String appVersion) {
    _appVersion = appVersion;
    return this;
  }

  /// A fixed `checksum` instead of the computed one.
  BackupBuilder withChecksum(String checksum) {
    _checksum = checksum;
    return this;
  }

  /// An extra member at the root, or inside `data` when [inData] (for
  /// forbidden-key tests such as `credits`).
  BackupBuilder withExtraKey(String key, Object? value, {bool inData = false}) {
    (inData ? _extraData : _extraRoot)[key] = value;
    return this;
  }

  /// The journal content.
  BackupData data() => BackupData(
    settings: _settings,
    readings: _readings,
    dailyCards: _dailyCards,
  );

  /// The typed backup.
  BackupV1 build() {
    final data = this.data();
    return BackupV1(
      exportedAt: _exportedAt,
      appVersion: _appVersion,
      data: data,
      checksum: _checksum ?? BackupChecksum.of(data),
    );
  }

  /// The file JSON.
  Map<String, Object?> buildJson() {
    final json = build().toJson();
    json['format'] = _format;
    json['schemaVersion'] = _version;
    if (_extraData.isNotEmpty) {
      json['data'] = {...json['data']! as Map<String, Object?>, ..._extraData};
    }
    json.addAll(_extraRoot);
    return json;
  }

  /// The file bytes (UTF-8 JSON).
  Uint8List bytes() => Uint8List.fromList(utf8.encode(jsonEncode(buildJson())));
}
