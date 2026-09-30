import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'att_preprompt_controller.freezed.dart';

/// The neutral in-app ATT pre-prompt (05 CS14, RC19): shown after UMP and
/// before the system prompt, when `ads.attPrepromptEnabled`.
@freezed
sealed class AttPrePromptState with _$AttPrePromptState {
  /// Nothing shown.
  const factory AttPrePromptState.hidden() = AttPrePromptHidden;

  /// The pre-prompt is up; its single **Continue** leads to the system
  /// prompt (no "deny" styling, no incentive).
  const factory AttPrePromptState.visible() = AttPrePromptVisible;
}

/// Drives the pre-prompt for `ConsentOrchestrator.prePrompt`: [request]
/// shows it and completes when the user continues ([proceed]).
final class AttPrePromptController extends Notifier<AttPrePromptState> {
  Completer<void>? _pending;

  @override
  AttPrePromptState build() {
    ref.onDispose(() => _pending?.complete());
    return const AttPrePromptState.hidden();
  }

  /// Shows the pre-prompt; completes after [proceed]. A second request
  /// while visible joins the first.
  Future<void> request() {
    final pending = _pending ??= Completer<void>();
    state = const AttPrePromptState.visible();
    return pending.future;
  }

  /// **Continue**: hides the pre-prompt; the system prompt follows.
  void proceed() {
    final pending = _pending;
    _pending = null;
    state = const AttPrePromptState.hidden();
    pending?.complete();
  }
}

/// The ATT pre-prompt (`attPrePromptProvider`, keep-alive: the
/// orchestrator awaits it from outside the widget tree).
final attPrePromptProvider =
    NotifierProvider<AttPrePromptController, AttPrePromptState>(
      AttPrePromptController.new,
    );
