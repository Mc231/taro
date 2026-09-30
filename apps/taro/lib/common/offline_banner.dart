import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:taro/app_state/connectivity_controller.dart';
import 'package:taro/l10n/generated/taro_localizations.dart';
import 'package:taro_ui/taro_ui.dart';

/// The non-blocking offline banner (01 §8.2): a [TaroOfflineBanner] while
/// `connectivityProvider` reports offline, nothing otherwise. Put it in
/// `TaroScaffold.topBanner` of any screen that needs the network (S05
/// `balanceStale`, S07 `offline`, S33 `offline`, S29 terms/privacy).
///
/// [message] replaces the default "You're offline. Your journal still
/// works."; [onRetry] adds a Retry action.
class OfflineBanner extends ConsumerWidget {
  /// Creates the banner.
  const OfflineBanner({this.message, this.onRetry, super.key});

  /// A screen-specific localised message.
  final String? message;

  /// Retries the screen's request.
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final online = ref.watch(connectivityProvider);
    if (online) return const SizedBox.shrink();
    final l10n = TaroLocalizations.of(context);
    return TaroOfflineBanner(
      message: message ?? l10n.offlineBanner,
      actionLabel: onRetry == null ? null : l10n.commonRetry,
      onAction: onRetry,
    );
  }
}
