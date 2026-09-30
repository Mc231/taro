import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show NotifierProviderFamily;
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:taro/app_state/connectivity_controller.dart';
import 'package:taro/di/providers.dart';
import 'package:taro_core/taro_core.dart';

part 'report_reading_controller.freezed.dart';

/// The S33 form: a reason chip and an optional note (≤ 500 characters).
@freezed
abstract class ReportDraft with _$ReportDraft {
  /// Creates a draft.
  const factory ReportDraft({ReportReason? reason, @Default('') String note}) =
      _ReportDraft;

  const ReportDraft._();

  /// Whether **Send** is enabled (a reason is required).
  bool get canSend => reason != null;
}

/// S33 Report reading (01 §8.3, CS7, RC72). The disclosure ("Your question
/// and this reading will be sent to Taro and kept for 90 days") is shown in
/// every form state by the view.
@freezed
sealed class ReportReadingState with _$ReportReadingState {
  /// The form.
  const factory ReportReadingState.editing(ReportDraft draft) =
      ReportReadingEditing;

  /// Sending.
  const factory ReportReadingState.submitting(ReportDraft draft) =
      ReportReadingSubmitting;

  /// Sent; the local `reported` flag is set.
  const factory ReportReadingState.submitted() = ReportReadingSubmitted;

  /// Sending failed: Retry.
  const factory ReportReadingState.failed(
    ReportDraft draft, {
    required Failure failure,
  }) = ReportReadingFailed;

  /// Offline: Send disabled with a notice.
  const factory ReportReadingState.offline(ReportDraft draft) =
      ReportReadingOffline;

  /// 10 reports per local day reached.
  const factory ReportReadingState.rateLimited(ReportDraft draft) =
      ReportReadingRateLimited;

  /// Already reported: the sheet is not reopened.
  const factory ReportReadingState.alreadyReported() =
      ReportReadingAlreadyReported;
}

/// S33 over the `ReportReading` use case (02 §9.9).
final class ReportReadingController extends Notifier<ReportReadingState> {
  /// A controller for the reading [id].
  ReportReadingController(this.id);

  /// The reported reading.
  final ReadingId id;

  ReportDraft _draft = const ReportDraft();
  Reading? _reading;

  @override
  ReportReadingState build() {
    ref.listen<bool>(connectivityProvider, (previous, online) {
      final current = state;
      if (!online && current is ReportReadingEditing) {
        state = ReportReadingState.offline(_draft);
      } else if (online && current is ReportReadingOffline) {
        state = ReportReadingState.editing(_draft);
      }
    });
    unawaited(Future.microtask(_load));
    return ReportReadingState.editing(_draft);
  }

  Future<void> _load() async {
    final stored = await ref.read(readingRepositoryProvider).get(id);
    if (!ref.mounted) return;
    _reading = stored.valueOrNull;
    if (_reading?.reported ?? false) {
      state = const ReportReadingState.alreadyReported();
    } else if (!ref.read(connectivityProvider)) {
      state = ReportReadingState.offline(_draft);
    }
  }

  /// A reason chip was selected.
  void selectReason(ReportReason reason) =>
      _edit(_draft.copyWith(reason: reason));

  /// The note changed; clamped to 500 characters.
  void updateNote(String note) => _edit(
    _draft.copyWith(
      note: QuestionPrecheck.limit(
        note,
        maxChars: ReportReading.noteMaxLength,
      ),
    ),
  );

  void _edit(ReportDraft draft) {
    _draft = draft;
    state = switch (state) {
      ReportReadingOffline() => ReportReadingState.offline(draft),
      ReportReadingSubmitted() ||
      ReportReadingAlreadyReported() ||
      ReportReadingSubmitting() => state,
      _ => ReportReadingState.editing(draft),
    };
  }

  /// **Send** (or Retry after `failed`).
  Future<void> submit() async {
    final reason = _draft.reason;
    final current = state;
    final sendable = switch (current) {
      ReportReadingEditing() || ReportReadingFailed() => true,
      _ => false,
    };
    if (reason == null || !sendable) return;
    state = ReportReadingState.submitting(_draft);
    final result = await ref
        .read(reportReadingProvider)
        .call(id, reason, note: _draft.note);
    if (!ref.mounted) return;
    switch (result) {
      case Ok():
        state = const ReportReadingState.submitted();
        final reading = _reading;
        await ref
            .read(analyticsServiceProvider)
            .log(
              ReadingReportedEvent(
                spread: reading == null
                    ? AnalyticsSpread.unknown
                    : AnalyticsSpread.fromId(reading.spreadId),
                reason: reason,
              ),
            );
      case Err(failure: RateLimitedFailure()):
        state = ReportReadingState.rateLimited(_draft);
      case Err(:final failure):
        state = ReportReadingState.failed(_draft, failure: failure);
    }
  }
}

/// S33 (`reportReadingControllerProvider(readingId)`).
final NotifierProviderFamily<
  ReportReadingController,
  ReportReadingState,
  ReadingId
>
reportReadingControllerProvider = NotifierProvider.autoDispose.family(
  ReportReadingController.new,
);
