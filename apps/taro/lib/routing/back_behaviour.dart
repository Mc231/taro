import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:taro/l10n/generated/taro_localizations.dart';
import 'package:taro/routing/route_paths.dart';

/// S09 back behaviour (01 §9.1): back from a reading result goes Home, not
/// back into the draw.
class ReadingResultBackScope extends StatelessWidget {
  /// Wraps the reading result [child].
  const ReadingResultBackScope({required this.child, super.key});

  /// The screen.
  final Widget child;

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: false,
    onPopInvokedWithResult: (didPop, _) {
      if (!didPop) context.go(RoutePaths.home);
    },
    child: child,
  );
}

/// S08 back behaviour (01 §9.1): once a card is picked ([confirm]), back
/// asks before leaving the draw; before that it leaves at once.
class DrawBackScope extends StatelessWidget {
  /// Wraps the draw [child].
  const DrawBackScope({required this.confirm, required this.child, super.key});

  /// Whether leaving needs a confirmation (a card has been picked).
  final bool confirm;

  /// The screen.
  final Widget child;

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !confirm,
    onPopInvokedWithResult: (didPop, _) {
      if (!didPop) unawaited(_confirmLeave(context));
    },
    child: child,
  );

  Future<void> _confirmLeave(BuildContext context) async {
    final l10n = TaroLocalizations.of(context);
    final leave = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: Text(l10n.drawLeaveTitle),
        content: Text(l10n.drawLeaveBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialog).pop(false),
            child: Text(l10n.drawLeaveStay),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialog).pop(true),
            child: Text(l10n.drawLeaveConfirm),
          ),
        ],
      ),
    );
    if ((leave ?? false) && context.mounted) {
      context.go(RoutePaths.home);
    }
  }
}
