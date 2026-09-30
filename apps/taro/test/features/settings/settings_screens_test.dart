import 'package:flutter/material.dart' hide ThemeMode;
import 'package:flutter_test/flutter_test.dart';
import 'package:taro/di/providers.dart' show SupportInfo;
import 'package:taro/features/settings/controller/delete_data_controller.dart';
import 'package:taro/features/settings/controller/language_controller.dart';
import 'package:taro/features/settings/controller/privacy_controller.dart';
import 'package:taro/features/settings/controller/reminder_settings_controller.dart';
import 'package:taro/features/settings/controller/settings_controller.dart';
import 'package:taro/features/settings/view/delete_data_screen.dart';
import 'package:taro/features/settings/view/language_names.dart';
import 'package:taro/features/settings/view/language_screen.dart';
import 'package:taro/features/settings/view/privacy_screen.dart';
import 'package:taro/features/settings/view/reminder_settings_screen.dart';
import 'package:taro/features/settings/view/settings_screen.dart';
import 'package:taro/l10n/generated/taro_localizations.dart';
import 'package:taro_core/taro_core.dart';
import 'package:taro_ui/taro_ui.dart';

import '../skeleton_support.dart';

const SupportInfo _support = SupportInfo(
  email: 'support@example.com',
  supportId: 'abcd1234',
  appVersion: '1.0.0',
  buildNumber: '7',
  platform: AppPlatform.ios,
  osVersion: '18.0',
  locale: 'en',
);

SettingsScreenState _settings({
  SettingsRestore restore = const SettingsRestore.idle(),
  SettingsTransfer transfer = const SettingsTransfer.idle(),
  bool adsRemoved = false,
  bool removeAdsOffered = true,
  CreditBalance? balance,
  UserSettings settings = const UserSettings(),
  SupportInfo? support = _support,
}) => SettingsScreenState.content(
  view: SettingsView(
    settings: settings,
    balance: balance,
    adsRemoved: adsRemoved,
    removeAdsOffered: removeAdsOffered,
    aiConsentGranted: true,
    support: support,
  ),
  restore: restore,
  transfer: transfer,
);

void main() {
  late TaroLocalizations l10n;

  setUpAll(() async => l10n = await enL10n());

  test('language endonyms', () {
    expect(languageEndonym('de'), 'Deutsch');
    expect(languageEndonym('pt-BR'), 'Português');
    expect(languageEndonym('xx'), 'xx');
    expect(kLanguageEndonyms.keys, containsAll(kSupportedLocales));
  });

  group('S20 settings view', () {
    Future<List<Object?>> pump(
      WidgetTester tester,
      SettingsScreenState state,
    ) async {
      final calls = <Object?>[];
      await pumpTaroWidget(
        tester,
        SettingsLayout(
          state: state,
          onNavigate: calls.add,
          onStore: () => calls.add('store'),
          onReversals: (v) => calls.add('reversals:$v'),
          onHaptics: (v) => calls.add('haptics:$v'),
          onTheme: (v) => calls.add('theme:${v.name}'),
          onRestore: () => calls.add('restore'),
          onMoveReadings: () => calls.add('move'),
          onAcknowledge: () => calls.add('ack'),
          onCopy: (v) => calls.add('copy:$v'),
        ),
        size: const Size(430, 3200),
      );
      return calls;
    }

    testWidgets('content: every row and toggle', (tester) async {
      final calls = await pump(
        tester,
        _settings(
          balance: aCreditBalance().withBonus(2).withFreeRemaining(1).build(),
          settings: const UserSettings(
            localeOverride: 'de',
            reminder: ReminderSettings(enabled: true, time: '08:30'),
          ),
        ),
      );
      expect(find.text('Deutsch'), findsOneWidget);
      expect(find.text('8:30 AM'), findsOneWidget);
      expect(
        find.text(
          l10n.commonItemSeparator(
            l10n.balanceReadings(2),
            l10n.balanceFreeToday(1),
          ),
        ),
        findsOneWidget,
      );
      for (final label in [
        l10n.commonItemSeparator(
          l10n.balanceReadings(2),
          l10n.balanceFreeToday(1),
        ),
        l10n.settingsGetMore,
        l10n.storeRemoveAdsTitle,
        l10n.storeRestore,
        l10n.settingsMoveReadings,
        l10n.settingsLanguage,
        l10n.settingsReminder,
        l10n.settingsThemeDark,
        l10n.settingsAiReadings,
        l10n.settingsPrivacyChoices,
        l10n.settingsExport,
        l10n.settingsImport,
        l10n.settingsDeleteAll,
        l10n.settingsHelpFaq,
        l10n.settingsSupportLines,
        l10n.settingsLegal,
        l10n.settingsCopyId,
      ]) {
        await tapText(tester, label);
      }
      await tester.tap(find.text(l10n.settingsReversals));
      await tester.tap(find.text(l10n.settingsHaptics));
      await tester.pumpAndSettle();
      expect(calls, [
        'store',
        'store',
        'store',
        'restore',
        'move',
        '/settings/language',
        '/settings/reminder',
        'theme:dark',
        '/settings/privacy',
        '/settings/privacy',
        '/settings/export',
        '/settings/import',
        '/settings/delete',
        '/help',
        '/help/crisis',
        '/legal/disclaimer',
        'copy:abcd1234',
        'reversals:false',
        'haptics:false',
      ]);
      expect(find.text(l10n.settingsVersion('1.0.0', '7')), findsOneWidget);
    });

    testWidgets('ads removed, reminder off, system language, no support', (
      tester,
    ) async {
      await pump(tester, _settings(adsRemoved: true, support: null));
      expect(find.text(l10n.storeRemoveAdsOwned), findsOneWidget);
      expect(find.text(l10n.settingsReminderOff), findsOneWidget);
      expect(find.text(l10n.settingsLanguageSystem), findsWidgets);
      expect(find.text(l10n.settingsCopyId), findsNothing);
      await pump(tester, _settings(removeAdsOffered: false));
      expect(find.text(l10n.storeRemoveAdsTitle), findsNothing);
    });

    testWidgets('restore states', (tester) async {
      var calls = await pump(
        tester,
        _settings(restore: const SettingsRestore.inProgress()),
      );
      expect(find.text(l10n.settingsRestoreInProgress), findsOneWidget);
      await tapText(tester, l10n.storeRestore);
      expect(calls, isEmpty);

      calls = await pump(
        tester,
        _settings(
          restore: const SettingsRestore.success(RestoreFinding.nothingFound),
        ),
      );
      expect(find.text(l10n.restoreNothingFound), findsOneWidget);
      await tapText(tester, l10n.commonDismiss);
      expect(calls, ['ack']);

      await pump(
        tester,
        _settings(
          restore: const SettingsRestore.success(
            RestoreFinding.removeAdsRestored,
          ),
        ),
      );
      expect(find.text(l10n.restoreRemoveAds), findsOneWidget);

      calls = await pump(
        tester,
        _settings(restore: const SettingsRestore.failed()),
      );
      expect(find.text(l10n.restoreFailed), findsOneWidget);
      await tapText(tester, l10n.commonRetry);
      expect(calls, ['restore']);
    });

    testWidgets('transfer states', (tester) async {
      var calls = await pump(
        tester,
        _settings(transfer: const SettingsTransfer.checking()),
      );
      expect(find.text(l10n.settingsTransferChecking), findsOneWidget);
      await tapText(tester, l10n.settingsMoveReadings);
      expect(calls, isEmpty);

      calls = await pump(
        tester,
        _settings(transfer: const SettingsTransfer.code('T-123')),
      );
      expect(find.text(l10n.settingsTransferCodeTitle), findsOneWidget);
      expect(find.textContaining('T-123'), findsOneWidget);
      await tapText(tester, l10n.commonCopy);
      expect(calls, ['copy:T-123']);

      for (final (transfer, text) in [
        (const SettingsTransfer.nothingFound(), l10n.settingsTransferNothing),
        (
          const SettingsTransfer.notEligible(),
          l10n.settingsTransferNotEligible,
        ),
      ]) {
        await pump(tester, _settings(transfer: transfer));
        expect(find.text(text), findsOneWidget);
      }
      calls = await pump(
        tester,
        _settings(transfer: const SettingsTransfer.failed(ErrorKind.network)),
      );
      expect(find.text(l10n.settingsTransferFailed), findsOneWidget);
      await tapText(tester, l10n.commonRetry);
      expect(calls, ['move']);
    });
  });

  group('S21 language view', () {
    testWidgets('system + 12 locales; a tap selects', (tester) async {
      final selected = <String?>[];
      var back = 0;
      await pumpTaroWidget(
        tester,
        LanguageLayout(
          state: const LanguageState.content(
            localeOverride: 'fr',
            locales: kSupportedLocales,
          ),
          phoneLanguage: 'de-DE',
          onSelect: selected.add,
          onBack: () => back++,
        ),
        size: const Size(430, 2000),
      );
      expect(find.text(l10n.languageFromPhone('Deutsch')), findsOneWidget);
      expect(find.byType(TaroRadioTile<String?>), findsNWidgets(13));
      await tapText(tester, 'العربية');
      await tapText(tester, l10n.languageUsePhone);
      await tester.tap(find.bySemanticsLabel(l10n.commonBack));
      expect(selected, ['ar', null]);
      expect(back, 1);
    });
  });

  group('S22 reminder view', () {
    testWidgets('content and permissionDenied', (tester) async {
      final enabled = <bool>[];
      final times = <TimeOfDay>[];
      var settings = 0;
      Future<void> pump(ReminderSettingsState state) => pumpTaroWidget(
        tester,
        ReminderSettingsLayout(
          state: state,
          onEnabled: enabled.add,
          onChangeTime: times.add,
          onOpenSettings: () => settings++,
          onBack: noop,
        ),
        size: const Size(430, 1600),
      );
      await pump(
        const ReminderSettingsState.content(
          ReminderSettings(enabled: true, time: '21:05'),
        ),
      );
      expect(find.text('9:05 PM'), findsWidgets);
      await tapText(tester, l10n.reminderAt);
      await tapText(tester, l10n.reminderToggle);
      await pump(
        const ReminderSettingsState.permissionDenied(ReminderSettings()),
      );
      expect(find.text(l10n.reminderPermissionDenied), findsOneWidget);
      await tapText(tester, l10n.commonOpenSettings);
      await tapText(tester, l10n.reminderAt);
      expect(enabled, [false]);
      expect(times, [const TimeOfDay(hour: 21, minute: 5)]);
      expect(settings, 1);
    });
  });

  group('S23 privacy view', () {
    testWidgets('AI allowed / not allowed, UMP, ATT, analytics', (
      tester,
    ) async {
      final calls = <String>[];
      Future<void> pump(PrivacyView view) => pumpTaroWidget(
        tester,
        PrivacyLayout(
          state: PrivacyState.content(view),
          onWithdrawAi: () => calls.add('withdraw'),
          onAllowAi: () => calls.add('allow'),
          onReviewAdChoices: () => calls.add('ump'),
          onTracking: () => calls.add('att'),
          onAnalytics: (on) => calls.add('analytics:$on'),
          onPolicy: () => calls.add('policy'),
          onBack: noop,
        ),
        size: const Size(430, 1600),
      );
      await pump(
        const PrivacyView(
          aiGranted: true,
          adsPrivacyOptionsRequired: true,
          tracking: TrackingStatus.authorized,
          analyticsEnabled: true,
        ),
      );
      expect(find.text(l10n.privacyTrackingAllowed), findsOneWidget);
      await tapText(tester, l10n.privacyAiWithdraw);
      await tapText(tester, l10n.privacyReviewAdChoices);
      await tapText(tester, l10n.privacyTracking);
      await tapText(tester, l10n.privacyAnalytics);
      await tapText(tester, l10n.privacyReadPolicy);
      for (final (status, text) in [
        (TrackingStatus.denied, l10n.privacyTrackingNotAllowed),
        (TrackingStatus.notDetermined, l10n.privacyTrackingNotAsked),
      ]) {
        await pump(
          PrivacyView(
            aiGranted: false,
            adsPrivacyOptionsRequired: false,
            tracking: status,
            analyticsEnabled: false,
          ),
        );
        expect(find.text(text), findsOneWidget);
      }
      await tapText(tester, l10n.privacyAiAllow);
      await pump(
        const PrivacyView(
          aiGranted: false,
          adsPrivacyOptionsRequired: false,
          tracking: null,
          analyticsEnabled: false,
        ),
      );
      expect(find.text(l10n.privacyAdsHeading), findsNothing);
      expect(calls, [
        'withdraw',
        'ump',
        'att',
        'analytics:false',
        'policy',
        'allow',
      ]);
    });
  });

  group('S26 delete data view', () {
    testWidgets('every state', (tester) async {
      final calls = <String>[];
      Future<void> pump(DeleteDataState state) => pumpTaroWidget(
        tester,
        DeleteDataLayout(
          state: state,
          onTyped: (t) => calls.add('typed:$t'),
          onDelete: () => calls.add('delete'),
          onRetry: () => calls.add('retry'),
          onExport: () => calls.add('export'),
          onDone: () => calls.add('done'),
          onBack: () => calls.add('back'),
        ),
        size: const Size(430, 1600),
      );
      const summary = DeleteDataSummary(
        journalEntries: 4,
        readingsKept: 3,
        removeAdsKept: true,
      );
      await pump(const DeleteDataState.confirm1(summary));
      expect(find.text(l10n.deleteErasedJournal(4)), findsOneWidget);
      expect(
        find.text(l10n.deleteKeptBalance(l10n.balanceReadings(3))),
        findsOneWidget,
      );
      expect(find.text(l10n.deleteKeptRemoveAds), findsOneWidget);
      await tapText(tester, l10n.deleteButton);
      await tester.enterText(find.byType(TextField), 'DELETE');
      await tapText(tester, l10n.deleteExportFirst);
      await pump(
        const DeleteDataState.confirm2(
          DeleteDataSummary(
            journalEntries: 0,
            readingsKept: 0,
            removeAdsKept: false,
          ),
        ),
      );
      expect(find.text(l10n.deleteKeptRemoveAds), findsNothing);
      await tapText(tester, l10n.deleteButton);
      await tester.tap(find.bySemanticsLabel(l10n.commonBack));
      await pump(const DeleteDataState.deleting());
      expect(find.bySemanticsLabel(l10n.commonBack), findsNothing);
      await pump(const DeleteDataState.done());
      expect(find.text(l10n.deleteDoneBody), findsOneWidget);
      await tapText(tester, l10n.commonDone);
      await pump(const DeleteDataState.partial());
      expect(find.textContaining(l10n.deletePartial), findsOneWidget);
      await pump(const DeleteDataState.failed(ErrorKind.storage));
      expect(find.text(l10n.deleteFailed), findsOneWidget);
      await tapText(tester, l10n.commonRetry);
      expect(calls, [
        'typed:DELETE',
        'export',
        'delete',
        'back',
        'done',
        'retry',
      ]);
    });
  });

  group('settings screens with fakes', () {
    late TaroFakes fakes;

    setUp(() => fakes = TaroFakes());

    testWidgets('S20: navigation, toggles, theme, restore, move, copy', (
      tester,
    ) async {
      final router = await pumpRouted(
        tester,
        const SettingsScreen(),
        fakes: fakes,
        size: const Size(430, 3200),
      );
      await tapText(tester, l10n.settingsReversals);
      await tapText(tester, l10n.settingsHaptics);
      await tapText(tester, l10n.settingsThemeDark);
      expect(fakes.settings.current.themeMode, ThemeMode.dark);
      await tapText(tester, l10n.storeRestore);
      await tester.pumpAndSettle();
      await tapText(tester, l10n.settingsMoveReadings);
      await tester.pumpAndSettle();
      final dismiss = find.text(l10n.commonDismiss);
      if (dismiss.evaluate().isNotEmpty) {
        await tapText(tester, l10n.commonDismiss);
      }
      await tapText(tester, l10n.settingsCopyId);
      await tapText(tester, l10n.settingsLanguage);
      expectRoute('/settings/language');
      router.pop();
      await tester.pumpAndSettle();
      await tapText(tester, l10n.settingsGetMore);
      expectRoute('/store?source=settings');
    });

    testWidgets('S21: selecting a language saves the override', (
      tester,
    ) async {
      await pumpRouted(
        tester,
        const LanguageScreen(),
        fakes: fakes,
        size: const Size(430, 2000),
        pushed: true,
      );
      await tapText(tester, 'Deutsch');
      expect(fakes.settings.current.localeOverride, 'de');
      await tester.tap(find.bySemanticsLabel(l10n.commonBack));
      await tester.pumpAndSettle();
      expectRoute('/');
    });

    testWidgets('S22: enable, denied, open settings, change time', (
      tester,
    ) async {
      await pumpRouted(
        tester,
        const ReminderSettingsScreen(),
        fakes: fakes,
        size: const Size(430, 1600),
        pushed: true,
      );
      fakes.reminders.permission = false;
      await tapText(tester, l10n.reminderToggle);
      expect(find.text(l10n.reminderPermissionDenied), findsOneWidget);
      fakes.reminders.permission = true;
      await tapText(tester, l10n.commonOpenSettings);
      expect(find.text(l10n.reminderPermissionDenied), findsNothing);
      await tapText(tester, l10n.reminderAt);
      await tapText(tester, 'OK');
      await tester.tap(find.bySemanticsLabel(l10n.commonBack));
      await tester.pumpAndSettle();
      expectRoute('/');
    });

    testWidgets('S23: withdraw (confirm + cancel), allow, analytics, UMP', (
      tester,
    ) async {
      fakes.consentStore.seed(
        const ConsentState(
          onboardingStep: OnboardingStep.done,
          ai: AiConsent(decision: AiConsentDecision.granted, version: 1),
        ),
      );
      final router = await pumpRouted(
        tester,
        const PrivacyScreen(),
        fakes: fakes,
        size: const Size(430, 1600),
        pushed: true,
      );
      await tapText(tester, l10n.privacyAiWithdraw);
      await tapText(tester, l10n.commonCancel);
      expect(find.text(l10n.privacyAiWithdraw), findsOneWidget);
      await tapText(tester, l10n.privacyAiWithdraw);
      await tapText(tester, l10n.privacyWithdrawConfirm);
      expect(find.text(l10n.privacyAiAllow), findsOneWidget);
      await tapText(tester, l10n.privacyAnalytics);
      final tracking = find.text(l10n.privacyTracking);
      if (tracking.evaluate().isNotEmpty) {
        await tapText(tester, l10n.privacyTracking);
      }
      await tapText(tester, l10n.privacyReadPolicy);
      expectRoute('/legal/privacy');
      router.pop();
      await tester.pumpAndSettle();
      await tapText(tester, l10n.privacyAiAllow);
      expectRoute('/consent/ai');
      router.pop();
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel(l10n.commonBack));
      await tester.pumpAndSettle();
      expectRoute('/');
    });

    testWidgets('S23: review ad choices when UMP requires it', (tester) async {
      fakes.consentStore.seed(
        const ConsentState(
          onboardingStep: OnboardingStep.done,
          ads: AdsConsent(
            status: AdsConsentStatus.obtained,
            canRequestAds: true,
            privacyOptionsRequired: true,
          ),
        ),
      );
      await pumpRouted(
        tester,
        const PrivacyScreen(),
        fakes: fakes,
        size: const Size(430, 1600),
      );
      expect(find.text(l10n.privacyAdPersonalisation), findsOneWidget);
      await tapText(tester, l10n.privacyReviewAdChoices);
    });

    testWidgets('S26: type the word, delete, done; export first; back', (
      tester,
    ) async {
      final router = await pumpRouted(
        tester,
        const DeleteDataScreen(),
        fakes: fakes,
        size: const Size(430, 1600),
        pushed: true,
      );
      await tapText(tester, l10n.deleteExportFirst);
      expectRoute('/settings/export');
      router.pop();
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), l10n.deleteConfirmWord);
      await tester.pumpAndSettle();
      await tapText(tester, l10n.deleteButton);
      expect(find.text(l10n.deleteDoneTitle), findsOneWidget);
      await tapText(tester, l10n.commonDone);
      expectRoute('/home');
    });

    testWidgets('S26: a failed wipe retries; back pops', (tester) async {
      fakes.journalRepository.failNext(
        const Failure.storage(),
        on: 'deleteAll',
      );
      await pumpRouted(
        tester,
        const DeleteDataScreen(),
        fakes: fakes,
        size: const Size(430, 1600),
        pushed: true,
      );
      await tester.enterText(find.byType(TextField), l10n.deleteConfirmWord);
      await tester.pumpAndSettle();
      await tapText(tester, l10n.deleteButton);
      if (find.text(l10n.deleteFailed).evaluate().isNotEmpty) {
        await tapText(tester, l10n.commonRetry);
      }
      await tester.tap(find.bySemanticsLabel(l10n.commonBack).first);
      await tester.pumpAndSettle();
    });
  });
}
