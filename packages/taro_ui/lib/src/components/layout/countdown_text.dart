import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:taro_ui/src/theme/taro_tokens_extension.dart';

/// How often [CountdownText] recomputes the remaining time. The copy has
/// minute precision ("in 5 h 12 min"), so a minute is enough; this is a
/// refresh cadence, not a visual duration (CLAUDE.md rule 15, RC90).
const Duration kCountdownRefreshInterval = Duration(minutes: 1);

/// Formats the remaining time into localised copy, e.g. "in 5 h 12 min".
typedef CountdownFormatter = String Function(Duration remaining);

/// Server-time based relative time (02 §14.3): "Next free in 5 h 12 min",
/// "Available again in 4 min". Never a fake timer (CLAUDE.md rule 11): the
/// target is the server's instant (`free.resetsAt`, a cooldown end), and
/// "now" comes from the app's `Clock` port through [now] (`taro_ui` never
/// reads the wall clock itself).
///
/// States: future ([format] of the remaining time), reached
/// ([reachedText], and [onReached] fires once so the app re-syncs), unknown
/// (`target == null`: [unknownText], e.g. offline copy). The text refreshes
/// every [refreshInterval]; it is not a live region (a per-minute
/// announcement would be noise).
class CountdownText extends StatefulWidget {
  /// Creates the text.
  const CountdownText({
    required this.target,
    required this.now,
    required this.format,
    required this.reachedText,
    required this.unknownText,
    this.onReached,
    this.refreshInterval = kCountdownRefreshInterval,
    this.style,
    this.textAlign,
    super.key,
  });

  /// The server instant counted down to; null when unknown.
  final DateTime? target;

  /// The current time (the app passes `clock.now`).
  final DateTime Function() now;

  /// Copy for a positive remaining time.
  final CountdownFormatter format;

  /// Copy once [target] has passed ("Your free reading is ready").
  final String reachedText;

  /// Copy when [target] is null.
  final String unknownText;

  /// Called once when [target] passes, to re-sync with the server.
  final VoidCallback? onReached;

  /// How often the text recomputes.
  final Duration refreshInterval;

  /// Overrides `type.body` in `color.text.secondary`.
  final TextStyle? style;

  /// Text alignment (directional).
  final TextAlign? textAlign;

  @override
  State<CountdownText> createState() => _CountdownTextState();
}

class _CountdownTextState extends State<CountdownText> {
  Timer? _timer;
  DateTime? _reportedFor;

  @override
  void initState() {
    super.initState();
    _schedule();
  }

  @override
  void didUpdateWidget(CountdownText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.target != widget.target ||
        oldWidget.refreshInterval != widget.refreshInterval) {
      _schedule();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _schedule() {
    _timer?.cancel();
    _timer = null;
    if (widget.target == null) return;
    _timer = Timer.periodic(widget.refreshInterval, (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final target = widget.target;
    final String text;
    if (target == null) {
      text = widget.unknownText;
    } else {
      final remaining = target.difference(widget.now());
      if (remaining > Duration.zero) {
        text = widget.format(remaining);
      } else {
        text = widget.reachedText;
        _timer?.cancel();
        if (_reportedFor != target) {
          _reportedFor = target;
          final onReached = widget.onReached;
          if (onReached != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) => onReached());
          }
        }
      }
    }
    return Text(
      text,
      textAlign: widget.textAlign,
      style:
          widget.style ??
          tokens.typography.body.copyWith(color: tokens.color.text.secondary),
    );
  }
}
