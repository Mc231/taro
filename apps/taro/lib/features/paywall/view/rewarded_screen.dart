import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:taro/common/failure_message.dart';
import 'package:taro/features/paywall/controller/rewarded_controller.dart';
import 'package:taro/l10n/generated/taro_localizations.dart';
import 'package:taro_core/taro_core.dart';
import 'package:taro_ui/taro_ui.dart';

/// S12 Rewarded flow overlay (04 §9.2), opened by `TaroModals.rewarded`
/// only after a tap on the rewarded row (never auto-shown, rule 12). Starts
/// the flow once when it opens; pops `true` from "Continue" after a grant.
class RewardedScreen extends ConsumerStatefulWidget {
  /// Creates the overlay.
  const RewardedScreen({super.key});

  @override
  ConsumerState<RewardedScreen> createState() => _RewardedScreenState();
}

class _RewardedScreenState extends ConsumerState<RewardedScreen> {
  @override
  void initState() {
    super.initState();
    unawaited(ref.read(rewardedControllerProvider.notifier).start());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(rewardedControllerProvider);
    return RewardedLayout(
      state: state,
      onClose: () => Navigator.of(context).pop(state is RewardedGranted),
    );
  }
}

/// The S12 skeleton for one [state] (Phase 13.5; restyled in Phase 16).
class RewardedLayout extends StatelessWidget {
  /// Creates the view.
  const RewardedLayout({
    required this.state,
    required this.onClose,
    super.key,
  });

  /// The controller state.
  final RewardedState state;

  /// Closes the overlay ("Continue", "Close").
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final l10n = TaroLocalizations.of(context);
    final close = TaroButton.secondary(
      label: l10n.commonClose,
      onPressed: onClose,
    );
    final child = switch (state) {
      RewardedLoadingAd() || RewardedShowing() => TaroLoadingView(
        semanticsLabel: l10n.rewardedLoadingAd,
        layout: TaroLoadingLayout.text,
        itemCount: 1,
      ),
      RewardedGranting() => TaroEmptyView(
        title: l10n.rewardedGrantingTitle,
        body: '${l10n.rewardedGrantingBody}\n${l10n.rewardedCloseNote}',
        largeTitle: false,
        action: close,
      ),
      RewardedGranted(:final amount) => TaroEmptyView(
        title: l10n.rewardedGrantedTitle,
        body: l10n.rewardedGrantedBody(amount),
        largeTitle: false,
        action: TaroButton.primary(
          label: l10n.commonContinue,
          onPressed: onClose,
        ),
      ),
      RewardedGrantDelayed() => TaroEmptyView(
        title: l10n.rewardedGrantDelayed,
        largeTitle: false,
        action: TaroButton.primary(
          label: l10n.commonContinue,
          onPressed: onClose,
        ),
      ),
      RewardedDismissedEarly() => TaroEmptyView(
        title: l10n.rewardedDismissedEarly,
        largeTitle: false,
        action: close,
      ),
      RewardedNoFill() => TaroEmptyView(
        title: l10n.rewardedNoFill,
        largeTitle: false,
        action: close,
      ),
      RewardedUnavailable(:final reason) => TaroEmptyView(
        title: reason == RewardUnavailableReason.cap
            ? l10n.rewardedCapped
            : l10n.failureRewardUnavailable,
        largeTitle: false,
        action: close,
      ),
      RewardedFailed(:final kind) => TaroErrorView(
        kind: FailureMessage.visual(kind),
        title: FailureMessage.title(l10n, kind),
        body: FailureMessage.body(l10n, kind),
        secondaryAction: close,
      ),
    };
    return TaroScaffold(
      appBar: TaroAppBar(
        leading: TaroAppBarLeading.close,
        leadingLabel: l10n.commonClose,
        onLeading: onClose,
      ),
      body: child,
    );
  }
}
