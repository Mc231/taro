import 'package:flutter/material.dart';
import 'package:taro_ui/src/components/actions/taro_button.dart';
import 'package:taro_ui/src/components/state/taro_state_layout.dart';
import 'package:taro_ui/src/theme/taro_tokens_extension.dart';

/// The visual kinds of [TaroErrorView]. Mirrors `taro_core`'s `ErrorKind`
/// (01 §8.2), which `taro_ui` cannot import (RC95); the app maps one onto
/// the other and supplies the localised title, body and action.
enum TaroErrorKind {
  /// No connection.
  network,

  /// The Worker or a store failed.
  server,

  /// Too many requests; try later.
  rateLimited,

  /// Device attestation failed.
  deviceUnverified,

  /// Local storage failed.
  storage,

  /// A chosen file is not usable (S25).
  invalidFile,

  /// Anything else.
  unknown;

  /// The kind's icon (never the only signal: the title names the problem).
  IconData get icon => switch (this) {
    TaroErrorKind.network => Icons.wifi_off_rounded,
    TaroErrorKind.server => Icons.cloud_off_rounded,
    TaroErrorKind.rateLimited => Icons.hourglass_empty_rounded,
    TaroErrorKind.deviceUnverified => Icons.gpp_maybe_outlined,
    TaroErrorKind.storage => Icons.sd_card_alert_outlined,
    TaroErrorKind.invalidFile => Icons.insert_drive_file_outlined,
    TaroErrorKind.unknown => Icons.error_outline_rounded,
  };
}

/// An error state by [kind] with its allowed action (01 §8.2, 02 §14.3):
/// icon in `color.status.error`, `type.title`, `type.body` and a retry
/// button when [onRetry] and [retryLabel] are given. Announced as a live
/// region (01 §12).
class TaroErrorView extends StatelessWidget {
  /// Creates the view.
  const TaroErrorView({
    required this.kind,
    required this.title,
    required this.body,
    this.onRetry,
    this.retryLabel,
    this.secondaryAction,
    super.key,
  });

  /// What went wrong.
  final TaroErrorKind kind;

  /// Localised title.
  final String title;

  /// Localised body.
  final String body;

  /// The retry action; shown with [retryLabel].
  final VoidCallback? onRetry;

  /// Localised retry label ("Try again").
  final String? retryLabel;

  /// Another action (e.g. "Back to Today").
  final Widget? secondaryAction;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final c = tokens.color;
    final badge = tokens.size.touchTarget.min + tokens.space.s5;
    return Semantics(
      container: true,
      liveRegion: true,
      child: TaroStateLayout(
        children: [
          Center(
            child: ExcludeSemantics(
              child: Container(
                width: badge,
                height: badge,
                decoration: BoxDecoration(
                  color: c.bg.surface,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  kind.icon,
                  size: tokens.size.icon.lg,
                  color: c.status.error,
                ),
              ),
            ),
          ),
          SizedBox(height: tokens.space.s7),
          Semantics(
            header: true,
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: tokens.typography.title.copyWith(color: c.text.primary),
            ),
          ),
          SizedBox(height: tokens.space.s3),
          Text(
            body,
            textAlign: TextAlign.center,
            style: tokens.typography.body.copyWith(color: c.text.secondary),
          ),
          if (onRetry != null && retryLabel != null) ...[
            SizedBox(height: tokens.space.s7),
            TaroButton.primary(label: retryLabel!, onPressed: onRetry),
          ],
          if (secondaryAction != null) ...[
            SizedBox(height: tokens.space.s3),
            secondaryAction!,
          ],
        ],
      ),
    );
  }
}
