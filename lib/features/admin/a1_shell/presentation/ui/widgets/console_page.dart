/// Module: admin / a1_shell
///
///*************************** FILE INFO ****************************///
/// File Name: console_page.dart
/// Purpose: Declares `ConsolePage`, `ConsoleSearchField`, `ConsoleFilters` and
///          `StatusPill` — the frame and furniture every full page uses.
/// Author: ASEC team
/// Created: 20/9/2026
///
/// Ported from manger_plus's console. EVERY page gets the same three things:
/// a title, a subtitle that says what the page is for, and a row of actions —
/// so a page never opens with content and no explanation of what it is.
///
/// The body fills the WIDTH it is given. Nothing here centres content in a
/// column: a table squeezed into the middle of a 1600pt window with grey on
/// both sides is wasted glass.

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:asec/core/custom/111-app_svg_icon.dart';
import 'package:asec/core/custom/35-custom_search_widget_custom.dart';
import 'package:asec/core/custom/8-custom_filter_app.dart';
import 'package:asec/core/theme/app_colors.dart';
import 'package:asec/core/theme/app_padding.dart';
import 'package:asec/core/theme/app_radius.dart';
import 'package:asec/core/theme/app_theme.dart';
import 'package:asec/core/animation/app_animations.dart';
import 'package:asec/core/helper/main_helper/format_helper.dart';

/// The height every control in a page header is drawn at, so a search box and
/// a button beside it have their centres in line.
const double kConsoleControlHeight = 38;

class ConsolePage extends StatelessWidget {
  const ConsolePage({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.actions = const <Widget>[],
    this.scrollable = false,
  });

  final String title;
  final String? subtitle;

  /// Search boxes, filters, an Add button. Held to [kConsoleControlHeight].
  final List<Widget> actions;

  final Widget child;

  /// True wraps [child] in a scroll view. Leave false when the body is a
  /// table or a grid that scrolls itself — two scrollbars is the bug this
  /// flag exists to prevent.
  final bool scrollable;

  @override
  Widget build(BuildContext context) {
    final Widget body = Padding(
      padding: EdgeInsets.fromLTRB(AppPadding.h, 0, AppPadding.h, 20.h),
      child: FadeSlideIn(
        delay: const Duration(milliseconds: 90),
        offset: const Offset(0, 18),
        scale: 0.99,
        child: child,
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Padding(
          padding: EdgeInsets.fromLTRB(AppPadding.h, 20.h, AppPadding.h, 16.h),
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints c) {
              final Widget titleBlock = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  FadeSlideIn(
                    offset: const Offset(-16, 0),
                    scale: 1,
                    child: Text(FormatHelper.capitalize(title), style: StyleText.fontSize26Weight600),
                  ),
                  if (subtitle != null) ...<Widget>[
                    SizedBox(height: 4.h),
                    Text(
                      FormatHelper.capitalize(subtitle!),
                      style: StyleText.fontSize14Weight400
                          .copyWith(color: AppColors.secondaryText),
                    ),
                  ],
                ],
              );

              // Under 760pt the actions no longer fit beside the title, so
              // they wrap onto their own line underneath it.
              final bool stacked = actions.isNotEmpty && c.maxWidth < 760;
              if (stacked) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    titleBlock,
                    SizedBox(height: 14.h),
                    Wrap(
                      spacing: 10.w,
                      runSpacing: 10.h,
                      children: <Widget>[
                        // Width only (09/11/2026): on a narrow window the
                        // scaled-down height cap was smaller than the search
                        // field and it overflowed by a few pixels.
                        for (final Widget a in actions)
                          ConstrainedBox(
                            constraints: BoxConstraints(maxWidth: 420.w),
                            child: a,
                          ),
                      ],
                    ),
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
                  Expanded(child: titleBlock),
                  for (int i = 0; i < actions.length; i++) ...<Widget>[
                    if (i > 0) SizedBox(width: 10.w),
                    // maxHeight, not a tight box: a control that wants more is
                    // brought into line rather than overflowing in stripes.
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: kConsoleControlHeight.h,
                      ),
                      child: actions[i],
                    ),
                  ],
                ],
              );
            },
          ),
        ),
        Expanded(
          child: scrollable ? SingleChildScrollView(child: body) : body,
        ),
      ],
    );
  }
}

/// The search box for a page header. Owns its controller so callers pass a
/// plain `onChanged`, and grows a clear button once there is something to
/// clear.
class ConsoleSearchField extends StatefulWidget {
  const ConsoleSearchField({
    super.key,
    required this.onChanged,
    this.hint,
    this.width = 300,
  });

  final ValueChanged<String> onChanged;
  final String? hint;
  final double width;

  @override
  State<ConsoleSearchField> createState() => _ConsoleSearchFieldState();
}

class _ConsoleSearchFieldState extends State<ConsoleSearchField> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _set(String value) {
    // The rebuild is for the clear button; the caller's own setState filters.
    setState(() {});
    widget.onChanged(value);
  }

  @override
  Widget build(BuildContext context) {
    return AppSearchTextField(
      controller: _controller,
      expanded: false,
      width: widget.width.w,
      hintText: widget.hint,
      onChanged: _set,
      suffixIcon: _controller.text.isEmpty
          ? null
          : IconButton(
              padding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
              constraints: BoxConstraints(minWidth: 28.w, minHeight: 28.h),
              iconSize: 16.sp,
              icon: const AppIcon(Icons.close_rounded),
              onPressed: () {
                _controller.clear();
                _set('');
              },
            ),
    );
  }
}

/// A row of filter chips, on the app's own chip widget.
class ConsoleFilters extends StatelessWidget {
  const ConsoleFilters({
    super.key,
    required this.items,
    required this.selectedKey,
    required this.onSelected,
    this.compact = false,
  });

  final List<StatusChipItem> items;
  final String selectedKey;
  final ValueChanged<String> onSelected;

  /// Small round counts and smaller text (StatusChipFilter.compact).
  final bool compact;

  @override
  Widget build(BuildContext context) => StatusChipFilter(
        items: items,
        selectedKey: selectedKey,
        onSelected: onSelected,
        compact: compact,
      );
}

/// A word on a soft tint — a state, not a button.
class StatusPill extends StatelessWidget {
  const StatusPill({super.key, required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: AppColors.chip,
        borderRadius: AppRadius.buttonR,
      ),
      child: Text(
        FormatHelper.capitalize(label),
        style: StyleText.fontSize12Weight600.copyWith(color: AppColors.onChip),
      ),
    );
  }
}
