import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Android backup rules (02 §6.1, RC75): `taro_device.db` and its siblings
/// are excluded from cloud backup, device transfer and legacy Auto Backup;
/// `taro_journal.db` is not.
void main() {
  const res = 'android/app/src/main/res/xml';
  const deviceFiles = [
    'app_flutter/taro_device.db',
    'app_flutter/taro_device.db-wal',
    'app_flutter/taro_device.db-shm',
    'app_flutter/taro_device.db-journal',
  ];

  List<String> excludes(String xml) => [
    for (final m in RegExp(
      '<exclude domain="file" path="([^"]+)" />',
    ).allMatches(xml))
      m[1]!,
  ];

  test('data_extraction_rules.xml excludes taro_device.db twice', () {
    final xml = File('$res/data_extraction_rules.xml').readAsStringSync();
    for (final section in ['cloud-backup', 'device-transfer']) {
      final body = RegExp(
        '<$section>(.*?)</$section>',
        dotAll: true,
      ).firstMatch(xml)![1]!;
      expect(excludes(body), deviceFiles, reason: section);
    }
    expect(excludes(xml), [...deviceFiles, ...deviceFiles]);
  });

  test('full_backup_content.xml excludes taro_device.db', () {
    final xml = File('$res/full_backup_content.xml').readAsStringSync();
    expect(
      excludes(xml),
      deviceFiles,
      reason: 'taro_journal.db stays backed up',
    );
  });
}
