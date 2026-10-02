import 'package:flutter/widgets.dart';

final RegExp _inline = RegExp(r'\*\*(.+?)\*\*|\[([^\]]+)\]\([^)]*\)');

/// The inline Markdown of a bundled article paragraph (`**bold**` and
/// `[label](url)`, 01 §7.9) as spans in [style]: bold runs in
/// `FontWeight.w600`, links reduced to their label (articles open no
/// links; the view adds its own actions).
TextSpan inlineMarkdown(String text, TextStyle style) {
  final spans = <InlineSpan>[];
  var at = 0;
  for (final match in _inline.allMatches(text)) {
    if (match.start > at) {
      spans.add(TextSpan(text: text.substring(at, match.start)));
    }
    final bold = match.group(1);
    spans.add(
      bold != null
          ? TextSpan(
              text: bold,
              style: const TextStyle(fontWeight: FontWeight.w600),
            )
          : TextSpan(text: match.group(2)),
    );
    at = match.end;
  }
  if (at < text.length) spans.add(TextSpan(text: text.substring(at)));
  return TextSpan(style: style, children: spans);
}
