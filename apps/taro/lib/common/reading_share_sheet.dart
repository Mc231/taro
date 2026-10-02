import 'package:flutter/material.dart';
import 'package:taro/l10n/generated/taro_localizations.dart';
import 'package:taro_ui/taro_ui.dart';

/// The share options of a reading (S09, S15): "Include my question" is off
/// by default (PR19).
class ReadingShareSheet extends StatefulWidget {
  /// Creates the sheet; the chip shows only when [hasQuestion].
  const ReadingShareSheet({required this.hasQuestion, super.key});

  /// Whether the reading has a question to include.
  final bool hasQuestion;

  /// Shows the sheet; completes with "include the question" when the user
  /// taps Share, `null` when dismissed.
  static Future<bool?> show(
    BuildContext context, {
    required bool hasQuestion,
  }) => TaroSheet.show<bool>(
    context,
    builder: (_) => ReadingShareSheet(hasQuestion: hasQuestion),
  );

  @override
  State<ReadingShareSheet> createState() => _ReadingShareSheetState();
}

class _ReadingShareSheetState extends State<ReadingShareSheet> {
  bool _includeQuestion = false;

  @override
  Widget build(BuildContext context) {
    final l10n = TaroLocalizations.of(context);
    return TaroSheet(
      title: l10n.shareTitle,
      actions: [
        TaroButton.primary(
          label: l10n.commonShare,
          expand: true,
          onPressed: () => Navigator.of(context).pop(_includeQuestion),
        ),
      ],
      child: widget.hasQuestion
          ? Align(
              alignment: AlignmentDirectional.centerStart,
              child: TaroChip.filter(
                label: l10n.shareIncludeQuestion,
                selected: _includeQuestion,
                onSelected: (on) => setState(() => _includeQuestion = on),
              ),
            )
          : const SizedBox.shrink(),
    );
  }
}
