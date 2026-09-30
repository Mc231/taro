import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:taro/app.dart';
import 'package:taro/app_state/sync_coordinator.dart';
import 'package:taro/bootstrap/startup_assertions.dart';
import 'package:taro/bootstrap/storage_error_app.dart';
import 'package:taro/bootstrap/taro_environment.dart';
import 'package:taro/data/secure/keys.dart';
import 'package:taro/di/providers.dart';
import 'package:taro/features/consent/controller/att_preprompt_controller.dart';
import 'package:taro/lifecycle/app_lifecycle_observer.dart';
import 'package:taro_core/taro_core.dart';
import 'package:taro_ui/taro_ui.dart' show registerTaroFontLicenses;

/// Riverpod's automatic retry is off everywhere (02 §7): only the API
/// client retries, so a side-effecting provider never runs twice.
Duration? noProviderRetry(int retryCount, Object error) => null;

/// The composition root (02 §9.1, RC76). Every step touching the platform
/// goes through [env]:
///
/// 1. `initFirebase`, then the databases are opened and the flavor's
///    adapters built with the caches loaded (config, balance, entitlement,
///    settings, consent), so the first frame is right offline;
/// 2. analytics consent is set to all denied before any event (RC68) and
///    the crash handlers are installed;
/// 3. the startup assertions run (02 §15);
/// 4. `InstallRepository.getOrCreate()`; the install ID, secret and
///    session token are registered with the log redactor;
/// 5. the purchase coordinator subscribes to the store before any UI;
/// 6. `env.runApp(UncontrolledProviderScope(...))`;
/// 7. after the first frame, without blocking it: the launch sync, the
///    UMP / ATT / ads sequence for returning users, and the lifecycle
///    observer.
///
/// A storage failure (steps 1 and 4) shows the blocking S01 `storageError`
/// screen, whose **Try again** runs bootstrap again; it never creates a
/// second install ID. Returns the container of the running app, or `null`
/// on the storage error.
Future<ProviderContainer?> bootstrap(TaroEnvironment env) async {
  final binding = WidgetsFlutterBinding.ensureInitialized();
  final flavor = env.flavor;
  await env.initFirebase();

  final List<Override> overrides;
  try {
    final dbs = await env.openDatabases();
    overrides = await env.buildOverrides(flavor, dbs);
  } on Object {
    _storageError(env);
    return null;
  }
  final container = ProviderContainer(
    overrides: overrides,
    retry: noProviderRetry,
  );

  final crash = container.read(crashReporterProvider);
  await container
      .read(analyticsServiceProvider)
      .setConsent(AnalyticsConsent.allDenied());
  env.installErrorHandlers(crash);
  assertStartup(
    flavor: flavor,
    random: container.read(randomSourceProvider),
    attestation: container.read(attestationServiceProvider),
  );

  final identity = await container
      .read(installRepositoryProvider)
      .getOrCreate();
  switch (identity) {
    case Err(:final failure):
      await crash.recordError(failure, StackTrace.current);
      container.dispose();
      _storageError(env);
      return null;
    case Ok(:final value):
      await _registerSecrets(container, env.secureStore, value);
  }

  // Before any UI: the store deliveries of a previous session are
  // processed even if no screen is ever opened (04 §6.2).
  container.read(purchaseCoordinatorProvider);
  // The neutral ATT pre-prompt (RC19) is shown by `AttPrePromptHost` in
  // `TaroApp`; the orchestrator awaits its Continue before the system
  // prompt.
  container.read(consentOrchestratorProvider).prePrompt = () =>
      container.read(attPrePromptProvider.notifier).request();
  registerFontLicensesOnce();

  env.runApp(
    UncontrolledProviderScope(container: container, child: const TaroApp()),
  );
  binding.addPostFrameCallback((_) => unawaited(afterFirstFrame(container)));
  return container;
}

bool _fontLicensesRegistered = false;

/// Adds the bundled font licences (OFL) to the licences page once per
/// process, however often bootstrap runs (S01 **Try again**).
void registerFontLicensesOnce() {
  if (_fontLicensesRegistered) return;
  _fontLicensesRegistered = true;
  registerTaroFontLicenses();
}

/// The post-frame launch work (02 §9.1 steps 6 and 7).
Future<void> afterFirstFrame(ProviderContainer container) async {
  container.read(appLifecycleObserverProvider).attach(WidgetsBinding.instance);
  final consent = container.read(consentOrchestratorProvider);
  await Future.wait([
    container.read(syncCoordinatorProvider).run(SyncReason.launch),
    consent.run(),
  ]);
}

Future<void> _registerSecrets(
  ProviderContainer container,
  SecureStore secure,
  InstallIdentity identity,
) async {
  final redactor = container.read(redactorProvider)
    ..registerInstallId(identity.installId.value);
  final secret = (await secure.read(SecureKeys.installSecret)).valueOrNull;
  if (secret != null) redactor.registerSecret(secret);
  final token =
      (await container.read(sessionTokenStoreProvider).read()).valueOrNull;
  if (token != null) redactor.registerSecret(token.token);
}

void _storageError(TaroEnvironment env) => env.runApp(
  StorageErrorApp(
    supportEmail: env.flavor.supportEmail,
    onRetry: () => unawaited(bootstrap(env)),
  ),
);
