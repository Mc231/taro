import 'package:taro_core/taro_core.dart';
import 'package:test/test.dart';

import 'failure_samples.dart';

void main() {
  group('Failure', () {
    test('samples cover every subtype (27 per 02 §3)', () {
      final types = failureSamples.map((s) => s.failure.runtimeType).toSet();
      expect(types, hasLength(27));
    });

    for (final sample in failureSamples) {
      final failure = sample.failure;
      group('${failure.runtimeType} (${sample.code})', () {
        test('has the stable code', () {
          expect(failure.code, sample.code);
        });

        test('code is UPPER_SNAKE', () {
          expect(failure.code, matches(RegExp(r'^[A-Z][A-Z0-9_]*$')));
        });

        test('messageKey is failure + class name without the suffix', () {
          final name = failure.runtimeType.toString();
          expect(name, endsWith('Failure'));
          final stem = name.substring(0, name.length - 'Failure'.length);
          expect(failure.messageKey, 'failure$stem');
        });

        test('crash reporting only for contract and unexpected', () {
          expect(
            failure.alwaysReportToCrash,
            failure is ContractFailure || failure is UnexpectedFailure,
          );
        });

        test('has value equality', () {
          expect(failure, equals(failure));
          expect(failure.hashCode, failure.hashCode);
          expect(failure.toString(), contains('Failure.'));
        });
      });
    }

    test('distinct fields are not equal', () {
      expect(
        const Failure.contract(wireCode: 'NOT_FOUND'),
        isNot(const Failure.contract(wireCode: 'SPREAD_INVALID')),
      );
      expect(
        const Failure.rateLimited(reason: RateLimitReason.burst),
        const Failure.rateLimited(reason: RateLimitReason.burst),
      );
    });

    test('ContractFailure.code is the wire code for every mapped code', () {
      const codes = [
        'VALIDATION_FAILED',
        'IDEMPOTENCY_KEY_REQUIRED',
        'NOT_FOUND',
        'IDEMPOTENCY_KEY_REUSED',
        'SPREAD_INVALID',
      ];
      for (final wire in codes) {
        expect(Failure.contract(wireCode: wire).code, wire);
      }
    });

    test('PurchaseFailure keeps the wire code and reason', () {
      const failure = Failure.purchase(wireCode: 'PRODUCT_UNKNOWN');
      expect(failure.code, 'PRODUCT_UNKNOWN');
      expect((failure as PurchaseFailure).reason, isNull);
    });

    test('sub-reason enums match GLOSSARY §5', () {
      expect(RateLimitReason.values.map((e) => e.name), [
        'burst',
        'dailyLimit',
        'declinedLimit',
        'lowTrustCap',
        'reportLimit',
      ]);
      expect(InsufficientReason.values.map((e) => e.name), [
        'noCredits',
        'lowTrustCap',
        'freePaused',
      ]);
      expect(PausedReason.values.map((e) => e.name), [
        'disabled',
        'budgetHard',
        'freeStop',
      ]);
      expect(RewardUnavailableReason.values.map((e) => e.name), [
        'disabled',
        'cap',
        'cooldown',
        'noFill',
        'consent',
      ]);
      expect(AttestationFailureKind.values.map((e) => e.name), [
        'unsupported',
        'keyInvalidated',
        'rejected',
        'quota',
        'transient',
      ]);
      expect(PurchasesBlockedReason.values.map((e) => e.name), [
        'blocked',
        'refundDebt',
        'storeDisabled',
      ]);
      expect(BackupInvalidReason.values.map((e) => e.name), [
        'notJson',
        'wrongFormat',
        'unsupportedVersion',
        'checksum',
        'schema',
        'tooLarge',
      ]);
    });
  });
}
