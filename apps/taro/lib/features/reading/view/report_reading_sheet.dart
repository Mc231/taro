import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:taro/features/reading/controller/report_reading_controller.dart';
import 'package:taro/l10n/generated/taro_localizations.dart';
import 'package:taro_core/taro_core.dart';
import 'package:taro_ui/taro_ui.dart';

/// S33 Report reading (01 §8.3, CS7, RC72): a modal sheet from S09 / S15
/// with the reason chips (none pre-selected), an optional note of at most
/// 500 characters and the 90-day disclosure in every form state.
class ReportReadingSheet extends ConsumerStatefulWidget {
  /// Creates the sheet for the reading [id].
  const ReportReadingSheet({required this.id, super.key});

  /// The reported reading.
  final ReadingId id;

  @override
  ConsumerState<ReportReadingSheet> createState() => _ReportReadingSheetState();
}

class _ReportReadingSheetState extends ConsumerState<ReportReadingSheet> {
  final TextEditingController _note = TextEditingController();

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = reportReadingControllerProvider(widget.id);
    ref.listen(provider, (previous, next) {
      if (next is! ReportReadingSubmitted ||
          previous is ReportReadingSubmitted) {
        return;
      }
      // `submitted`: the sheet closes and a toast thanks the user (S33).
      final message = TaroLocalizations.of(context).reportSubmitted;
      TaroToast.show(context, message: message);
      unawaited(Navigator.of(context).maybePop());
    });
    final state = ref.watch(provider);
    final controller = ref.read(provider.notifier);
    return ReportReadingLayout(
      state: state,
      note: _note,
      onReason: controller.selectReason,
      onNote: controller.updateNote,
      onSend: () => unawaited(controller.submit()),
      onClose: () => Navigator.of(context).maybePop(),
    );
  }
}

/// The S33 layout for [state].
class ReportReadingLayout extends StatelessWidget {
  /// Creates the view.
  const ReportReadingLayout({
    required this.state,
    required this.note,
    required this.onReason,
    required this.onNote,
    required this.onSend,
    required this.onClose,
    super.key,
  });

  /// The controller state.
  final ReportReadingState state;

  /// The note field's text.
  final TextEditingController note;

  /// A reason chip was selected.
  final ValueChanged<ReportReason> onReason;

  /// The note changed.
  final ValueChanged<String> onNote;

  /// **Send** (or Retry after `failed`).
  final VoidCallback onSend;

  /// Closes the sheet.
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final l10n = TaroLocalizations.of(context);
    final tokens = context.tokens;
    final cancel = TaroButton.secondary(
      label: l10n.commonCancel,
      expand: true,
      onPressed: onClose,
    );
    final draft = switch (state) {
      ReportReadingEditing(:final draft) ||
      ReportReadingSubmitting(:final draft) ||
      ReportReadingFailed(:final draft) ||
      ReportReadingOffline(:final draft) ||
      ReportReadingRateLimited(:final draft) => draft,
      ReportReadingSubmitted() || ReportReadingAlreadyReported() => null,
    };
    if (draft == null) {
      return TaroSheet(
        title: l10n.reportReadingTitle,
        actions: [
          TaroButton.secondary(
            label: l10n.commonClose,
            expand: true,
            onPressed: onClose,
          ),
        ],
        child: TaroInlineNotice(
          kind: TaroNoticeKind.success,
          liveRegion: true,
          title: state is ReportReadingSubmitted
              ? l10n.reportSubmitted
              : l10n.readingReported,
        ),
      );
    }
    final submitting = state is ReportReadingSubmitting;
    final canSend =
        draft.canSend &&
        switch (state) {
          ReportReadingEditing() || ReportReadingFailed() => true,
          _ => false,
        };
    final notice = switch (state) {
      ReportReadingOffline() => (TaroNoticeKind.warning, l10n.reportOffline),
      ReportReadingRateLimited() => (
        TaroNoticeKind.warning,
        l10n.reportRateLimited,
      ),
      ReportReadingFailed() => (TaroNoticeKind.error, l10n.reportFailed),
      _ => null,
    };
    final caption = tokens.typography.caption.copyWith(
      color: tokens.color.text.secondary,
    );
    return TaroSheet(
      title: l10n.reportReadingTitle,
      actions: [
        if (notice != null)
          TaroInlineNotice(
            kind: notice.$1,
            title: notice.$2,
            liveRegion: true,
          ),
        TaroButton.primary(
          label: state is ReportReadingFailed
              ? l10n.commonRetry
              : l10n.reportSend,
          expand: true,
          loading: submitting,
          loadingSemanticsHint: l10n.commonLoading,
          onPressed: canSend ? onSend : null,
        ),
        if (!draft.canSend)
          Text(
            l10n.reportChooseReason,
            textAlign: TextAlign.center,
            style: caption,
          ),
        cancel,
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: tokens.space.s4,
        children: [
          Text(
            l10n.reportBody,
            style: tokens.typography.label.copyWith(
              color: tokens.color.text.secondary,
            ),
          ),
          Semantics(
            header: true,
            child: Text(l10n.reportReasonLegend, style: caption),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final reason in ReportReason.values)
                TaroRadioTile<ReportReason>(
                  value: reason,
                  groupValue: draft.reason,
                  title: _reasonLabel(l10n, reason),
                  onChanged: submitting ? null : onReason,
                ),
            ],
          ),
          TaroTextField(
            controller: note,
            style: TaroTextFieldStyle.multiLine,
            label: l10n.reportDetailsLabel,
            hintText: l10n.reportDetailsHint,
            maxGraphemes: ReportReading.noteMaxLength,
            counterVisibleFrom: 0,
            counterFormatter: l10n.commonNoteCounter,
            enabled: !submitting,
            onChanged: onNote,
          ),
          // The `reportReadingDisclosure` panel (05 §3, CS7).
          DecoratedBox(
            decoration: BoxDecoration(
              color: tokens.color.bg.surface,
              borderRadius: BorderRadius.circular(tokens.radius.md),
            ),
            child: Padding(
              padding: EdgeInsetsDirectional.all(tokens.space.s4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: tokens.space.s3,
                children: [
                  Icon(
                    Icons.info_outline,
                    size: tokens.size.icon.md,
                    color: tokens.color.text.secondary,
                  ),
                  Expanded(
                    child: Text(l10n.reportReadingDisclosure, style: caption),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _reasonLabel(TaroLocalizations l10n, ReportReason reason) =>
      switch (reason) {
        ReportReason.offensive => l10n.reportReasonOffensive,
        ReportReason.harmfulAdvice => l10n.reportReasonHarmfulAdvice,
        ReportReason.sexual => l10n.reportReasonSexual,
        ReportReason.hateful => l10n.reportReasonHateful,
        ReportReason.other => l10n.reportReasonOther,
      };
}
