/// Module: core / custom
///
///*************************** FILE INFO ****************************///
/// File Name: 113-custom_circular_menu.dart
/// Purpose: Declares `CustomCircularMenu` and `CircularMenuItem` — a round
///          "speed dial" that fans its items out in an arc around the spot
///          that was tapped (like the `circular_menu` package).
/// Author: ASEC team
/// Created: 21/10/2026
/// Updated: 22/10/2026 - Radius 104 → 150 so the bubbles and their labels
///          sit further from the centre button and from each other.
/// Updated: 22/10/2026 - Optional `sweep` (radians) on `show`, so the phone
///          bar's centre button can fan its tools in a narrower arc that
///          stays above the bar.
/// Updated: 29/10/2026 - Rail / drawer: the arc is replaced by ONE STRAIGHT
///          COLUMN beside the ✕ (circles on one line, names beside them).
/// Updated: 29/10/2026 - Rail / drawer on tablet & desktop: the column is
///          replaced by a HALF CIRCLE around the ✕, opening towards the
///          middle of the screen; each name sits just outside its bubble.
///          Narrow screens keep the straight column.
/// Updated: 29/10/2026 - `vertical: true` is now a CARD of tiles (3 per
///          row, the tool's SVG drawing with its short name under it)
///          above the centre button, replacing the stacked rows.
/// Updated: 22/10/2026 - `vertical: true` — a speed dial: the items stack
///          straight up from the anchor, each a round icon with its name in
///          a pill beside it (the phone bar's centre Calculators button).
///          The list is centred on the screen and the ✕ is drawn exactly on
///          the button that opened it, at the same size.
///
/// ```dart
/// final int? picked = await CustomCircularMenu.show(
///   context: context,
///   anchor: rectOfTheTappedButton,
///   items: const <CircularMenuItem>[
///     CircularMenuItem(icon: Icons.calculate_rounded, label: 'Converter'),
///     CircularMenuItem(icon: Icons.air_rounded, label: 'Ducts'),
///   ],
///   selected: 0,
/// );
/// ```
///
/// The arc always opens TOWARDS THE MIDDLE OF THE SCREEN, so the same menu
/// opens upwards from the phone's bottom bar and sideways from the rail /
/// drawer, in LTR and RTL alike. Tapping outside or the centre ✕ closes it
/// and returns null.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:asec/core/custom/111-app_svg_icon.dart';
import 'package:asec/core/helper/main_helper/format_helper.dart';
import 'package:asec/core/theme/app_colors.dart';
import 'package:asec/core/theme/app_theme.dart';

/// One choice of [CustomCircularMenu].
class CircularMenuItem {
  const CircularMenuItem({required this.icon, required this.label});

  final IconData icon;
  final String label;
}

class CustomCircularMenu {
  const CustomCircularMenu._();

  /// Diameter of each item bubble.
  static const double itemSize = 54;

  /// Diameter of the centre (close) button.
  static const double centerSize = 58;

  /// Distance from the centre to each item.
  static const double radius = 150;

  /// Opens the menu around [anchor] (global coordinates of the tapped
  /// control). Returns the picked item's index, or null when dismissed.
  static Future<int?> show({
    required BuildContext context,
    required Rect anchor,
    required List<CircularMenuItem> items,
    int? selected,
    double? sweep,
    bool vertical = false,
  }) {
    return showGeneralDialog<int>(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.black.withOpacity(0.35),
      transitionDuration: const Duration(milliseconds: 320),
      pageBuilder: (BuildContext dialogContext, Animation<double> animation,
              Animation<double> _) =>
          _CircularMenuOverlay(
        anchor: anchor,
        items: items,
        selected: selected,
        animation: animation,
        sweep: sweep,
        vertical: vertical,
      ),
    );
  }

  /// The global rectangle of the widget that owns [context].
  static Rect rectOf(BuildContext context) {
    final RenderObject? ro = context.findRenderObject();
    if (ro is RenderBox && ro.hasSize) {
      return ro.localToGlobal(Offset.zero) & ro.size;
    }
    final Size screen = MediaQuery.sizeOf(context);
    return Rect.fromCenter(
      center: Offset(screen.width / 2, screen.height - 60),
      width: 1,
      height: 1,
    );
  }
}

class _CircularMenuOverlay extends StatelessWidget {
  const _CircularMenuOverlay({
    required this.anchor,
    required this.items,
    required this.selected,
    required this.animation,
    this.sweep,
    this.vertical = false,
  });

  /// Phone bar's centre button: a card with a grid of tiles above it
  /// (drawing + short name) instead of an arc.
  final bool vertical;

  /// Total arc in radians; null = 60° between neighbours, half a circle max.
  final double? sweep;

  final Rect anchor;
  final List<CircularMenuItem> items;
  final int? selected;
  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    final Size screen = MediaQuery.sizeOf(context);
    final EdgeInsets pad = MediaQuery.paddingOf(context);
    // Vertical (the phone bar's centre button): the ✕ takes the button's own
    // size and sits exactly on it.
    final double centerSize =
        vertical ? anchor.shortestSide : CustomCircularMenu.centerSize;
    final double half = centerSize / 2;
    // Tablet / desktop rail: a half circle. Leave room above and below it.
    final bool arc = !vertical && screen.width >= _arcMinWidth;
    final double reachY = arc ? _arcReach : half;
    final double minY = reachY + 8 + pad.top;
    final double maxY = math.max(minY, screen.height - pad.bottom - reachY - 8);
    final Offset center = vertical ? anchor.center : Offset(
      anchor.center.dx.clamp(half + 8, screen.width - half - 8),
      anchor.center.dy.clamp(minY, maxY),
    );

    return AnimatedBuilder(
      animation: animation,
      builder: (BuildContext context, Widget? _) {
        final double fade = animation.value.clamp(0.0, 1.0);

        // showGeneralDialog adds no Material: without this, every Text
        // here gets Flutter's yellow double underline.
        return Material(
          type: MaterialType.transparency,
          child: Stack(
          children: <Widget>[
            // Vertical: rows rise one after another, icon + name beside it.
            if (vertical) _grid(context, screen, center, centerSize),
            // Rail / drawer on tablet & desktop: a half circle round the ✕.
            if (arc) ..._halfCircle(context, screen, center),
            // Narrow screens: the tools in ONE STRAIGHT COLUMN.
            if (!vertical && !arc) _column(context, screen, pad, center, half),
            // The centre button: ✕ that turns in as the menu opens.
            _place(
              center,
              Transform.rotate(
                angle: (1 - fade) * math.pi / 2,
                child: _CenterButton(onTap: () => Navigator.of(context).pop()),
              ),
              width: centerSize,
              height: centerSize,
            ),
          ],
          ),
        );
      },
    );
  }

  /// Below this width the rail menu stays a straight column.
  static const double _arcMinWidth = 600;

  /// Distance from the ✕ to the far edge of a name pill on the arc.
  static const double _arcReach =
      CustomCircularMenu.radius + CustomCircularMenu.itemSize / 2 + _labelGap + 34;

  /// Space between a bubble and its name pill.
  static const double _labelGap = 6;

  /// 29/10/2026 — THE RAIL'S CALCULATORS (tablet / desktop): the bubbles
  /// on a HALF CIRCLE around the ✕, opening towards the middle of the
  /// screen (right from an LTR rail, left from an RTL one). Each name sits
  /// just outside its bubble, along the same ray, so names never overlap
  /// the neighbouring bubbles. Bubbles fly out of the ✕ one after another.
  List<Widget> _halfCircle(BuildContext context, Size screen, Offset center) {
    const double r = CustomCircularMenu.radius;
    const double item = CustomCircularMenu.itemSize;
    final int n = items.length;
    final double side = center.dx < screen.width / 2 ? 1 : -1;
    final List<Widget> out = <Widget>[];

    for (int i = 0; i < n; i++) {
      // Top (-90°) to bottom (+90°), mirrored for a rail on the right.
      final double a = n == 1 ? 0 : -math.pi / 2 + math.pi * i / (n - 1);
      final double dx = math.cos(a) * side;
      final double dy = math.sin(a);

      final double start = (i * 0.07).clamp(0.0, 0.6);
      final double raw = ((animation.value - start) / (1 - start)).clamp(0.0, 1.0);
      final double t = Curves.easeOutBack.transform(raw);

      final Offset bubble = center + Offset(dx, dy) * (r * t);
      final Offset labelAt = center + Offset(dx, dy) * ((r + item / 2 + _labelGap) * t);
      void pick() => Navigator.of(context).pop(i);

      out.add(Positioned(
        left: bubble.dx - item / 2,
        top: bubble.dy - item / 2,
        width: item,
        height: item,
        child: Opacity(
          opacity: raw,
          child: _Bubble(item: items[i], selected: i == selected, onTap: pick),
        ),
      ));
      // The pill's nearest edge touches the ray just past the bubble.
      out.add(Positioned(
        left: labelAt.dx,
        top: labelAt.dy,
        child: Opacity(
          opacity: raw,
          child: FractionalTranslation(
            translation: Offset((dx - 1) / 2, (dy - 1) / 2),
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: pick,
                child: _Label(item: items[i], selected: i == selected),
              ),
            ),
          ),
        ),
      ));
    }
    return out;
  }

  /// 29/10/2026 — THE RAIL'S CALCULATORS: one straight column beside the
  /// ✕, centred on it (kept on screen). The circles stand on one vertical
  /// line, each name in a pill beside its circle; rows slide out of the ✕
  /// one after another. Opens towards the middle of the screen, so it works
  /// from a rail on either side (LTR / RTL).
  Widget _column(
    BuildContext context,
    Size screen,
    EdgeInsets pad,
    Offset center,
    double half,
  ) {
    const double row = CustomCircularMenu.itemSize;
    const double gap = 12;
    final int n = items.length;
    final double total = n * row + (n - 1) * gap;
    final bool toRight = center.dx < screen.width / 2;
    final double minTop = pad.top + 8;
    final double maxTop = math.max(minTop, screen.height - pad.bottom - 8 - total);
    final double top = (center.dy - total / 2).clamp(minTop, maxTop);
    const double side = 18;

    final Widget column = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment:
          toRight ? CrossAxisAlignment.start : CrossAxisAlignment.end,
      children: <Widget>[
        for (int i = 0; i < n; i++)
          Builder(builder: (BuildContext _) {
            final double start = (i * 0.07).clamp(0.0, 0.6);
            final double raw =
                ((animation.value - start) / (1 - start)).clamp(0.0, 1.0);
            final double t = Curves.easeOutBack.transform(raw);
            return Padding(
              padding: EdgeInsets.only(top: i == 0 ? 0 : gap),
              child: Opacity(
                opacity: raw,
                child: Transform.translate(
                  offset: Offset((1 - t) * (toRight ? -40 : 40), 0),
                  child: _ItemRow(
                    item: items[i],
                    selected: i == selected,
                    bubbleFirst: toRight,
                    onTap: () => Navigator.of(context).pop(i),
                  ),
                ),
              ),
            );
          }),
      ],
    );

    return toRight
        ? Positioned(left: center.dx + half + side, top: top, child: column)
        : Positioned(
            right: screen.width - (center.dx - half - side),
            top: top,
            child: column,
          );
  }

  /// 29/10/2026 — THE PHONE'S CALCULATORS: one card standing just above the
  /// centre button, the tools in a grid of 3 — each its drawing (SVG) in a
  /// tinted square with its SHORT name under it. The card grows out of the
  /// button; the tiles pop in one after another. The open one is filled.
  Widget _grid(
    BuildContext context,
    Size screen,
    Offset center,
    double centerSize,
  ) {
    const double gap = 14;
    const int cols = 3;
    const double pad = 14;
    const double spacing = 10;
    final double width = math.min(screen.width - 32, 380);
    final double tile = (width - pad * 2 - spacing * (cols - 1)) / cols;
    final int n = items.length;
    final double open = Curves.easeOutCubic.transform(animation.value.clamp(0.0, 1.0));

    return Positioned(
      left: 0,
      right: 0,
      bottom: screen.height - (center.dy - centerSize / 2 - gap),
      child: Center(
        child: Opacity(
          opacity: open,
          child: Transform.scale(
            scale: 0.85 + 0.15 * open,
            alignment: Alignment.bottomCenter,
            child: Transform.translate(
              offset: Offset(0, (1 - open) * 24),
              child: Container(
                width: width,
                padding: const EdgeInsets.all(pad),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: Colors.black.withOpacity(0.18),
                      blurRadius: 28,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Wrap(
                  spacing: spacing,
                  runSpacing: spacing,
                  children: <Widget>[
                    for (int i = 0; i < n; i++)
                      Builder(builder: (BuildContext _) {
                        final double start = (0.15 + i * 0.07).clamp(0.0, 0.7);
                        final double raw =
                            ((animation.value - start) / (1 - start)).clamp(0.0, 1.0);
                        final double t = Curves.easeOutBack.transform(raw);
                        return Opacity(
                          opacity: raw,
                          child: Transform.scale(
                            scale: 0.6 + 0.4 * t,
                            child: _ItemTile(
                              item: items[i],
                              size: tile,
                              selected: i == selected,
                              onTap: () => Navigator.of(context).pop(i),
                            ),
                          ),
                        );
                      }),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Positions [child] so that its circle is centred on [p].
  Widget _place(
    Offset p,
    Widget child, {
    required double width,
    required double? height,
    bool alignTop = false,
  }) {
    final double top = alignTop || height == null
        ? p.dy - CustomCircularMenu.itemSize / 2
        : p.dy - height / 2;
    return Positioned(
      left: p.dx - width / 2,
      top: top,
      width: width,
      height: height,
      child: child,
    );
  }
}

class _CenterButton extends StatelessWidget {
  const _CenterButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.primary,
      shape: const CircleBorder(),
      elevation: 6,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Center(
          child: Icon(Icons.close_rounded, color: AppColors.textButton, size: 28),
        ),
      ),
    );
  }
}

/// A column row: the round icon (with the tool's drawing) and its short
/// name in a pill beside it. [bubbleFirst] = circle on the left.
class _ItemRow extends StatelessWidget {
  const _ItemRow({
    required this.item,
    required this.selected,
    required this.bubbleFirst,
    required this.onTap,
  });

  final CircularMenuItem item;
  final bool selected;
  final bool bubbleFirst;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Widget bubble = SizedBox(
      width: CustomCircularMenu.itemSize,
      height: CustomCircularMenu.itemSize,
      child: _Bubble(item: item, selected: selected),
    );
    final Widget label = _Label(item: item, selected: selected);
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          // Laid out by side, not by language: the circles must stay on the
          // line nearest the ✕.
          textDirection: TextDirection.ltr,
          children: bubbleFirst
              ? <Widget>[bubble, const SizedBox(width: 10), label]
              : <Widget>[label, const SizedBox(width: 10), bubble],
        ),
      ),
    );
  }
}

/// The round icon of one tool; filled when it is the open one.
class _Bubble extends StatelessWidget {
  const _Bubble({required this.item, required this.selected, this.onTap});

  final CircularMenuItem item;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.primary : AppColors.card,
      shape: const CircleBorder(),
      elevation: 4,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Center(
          child: AppIcon(
            item.icon,
            size: 26,
            color: selected
                ? AppTheme.readableOn(AppColors.primary)
                : AppTheme.accentOn(AppColors.card),
          ),
        ),
      ),
    );
  }
}

/// The tool's name in a small pill.
class _Label extends StatelessWidget {
  const _Label({required this.item, required this.selected});

  final CircularMenuItem item;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(10),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Text(
        FormatHelper.capitalize(item.label),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: StyleText.fontSize14Weight600.copyWith(
          color: selected ? AppTheme.accentOn(AppColors.card) : AppColors.text,
        ),
      ),
    );
  }
}

/// A grid tile: the tool's drawing in a tinted rounded square, its short
/// name under it (one line).
class _ItemTile extends StatefulWidget {
  const _ItemTile({
    required this.item,
    required this.size,
    required this.selected,
    required this.onTap,
  });

  final CircularMenuItem item;
  final double size;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_ItemTile> createState() => _ItemTileState();
}

class _ItemTileState extends State<_ItemTile> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final bool sel = widget.selected;
    final double box = widget.size * 0.62;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _down = true),
      onTapCancel: () => setState(() => _down = false),
      onTapUp: (_) => setState(() => _down = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _down ? 0.92 : 1,
        duration: const Duration(milliseconds: 120),
        child: SizedBox(
          width: widget.size,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: box,
                height: box,
                decoration: BoxDecoration(
                  color: sel ? AppColors.primary : AppColors.primary.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(box * 0.3),
                  boxShadow: sel
                      ? <BoxShadow>[
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.35),
                            blurRadius: 12,
                            offset: const Offset(0, 5),
                          ),
                        ]
                      : const <BoxShadow>[],
                ),
                child: Center(
                  child: AppIcon(
                    widget.item.icon,
                    size: box * 0.6,
                    color: sel ? AppTheme.readableOn(AppColors.primary) : AppTheme.accentOn(AppColors.card),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                FormatHelper.capitalize(widget.item.label),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: StyleText.fontSize13Weight600.copyWith(
                  color: sel ? AppTheme.accentOn(AppColors.card) : AppColors.text,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
