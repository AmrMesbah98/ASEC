/// Module: core
///
///*************************** FILE INFO ****************************///
/// File Name: custom_dropdown.dart
/// Purpose: Declares `DropdownItem`.
/// Author: Manger Plus team
/// Updated: 11/8/2026 - Added the standard module + FILE INFO header.

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:asec/core/theme/app_colors.dart';
import 'package:asec/core/theme/app_padding.dart';
import 'package:asec/core/theme/app_radius.dart';
import 'package:asec/core/theme/app_theme.dart';
import 'package:asec/core/custom/111-app_svg_icon.dart';
import 'package:asec/core/helper/main_helper/format_helper.dart';

/// The one placeholder colour every dropdown in the app uses.
///
/// ADDED 19/8/2026 — the hint colour used to be whatever a caller happened to
/// pass in `hintStyle`, and the three dropdowns disagreed about the default:
/// `AppColors.text.withOpacity(0.4)` here and on the range calendar, plain
/// `AppColors.secondaryText` on the date calendar. Two of those sitting on one
/// row showed two different greys.
///
/// It is NOT a parameter any more. `hintStyle` still owns size, weight and
/// family — the colour is reapplied on top of whatever the caller passes, so
/// `hintStyle: ....copyWith(color: Colors.red)` is silently ignored rather
/// than allowed to drift. Both calendar dropdowns import this rather than
/// keeping a copy, which is what let them drift in the first place.
///
/// A getter, not a `const`: `AppColors.secondaryText` resolves against the
/// active theme, so this has to be read at build time.
Color get kDropdownHintColor => AppColors.secondaryText.withOpacity(0.5);

/// Vertical gap between a field's label and the field itself.
///
/// ADDED 29/8/2026. Three controls that routinely stand side by side in one row
/// each had their own idea of this gap — `CustomDropdown` used 3,
/// `CustomDropdownCalendar` used 6, and screens that hand-roll a labelled box
/// (Adding New Access) used 8. Since the gap sits ABOVE the field, a different
/// gap means the FIELDS start at different heights: a row of three read as
/// stepped rather than aligned, and no amount of matching the field heights
/// fixed it.
///
/// Raw, not `.sp`: callers apply `.sp` at the point of use, so a value that has
/// already been scaled is never scaled twice.
///
/// Anything drawing a label above a field should use this rather than its own
/// number — that is the whole point of it being here.
const double kFieldLabelGap = 6;

/// A dropdown item model
class DropdownItem<T> {
  final T value;
  final String label;
  final Widget? leading;
  final Widget? trailing;
  final bool enabled;

  const DropdownItem({
    required this.value,
    required this.label,
    this.leading,
    this.trailing,
    this.enabled = true,
  });
}

/// Custom dropdown widget
class CustomDropdown<T> extends StatefulWidget {
  final T? value;
  final List<DropdownItem<T>> items;
  final ValueChanged<T>? onChanged;
  final String? hint;
  final String? label;
  final String? errorText;
  final String? helperText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool enabled;
  final bool required;
  final Color? fillColor;
  final double? maxOverlayHeight;
  final EdgeInsetsGeometry? triggerPadding;

  /// Fixed height for the TRIGGER, or null to let it size itself. ADDED
  /// 17/8/2026; every existing dropdown leaves it null and is unaffected.
  ///
  /// INTERPRETED IN `.sp` and scaled here — pass the raw design number (`36`),
  /// not `36.sp`, exactly as `CustomTextField.height` documents. A pre-scaled
  /// value would be scaled twice.
  ///
  /// It sizes the TRIGGER only, never the label or the error line: a dropdown
  /// with a label is a Column of three pieces, and pinning the whole Column
  /// would squeeze the label instead of the box.
  ///
  /// Prefer this over [triggerPadding] when the box has to match something of
  /// a known height — a 46pt table row, a field beside it. `contentPadding`
  /// pads the input AREA, not the trigger (see `CustomSortButton`), so padding
  /// is the wrong lever for a target height.
  final double? height;

  /// Whether the suffix slot is BUILT AT ALL. ADDED 16/8/2026.
  ///
  /// Passing `suffixIcon: SizedBox(width: 0)` was not enough to get rid of it:
  /// the slot was still created, still wrapped in its `Padding`, and — because
  /// `InputDecorator` lays the suffix out after the input area — it kept that
  /// area alive on the right of the trigger. On a form field that is invisible;
  /// on `CustomSortButton`, a 100.sp button with no chevron, it read as a hole
  /// after the label.
  ///
  /// False builds no suffix at all, so the trigger ends at the prefix.
  /// Defaults to true, so every existing dropdown keeps its chevron.
  final bool showSuffixIcon;

  /// Padding around [prefixIcon] / [suffixIcon] inside the trigger.
  ///
  /// ADDED 16/8/2026. These used to be hardcoded at 12/8 and 8/12, which is
  /// right for a full-width form field and far too generous for a compact
  /// toolbar button: on a 100.sp sort button the two of them plus the icon ate
  /// everything but ~20pt, so the label rendered as "Sor". Left null they keep
  /// the original values, so every existing form field is untouched.
  final EdgeInsetsGeometry? prefixIconPadding;
  final EdgeInsetsGeometry? suffixIconPadding;

  /// Whether the 14.sp label / 12.sp hint rule is applied. ADDED 16/8/2026.
  ///
  /// True for every FORM dropdown, which is what the rule is about: a dropdown
  /// sits beside a `CustomTextField` in every form in the app, so the two have
  /// to agree about how big a title and a placeholder are.
  ///
  /// `CustomSortButton` sets it false. It is not a form field — it is a toolbar
  /// button that happens to be built from this widget, its "hint" is the button
  /// LABEL, and next to the 14.sp Filter button beside it a 12.sp "Sort" would
  /// just look like a mistake.
  final bool enforceTypeScale;

  /// Keeps [hint] on the trigger even after something is selected, instead of
  /// swapping it for the selected item's label. ADDED 16/8/2026.
  ///
  /// For a form field the selected value IS the answer, so replacing the hint
  /// with it is right. For an ACTION button — Sort — the label names what the
  /// button does, and swapping it for "Last Updated" leaves a control on the
  /// toolbar that no longer says what it is. The selection is still shown, both
  /// by the highlighted row in the menu and by the button's own fill; it just
  /// is not shown by overwriting the label.
  ///
  /// Defaults to false, so every existing dropdown behaves exactly as before.
  final bool alwaysShowHint;

  /// Corner radius for both the trigger and the open overlay.
  ///
  /// Optional — when null it defaults to `AppRadius.fieldR`, so every
  /// existing dropdown keeps its current look. Pass a value to override (e.g.
  /// `AppRadius.fieldR`).
  final BorderRadius? borderRadius;
  final TextStyle? valueStyle;

  /// Size / weight / family of the placeholder.
  ///
  /// The COLOUR is not taken from here — it is always [kDropdownHintColor].
  final TextStyle? hintStyle;
  final TextStyle? itemStyle;
  final TextStyle? labelStyle;
  final TextStyle? errorStyle;
  final TextStyle? helperStyle;
  final double? itemHeight;
  final double overlayElevation;
  final double? overlayOffset;
  final bool showDivider;
  final Color? dividerColor;
  final Widget? emptyWidget;
  final VoidCallback? onOpen;
  final VoidCallback? onClose;

  const CustomDropdown({
    super.key,
    required this.items,
    this.value,
    this.onChanged,
    this.hint,
    this.label,
    this.errorText,
    this.helperText,
    this.prefixIcon,
    this.suffixIcon,
    this.enabled = true,
    this.required = false,
    this.fillColor,
    this.maxOverlayHeight,
    this.triggerPadding,
    this.height,
    this.prefixIconPadding,
    this.suffixIconPadding,
    this.showSuffixIcon = true,
    this.enforceTypeScale = true,
    this.alwaysShowHint = false,
    this.borderRadius,
    this.valueStyle,
    this.hintStyle,
    this.itemStyle,
    this.labelStyle,
    this.errorStyle,
    this.helperStyle,
    this.itemHeight,
    this.overlayElevation = 4,
    this.overlayOffset,
    this.showDivider = false,
    this.dividerColor,
    this.emptyWidget,
    this.onOpen,
    this.onClose,
  });

  @override
  State<CustomDropdown<T>> createState() => _CustomDropdownState<T>();
}

class _CustomDropdownState<T> extends State<CustomDropdown<T>>
    with SingleTickerProviderStateMixin {
  // ── CompositedTransformTarget link ──────────────────────
  final _layerLink = LayerLink();

  OverlayEntry? _overlayEntry;
  bool _isOpen = false;
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  // We need the trigger height to position the follower below it.
  // We read it after layout via a GlobalKey on the trigger Container.
  final _triggerKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );
    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    // MUST run BEFORE `_animController.dispose()` — see [_removeOverlayEntry].
    // Disposing the controller CANCELS the ticker future, so anything waiting
    // on the close animation to take the entry down never runs.
    _removeOverlayEntry();
    _animController.dispose();
    super.dispose();
  }

  void _toggleDropdown() {
    if (!widget.enabled) return;
    _isOpen ? _closeOverlay() : _openOverlay();
  }

  void _openOverlay() {
    final renderBox =
        _triggerKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final triggerSize = renderBox.size;
    final verticalOffset = widget.overlayOffset ?? 2.sp; // ← 2.sp gap

    // Determine whether to open upward or downward
    final globalOffset = renderBox.localToGlobal(Offset.zero);
    final screenHeight = MediaQuery.of(context).size.height;
    final spaceBelow = screenHeight - globalOffset.dy - triggerSize.height;
    final spaceAbove = globalOffset.dy;
    final openUpward = spaceBelow < 150.sp && spaceAbove > spaceBelow;

    // A previous entry may still be fading out (tap to close, tap again inside
    // the 180ms reverse). Overwriting `_overlayEntry` while it is still
    // inserted would strand it in the Overlay, and its full-screen dismiss
    // layer would keep eating every tap in the app. Drop it first.
    _removeOverlayEntry();

    _overlayEntry = OverlayEntry(
      builder: (_) => _DropdownOverlay<T>(
        layerLink: _layerLink,
        triggerSize: triggerSize,
        verticalOffset: verticalOffset,
        openUpward: openUpward,
        items: widget.items,
        maxHeight: widget.maxOverlayHeight ?? 240.sp,
        itemHeight: widget.itemHeight ?? 36.sp,
        borderRadius: widget.borderRadius ?? AppRadius.fieldR,
        elevation: widget.overlayElevation,
        itemStyle: widget.itemStyle,
        showDivider: widget.showDivider,
        dividerColor: widget.dividerColor,
        emptyWidget: widget.emptyWidget,
        fadeAnimation: _fadeAnimation,
        scaleAnimation: _scaleAnimation,
        selectedValue: widget.value,
        onSelected: (item) {
          _closeOverlay();
          widget.onChanged?.call(item.value);
        },
        onDismiss: _closeOverlay,
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
    _animController.forward(from: 0);
    setState(() => _isOpen = true);
    widget.onOpen?.call();
  }

  /// Takes the overlay entry down NOW, without waiting for the close
  /// animation. Safe to call more than once.
  ///
  /// FIXED 30/8/2026 — RELEASE-ONLY FREEZE AFTER PICKING AN ITEM.
  ///
  /// `_closeOverlay` used to remove the entry only from
  /// `_animController.reverse().then(...)`, i.e. 180ms later. Selecting an item
  /// calls `onChanged`, and every call site keys this widget off the selected
  /// value (`key: ValueKey(selected)`), so the parent's `setState` gives the
  /// dropdown a NEW key on the very next frame: the old `State` is disposed
  /// long before those 180ms are up, and disposing an `AnimationController`
  /// CANCELS its `TickerFuture` — `TickerFuture.then()` listens on the primary
  /// completer, which is never completed on cancel, so the callback simply
  /// never fires and the `OverlayEntry` stays in the Overlay forever.
  ///
  /// The stranded entry is invisible (`showWhenUnlinked: false` hides the menu
  /// once its LayerLink loses the leader) but its `Positioned.fill`
  /// `HitTestBehavior.translucent` dismiss layer is not — it sits over the
  /// whole app and swallows every pointer event. That is the "screen freezes
  /// and nothing responds again" report.
  ///
  /// Debug builds hid it: `_closeOverlay()` ran first in `dispose()` and its
  /// `setState` (`mounted` is still true inside `dispose`) tripped
  /// `markNeedsBuild`'s `_lifecycleState != defunct` assertion, which aborted
  /// `dispose()` before `_animController.dispose()` — the controller survived,
  /// the reverse finished, and the entry was removed. Asserts are compiled out
  /// in release, so there the controller really is disposed and the entry
  /// really does leak. Same code, opposite outcome.
  void _removeOverlayEntry() {
    final OverlayEntry? entry = _overlayEntry;
    if (entry == null) return;
    _overlayEntry = null; // null first: `remove()` must never run twice
    entry.remove();
  }

  void _closeOverlay() {
    final OverlayEntry? entry = _overlayEntry;
    if (entry == null) return;

    // Being disposed / already detached: nothing is left to drive the close
    // animation, so take the entry down immediately.
    if (!mounted) {
      _removeOverlayEntry();
      return;
    }

    setState(() => _isOpen = false);
    widget.onClose?.call();

    // `whenCompleteOrCancel`, not `then`: it also fires when the ticker is
    // cancelled (controller disposed mid-animation), so the entry comes down
    // either way. The identity check keeps it from removing an entry that
    // `dispose()` or a re-open has already dealt with.
    _animController.reverse().whenCompleteOrCancel(() {
      if (identical(_overlayEntry, entry)) _removeOverlayEntry();
    });
  }

  DropdownItem<T>? get _selectedItem {
    try {
      return widget.items.firstWhere((e) => e.value == widget.value);
    } catch (_) {
      return null;
    }
  }

  /// Label 14.sp, hint 12.sp, ALWAYS (16/8/2026).
  ///
  /// The same contract `CustomTextField` carries, and for the same reason: a
  /// dropdown sits next to a text field in every form in the app, so the two
  /// have to agree about how big a title and a placeholder are. They did not —
  /// the hint here defaulted to 14 while the field's was 12, so a Permissions
  /// dropdown beside a Description box showed a visibly larger placeholder.
  ///
  /// [labelStyle] / [hintStyle] still decide colour, weight and everything
  /// else; only the font size is reapplied on top.
  static const double _labelSize = 14;
  static const double _hintSize = 12;

  /// [base] with the scale's size forced on, or untouched when the caller
  /// opted out via [CustomDropdown.enforceTypeScale].
  TextStyle _scaled(TextStyle base, double size) =>
      widget.enforceTypeScale ? base.copyWith(fontSize: size.sp) : base;

  @override
  Widget build(BuildContext context) {
    final hasError = widget.errorText != null && widget.errorText!.isNotEmpty;

    // ── Trigger ──────────────────────────────────────────
    // Uses InputDecorator so the rendered height is pixel-identical to a
    // CustomTextField with the same contentPadding.
    final Widget trigger = _sized(CompositedTransformTarget(
      link: _layerLink,
      child: GestureDetector(
        onTap: _toggleDropdown,
        // InputDecorator asserts it must have a bounded width. When this
        // dropdown is placed in a parent that provides an unbounded width
        // (e.g. a Row/Column without Expanded/Flexible/SizedBox), fall back
        // to sizing the trigger to its intrinsic width so it never crashes
        // with "InputDecorator cannot have an unbounded width".
        child: LayoutBuilder(
          builder: (context, constraints) {
            final trigger = _buildTrigger(context);
            return constraints.maxWidth.isFinite
                ? trigger
                : IntrinsicWidth(child: trigger);
          },
        ),
      ),
    ));

    // NO LABEL, NO ERROR, NO HELPER → NO COLUMN (16/8/2026).
    //
    // The Column below stacks three optional pieces. When none of them are
    // present it wraps a single child and changes nothing visually — but it
    // does change LAYOUT: a Column hands its children UNBOUNDED height, so a
    // caller that sizes this dropdown with a SizedBox (a toolbar button next
    // to other 38pt buttons, say) never reaches the InputDecorator. The
    // decorator then lays out at its own intrinsic height and the Column,
    // pinned to the SizedBox, reports "RenderFlex overflowed by N pixels".
    //
    // Returning the trigger bare lets the caller's constraint through, and
    // InputDecorator already clamps itself to the height it is given — so a
    // bounded parent gets exactly the height it asked for and an unbounded one
    // behaves exactly as before.
    final bool hasSurroundingText =
        widget.label != null || hasError || widget.helperText != null;
    if (!hasSurroundingText) return trigger;

    // ── Label ──────────────────────────────────────────
    final List<Widget> above = <Widget>[
      if (widget.label != null) ...[
        RichText(
          text: TextSpan(
            text: widget.label,
            style: _scaled(
              widget.labelStyle ??
                  StyleText.fontSize14Weight500.copyWith(
                    color: hasError
                        ? AppColors.red
                        : widget.enabled
                            ? AppColors.text
                            : AppColors.text,
                  ),
              _labelSize,
            ),
            children: widget.required
                ? [
                    TextSpan(
                      text: ' *',
                      style: _scaled(
                        StyleText.fontSize14Weight500
                            .copyWith(color: AppColors.red),
                        _labelSize,
                      ),
                    )
                  ]
                : [],
          ),
        ),
        // CHANGED 29/8/2026: was 3. See [kFieldLabelGap].
        SizedBox(height: kFieldLabelGap.sp),
      ],
    ];

    // ── Error / Helper ─────────────────────────────────
    final List<Widget> below = <Widget>[
      if (hasError) ...[
        SizedBox(height: 4.sp),
        Text(
          FormatHelper.capitalize(widget.errorText!),
          style: widget.errorStyle ??
              StyleText.fontSize12Weight400.copyWith(color: AppColors.red),
        ),
      ] else if (widget.helperText != null) ...[
        SizedBox(height: 4.sp),
        Text(
          FormatHelper.capitalize(widget.helperText!),
          style: widget.helperStyle ??
              StyleText.fontSize12Weight400
                  .copyWith(color: AppColors.text.withOpacity(0.5)),
        ),
      ],
    ];

    // A BOUNDED PARENT SIZES THE TRIGGER, NOT THE STACK (18/8/2026).
    //
    // The comment above explains why the no-label case returns the trigger
    // bare. The labelled case had the mirror-image problem and no equivalent
    // guard: label + 6sp + trigger is roughly 63pt, so any caller that wrote
    // `SizedBox(height: 36, child: CustomDropdown(label: ...))` — the obvious
    // way to make a dropdown match a 36pt row of controls, and what several
    // screens actually did — clamped the whole stack and got
    // "A RenderFlex overflowed by 27 pixels on the bottom" pointing at the
    // Column below.
    //
    // `height:` is the parameter that means "size the trigger" (see `_sized`),
    // and call sites should prefer it. But a widget should not paint a red
    // stripe because its caller constrained it: when the incoming height is
    // bounded, hand the label and helper their natural height and let the
    // trigger absorb the remainder, exactly as `height:` would have.
    // Unbounded parents keep the previous behaviour byte for byte.
    // `Flexible(fit: loose)` and not `Expanded`: loose means the trigger keeps
    // its natural height whenever there is room for it, and only gives ground
    // when there is not. `Expanded` would force it to fill, so a dropdown
    // sitting in a tall Row (bounded, but with height to spare) would stretch
    // to the full row — a regression the striped overflow would have hidden.
    //
    // The bounded check is required, not cosmetic: a flex child inside a
    // Column with an unbounded main axis is a hard error in Flutter, and the
    // common case here — a dropdown in a scroll view — is exactly that.
    return LayoutBuilder(
      builder: (context, constraints) {
        final Widget sizedTrigger = constraints.hasBoundedHeight
            ? Flexible(fit: FlexFit.loose, child: ClipRect(child: trigger))
            : trigger;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [...above, sizedTrigger, ...below],
        );
      },
    );
  }

  /// Applies [CustomDropdown.height] to the trigger, or leaves it alone.
  ///
  /// A `SizedBox` rather than a taller `contentPadding`: InputDecorator clamps
  /// itself to the height it is handed (the note in `build` relies on the same
  /// fact), while padding only grows the input area between the prefix and
  /// suffix slots and cannot shrink the trigger below what those slots need.
  Widget _sized(Widget trigger) {
    final double? h = widget.height;
    if (h == null) return trigger;
    // 16/11/2026: a MINIMUM, not a fixed height. On phones (and with a larger
    // system font) the text + 20.sp chevron + padding is taller than a fixed
    // 34–38 box, and the value was cut off. Now the trigger is at least [h]
    // and grows just enough to show its text.
    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: h.sp),
      child: trigger,
    );
  }

  Widget _buildTrigger(BuildContext context) {
    final hasError = widget.errorText != null && widget.errorText!.isNotEmpty;
    final radius = widget.borderRadius ?? AppRadius.fieldR;

    // With [alwaysShowHint] the trigger renders as if nothing were selected —
    // InputDecorator only draws `hintText` while it believes it is empty, so
    // this one flag drives all three of `isEmpty`, `hintText` and the child.
    final DropdownItem<T>? shownItem =
        widget.alwaysShowHint ? null : _selectedItem;

    return InputDecorator(
      key: _triggerKey,
      isFocused: false,
      isEmpty: shownItem == null,
      decoration: InputDecoration(
        isDense: true,
        // 10.sp vertical (16/8/2026, was 12.sp). The trigger carries a
        // 20.sp chevron in its suffix, so its content is already taller
        // than a text field's single line — the same padding on both
        // made every dropdown stand proud of the fields beside it.
        //
        // Callers that pass [triggerPadding] are untouched: the sort
        // button sets its own, and the two role screens that set
        // 8.sp/12.sp meant those numbers.
        contentPadding: widget.triggerPadding ??
            EdgeInsets.symmetric(horizontal: AppPadding.h, vertical: 10.sp),
        filled: true,
        fillColor: widget.enabled
            ? (widget.fillColor ?? AppColors.background)
            : AppColors.background,
        // ── No border rule — red only on error ──────
        // InputDecorator does not trigger errorBorder on its own
        // (no errorText), so we drive the border via enabledBorder.
        border: OutlineInputBorder(
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
        prefixIcon: widget.prefixIcon != null
            ? Padding(
                padding: widget.prefixIconPadding ??
                    EdgeInsets.only(left: AppPadding.h,right: AppPadding.h),
                child: widget.prefixIcon,
              )
            : null,
        prefixIconConstraints: const BoxConstraints(),
        // NO SUFFIX AT ALL when the caller opted out (16/8/2026) —
        // see [showSuffixIcon]. A zero-width child does not do it,
        // because the slot itself is what holds the right-hand space
        // open.
        suffixIcon: !widget.showSuffixIcon
            ? null
            : Padding(
                padding: widget.suffixIconPadding ??
                    EdgeInsets.only(left: AppPadding.h,right: AppPadding.h),
                child: widget.suffixIcon ??
                    AnimatedRotation(
                      turns: _isOpen ? 0.5 : 0,
                      duration: const Duration(milliseconds: 180),
                      child: AppIcon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 20.sp,
                        color: AppColors.secondaryText.withOpacity(.5),
                      ),
                    ),
              ),
        suffixIconConstraints: const BoxConstraints(),
        hintText: shownItem == null ? (widget.hint ?? '') : null,
        // The colour is forced last on purpose — see
        // [kDropdownHintColor]. `hintStyle` still decides size, weight
        // and family; it can no longer decide the grey.
        hintStyle: _scaled(
          (widget.hintStyle ?? StyleText.fontSize12Weight400)
              .copyWith(color: kDropdownHintColor),
          _hintSize,
        ),
        // Suppress built-in error text — we render our own below
        errorText: null,
      ),
      child: shownItem != null
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (shownItem.leading != null) ...[
                  shownItem.leading!,
                  SizedBox(width: 8.sp),
                ],
                Expanded(
                  child: Text(
                    FormatHelper.capitalize(shownItem.label),
                    style: widget.valueStyle ??
                        StyleText.fontSize14Weight400.copyWith(
                          color:
                              widget.enabled ? AppColors.text : AppColors.text,
                        ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            )
          // InputDecorator shows hintText automatically when child
          // isEmpty — but we still need a zero-height child.
          : const SizedBox.shrink(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Overlay widget — now uses CompositedTransformFollower for pixel-perfect
// positioning directly below (or above) the trigger.
// ─────────────────────────────────────────────────────────────────────────────

class _DropdownOverlay<T> extends StatelessWidget {
  final LayerLink layerLink;
  final Size triggerSize;
  final double verticalOffset;
  final bool openUpward;
  final List<DropdownItem<T>> items;
  final double maxHeight;
  final double itemHeight;
  final BorderRadius borderRadius;
  final double elevation;
  final TextStyle? itemStyle;
  final bool showDivider;
  final Color? dividerColor;
  final Widget? emptyWidget;
  final Animation<double> fadeAnimation;
  final Animation<double> scaleAnimation;
  final T? selectedValue;
  final ValueChanged<DropdownItem<T>> onSelected;
  final VoidCallback onDismiss;

  const _DropdownOverlay({
    required this.layerLink,
    required this.triggerSize,
    required this.verticalOffset,
    required this.openUpward,
    required this.items,
    required this.maxHeight,
    required this.itemHeight,
    required this.borderRadius,
    required this.elevation,
    required this.fadeAnimation,
    required this.scaleAnimation,
    required this.onSelected,
    required this.onDismiss,
    this.itemStyle,
    this.showDivider = false,
    this.dividerColor,
    this.emptyWidget,
    this.selectedValue,
  });

  /// Width the OVERLAY needs so the longest item label shows in full (no
  /// ellipsis). Each label is measured with its own text style; the widest
  /// wins, floored at the trigger width (the menu is never narrower than the
  /// button) and capped at the available screen width (so it can't run off
  /// screen). The TRIGGER button width is NOT affected — only the menu grows.
  double _resolveMenuWidth(BuildContext context) {
    final TextStyle baseStyle = itemStyle ?? StyleText.fontSize14Weight400;
    final TextDirection dir = Directionality.of(context);

    // FIXED 2/9/2026 — the painter was measuring at scale 1.0 while the tile
    // below renders through MediaQuery's text scaler. With OS text scaling
    // turned up, every label was measured NARROWER than it draws, so the menu
    // came out too tight and the longest item ellipsised — the "Read Mes…"
    // case on the messages Sort button. Measure with the same scaler the tile
    // paints with.
    final TextScaler scaler = MediaQuery.textScalerOf(context);

    double widest = 0;
    for (final item in items) {
      final tp = TextPainter(
        text: TextSpan(text: item.label, style: baseStyle),
        textDirection: dir,
        textScaler: scaler,
        maxLines: 1,
      )..layout();

      // 12.sp horizontal padding on each side of the tile + a little slack so
      // the glyphs never touch the edge.
      double w = tp.width + (12.sp * 2) + 8.sp;
      if (item.leading != null) w += 20.sp + 8.sp; // approx leading + gap
      if (item.trailing != null) w += 20.sp + 8.sp; // approx trailing + gap
      if (w > widest) widest = w;
    }

    final double screenCap = MediaQuery.of(context).size.width - 32.sp;
    double result = widest < triggerSize.width ? triggerSize.width : widest;
    if (result > screenCap) result = screenCap;
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final double menuWidth = _resolveMenuWidth(context);
    return SizedBox.expand(
      child: Stack(
        children: [
          // Full-screen dismiss layer
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: onDismiss,
            ),
          ),

          // ── CompositedTransformFollower keeps the overlay
          //    anchored directly to the trigger at all times ──
          CompositedTransformFollower(
            link: layerLink,
            showWhenUnlinked: false,
            // When opening downward: anchor top-left of trigger → offset by
            // triggerHeight + gap so overlay top sits right below trigger.
            // When opening upward: anchor top-left of trigger → offset is
            // negative so overlay bottom sits right above trigger.
            targetAnchor: openUpward ? Alignment.topLeft : Alignment.bottomLeft,
            followerAnchor:
                openUpward ? Alignment.bottomLeft : Alignment.topLeft,
            offset: Offset(
              0,
              openUpward ? -verticalOffset : verticalOffset,
            ),
            child: FadeTransition(
              opacity: fadeAnimation,
              child: ScaleTransition(
                scale: scaleAnimation,
                alignment:
                    openUpward ? Alignment.bottomCenter : Alignment.topCenter,
                child: Material(
                  elevation: elevation,
                  borderRadius: borderRadius,
                  color: AppColors.card,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: maxHeight,
                      // Grow the menu to fit the widest item (see
                      // [_resolveMenuWidth]); never narrower than the trigger.
                      minWidth: menuWidth,
                      maxWidth: menuWidth,
                    ),
                    child: ClipRRect(
                      borderRadius: borderRadius,
                      child: items.isEmpty
                          ? SizedBox(
                              height: itemHeight,
                              child: emptyWidget ??
                                  Center(
                                    child: Text(
                                      FormatHelper.capitalize('No options'),
                                      style: StyleText.fontSize13Weight400
                                          .copyWith(
                                        color: AppColors.text.withOpacity(0.4),
                                      ),
                                    ),
                                  ),
                            )
                          : ListView.separated(
                              padding: EdgeInsets.zero,
                              shrinkWrap: true,
                              itemCount: items.length,
                              separatorBuilder: (_, __) => showDivider
                                  ? Divider(
                                      height: 1.sp,
                                      thickness: 1.sp,
                                      color: dividerColor ??
                                          AppColors.text.withOpacity(0.08),
                                    )
                                  : const SizedBox.shrink(),
                              itemBuilder: (_, i) {
                                final item = items[i];
                                final isSelected = item.value == selectedValue;
                                return _DropdownItemTile<T>(
                                  item: item,
                                  isSelected: isSelected,
                                  height: itemHeight,
                                  style: itemStyle,
                                  onTap: item.enabled
                                      ? () => onSelected(item)
                                      : null,
                                );
                              },
                            ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Item tile with hover state
// ─────────────────────────────────────────────────────────────────────────────

class _DropdownItemTile<T> extends StatefulWidget {
  final DropdownItem<T> item;
  final bool isSelected;
  final double height;
  final TextStyle? style;
  final VoidCallback? onTap;

  const _DropdownItemTile({
    required this.item,
    required this.isSelected,
    required this.height,
    this.style,
    this.onTap,
  });

  @override
  State<_DropdownItemTile<T>> createState() => _DropdownItemTileState<T>();
}

class _DropdownItemTileState<T> extends State<_DropdownItemTile<T>> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final isDisabled = widget.onTap == null;

    return MouseRegion(
      cursor:
          isDisabled ? SystemMouseCursors.forbidden : SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          height: widget.height,
          padding: EdgeInsets.symmetric(horizontal: AppPadding.h),
          color: widget.isSelected
              ? AppColors.primary
              : (_hovered && !isDisabled)
                  ? AppColors.primary
                  : AppColors.transparent,
          child: Row(
            children: [
              if (widget.item.leading != null) ...[
                widget.item.leading!,
                SizedBox(width: 8.sp),
              ],
              Expanded(
                child: Text(
                  FormatHelper.capitalize(widget.item.label),
                  style: (widget.style ??
                          (widget.isSelected
                              ? StyleText.fontSize14Weight500
                              : StyleText.fontSize14Weight400))
                      .copyWith(
                    color: isDisabled
                        ? AppColors.text.withOpacity(0.3)
                        : (widget.isSelected || _hovered)
                            ? AppColors.textButton
                            : AppColors.secondaryText,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (widget.item.trailing != null) ...[
                SizedBox(width: 8.sp),
                widget.item.trailing!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}
