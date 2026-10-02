import 'dart:async';

import 'package:flutter/material.dart';
import 'package:taro/l10n/generated/taro_localizations.dart';
import 'package:taro_ui/taro_ui.dart';

/// "Delete this entry?" with Delete and Cancel (S14 swipe/menu, S15 "Delete
/// entry"); completes with `true` only on Delete.
Future<bool> confirmJournalDelete(BuildContext context) async {
  final l10n = TaroLocalizations.of(context);
  final confirmed = await TaroDialog.show<bool>(
    context,
    dismissible: true,
    builder: (dialog) => TaroDialog(
      title: l10n.journalDeleteTitle,
      body: l10n.journalDeleteBody,
      actions: [
        TaroButton.secondary(
          label: l10n.commonCancel,
          onPressed: () => Navigator.of(dialog).pop(false),
        ),
        TaroButton.destructive(
          label: l10n.commonDelete,
          onPressed: () => Navigator.of(dialog).pop(true),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}

/// The "Entry deleted" toast with Undo (01 §7.8): it floats above the
/// bottom slot (the banner keeps its `space.adGap`) and lives in the app's
/// `ScaffoldMessenger`, so it stays visible after S15 pops back to S14.
final class JournalUndoToast {
  JournalUndoToast._(this._toast) {
    unawaited(_toast.closed.whenComplete(() => _open = false));
  }

  /// Shows the toast; [onUndo] runs on Undo (which also closes it).
  factory JournalUndoToast.show(
    BuildContext context, {
    required VoidCallback onUndo,
  }) {
    final l10n = TaroLocalizations.of(context);
    return JournalUndoToast._(
      TaroToast.show(
        context,
        message: l10n.journalDeleted,
        actionLabel: l10n.commonUndo,
        onAction: onUndo,
      ),
    );
  }

  final ScaffoldFeatureController<SnackBar, SnackBarClosedReason> _toast;
  bool _open = true;

  /// Completes when the toast has gone.
  Future<SnackBarClosedReason> get closed => _toast.closed;

  /// Hides the toast when the undo window ends (no-op once it has gone).
  void close() {
    if (!_open) return;
    _open = false;
    _toast.close();
  }
}
