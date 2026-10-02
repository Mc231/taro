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
///
/// `grantDelayed` and `dismissedEarly` close the dialog with a neutral
/// snackbar; `noFill` closes it silently (S10 / S11 then grey the row out
/// with "No ads available right now" for 60 s).
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

  void _closeWith(String? message) {
    // The snackbar lives on the app's messenger, so it outlives the dialog.
    if (message != null) TaroToast.show(context, message: message);
    Navigator.of(context).pop(false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = TaroLocalizations.of(context);
    ref.listen(rewardedControllerProvider, (_, next) {
      switch (next) {
        case RewardedGrantDelayed():
          _closeWith(l10n.rewardedGrantDelayed);
        case RewardedDismissedEarly():
          _closeWith(l10n.rewardedDismissedEarly);
        case RewardedNoFill():
          _closeWith(null);
        default:
          break;
      }
    });
    final state = ref.watch(rewardedControllerProvider);
    return RewardedLayout(
      state: state,
      onClose: () => Navigator.of(context).pop(state is RewardedGranted),
    );
  }
}

/// The S12 dialog for one [state] (`Rewarded.dc.html`,
/// `RewardedGranted.dc.html`): a progress ring around a small card back
/// while the ad loads and the grant is polled, a check once granted. No
/// banner (RC18).
class RewardedLayout extends StatelessWidget {
  /// Creates the view.
  const RewardedLayout({
    required this.state,
    required this.onClose,
    super.key,
  });

  /// The controller state.
  final RewardedState state;

  /// Closes the overlay ("Cancel", "Continue", "Close").
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final l10n = TaroLocalizations.of(context);
    final tokens = context.tokens;
    final c = tokens.color;
    final cancel = TaroButton.secondary(
      label: l10n.commonCancel,
      onPressed: onClose,
    );
    final close = TaroButton.secondary(
      label: l10n.commonClose,
      onPressed: onClose,
    );
    final cont = TaroButton.primary(
      label: l10n.commonContinue,
      onPressed: onClose,
    );
    final (
      Widget? visual,
      String title,
      String? body,
      String? caption,
      Widget action,
    ) = switch (state) {
      RewardedLoadingAd() || RewardedShowing() => (
        _Ring(label: l10n.rewardedLoadingAd),
        l10n.rewardedLoadingAd,
        null,
        null,
        cancel,
      ),
      RewardedGranting() => (
        _Ring(label: l10n.rewardedGrantingTitle),
        l10n.rewardedGrantingTitle,
        l10n.rewardedGrantingBody,
        l10n.rewardedCloseNote,
        cancel,
      ),
      RewardedGranted(:final amount) => (
        _Done(label: l10n.commonDone),
        l10n.rewardedGrantedTitle,
        l10n.rewardedGrantedBody(amount),
        null,
        cont,
      ),
      RewardedGrantDelayed() => (
        null,
        l10n.rewardedGrantDelayed,
        null,
        null,
        cont,
      ),
      RewardedDismissedEarly() => (
        null,
        l10n.rewardedDismissedEarly,
        null,
        null,
        close,
      ),
      RewardedNoFill() => (null, l10n.rewardedNoFill, null, null, close),
      RewardedUnavailable(:final reason) => (
        null,
        reason == RewardUnavailableReason.cap
            ? l10n.rewardedCapped
            : l10n.failureRewardUnavailable,
        null,
        null,
        close,
      ),
      RewardedFailed(:final kind) => (
        _Icon(FailureMessage.visual(kind)),
        FailureMessage.title(l10n, kind),
        FailureMessage.body(l10n, kind),
        null,
        close,
      ),
    };
    return Dialog(
      backgroundColor: c.bg.surfaceRaised,
      surfaceTintColor: c.bg.surfaceRaised,
      elevation: 0,
      insetPadding: EdgeInsets.symmetric(
        horizontal: tokens.space.s7,
        vertical: tokens.space.s7,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(tokens.radius.xl),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: tokens.layout.maxContentWidth),
        child: SingleChildScrollView(
          padding: EdgeInsetsDirectional.fromSTEB(
            tokens.space.s7,
            tokens.space.s8,
            tokens.space.s7,
            tokens.space.s6,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (visual != null) ...[
                Center(child: visual),
                SizedBox(height: tokens.space.s6),
              ],
              Semantics(
                header: true,
                liveRegion: true,
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: tokens.typography.cardName.copyWith(
                    color: c.text.primary,
                  ),
                ),
              ),
              if (body != null) ...[
                SizedBox(height: tokens.space.s3),
                Text(
                  body,
                  textAlign: TextAlign.center,
                  style: tokens.typography.body.copyWith(
                    color: c.text.secondary,
                  ),
                ),
              ],
              if (caption != null) ...[
                SizedBox(height: tokens.space.s5),
                Text(
                  caption,
                  textAlign: TextAlign.center,
                  style: tokens.typography.caption.copyWith(
                    color: c.text.tertiary,
                  ),
                ),
              ],
              SizedBox(height: tokens.space.s6),
              action,
            ],
          ),
        ),
      ),
    );
  }
}

/// The progress ring with a small card back in its centre; a still arc
/// under reduced motion.
class _Ring extends StatelessWidget {
  const _Ring({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final size = tokens.size.card.md;
    return Semantics(
      label: label,
      child: SizedBox.square(
        dimension: size,
        child: Stack(
          alignment: AlignmentDirectional.center,
          children: [
            SizedBox.expand(
              child: CircularProgressIndicator(
                value: context.reduceMotion ? 0.75 : null,
                strokeWidth: TaroStrokes.focusRing,
                color: tokens.color.accent.primary,
                backgroundColor: tokens.color.border.subtle,
              ),
            ),
            const ExcludeSemantics(
              child: TaroCardBack(size: TaroCardSize.thumb),
            ),
          ],
        ),
      ),
    );
  }
}

/// The granted check in `color.status.success` with its "Done" label.
class _Done extends StatelessWidget {
  const _Done({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final success = tokens.color.status.success;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ExcludeSemantics(
          child: Container(
            width: tokens.size.card.md,
            height: tokens.size.card.md,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: success, width: TaroStrokes.focusRing),
            ),
            child: Icon(
              Icons.check_rounded,
              size: tokens.space.s10,
              color: success,
            ),
          ),
        ),
        SizedBox(height: tokens.space.s4),
        Text(
          label,
          style: tokens.typography.label.copyWith(color: success),
        ),
      ],
    );
  }
}

class _Icon extends StatelessWidget {
  const _Icon(this.kind);

  final TaroErrorKind kind;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return ExcludeSemantics(
      child: Icon(
        switch (kind) {
          TaroErrorKind.network => Icons.wifi_off_rounded,
          _ => Icons.error_outline_rounded,
        },
        size: tokens.size.icon.lg,
        color: tokens.color.text.secondary,
      ),
    );
  }
}
