import 'dart:typed_data';

import 'package:taro_core/taro_core.dart';
import 'package:test/test.dart';

import '../fakes/builders/builders.dart';
import 'contract_support.dart';

/// What the `ReminderScheduler` contract needs besides the port.
abstract interface class ReminderSchedulerHarness {
  /// The scheduler under test (nothing scheduled).
  ReminderScheduler get subject;

  /// Daily reminders currently scheduled with the OS.
  int get scheduledReminders;
}

/// The `ReminderScheduler` contract (01 §7.7): at most one daily reminder.
void runReminderSchedulerContract(
  ReminderSchedulerHarness Function() create,
) {
  group('ReminderScheduler contract', () {
    late ReminderSchedulerHarness harness;
    late ReminderScheduler reminders;
    const on = ReminderSettings(enabled: true, time: '08:30');

    setUp(() {
      harness = create();
      reminders = harness.subject;
    });

    test('schedules one reminder, even when rescheduled', () async {
      await reminders.schedule(on, 'en');
      await reminders.schedule(on.copyWith(time: '21:00'), 'uk');
      expect(harness.scheduledReminders, 1);
    });

    test('disabled settings cancel the reminder', () async {
      await reminders.schedule(on, 'en');
      await reminders.schedule(const ReminderSettings(), 'en');
      expect(harness.scheduledReminders, 0);
    });

    test('cancelAll removes it', () async {
      await reminders.schedule(on, 'en');
      await reminders.cancelAll();
      expect(harness.scheduledReminders, 0);
    });

    test('requestPermission answers', () async {
      expect(await reminders.requestPermission(), isA<bool>());
    });
  });
}

/// The `AttestationService` contract (02 §6.4, 03 §3.3, §3.4). [create]
/// returns a service on a supported or unsupported device.
void runAttestationServiceContract(AttestationService Function() create) {
  group('AttestationService contract', () {
    late AttestationService attestation;

    setUp(() => attestation = create());

    const installId = '3f1c2b1e-0000-4000-8000-000000000001';

    test('attest answers the challenge with a matching kind', () async {
      final signal = await attestation.deviceSignal();
      final blob = expectOk(
        await attestation.attest(
          challenge: 'chal-1',
          installId: installId,
          signal: signal,
        ),
      );
      expect(blob.challenge, 'chal-1');
      if (attestation.isSupported) {
        expect(blob.type, isNot(AttestationType.none));
        expect(blob.payload, isNotEmpty);
      } else {
        expect(blob.type, AttestationType.none);
      }
      // An App Attest registration names the key later assertions use.
      if (blob.type == AttestationType.appAttest) {
        expect(blob.keyId, isNotEmpty);
      }
    });

    test('assertion headers use the 03 §3.4 form', () async {
      final signal = await attestation.deviceSignal();
      final attested = expectOk(
        await attestation.attest(
          challenge: 'chal-2',
          installId: installId,
          signal: signal,
        ),
      );
      final blob = expectOk(
        await attestation.assert_(
          clientDataHash: List<int>.filled(32, 7),
          keyId: attested.keyId,
        ),
      );
      expect(blob.header, matches(RegExp(r'^(aa1\..+|pi1\..+|none)$')));
      expect(blob.header == 'none', !attestation.isSupported);
    });

    test('deviceSignal completes', () async {
      await attestation.deviceSignal();
    });
  });
}

/// What the `FileTransfer` contract needs besides the port.
abstract interface class FileTransferHarness {
  /// The transfer under test.
  FileTransfer get subject;

  /// The user picks a file with [bytes] in the next picker (`null` =
  /// cancels).
  void userPicks(Uint8List? bytes);

  /// Names of the files handed to the share sheet.
  List<String> get sharedFileNames;
}

/// The `FileTransfer` contract (02 §12).
void runFileTransferContract(FileTransferHarness Function() create) {
  group('FileTransfer contract', () {
    late FileTransferHarness harness;
    late FileTransfer files;

    setUp(() {
      harness = create();
      files = harness.subject;
    });

    test('shares the file under its name', () async {
      expectOk(
        await files.share(
          Uint8List.fromList([123, 125]),
          'taro-backup-2026-09-26.json',
          'application/json',
        ),
      );
      expect(harness.sharedFileNames, ['taro-backup-2026-09-26.json']);
    });

    test('returns the picked bytes unchanged', () async {
      final bytes = aBackup().bytes();
      harness.userPicks(bytes);
      expect(expectOk(await files.pickJson()), bytes);
    });

    test('a cancelled picker is Ok(null)', () async {
      harness.userPicks(null);
      expect(expectOk(await files.pickJson()), isNull);
    });
  });
}

/// What the `ConnectivityMonitor` contract needs besides the port.
abstract interface class ConnectivityMonitorHarness {
  /// The monitor under test (online).
  ConnectivityMonitor get subject;

  /// The network goes up or down.
  void setNetwork({required bool online});
}

/// The `ConnectivityMonitor` contract (02 §10).
void runConnectivityMonitorContract(
  ConnectivityMonitorHarness Function() create,
) {
  group('ConnectivityMonitor contract', () {
    late ConnectivityMonitorHarness harness;
    late ConnectivityMonitor monitor;

    setUp(() {
      harness = create();
      monitor = harness.subject;
    });

    test('reports the current hint', () async {
      expect(await monitor.isOnline(), isTrue);
      harness.setNetwork(online: false);
      expect(await monitor.isOnline(), isFalse);
    });

    test('emits each change once', () async {
      final seen = <bool>[];
      final sub = monitor.online.listen(seen.add);
      harness
        ..setNetwork(online: false)
        ..setNetwork(online: false)
        ..setNetwork(online: true);
      await settle();
      await sub.cancel();
      expect(seen, [false, true]);
    });
  });
}

/// The `BackupExclusion` contract (02 §6.1, RC75): [paths] are files the
/// harness created; excluding them, an absent path, or the same path twice
/// succeeds.
void runBackupExclusionContract(
  BackupExclusion Function() create, {
  List<String> Function()? paths,
}) {
  group('BackupExclusion contract', () {
    test('excludes existing files and skips absent ones', () async {
      final exclusion = create();
      final existing = paths?.call() ?? const <String>['/taro/taro_device.db'];
      expectOk(await exclusion.exclude([...existing, '/absent/x.db-wal']));
    });

    test('is idempotent', () async {
      final exclusion = create();
      final existing = paths?.call() ?? const <String>['/taro/taro_device.db'];
      expectOk(await exclusion.exclude(existing));
      expectOk(await exclusion.exclude(existing));
    });

    test('accepts an empty list', () async {
      expectOk(await create().exclude(const []));
    });
  });
}

/// The `AppInfo` contract (02 §5).
void runAppInfoContract(AppInfo Function() create) {
  group('AppInfo contract', () {
    test('reports well-formed, coarse facts', () {
      final info = create();
      expect(info.version, matches(RegExp(r'^\d+\.\d+\.\d+$')));
      expect(info.buildNumber, matches(RegExp(r'^\d+$')));
      expect(AppPlatform.values, contains(info.platform));
      expect(info.osVersion, isNotEmpty);
      expect(info.deviceModelClass, isNotEmpty);
    });
  });
}

/// The `UrlLauncher` contract (02 §5): the allowed schemes open, any other
/// scheme is an `Err`, and nothing throws.
void runUrlLauncherContract(UrlLauncher Function() create) {
  group('UrlLauncher contract', () {
    test('opens tel:, sms:, mailto: and https: links', () async {
      final launcher = create();
      expectOk(await launcher.open(Uri.parse('tel:116123')));
      expectOk(await launcher.open(Uri.parse('sms:85258')));
      expectOk(await launcher.open(Uri.parse('mailto:help@example.com')));
      expectOk(await launcher.open(Uri.parse('https://findahelpline.com')));
    });

    test('opens https: in the in-app browser, nothing else', () async {
      final launcher = create();
      expectOk(await launcher.openInApp(Uri.parse('https://example.com/t')));
      expect(
        (await launcher.openInApp(Uri.parse('tel:116123'))).isErr,
        isTrue,
      );
    });

    test('opens the app settings', () async {
      expectOk(await create().openAppSettings());
    });

    test('rejects other schemes without throwing', () async {
      final launcher = create();
      expect(
        (await launcher.open(Uri.parse('javascript:alert(1)'))).isErr,
        isTrue,
      );
      expect(
        (await launcher.open(Uri.parse('http://example.com'))).isErr,
        isTrue,
      );
    });
  });
}
