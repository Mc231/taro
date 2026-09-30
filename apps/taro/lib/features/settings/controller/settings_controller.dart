import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:taro/app_state/balance_controller.dart';
import 'package:taro/app_state/consent_controller.dart';
import 'package:taro/app_state/entitlement_controller.dart';
import 'package:taro/app_state/remote_config_controller.dart';
import 'package:taro/app_state/settings_controller.dart' show settingsProvider;
import 'package:taro/di/providers.dart';
import 'package:taro_core/taro_core.dart';

part 'settings_controller.freezed.dart';

/// How long S20 waits for the store's restore answer.
const Duration kRestoreAnswerTimeout = Duration(seconds: 30);

/// How long the transfer check waits for the Worker's verification of the
/// re-submitted purchases (RC84).
const Duration kTransferCheckTimeout = Duration(seconds: 45);

/// The store-answer timeouts of S20 (tests shorten them).
final settingsStoreTimeoutsProvider =
    Provider<({Duration restore, Duration transfer})>(
      (ref) =>
          (restore: kRestoreAnswerTimeout, transfer: kTransferCheckTimeout),
    );

/// What a finished restore found (01 F4).
enum RestoreFinding {
  /// "No purchases to restore. Reading packs are tied to this app
  /// installation and can't be restored."
  nothingFound,

  /// "Remove Banner Ads restored".
  removeAdsRestored,
}

/// The Restore purchases row of S20.
@freezed
sealed class SettingsRestore with _$SettingsRestore {
  /// Not running.
  const factory SettingsRestore.idle() = SettingsRestoreIdle;

  /// `restoreInProgress`: a spinner, the row disabled.
  const factory SettingsRestore.inProgress() = SettingsRestoreInProgress;

  /// `restoreSuccess(nothingFound | removeAdsRestored)`.
  const factory SettingsRestore.success(RestoreFinding finding) =
      SettingsRestoreSuccess;

  /// `restoreFailed`: inline error + Retry.
  const factory SettingsRestore.failed() = SettingsRestoreFailed;
}

/// "Move readings from another device" (01 §7.10, 03 §6.6, RC84).
@freezed
sealed class SettingsTransfer with _$SettingsTransfer {
  /// Not running.
  const factory SettingsTransfer.idle() = SettingsTransferIdle;

  /// Re-submitting past purchases to the Worker.
  const factory SettingsTransfer.checking() = SettingsTransferChecking;

  /// A purchase belongs to another install: show [transferCode] (the
  /// single-use `transferToken`, 7-day TTL) with the Support ID to email.
  const factory SettingsTransfer.code(String transferCode) =
      SettingsTransferCode;

  /// A purchase is claimed elsewhere but this store account could not be
  /// proven (`transferEligible == false`): contact support.
  const factory SettingsTransfer.notEligible() = SettingsTransferNotEligible;

  /// Nothing to move.
  const factory SettingsTransfer.nothingFound() = SettingsTransferNothing;

  /// The store or the Worker failed; retry.
  const factory SettingsTransfer.failed(ErrorKind kind) =
      SettingsTransferFailed;
}

/// What S20 shows.
@freezed
abstract class SettingsView with _$SettingsView {
  /// Creates a view.
  const factory SettingsView({
    required UserSettings settings,

    /// The balance row ("3 readings · 1 free today").
    required CreditBalance? balance,

    /// `adsRemoved`: "Banner ads removed ✓", no price.
    required bool adsRemoved,

    /// Whether Remove Banner Ads is offered (`store.removeAdsEnabled`).
    required bool removeAdsOffered,

    /// The AI readings row (Allowed / Not allowed).
    required bool aiConsentGranted,

    /// About: version, build and the Support ID (RC43); `null` until the
    /// install is known.
    SupportInfo? support,
  }) = _SettingsView;
}

/// S20 Settings (01 §7.10, §8.3).
@freezed
sealed class SettingsScreenState with _$SettingsScreenState {
  /// The settings list with the restore and transfer rows.
  const factory SettingsScreenState.content({
    required SettingsView view,
    required SettingsRestore restore,
    required SettingsTransfer transfer,
  }) = SettingsContent;
}

/// Drives S20: the toggles (reversals, haptics, theme), Restore purchases,
/// "Move readings from another device" and the About block.
final class SettingsController extends Notifier<SettingsScreenState> {
  late ProviderSubscription<UserSettings> _settings;
  late ProviderSubscription<CreditBalance?> _balance;
  late ProviderSubscription<Entitlement> _entitlement;
  late ProviderSubscription<RemoteConfig> _config;
  late ProviderSubscription<bool> _aiConsent;
  SupportInfo? _support;
  SettingsRestore _restore = const SettingsRestore.idle();
  SettingsTransfer _transfer = const SettingsTransfer.idle();

  @override
  SettingsScreenState build() {
    _settings = ref.listen(settingsProvider, (_, _) => _update());
    _balance = ref.listen(balanceProvider, (_, _) => _update());
    _entitlement = ref.listen(entitlementProvider, (_, _) => _update());
    _config = ref.listen(remoteConfigProvider, (_, _) => _update());
    _aiConsent = ref.listen(aiConsentValidProvider, (_, _) => _update());
    unawaited(_loadSupport());
    return _compute();
  }

  /// "Reversed cards".
  Future<void> setReversals({required bool enabled}) => _change(
    (s) => s.copyWith(reversalsEnabled: enabled),
    SettingChangedEvent.reversals(enabled: enabled),
  );

  /// "Haptics".
  Future<void> setHaptics({required bool enabled}) => _change(
    (s) => s.copyWith(hapticsEnabled: enabled),
    SettingChangedEvent.haptics(enabled: enabled),
  );

  /// Theme (System / Light / Dark).
  Future<void> setTheme(ThemeMode mode) => _change(
    (s) => s.copyWith(themeMode: mode),
    SettingChangedEvent.theme(mode: mode),
  );

  /// Restore purchases (01 F4): Remove Banner Ads comes back; consumable
  /// readings are not restorable by store rules.
  Future<void> restore() async {
    if (_restore is SettingsRestoreInProgress) return;
    _setRestore(const SettingsRestore.inProgress());
    final iap = ref.read(iapServiceProvider);
    final coordinator = ref.read(purchaseCoordinatorProvider);
    final answer = iap.events
        .where((e) => e is IapRestored)
        .cast<IapRestored>()
        .first
        .timeout(ref.read(settingsStoreTimeoutsProvider).restore);
    final started = await coordinator.restore();
    if (started case Err()) {
      answer.ignore();
      _setRestore(const SettingsRestore.failed());
      return;
    }
    try {
      final restored = await answer;
      if (!ref.mounted) return;
      _setRestore(
        SettingsRestore.success(
          restored.productIds.contains(TaroProducts.removeAds.id) ||
                  _entitlement.read().removesAds
              ? RestoreFinding.removeAdsRestored
              : RestoreFinding.nothingFound,
        ),
      );
    } on TimeoutException {
      if (!ref.mounted) return;
      _setRestore(
        SettingsRestore.success(
          _entitlement.read().removesAds
              ? RestoreFinding.removeAdsRestored
              : RestoreFinding.nothingFound,
        ),
      );
    }
  }

  /// "Move readings from another device" (RC84): re-submits past purchases
  /// of this store account to `POST /v1/purchases/verify`; a transaction
  /// claimed by another install yields the transfer code.
  Future<void> moveReadings() async {
    if (_transfer is SettingsTransferChecking) return;
    _setTransfer(const SettingsTransfer.checking());
    final coordinator = ref.read(purchaseCoordinatorProvider);
    final iap = ref.read(iapServiceProvider);
    final timeout = ref.read(settingsStoreTimeoutsProvider).transfer;
    final done = Completer<SettingsTransfer>();
    Set<ProductId>? restored;
    final answered = <ProductId>{};
    var claimedWithoutCode = false;

    void settle() {
      final expected = restored;
      if (done.isCompleted || expected == null) return;
      if (expected.isEmpty || answered.containsAll(expected)) {
        done.complete(
          claimedWithoutCode
              ? const SettingsTransfer.notEligible()
              : const SettingsTransfer.nothingFound(),
        );
      }
    }

    final updates = coordinator.updates.listen((update) {
      answered.add(update.productId);
      switch (update.outcome) {
        case PurchaseOutcomeFailed(
          failure: PurchaseAlreadyClaimedFailure(:final transferToken?),
        ):
          if (!done.isCompleted) {
            done.complete(SettingsTransfer.code(transferToken));
          }
        case PurchaseOutcomeFailed(failure: PurchaseAlreadyClaimedFailure()):
          claimedWithoutCode = true;
        case _:
          break;
      }
      settle();
    });
    final events = iap.events.listen((event) {
      if (event is IapRestored) {
        restored = {
          for (final id in event.productIds)
            if (TaroProducts.byId(id)?.isConsumable ?? false) id,
        };
        settle();
      }
    });
    try {
      final started = await coordinator.restore();
      if (started case Err(:final failure)) {
        _setTransfer(SettingsTransfer.failed(ErrorKind.fromFailure(failure)));
        return;
      }
      final result = await done.future.timeout(
        timeout,
        onTimeout: () => claimedWithoutCode
            ? const SettingsTransfer.notEligible()
            : const SettingsTransfer.failed(ErrorKind.network),
      );
      _setTransfer(result);
    } finally {
      await updates.cancel();
      await events.cancel();
    }
  }

  /// Clears a shown restore or transfer result.
  void acknowledge() {
    if (_restore is! SettingsRestoreInProgress) {
      _restore = const SettingsRestore.idle();
    }
    if (_transfer is! SettingsTransferChecking) {
      _transfer = const SettingsTransfer.idle();
    }
    _update();
  }

  Future<void> _change(
    UserSettings Function(UserSettings) change,
    SettingChangedEvent event,
  ) async {
    final analytics = ref.read(analyticsServiceProvider);
    final saved = await ref.read(settingsRepositoryProvider).update(change);
    if (saved case Ok()) await analytics.log(event);
  }

  Future<void> _loadSupport() async {
    final support = await loadSupportInfo(ref);
    _support = support.valueOrNull;
    _update();
  }

  void _setRestore(SettingsRestore restore) {
    _restore = restore;
    _update();
  }

  void _setTransfer(SettingsTransfer transfer) {
    _transfer = transfer;
    _update();
  }

  void _update() {
    if (ref.mounted) state = _compute();
  }

  SettingsScreenState _compute() => SettingsScreenState.content(
    view: SettingsView(
      settings: _settings.read(),
      balance: _balance.read(),
      adsRemoved: _entitlement.read().removesAds,
      removeAdsOffered: _config.read().storeRemoveAdsEnabled,
      aiConsentGranted: _aiConsent.read(),
      support: _support,
    ),
    restore: _restore,
    transfer: _transfer,
  );
}

/// S20 controller.
final NotifierProvider<SettingsController, SettingsScreenState>
settingsScreenControllerProvider = NotifierProvider.autoDispose(
  SettingsController.new,
);
