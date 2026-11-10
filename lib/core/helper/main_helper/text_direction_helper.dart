/// Module: core/helper
///
///*************************** FILE INFO ****************************///
/// File Name: text_direction_helper.dart
/// Purpose: Declares `TextDirectionHelper` — the direction of a piece of text
///          people WROTE (a question, an answer, a post), from the text
///          itself, not from the app's language.
/// Author: ASEC team
/// Created: 06/11/2026
///
/// WHY. An Arabic answer shown in the English app was laid out left-to-right:
/// lines started on the left, "1." stood on the wrong side, the reply card
/// read backwards. Each text now takes the direction of its FIRST real letter
/// (as browsers do with dir="auto"): Arabic → right-to-left, English →
/// left-to-right; numbers and symbols at the start are skipped. A text with
/// no letters keeps the app's direction.
library;

import 'package:flutter/widgets.dart';

abstract final class TextDirectionHelper {
  const TextDirectionHelper._();

  /// Arabic (with its supplements and presentation forms), Hebrew, Syriac,
  /// Thaana, N'Ko — the right-to-left scripts.
  static bool _isRtl(int c) =>
      (c >= 0x0590 && c <= 0x08FF) || (c >= 0xFB1D && c <= 0xFDFF) || (c >= 0xFE70 && c <= 0xFEFF);

  /// A letter of a left-to-right script (Latin, Greek, Cyrillic, …).
  static bool _isLtrLetter(int c) =>
      (c >= 0x41 && c <= 0x5A) || (c >= 0x61 && c <= 0x7A) || (c >= 0x00C0 && c <= 0x058F);

  /// The direction of [text]'s first letter; [fallback] when it has none.
  static TextDirection of(String text, {TextDirection fallback = TextDirection.ltr}) {
    for (final int c in text.runes) {
      if (_isRtl(c)) return TextDirection.rtl;
      if (_isLtrLetter(c)) return TextDirection.ltr;
    }
    return fallback;
  }

  /// [of], falling back to the app's current direction.
  static TextDirection inContext(BuildContext context, String text) =>
      of(text, fallback: Directionality.maybeOf(context) ?? TextDirection.ltr);
}

/// A user-written text laid out in ITS OWN direction, filling the width so an
/// Arabic text sits on the right and an English one on the left whatever the
/// app's language.
class AutoDirectionText extends StatelessWidget {
  const AutoDirectionText(this.text, {super.key, this.style});

  final String text;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final TextDirection dir = TextDirectionHelper.inContext(context, text);
    return SizedBox(
      width: double.infinity,
      child: Text(text, textDirection: dir, textAlign: TextAlign.start, style: style),
    );
  }
}
