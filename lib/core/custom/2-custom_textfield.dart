/// Module: core
///
///*************************** FILE INFO ****************************///
/// File Name: custom_textfield.dart
/// Purpose: Declares `CustomTextField`.
/// Author: Manger Plus team
/// Updated: 11/8/2026 - Added the standard module + FILE INFO header.

import 'package:flutter/material.dart';
import 'package:asec/core/helper/main_helper/localized_number.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:asec/core/constants/app_assets.dart';
import 'package:asec/core/custom/32-custom_svg.dart';
import 'package:asec/core/theme/app_colors.dart';
import 'package:asec/core/theme/app_padding.dart';
import 'package:asec/core/theme/app_radius.dart';
import 'package:asec/core/theme/app_theme.dart';
import 'package:asec/core/helper/main_helper/format_helper.dart';

/// Custom text field widget — mirrors CustomDropdown API exactly.
///
/// Border rule: NO border by default; red border only when [errorText] is set.
///
/// Type-size rule (16/8/2026): the LABEL is always 14.sp and the HINT always
/// 12.sp. [labelStyle] and [hintStyle] still control colour, weight and the
/// rest — only the font size is fixed by the widget.
class CustomTextField extends StatefulWidget {
  // ── Controller / Focus ───────────────────────────────────────────────────

  /// Text editing controller. If null an internal one is created.
  final TextEditingController? controller;

  /// Focus node. If null an internal one is created.
  final FocusNode? focusNode;

  // ── Content ──────────────────────────────────────────────────────────────

  /// Initial value (only used when [controller] is null).
  final String? initialValue;

  /// Placeholder text.
  final String? hint;

  /// Label displayed above the field.
  final String? label;

  /// Error message — also triggers the red border.
  final String? errorText;

  /// Helper text displayed below the field.
  final String? helperText;

  // ── Icons ────────────────────────────────────────────────────────────────

  /// Widget shown at the start of the field.
  final Widget? prefixIcon;

  /// Widget shown at the end of the field (overrides the password-toggle eye).
  final Widget? suffixIcon;

  // ── Behaviour ────────────────────────────────────────────────────────────

  /// Whether the field is interactive.
  final bool enabled;

  /// Whether the field is read-only (tappable but not editable).
  final bool readOnly;

  /// Adds a red " *" to the label.
  final bool required;

  /// Hides text (password mode). Shows an eye-toggle unless [suffixIcon] is
  /// provided.
  final bool obscureText;

  /// The character shown for each hidden glyph while [obscureText] is on.
  /// Defaults to the Flutter default '•'; pass '*' for a star mask.
  final String obscuringCharacter;

  /// Maximum number of lines. 1 = single-line (default). null = unlimited.
  final int? maxLines;

  /// Minimum number of lines for multiline fields.
  final int? minLines;

  /// Hard character limit. Shows a counter when set.
  final int? maxLength;

  /// Keyboard type.
  final TextInputType? keyboardType;

  /// Input formatters (e.g. digits-only).
  final List<TextInputFormatter>? inputFormatters;

  /// Text alignment inside the field.
  final TextAlign textAlign;

  /// Text direction (useful for RTL/LTR mixed content).
  final TextDirection? textDirection;

  /// Action button on the keyboard.
  final TextInputAction? textInputAction;

  /// Auto-capitalisation strategy.
  final TextCapitalization textCapitalization;

  /// Whether to enable autocorrect.
  final bool autocorrect;

  /// Whether to show text-suggestions.
  final bool enableSuggestions;

  // ── Callbacks ────────────────────────────────────────────────────────────

  /// Called on every keystroke.
  final ValueChanged<String>? onChanged;

  /// Called when the user submits (presses the keyboard action button).
  final ValueChanged<String>? onSubmitted;

  /// Called when the field gains or loses focus.
  final ValueChanged<bool>? onFocusChanged;

  /// Called when the field is tapped (useful when [readOnly] is true).
  final VoidCallback? onTap;

  // ── Appearance ───────────────────────────────────────────────────────────

  /// Background fill color.
  final Color? fillColor;

  /// Border radius — defaults to 8.r internally.
  final BorderRadius? borderRadius;

  /// Padding inside the field container.
  final EdgeInsetsGeometry? contentPadding;

  // ── Text styles ──────────────────────────────────────────────────────────

  final TextStyle? valueStyle;

  /// Hint style. Its font SIZE is ignored — the hint is always 12.sp,
  /// unless [hintFontSize] is given.
  final TextStyle? hintStyle;

  /// Optional override for the hint's font size (in `.sp`). Defaults to 12.sp
  /// to preserve the app-wide rule; pass e.g. 16 for a field that needs a
  /// larger placeholder (the User-Management search box).
  final double? hintFontSize;

  /// Label style. Its font SIZE is ignored — the label is always 14.sp.
  final TextStyle? labelStyle;
  final TextStyle? errorStyle;
  final TextStyle? helperStyle;
  final TextStyle? counterStyle;

  // ── Sizing (optional fixed box) ────────────────────────────────────────────

  /// Fixed width (interpreted in .sp). Null → expands to parent.
  final double? width;

  /// Fixed height (interpreted in .sp). Null → sizes to content.
  final double? height;

  // ── Built-in validation (opt-in) ───────────────────────────────────────────

  /// When true, an empty field shows a "required" error (use after a submit
  /// attempt). Only takes effect together with the other validation flags.
  final bool submitted;

  /// Restricts input to digits and validates the value is numeric.
  final bool onlyDigits;

  /// Restricts input to the script implied by [textDirection]
  /// (Arabic for RTL, English otherwise) and validates accordingly.
  final bool restrictByDirection;

  /// Auto-capitalises the first letter of each word (LTR, non-digit only).
  final bool autoCapitalize;

  /// Shows a character counter even when [maxLength] is null (limit = 500).
  final bool showCharCount;

  /// Suppress the counter WITHOUT giving up the character limit.
  ///
  /// ADDED 2/9/2026. [_showCounter] treats any [maxLength] as "show a
  /// counter", so a field that just wants a hard cap — the group name, capped
  /// at 100 — had no way to keep the cap and lose the "0 / 100" line. Passing
  /// `showCharCount: false` did nothing, because maxLength alone was enough.
  ///
  /// Defaults to false, so every existing field keeps the counter it has.
  final bool hideCounter;

  const CustomTextField({
    super.key,
    this.controller,
    this.focusNode,
    this.initialValue,
    this.hint,
    this.label,
    this.errorText,
    this.helperText,
    this.prefixIcon,
    this.suffixIcon,
    this.enabled = true,
    this.readOnly = false,
    this.required = false,
    this.obscureText = false,
    this.obscuringCharacter = '•',
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.keyboardType,
    this.inputFormatters,
    this.textAlign = TextAlign.start,
    this.textDirection,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.autocorrect = true,
    this.enableSuggestions = true,
    this.onChanged,
    this.onSubmitted,
    this.onFocusChanged,
    this.onTap,
    this.fillColor,
    this.borderRadius,
    this.contentPadding,
    this.valueStyle,
    this.hintStyle,
    this.hintFontSize,
    this.labelStyle,
    this.errorStyle,
    this.helperStyle,
    this.counterStyle,
    this.width,
    this.height,
    this.submitted = false,
    this.onlyDigits = false,
    this.restrictByDirection = false,
    this.autoCapitalize = false,
    this.showCharCount = false,
    this.hideCounter = false,
  });

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  late FocusNode _focusNode;
  late TextEditingController _controller;
  bool _ownsController = false;
  bool _ownsFocusNode = false;
  bool _obscured = true; // tracks password visibility toggle

  // Live character count (only needed when maxLength is set)
  int _charCount = 0;

  @override
  void initState() {
    super.initState();

    // Controller
    if (widget.controller != null) {
      _controller = widget.controller!;
    } else {
      _controller = TextEditingController(text: widget.initialValue);
      _ownsController = true;
    }

    // Focus node
    if (widget.focusNode != null) {
      _focusNode = widget.focusNode!;
    } else {
      _focusNode = FocusNode();
      _ownsFocusNode = true;
    }

    _focusNode.addListener(_onFocusChange);

    if (_needsTextListener) {
      _charCount = _controller.text.length;
      _controller.addListener(_onTextChange);
    }
  }

  /// Adopts a controller or focus node the parent swapped underneath us.
  /// ADDED 16/8/2026.
  ///
  /// THE BUG THIS FIXES
  /// ------------------
  /// [initState] read `widget.controller` once and the state never looked at it
  /// again, so a parent that handed this field a DIFFERENT controller on a
  /// later build kept talking to the first one. When the parent then disposed
  /// that first controller — the normal thing to do with a controller you have
  /// replaced — the next rebuild threw:
  ///
  ///     A TextEditingController was used after being disposed.
  ///
  /// from `TextField`'s own `didUpdateWidget`, because the field was still
  /// wired to the dead object. `create_table_page` hits this every time its
  /// column list is replaced: it builds fresh controllers per column id and
  /// disposes the old ones after the frame.
  ///
  /// A `State` that caches anything out of its widget owes it a
  /// `didUpdateWidget`. This is that debt paid.
  ///
  /// ORDER MATTERS: the listener comes off the OLD object before the new one is
  /// adopted, and the old one is disposed only if WE made it. `removeListener`
  /// is documented as safe on an already-disposed notifier, which is what makes
  /// the parent-disposes-first ordering survivable; `addListener` is not, so it
  /// only ever touches the new one.
  @override
  void didUpdateWidget(CustomTextField oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.controller != oldWidget.controller) {
      final TextEditingController previous = _controller;
      final bool previousWasOurs = _ownsController;

      previous.removeListener(_onTextChange);

      if (widget.controller != null) {
        _controller = widget.controller!;
        _ownsController = false;
      } else {
        // The parent stopped supplying one. Keep the text on screen rather than
        // blanking the field — `.text` is a plain getter and stays readable on
        // a disposed controller, so this is safe even in the ordering above.
        _controller = TextEditingController(text: previous.text);
        _ownsController = true;
      }

      if (_needsTextListener) {
        _charCount = _controller.text.length;
        _controller.addListener(_onTextChange);
      }

      // Ours to dispose only if we created it. An external controller belongs
      // to the parent and disposing it here would break the caller's next use.
      if (previousWasOurs) previous.dispose();
    } else if (_needsTextListener != _neededTextListener(oldWidget)) {
      // Same controller, but the field just gained or lost its counter /
      // validation, which is what decides whether the listener is wanted.
      if (_needsTextListener) {
        _charCount = _controller.text.length;
        _controller.addListener(_onTextChange);
      } else {
        _controller.removeListener(_onTextChange);
      }
    }

    if (widget.focusNode != oldWidget.focusNode) {
      final FocusNode previous = _focusNode;
      final bool previousWasOurs = _ownsFocusNode;

      previous.removeListener(_onFocusChange);

      if (widget.focusNode != null) {
        _focusNode = widget.focusNode!;
        _ownsFocusNode = false;
      } else {
        _focusNode = FocusNode();
        _ownsFocusNode = true;
      }

      _focusNode.addListener(_onFocusChange);
      if (previousWasOurs) previous.dispose();
    }
  }

  /// [_needsTextListener] evaluated against a PREVIOUS widget, so
  /// [didUpdateWidget] can tell whether the answer changed.
  bool _neededTextListener(CustomTextField old) =>
      old.showCharCount ||
      old.maxLength != null ||
      old.submitted ||
      old.onlyDigits ||
      old.restrictByDirection;

  void _onFocusChange() {
    if (!mounted) return;
    setState(() {}); // rebuild so suffix eye-icon tint can update if needed
    widget.onFocusChanged?.call(_focusNode.hasFocus);
  }

  void _onTextChange() {
    if (!mounted) return;
    setState(() => _charCount = _controller.text.length);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    if (_ownsFocusNode) _focusNode.dispose();
    // UNCONDITIONAL (16/8/2026), was gated on `_needsTextListener`. That getter
    // reads the CURRENT widget, so a field that had a counter when the listener
    // was attached and lost it before disposal left the listener behind on a
    // controller the parent goes on using. `removeListener` is a no-op when
    // there is nothing to remove, and is safe on a disposed notifier.
    _controller.removeListener(_onTextChange);
    if (_ownsController) _controller.dispose();
    super.dispose();
  }

  bool get _isMultiline => (widget.maxLines ?? 1) != 1 || widget.minLines != null;

  /// Whether the input should STRETCH to fill the fixed box instead of sizing
  /// itself to its line count.
  ///
  /// FIXED 22/8/2026 — this is the "space between the field and the counter"
  /// bug. The field is wrapped in `SizedBox(height: …)`, but a `TextField` does
  /// not fill a tight height: `InputDecorator` lays its container out at the
  /// height its CONTENT needs and only the RenderBox is stretched to the
  /// constraint. The filled background is painted over `containerHeight`, so
  /// when the box is taller than seven lines of text the remainder is
  /// transparent dead space — invisible, but still occupying layout, which is
  /// exactly the gap that pushed `158 / 500` away from the bottom of the box.
  ///
  /// `expands: true` makes the input take the full height it is given, so the
  /// painted box ends where the SizedBox ends and the counter sits right under
  /// it. It requires `maxLines` and `minLines` to both be null, hence the
  /// overrides below; the character limit is enforced by `maxLength`, not by
  /// the line count, so nothing is lost.
  ///
  /// Single-line fields are deliberately excluded: `expands` would let them
  /// accept newlines.
  bool get _fillsHeight => widget.height != null && _isMultiline;

  // ── Opt-in helpers ─────────────────────────────────────────────────────────

  /// Effective character limit: explicit [maxLength], else 500 when a counter
  /// is requested, else none.
  int? get _effectiveMaxLength =>
      widget.maxLength ?? (widget.showCharCount ? 500 : null);

  bool get _showCounter =>
      !widget.hideCounter && (widget.showCharCount || widget.maxLength != null);

  /// Locale whose numerals the character counter uses.
  ///
  /// Keyed off the field's own [CustomTextField.textDirection] so a bilingual
  /// form counts each side in its own script, falling back to the active
  /// locale when the field does not state a direction.
  String _counterLocale(BuildContext context) {
    switch (widget.textDirection) {
      case TextDirection.rtl:
        return 'ar';
      case TextDirection.ltr:
        return 'en';
      case null:
        return Localizations.localeOf(context).languageCode;
    }
  }

  bool get _hasValidation =>
      widget.submitted || widget.onlyDigits || widget.restrictByDirection;

  bool get _needsTextListener => _showCounter || _hasValidation;

  /// Resolves the error to display: explicit [errorText] wins, otherwise the
  /// built-in validation (only active when a validation flag is set).
  String? get _resolvedError {
    final explicit = widget.errorText;
    if (explicit != null && explicit.isNotEmpty) return explicit;
    if (!_hasValidation) return null;

    final text = _controller.text;
    final isEmpty = text.trim().isEmpty;
    final isRtl = widget.textDirection == TextDirection.rtl;
    final hasArabic = RegExp(r'[؀-ۿ]').hasMatch(text);

    if (widget.submitted && isEmpty) {
      return isRtl ? 'هذا الحقل مطلوب' : 'This field is required.';
    }
    if (!isEmpty && widget.restrictByDirection) {
      if (!isRtl && hasArabic) return 'Please use English characters only.';

      // FIXED 26/8/2026 — the RTL branch used to be a WHITELIST:
      //
      //     if (isRtl && !RegExp(r'^[؀-ۿ\s]+$').hasMatch(text))
      //
      // which demanded the whole value be Arabic letters and whitespace and
      // nothing else. That rejected every ASCII punctuation mark a real
      // sentence needs — `.` `,` `(` `)` `"` `'` `:` `;` — and Latin digits
      // with them, so an ordinary Arabic service description like
      // "…وتحديد السجلات الناقصة." was marked invalid over its own full stop.
      // Arabic punctuation passed only by accident: `،` `؛` `؟` sit inside the
      // 0600–06FF block, so the whitelist admitted them while refusing their
      // ASCII equivalents — the same mark, accepted or rejected depending on
      // which keyboard produced it.
      //
      // It also disagreed with the rule actually being ENFORCED.
      // [_ArabicOnlyInputFormatter] blocks `[a-zA-Z]` and nothing else, so the
      // formatter let the user type a full stop and the validator then failed
      // the field for containing it: two different definitions of "Arabic
      // only" in one widget, and the stricter one had no formatter behind it
      // to stop the input in the first place.
      //
      // Now a BLACKLIST, mirroring both the formatter and the LTR branch
      // directly above. The field objects to the foreign SCRIPT — which is
      // what its message says — and stays out of the way of punctuation,
      // numbers and symbols.
      if (isRtl && RegExp(r'[a-zA-Z]').hasMatch(text)) {
        return 'الرجاء استخدام الأحرف العربية فقط.';
      }
    }
    if (widget.onlyDigits &&
        text.isNotEmpty &&
        !RegExp(r'^\d+$').hasMatch(text)) {
      return 'Only numbers are allowed.';
    }
    return null;
  }

  /// Builds input formatters from the opt-in flags, then appends any caller
  /// supplied [inputFormatters].
  List<TextInputFormatter>? get _resolvedFormatters {
    final list = <TextInputFormatter>[];
    if (widget.autoCapitalize &&
        widget.textDirection != TextDirection.rtl &&
        !widget.onlyDigits) {
      list.add(_CapitalizeTextFormatter());
    }
    if (widget.restrictByDirection) {
      if (widget.textDirection == TextDirection.rtl) {
        list.add(_ArabicOnlyInputFormatter());
      } else if (!widget.onlyDigits) {
        list.add(_EnglishOnlyInputFormatter());
      }
    }
    if (widget.onlyDigits) {
      list.add(FilteringTextInputFormatter.digitsOnly);
    }
    if (widget.inputFormatters != null) list.addAll(widget.inputFormatters!);
    return list.isEmpty ? null : list;
  }

  // Effective obscure: only applies when the prop is true AND not multiline
  bool get _effectiveObscure =>
      widget.obscureText && !_isMultiline && _obscured;

  @override
  Widget build(BuildContext context) {
    final resolvedError = _resolvedError;
    final hasError = resolvedError != null && resolvedError.isNotEmpty;
    final radius = widget.borderRadius ?? AppRadius.fieldR;
    final isDisabled = !widget.enabled;

    // ── Suffix icon resolution ─────────────────────────────────────────────
    // Priority: explicit suffixIcon > password-toggle eye > nothing
    Widget? resolvedSuffix = widget.suffixIcon;
    if (resolvedSuffix == null && widget.obscureText && !_isMultiline) {
      resolvedSuffix = GestureDetector(
        onTap: () => setState(() => _obscured = !_obscured),
        child: CustomSvgImage(
          // One glyph, not two: the library has no eye pair, and the field's
          // own contents already say whether the password is showing.
          assetPath: AppAssets.lock,
          width: 20.sp,
          height: 20.sp,
          color: hasError
              ? AppColors.red
              : isDisabled
                  ? AppColors.text.withOpacity(0.3)
                  : _obscured
                      ? AppColors.text.withOpacity(0.5)
                      : AppColors.secondaryPrimary,
        ),
      );
    }

    // ── Content padding ────────────────────────────────────────────────────
    final effectivePadding = widget.contentPadding ??
        EdgeInsets.symmetric(horizontal: AppPadding.h, vertical: 10.sp);

    // ── Label 14.sp / hint 12.sp, ALWAYS (16/8/2026) ───────────────────────
    //
    // The two sizes are the field's contract, not a default a caller can talk
    // it out of. [CustomTextField.labelStyle] and [CustomTextField.hintStyle]
    // still decide colour, weight, letter spacing and everything else — the
    // font SIZE is reapplied on top of whatever comes in.
    //
    // This is a rule and not a suggestion because the call sites had drifted
    // the other way round: several form cards pass a 12pt label and a 14pt
    // hint, so the placeholder was rendering LARGER than the field's own title
    // and the forms disagreed with each other screen by screen. Fixing the
    // callers one at a time fixes today's screens; fixing it here is what
    // makes tomorrow's screen right without anyone remembering the rule.
    final double labelFontSize = 14.sp;
    final double hintFontSize = (widget.hintFontSize ?? 12).sp;

    final TextStyle labelStyle = (widget.labelStyle ??
            StyleText.fontSize14Weight500.copyWith(
              color: hasError
                  ? AppColors.red
                  : isDisabled
                      ? AppColors.text
                      : AppColors.text,
            ))
        .copyWith(fontSize: labelFontSize);

    final TextStyle hintStyle = (widget.hintStyle ??
            StyleText.fontSize12Weight400.copyWith(
              color: AppColors.text.withOpacity(0.4),
            ))
        .copyWith(fontSize: hintFontSize);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Label ──────────────────────────────────────────────────────────
        if (widget.label != null) ...[
          RichText(
            text: TextSpan(
              text: widget.label,
              style: labelStyle,
              children: widget.required
                  ? [
                TextSpan(
                  text: '',
                  // Same size as the label it trails, so the asterisk cannot
                  // sit off the title's baseline.
                  style: StyleText.fontSize14Weight500.copyWith(
                    color: AppColors.red,
                    fontSize: labelFontSize,
                  ),
                ),
              ]
                  : [],
            ),
          ),
          SizedBox(height: 6.sp),
        ],

        // ── Field ──────────────────────────────────────────────────────────
        SizedBox(
          width: widget.width?.sp,
          height: widget.height?.sp,
          child: TextField(
          controller: _controller,
          focusNode: _focusNode,
          enabled: widget.enabled,
          readOnly: widget.readOnly,
          obscureText: _effectiveObscure,
          obscuringCharacter: widget.obscuringCharacter,
          // `expands: true` requires BOTH of these to be null — see
          // [_fillsHeight]. `textAlignVertical: top` keeps the caret on the
          // first line of the stretched box instead of centring it.
          maxLines: widget.obscureText ? 1 : (_fillsHeight ? null : widget.maxLines),
          minLines: _fillsHeight ? null : widget.minLines,
          expands: _fillsHeight,
          textAlignVertical:
              _fillsHeight ? TextAlignVertical.top : null,
          maxLength: _effectiveMaxLength,
          keyboardType: _isMultiline
              ? TextInputType.multiline
              : (widget.keyboardType ??
                  (widget.onlyDigits ? TextInputType.number : null)),
          inputFormatters: _resolvedFormatters,
          textAlign: widget.textAlign,
          textDirection: widget.textDirection,
          textInputAction: widget.textInputAction,
          textCapitalization: widget.textCapitalization,
          autocorrect: widget.autocorrect,
          enableSuggestions: widget.enableSuggestions,
          onChanged: widget.onChanged,
          onSubmitted: widget.onSubmitted,
          onTap: widget.onTap,
          // 26/10/2026: a touch anywhere outside the field closes the
          // keyboard — also where the app-wide tap (main.dart) loses the
          // gesture to a list, a table or a button. iOS number pads have no
          // "Done" key, so this is the only way to put them away.
          onTapOutside: (PointerDownEvent _) => _focusNode.unfocus(),
          style: widget.valueStyle ??
              StyleText.fontSize14Weight400.copyWith(
                color: isDisabled
                    ? AppColors.text
                    : AppColors.text,
              ),
          // Hide the built-in counter — we render our own below
          buildCounter: _effectiveMaxLength != null
              ? (_, {required currentLength, required isFocused, maxLength}) =>
          const SizedBox.shrink()
              : null,
          decoration: InputDecoration(
            isDense: true,
            contentPadding: effectivePadding,
            filled: true,
            // No hover overlay tint on desktop/web
            hoverColor: Colors.transparent,
            fillColor: isDisabled
                ? (widget.fillColor ?? AppColors.background)
                : widget.fillColor ?? AppColors.background,

            // ── No border rule ────────────────────────────────────────────
            // Default / focused / disabled → no border at all.
            // Error → red border.
            border: hasError
                ? OutlineInputBorder(
              borderRadius: radius,
              borderSide: BorderSide(color: AppColors.red, width: 1.5.sp),
            )
                : OutlineInputBorder(
              borderRadius: radius,
              borderSide: BorderSide.none,
            ),
            enabledBorder: hasError
                ? OutlineInputBorder(
              borderRadius: radius,
              borderSide: BorderSide(color: AppColors.red, width: 1.5.sp),
            )
                : OutlineInputBorder(
              borderRadius: radius,
              borderSide: BorderSide.none,
            ),
            focusedBorder: hasError
                ? OutlineInputBorder(
              borderRadius: radius,
              borderSide: BorderSide(color: AppColors.red, width: 1.5.sp),
            )
                : OutlineInputBorder(
              borderRadius: radius,
              borderSide: BorderSide.none,
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: radius,
              borderSide: BorderSide.none,
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: radius,
              borderSide: BorderSide(color: AppColors.red, width: 1.5.sp),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: radius,
              borderSide: BorderSide(color: AppColors.red, width: 1.5.sp),
            ),
            // ─────────────────────────────────────────────────────────────

            hintText: widget.hint,
            hintStyle: hintStyle,

            prefixIcon: widget.prefixIcon != null
                ? Padding(
              padding: EdgeInsets.only(left: AppPadding.h,right: AppPadding.h),
              child: widget.prefixIcon,
            )
                : null,
            prefixIconConstraints: const BoxConstraints(),

            suffixIcon: resolvedSuffix != null
                ? Padding(
              padding: EdgeInsets.only(left: AppPadding.h,right: AppPadding.h),
              child: resolvedSuffix,
            )
                : null,
            suffixIconConstraints: const BoxConstraints(),

            // Suppress built-in error / helper — we render our own
            errorText: null,
            helperText: null,
            counterText: '',
          ),
          ),
        ),

        // ── Error / Helper / Counter row ───────────────────────────────────
        if (hasError || widget.helperText != null || _showCounter) ...[
          // TIGHTENED 22/8/2026: a message needs air between it and the field,
          // but a bare character counter is a footnote ON the box — the 4.sp
          // here plus the dead space fixed by [_fillsHeight] read as a stray
          // margin under the field. No gap when the counter is all there is.
          if (hasError || widget.helperText != null) SizedBox(height: 4.sp),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left: error or helper
              Expanded(
                child: hasError
                    ? Text(
                  FormatHelper.capitalize(resolvedError!),
                  style: widget.errorStyle ??
                      StyleText.fontSize12Weight400.copyWith(color: AppColors.red),
                )
                    : widget.helperText != null
                    ? Text(
                  FormatHelper.capitalize(widget.helperText!),
                  style: widget.helperStyle ??
                      StyleText.fontSize12Weight400.copyWith(
                        color: AppColors.text.withOpacity(0.5),
                      ),
                )
                    : const SizedBox.shrink(),
              ),

              // Right: character counter
              if (_showCounter && _effectiveMaxLength != null) ...[
                SizedBox(width: 8.sp),
                // Forced LTR: "13 / 500" is a numeric expression, so in an RTL
                // field the bidi algorithm would otherwise reorder it to
                // "500 / 13".
                Directionality(
                  textDirection: TextDirection.ltr,
                  child: Text(
                    FormatHelper.capitalize(// FIXED 13/8/2026: the counter was always ASCII, so an
                    // Arabic field showed "0 / 500" under Arabic text. The
                    // numerals follow the field, not the app: an RTL field
                    // counts in Arabic-Indic digits, an explicitly LTR field
                    // stays Latin, and a field that states no direction
                    // follows the active locale.
                    //
                    // The forced LTR wrapper above still matters — "٠ / ٥٠٠"
                    // is a numeric expression and bidi would otherwise flip it
                    // to "٥٠٠ / ٠".
                    '${LocalizedNumber.forLocale(_charCount, _counterLocale(context))}'
                    ' / '
                    '${LocalizedNumber.forLocale(_effectiveMaxLength!, _counterLocale(context))}'),
                    textDirection: TextDirection.ltr,
                    style: widget.counterStyle ??
                        StyleText.fontSize12Weight400.copyWith(
                          color: _charCount > _effectiveMaxLength!
                              ? AppColors.red
                              : AppColors.text.withOpacity(0.4),
                        ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Private input formatters (self-contained — no external dependencies)
// ─────────────────────────────────────────────────────────────────────────────

/// Blocks English letters (used for Arabic/RTL fields).
class _ArabicOnlyInputFormatter extends _ScriptInputFormatter {
  _ArabicOnlyInputFormatter() : super(RegExp(r'[a-zA-Z]'));
}

/// Blocks Arabic characters (used for English/LTR fields).
class _EnglishOnlyInputFormatter extends _ScriptInputFormatter {
  _EnglishOnlyInputFormatter() : super(RegExp(r'[؀-ۿ]'));
}

/// Refuses edits that ADD a character of the wrong script.
///
/// WHY "ADD" AND NOT "CONTAIN"
/// ---------------------------
/// 12/8/2026: both formatters used to reject any value CONTAINING a foreign
/// character, which locks a field that is already holding one — a record saved
/// before the field was restricted, or a resumed draft. Every edit of such a
/// field, backspace included, produces a value that still contains the foreign
/// character, so the rejection fires on the correction as well as on the
/// mistake and the box stops responding entirely with no way for the user to
/// find out why.
///
/// Counting instead of testing keeps the rule the user actually wants ("this
/// box will not take English") while leaving the exit open: an edit that leaves
/// the same number of foreign characters or fewer goes through, so text already
/// there can always be selected, typed over, or deleted.
///
/// Rejecting rather than stripping is deliberate. Silently dropping the Latin
/// half of a pasted "Sales قسم" leaves the user with a value they did not check
/// and did not intend; refusing the paste keeps the clipboard intact so they
/// can put it in the field it belongs to.
abstract class _ScriptInputFormatter extends TextInputFormatter {
  _ScriptInputFormatter(this._foreign);

  final RegExp _foreign;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final int added = _count(newValue.text) - _count(oldValue.text);
    return added > 0 ? oldValue : newValue;
  }

  int _count(String text) => _foreign.allMatches(text).length;
}

/// Capitalises the first letter of every word.
class _CapitalizeTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) return newValue;

    final List<String> words = newValue.text.split(' ');
    int i = -1;
    final capitalizedText = words.map((word) {
      i++;
      if (word.isEmpty) return word;
      // Small joining words stay small: "Tips and Tricks".
      if (word.length > 1 && isSmallWord(word) && !startsPart(words, i)) {
        return word.toLowerCase();
      }
      if (word.length == 1) return word.toUpperCase();
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');

    return TextEditingValue(
      text: capitalizedText,
      selection: TextSelection.collapsed(offset: capitalizedText.length),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Usage examples
// ─────────────────────────────────────────────────────────────────────────────

/*
// ── Simple text ──────────────────────────────────────────────────────────────
CustomTextField(
  label: 'Full Name',
  hint: 'Enter your name',
  required: true,
  prefixIcon: CustomSvgImage(assetPath: AppAssets.person, width: 18.sp, height: 18.sp),
  onChanged: (v) {},
)

// ── Password ─────────────────────────────────────────────────────────────────
CustomTextField(
  label: 'Password',
  hint: 'Enter password',
  required: true,
  obscureText: true,
  textInputAction: TextInputAction.done,
)

// ── Multiline ────────────────────────────────────────────────────────────────
CustomTextField(
  label: 'Notes',
  hint: 'Write something…',
  maxLines: 5,
  minLines: 3,
  maxLength: 500,
  helperText: 'Max 500 characters',
)

// ── Read-only ────────────────────────────────────────────────────────────────
CustomTextField(
  label: 'Email',
  controller: TextEditingController(text: 'amr@example.com'),
  readOnly: true,
  prefixIcon: CustomSvgImage(assetPath: AppAssets.email, width: 18.sp, height: 18.sp),
)

// ── Digits only ──────────────────────────────────────────────────────────────
CustomTextField(
  label: 'Phone',
  hint: '05xxxxxxxx',
  keyboardType: TextInputType.phone,
  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
  maxLength: 10,
)

// ── Error state ──────────────────────────────────────────────────────────────
CustomTextField(
  label: 'Username',
  errorText: 'Username is already taken',
)

// ── Disabled ─────────────────────────────────────────────────────────────────
CustomTextField(
  label: 'Role',
  controller: TextEditingController(text: 'Admin'),
  enabled: false,
)
*/
