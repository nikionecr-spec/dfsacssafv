import 'package:flutter/material.dart';

/// A [TextEditingController] that renders markdown syntax highlighting *inside*
/// the editable field, without changing the underlying text.
///
/// The trick is to override [buildTextSpan] and return a styled span tree whose
/// concatenated text is byte-for-byte identical to `text` — that guarantees the
/// caret and selection stay perfectly aligned. Highlighting is line-based
/// (headings, quotes, fenced code, list markers) with a small inline pass for
/// bold / italic / code / links.
class MarkdownEditingController extends TextEditingController {
  MarkdownEditingController({super.text});

  static final RegExp _heading = RegExp(r'^#{1,6}\s');
  static final RegExp _listMarker = RegExp(r'^(\s*(?:[-*+]|\d+\.)\s)');
  static final RegExp _inline = RegExp(
    r'(`[^`]+`)'          // inline code
    r'|(\*\*.+?\*\*)'     // **bold**
    r'|(__.+?__)'         // __bold__
    r'|(\*[^*]+?\*)'      // *italic*
    r'|(_[^_]+?_)'        // _italic_
    r'|(\[[^\]]+\]\([^)]+\))', // [text](url)
  );

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final TextStyle base = style ?? const TextStyle();
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final List<InlineSpan> spans = <InlineSpan>[];
    final List<String> lines = text.split('\n');
    bool inFence = false;

    for (int i = 0; i < lines.length; i++) {
      final String line = lines[i];
      final String trimmed = line.trimLeft();

      if (trimmed.startsWith('```')) {
        inFence = !inFence;
        spans.add(TextSpan(
          text: line,
          style: base.copyWith(fontFamily: 'monospace', color: scheme.tertiary),
        ));
      } else if (inFence) {
        spans.add(TextSpan(
          text: line,
          style: base.copyWith(
              fontFamily: 'monospace', color: scheme.onSurfaceVariant),
        ));
      } else if (_heading.hasMatch(trimmed)) {
        spans.add(TextSpan(
          text: line,
          style: base.copyWith(
              fontWeight: FontWeight.w800, color: scheme.primary),
        ));
      } else if (trimmed.startsWith('>')) {
        spans.add(TextSpan(
          text: line,
          style: base.copyWith(
              color: scheme.onSurfaceVariant, fontStyle: FontStyle.italic),
        ));
      } else {
        _appendLine(spans, line, base, scheme);
      }

      if (i != lines.length - 1) {
        spans.add(TextSpan(text: '\n', style: base));
      }
    }

    return TextSpan(style: base, children: spans);
  }

  void _appendLine(
    List<InlineSpan> spans,
    String line,
    TextStyle base,
    ColorScheme scheme,
  ) {
    int start = 0;
    final RegExpMatch? marker = _listMarker.firstMatch(line);
    if (marker != null) {
      spans.add(TextSpan(
        text: marker.group(0),
        style: base.copyWith(color: scheme.primary, fontWeight: FontWeight.w700),
      ));
      start = marker.end;
    }
    _appendInline(spans, line.substring(start), base, scheme);
  }

  void _appendInline(
    List<InlineSpan> spans,
    String s,
    TextStyle base,
    ColorScheme scheme,
  ) {
    if (s.isEmpty) return;
    int last = 0;
    for (final RegExpMatch m in _inline.allMatches(s)) {
      if (m.start > last) {
        spans.add(TextSpan(text: s.substring(last, m.start), style: base));
      }
      final String g = m.group(0)!;
      late final TextStyle st;
      if (m.group(1) != null) {
        st = base.copyWith(
          fontFamily: 'monospace',
          color: scheme.tertiary,
          backgroundColor: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
        );
      } else if (m.group(2) != null || m.group(3) != null) {
        st = base.copyWith(fontWeight: FontWeight.w800);
      } else if (m.group(4) != null || m.group(5) != null) {
        st = base.copyWith(fontStyle: FontStyle.italic);
      } else {
        st = base.copyWith(
            color: scheme.primary, decoration: TextDecoration.underline);
      }
      spans.add(TextSpan(text: g, style: st));
      last = m.end;
    }
    if (last < s.length) {
      spans.add(TextSpan(text: s.substring(last), style: base));
    }
  }
}
