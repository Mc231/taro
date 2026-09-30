import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taro/common/failure_message.dart';
import 'package:taro/l10n/generated/taro_localizations.dart';
import 'package:taro_core/taro_core.dart';
import 'package:taro_ui/taro_ui.dart';

import '../helpers/pump_taro_widget.dart';

/// One failure of every `Failure` subtype (GLOSSARY §16.1).
final List<Failure> _allFailures = [
  const Failure.network(),
  const Failure.timeout(),
  const Failure.server(status: 503, wireCode: 'X'),
  const Failure.rateLimited(reason: RateLimitReason.dailyLimit),
  const Failure.upgradeRequired(),
  const Failure.contract(wireCode: 'NOT_FOUND'),
  const Failure.sessionExpired(),
  const Failure.attestation(kind: AttestationFailureKind.transient),
  const Failure.insufficientCredits(reason: InsufficientReason.freePaused),
  const Failure.holdConflict(),
  const Failure.readingExpiredRefunded(),
  const Failure.aiConsentRequired(requiredVersion: 2),
  const Failure.aiUnavailableRegion(),
  const Failure.readingsPaused(reason: PausedReason.budgetHard),
  const Failure.aiUnavailable(),
  const Failure.requestInProgress(),
  const Failure.rewardUnavailable(reason: RewardUnavailableReason.cap),
  Failure.timezoneChangeRejected(allowedAfter: DateTime.utc(2026)),
  const Failure.purchaseCancelled(),
  const Failure.purchasePending(),
  const Failure.purchase(wireCode: 'PRODUCT_UNKNOWN'),
  const Failure.purchaseAlreadyClaimed(transferEligible: true),
  const Failure.purchasesBlocked(reason: PurchasesBlockedReason.refundDebt),
  const Failure.productUnavailable(),
  const Failure.storage(),
  const Failure.backupInvalid(reason: BackupInvalidReason.tooLarge),
  Failure.unexpected(error: StateError('x'), stack: StackTrace.empty),
];

void main() {
  late TaroLocalizations en;
  setUpAll(() async {
    en = await TaroLocalizations.delegate.load(const Locale('en'));
  });

  test('every Failure has its own non-empty message (RC5)', () {
    final messages = <String, String>{};
    for (final failure in _allFailures) {
      final message = FailureMessage.ofL10n(en, failure);
      expect(message, isNotEmpty, reason: failure.code);
      messages[failure.messageKey] = message;
      // The message key resolves to the same text.
      expect(FailureMessage.forKey(en, failure.messageKey), message);
    }
    expect(messages.length, 27);
  });

  test('specific messages', () {
    expect(
      FailureMessage.ofL10n(en, const Failure.network()),
      'You’re offline. Check your connection and try again.',
    );
    expect(
      FailureMessage.ofL10n(en, const Failure.purchasePending()),
      en.failurePurchasePending,
    );
  });

  test('refusal texts per category (GLOSSARY §5.2)', () {
    final texts = {
      for (final c in RefusalCategory.values) FailureMessage.refusal(en, c),
    };
    expect(texts.length, RefusalCategory.values.length);
    expect(
      FailureMessage.refusal(en, RefusalCategory.other),
      en.refusalGeneric,
    );
    for (final c in RefusalCategory.values) {
      expect(
        FailureMessage.forKey(en, c.messageKey),
        FailureMessage.refusal(en, c),
      );
    }
  });

  test('unknown keys never show raw', () {
    expect(
      FailureMessage.forKey(en, 'safetyDeclinedSomethingNew'),
      en.refusalGeneric,
    );
    expect(
      FailureMessage.forKey(en, 'failureSomethingNew'),
      en.failureUnexpected,
    );
  });

  test('every ErrorKind has a title, a body and a visual kind', () {
    for (final kind in ErrorKind.values) {
      expect(FailureMessage.title(en, kind), isNotEmpty);
      expect(FailureMessage.body(en, kind), isNotEmpty);
      expect(FailureMessage.visual(kind).name, kind.name);
    }
    expect(
      ErrorKind.values.map((k) => FailureMessage.title(en, k)).toSet().length,
      ErrorKind.values.length,
    );
  });

  test('every locale has the failure messages', () async {
    for (final locale in TaroLocalizations.supportedLocales) {
      final l10n = await TaroLocalizations.delegate.load(locale);
      for (final failure in _allFailures) {
        expect(FailureMessage.ofL10n(l10n, failure), isNotEmpty);
      }
    }
  });

  testWidgets('of(context) uses the ambient locale', (tester) async {
    late String message;
    await pumpTaroWidget(
      tester,
      Builder(
        builder: (context) {
          message = FailureMessage.of(context, const Failure.storage());
          return const SizedBox.shrink();
        },
      ),
    );
    expect(message, en.failureStorage);
  });

  group('FailureView', () {
    testWidgets('storage error with Retry', (tester) async {
      var retries = 0;
      await pumpTaroWidget(
        tester,
        FailureView.of(const Failure.storage(), onRetry: () => retries++),
      );
      expect(find.text(en.errorStorageTitle), findsOneWidget);
      expect(find.text(en.errorStorageBody), findsOneWidget);
      final view = tester.widget<TaroErrorView>(find.byType(TaroErrorView));
      expect(view.kind, TaroErrorKind.storage);
      await tester.tap(find.text('Try again'));
      expect(retries, 1);
    });

    testWidgets('network error without Retry, with a secondary action', (
      tester,
    ) async {
      await pumpTaroWidget(
        tester,
        FailureView(
          kind: ErrorKind.network,
          secondaryAction: TaroButton.secondary(
            label: en.commonBackToToday,
            onPressed: () {},
          ),
        ),
      );
      expect(find.text(en.errorNetworkTitle), findsOneWidget);
      expect(find.text('Try again'), findsNothing);
      expect(find.text(en.commonBackToToday), findsOneWidget);
    });

    testWidgets('localised in ar', (tester) async {
      await pumpTaroWidget(
        tester,
        FailureView.of(const Failure.network()),
        locale: const Locale('ar'),
      );
      final ar = await TaroLocalizations.delegate.load(const Locale('ar'));
      expect(find.text(ar.errorNetworkTitle), findsOneWidget);
    });
  });
}
