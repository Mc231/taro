import 'dart:async';

import 'package:flutter/material.dart';
import 'package:taro_ui/src/components/reading/reading_section_header.dart';
import 'package:taro_ui/src/components/state/skeleton_block.dart';
import 'package:taro_ui/src/components/state/taro_shimmer.dart';
import 'package:taro_ui/src/motion/taro_motion.dart';
import 'package:taro_ui/src/theme/taro_tokens_extension.dart';

/// One section of a [ReadingTextView].
@immutable
class ReadingTextSection {
  /// Creates the section.
  const ReadingTextSection({required this.body, this.heading, this.subheading});

  /// Localised heading, drawn with `ReadingSectionHeader`.
  final String? heading;

  /// Localised sub-line of the heading.
  final String? subheading;

  /// The section text; blank lines separate paragraphs.
  final String body;
}

/// Long-form, selectable reading text (02 §14.3): the quoted question, the
/// source label, the reading title (`type.headline`) and the sections in
/// `type.bodyReading`, capped at `layout.readingMaxWidth` and start-aligned.
///
/// * [reveal]: the sections enter with a `motion.ritual.readingReveal`
///   stagger (fade + `space.3` rise, `motion.easing.decelerate`); under
///   reduced motion everything appears at once.
/// * [ReadingTextView.loading]: skeleton lines (the loading-from-storage
///   state) announced with [ReadingTextView.loadingLabel].
///
/// The text wraps and never truncates at 200 % (01 §12); the host scrolls.
class ReadingTextView extends StatefulWidget {
  /// Creates the text.
  const ReadingTextView({
    required this.sections,
    this.question,
    this.sourceLabel,
    this.title,
    this.footer,
    this.reveal = false,
    super.key,
  }) : loadingLabel = null;

  /// The loading-from-storage skeleton.
  const ReadingTextView.loading({required String this.loadingLabel, super.key})
    : sections = const [],
      question = null,
      sourceLabel = null,
      title = null,
      footer = null,
      reveal = false;

  /// The question, already quoted for the locale.
  final String? question;

  /// The source label (`AiGeneratedLabel`).
  final Widget? sourceLabel;

  /// Localised reading title.
  final String? title;

  /// The sections.
  final List<ReadingTextSection> sections;

  /// A trailing widget (the app's `DisclaimerFooter`).
  final Widget? footer;

  /// Whether to play the reveal stagger.
  final bool reveal;

  /// Screen-reader label of the loading state.
  final String? loadingLabel;

  @override
  State<ReadingTextView> createState() => _ReadingTextViewState();
}

class _ReadingTextViewState extends State<ReadingTextView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, value: 1);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (widget.reveal && !context.reduceMotion) {
      final ritual = context.motion.ritual.readingReveal;
      final blocks = _blockCount;
      _controller
        ..duration = ritual + ritual * ((blocks - 1) / 4)
        ..value = 0;
      unawaited(_controller.forward());
    }
  }

  int get _blockCount =>
      (widget.title == null ? 0 : 1) + widget.sections.length;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _staggered(int index, Widget child) {
    if (_controller.value == 1 && !_controller.isAnimating) return child;
    final blocks = _blockCount;
    final span = 1 / (1 + (blocks - 1) / 4);
    final start = index * span / 4;
    final interval = Interval(
      start.clamp(0, 1),
      (start + span).clamp(0, 1),
      curve: context.motion.easing.decelerate,
    );
    final rise = context.tokens.space.s3;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = interval.transform(_controller.value);
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, (1 - t) * rise),
            child: child,
          ),
        );
      },
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final c = tokens.color;
    if (widget.loadingLabel != null) {
      return Semantics(
        label: widget.loadingLabel,
        liveRegion: true,
        child: TaroShimmer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: tokens.space.s3,
            children: [
              SkeletonBlock(height: tokens.space.s8),
              SizedBox(height: tokens.space.s2),
              for (var i = 0; i < 6; i++) const SkeletonBlock(),
            ],
          ),
        ),
      );
    }
    final reading = tokens.typography.bodyReading.copyWith(
      color: c.text.primary,
    );
    var block = 0;
    final children = <Widget>[
      if (widget.question != null)
        Text(
          widget.question!,
          style: tokens.typography.body.copyWith(
            color: c.text.secondary,
            fontStyle: FontStyle.italic,
          ),
        ),
      if (widget.sourceLabel != null)
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: widget.sourceLabel,
        ),
      if (widget.title != null)
        _staggered(
          block++,
          Semantics(
            header: true,
            child: Text(
              widget.title!,
              style: tokens.typography.headline.copyWith(
                color: c.text.primary,
              ),
            ),
          ),
        ),
      for (final section in widget.sections)
        _staggered(
          block++,
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: tokens.space.s3,
            children: [
              if (section.heading != null)
                ReadingSectionHeader(
                  title: section.heading!,
                  subtitle: section.subheading,
                ),
              for (final paragraph in section.body.split(RegExp(r'\n\s*\n')))
                Text(paragraph.trim(), style: reading),
            ],
          ),
        ),
      ?widget.footer,
    ];
    return Align(
      alignment: AlignmentDirectional.topStart,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: tokens.layout.readingMaxWidth),
        child: SelectionArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            spacing: tokens.space.s5,
            children: children,
          ),
        ),
      ),
    );
  }
}
