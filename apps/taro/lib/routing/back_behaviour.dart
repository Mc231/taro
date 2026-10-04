import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:taro/l10n/generated/taro_localizations.dart';
import 'package:taro/routing/route_paths.dart';
import 'package:taro_ui/taro_ui.dart';

/// S09 / S32 back behaviour (01 §9.1): back from a reading result returns
/// to the screen it was opened from (Home, or the S15 journal entry) and
/// never into the draw. S08 opens the result over Home ([openFromDraw]), so
/// the app-bar Close, the iOS edge swipe and Android system back all land
/// Home; a result with nothing below it (a cold deep link) goes Home.
class ReadingResultBackScope extends StatelessWidget {
  /// Wraps the reading result [child].
  const ReadingResultBackScope({required this.child, super.key});

  /// The screen.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    // Something below (Home or S15): a plain pop, so the iOS edge swipe works.
    final below = GoRouter.of(context).canPop();
    return PopScope(
      canPop: below,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) context.go(RoutePaths.home);
      },
      child: child,
    );
  }

  /// The app-bar Close / Done of S09 and S32: back to where the result was
  /// opened from, or Home when nothing is below it.
  static void close(BuildContext context) {
    final router = GoRouter.of(context);
    if (router.canPop()) {
      router.pop();
    } else {
      router.go(RoutePaths.home);
    }
  }

  /// S08's hand-off on a completed reading: the flow (S06–S08) is replaced
  /// by Home with the result [location] on top, so back from it is Home.
  static void openFromDraw(BuildContext context, String location) {
    final router = GoRouter.of(context)..go(RoutePaths.home);
    unawaited(router.push<void>(location));
  }
}

/// S08 back behaviour (01 §9.1, S08 "Leaving"): once a card is picked
/// ([confirm]), back and Close ask before leaving the draw; before that it
/// leaves at once. [saved] picks the "your cards are saved" wording (the
/// pending reading is stored once every card is placed).
class DrawBackScope extends StatelessWidget {
  /// Wraps the draw [child].
  const DrawBackScope({
    required this.confirm,
    required this.child,
    this.saved = false,
    super.key,
  });

  /// Whether leaving needs a confirmation (a card has been picked).
  final bool confirm;

  /// Whether the picked cards are already stored.
  final bool saved;

  /// The screen.
  final Widget child;

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !confirm,
    onPopInvokedWithResult: (didPop, _) {
      if (!didPop) unawaited(confirmLeave(context, saved: saved));
    },
    child: child,
  );

  /// "Leave this reading?" with equal-weight Leave / Stay buttons; Leave goes
  /// Home.
  static Future<void> confirmLeave(
    BuildContext context, {
    bool saved = false,
  }) async {
    final l10n = TaroLocalizations.of(context);
    final leave = await TaroDialog.show<bool>(
      context,
      dismissible: true,
      builder: (dialog) => TaroDialog(
        title: l10n.drawLeaveTitle,
        body: saved ? l10n.drawLeaveBodySaved : l10n.drawLeaveBody,
        actions: [
          TaroButton.secondary(
            label: l10n.drawLeaveConfirm,
            expand: true,
            onPressed: () => Navigator.of(dialog).pop(true),
          ),
          TaroButton.secondary(
            label: l10n.drawLeaveStay,
            expand: true,
            onPressed: () => Navigator.of(dialog).pop(false),
          ),
        ],
      ),
    );
    if ((leave ?? false) && context.mounted) {
      context.go(RoutePaths.home);
    }
  }
}
