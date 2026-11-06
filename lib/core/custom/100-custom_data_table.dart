/// Module: core / custom
///
///*************************** FILE INFO ****************************///
/// File Name: 100-custom_data_table.dart
/// Purpose: Declares `AppTableColumn`, `AppDataTable` and `AppTableCellText` —
///          the app's one table.
/// Author: Manger Plus team
/// Created: 3/9/2026
///
/// WHY NOT `DataTable`
/// -------------------
/// Material's `DataTable` draws a divider under every row and a border around
/// the header, sizes columns to their content (so a long note makes the whole
/// table wider than the window), and has no sticky header. All three fight the
/// house style. This is a `Column` of `Row`s: flex-weighted columns, a header
/// that stays put while the body scrolls, and separation by ALTERNATING ROW
/// FILL rather than by lines.
///
/// THE RULES IT ENCODES
/// --------------------
///   * No borders and no dividers anywhere. Rows read as rows because they
///     alternate `AppColors.oddRowColor` / `AppColors.evenRowColor`.
///   * The header is `AppColors.background` — the page colour, so it reads as
///     part of the frame rather than as a first data row.
///   * Selection is `AppColors.primary` at 18% — visible on both zebra shades
///     and in both themes, without turning the row into a yellow block that
///     swallows its own text.
///   * The whole thing is clipped to radius 8, matching every card.
///
/// TABLET: THERE IS NO TABLE
/// -------------------------
/// A table is a DESKTOP object. Seven flex columns on an iPad give seven
/// columns of ellipsis, and a row of 20px icon buttons on a touch screen is a
/// row of missed taps. So in a TABLET LAYOUT this widget does not draw a table
/// at all: the same columns are re-laid as CARDS in a
/// `SliverGridDelegateWithFixedCrossAxisCount` grid, counted by
/// [CrossAxisCountHelper.getCrossAxisCountForDefaultTablet2].
///
/// No page has to opt in and no page needs a second widget: a card is built
/// FROM the columns it was already given — the first column is the card's
/// heading, the label-less fixed-width column of buttons is its footer, and
/// everything between becomes a `label  value` line. Pass [cardBuilder] only
/// where a page wants a card that is not simply its row turned sideways, and
/// [cardSlot] on a column to overrule where it lands.
///
/// "Tablet layout" is decided by the WIDTH THIS TABLE IS GIVEN, not by the
/// platform — see [PlatformHelper.isTabletLayout]. A real iPad qualifies, and
/// so does the macOS console in a window (or a panel) narrower than
/// [PlatformHelper.desktopLayoutWidth]: that window has an iPad's room, so it
/// gets an iPad's layout. Only a genuinely wide window keeps the table.
///
/// COLUMN WIDTHS
/// -------------
/// Columns are FLEX weights, not pixels: the table always fills its box and
/// never scrolls sideways. Give a column `fixedWidth` only when its content has
/// a genuine ceiling — a status chip, a row of action buttons.

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:asec/core/constants/app_assets.dart';
import 'package:asec/core/custom/32-custom_svg.dart';
import 'package:asec/core/custom/69-cross_axis_count_helper.dart';
import 'package:asec/core/custom/89-custom_empty_state.dart';
import 'package:asec/core/helper/main_helper/localized_number.dart';
import 'package:asec/core/helper/main_helper/platform_helper.dart';
import 'package:asec/core/theme/app_colors.dart';
import 'package:asec/core/theme/app_padding.dart';
import 'package:asec/core/theme/app_radius.dart';
import 'package:asec/core/theme/app_theme.dart';
import 'package:asec/core/animation/app_animations.dart';
import 'package:asec/core/helper/main_helper/format_helper.dart';

/// One column of [AppDataTable].
class AppTableColumn<T> {
  const AppTableColumn({
    required this.label,
    required this.cell,
    this.flex = 1,
    this.fixedWidth,
    this.alignment = Alignment.centerLeft,
    this.sortKey,
    this.cardSlot = AppTableCardSlot.auto,
  });

  /// Header text. Rendered uppercase-free and in 12/w600 — a label, not a
  /// shouted one.
  final String label;

  /// Builds this column's cell for [row]. Return an [AppTableCellText] for
  /// plain values; anything else (a chip, a button row) is passed through.
  final Widget Function(BuildContext context, T row) cell;

  /// Share of the leftover width. Ignored when [fixedWidth] is set.
  final int flex;

  /// Pins the column to an exact width. Use for chips and action clusters.
  final double? fixedWidth;

  final Alignment alignment;

  /// Non-null makes the header tappable; the value is handed back to
  /// [AppDataTable.onSort]. Null columns are not sortable and show no affordance.
  final String? sortKey;

  /// Where this column goes when the table is drawn as cards (tablet). Leave
  /// it [AppTableCardSlot.auto] unless the guess is wrong.
  final AppTableCardSlot cardSlot;

  /// The slot [AppTableCardSlot.auto] resolves to for the column at [index].
  AppTableCardSlot resolvedSlot(int index) {
    if (cardSlot != AppTableCardSlot.auto) return cardSlot;
    if (index == 0) return AppTableCardSlot.title;
    // A fixed-width column with no header is an action cluster or a chevron:
    // on a card those belong in the footer, not in the label/value list.
    if (label.isEmpty && fixedWidth != null) return AppTableCardSlot.trailing;
    return AppTableCardSlot.body;
  }
}

/// Where a column lands on the CARD the tablet layout builds from it.
enum AppTableCardSlot {
  /// Decided by position — see [AppTableColumn.resolvedSlot].
  auto,

  /// The card's heading line. The first column, normally.
  title,

  /// A `label  value` line in the card's body.
  body,

  /// The card's footer — the row actions.
  trailing,

  /// Left off the card. For a column that only makes sense in a wide row.
  hidden,
}

/// The standard cell: one line, ellipsised, in the app's body style.
class AppTableCellText extends StatelessWidget {
  const AppTableCellText(
    this.value, {
    super.key,
    this.style,
    this.color,
    this.emphasis = false,
    this.textAlign,
  });

  final String value;
  final TextStyle? style;
  final Color? color;

  /// The one column that identifies the row — an order number, a customer
  /// name. Renders w600 so the eye has an anchor per row.
  final bool emphasis;

  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    final TextStyle base = style ??
        (emphasis
            ? StyleText.fontSize13Weight600
            : StyleText.fontSize13Weight400);

    return Text(
      FormatHelper.capitalize(value),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      textAlign: textAlign,
      style: base.copyWith(
        color: color ?? (emphasis ? AppColors.text : AppColors.secondaryText),
      ),
    );
  }
}

/// A borderless, zebra-striped, flex-column table with a sticky header.
class AppDataTable<T> extends StatelessWidget {
  const AppDataTable({
    super.key,
    required this.columns,
    required this.rows,
    this.onRowTap,
    this.isRowSelected,
    this.rowHeight,
    this.headerHeight,
    this.horizontalPadding,
    this.emptyState,
    this.shrinkWrap = false,
    this.scrollController,
    this.sortKey,
    this.sortAscending = true,
    this.onSort,
    this.showRowNumbers = false,
    this.rowNumberLabel = '#',
    this.cardBuilder,
    this.cardsOnTablet = true,
    this.forceCards = false,
    this.cardExtent,
    this.cardMinWidth = 300,
  });

  final List<AppTableColumn<T>> columns;
  final List<T> rows;

  final ValueChanged<T>? onRowTap;

  /// Marks the row that is open in a side panel. Kept a predicate rather than
  /// an index so the caller can key on the record's id — a list that reorders
  /// underneath a selection then keeps the right row lit.
  final bool Function(T row)? isRowSelected;

  final double? rowHeight;
  final double? headerHeight;
  final double? horizontalPadding;

  /// Shown instead of the body when [rows] is empty. Defaults to the app's
  /// wordless [CustomEmptyState]. Pass your own only for a FAILED read, which
  /// is a different fact from an empty one.
  final Widget? emptyState;

  /// True inside an already-scrolling page. False (the default) makes the body
  /// scroll on its own under a header that stays put.
  final bool shrinkWrap;

  final ScrollController? scrollController;

  /// The column currently sorted, by its `sortKey`.
  final String? sortKey;
  final bool sortAscending;
  final void Function(String key)? onSort;

  /// Prepends knowticed's role-management "No" column — a 1-based counter in
  /// the reader's own digits.
  ///
  /// It numbers the ROWS AS DISPLAYED, not the records: re-sort the table and
  /// row 1 is whatever is now on top. That is the point of it — it is a place
  /// marker for "the third one down", which is how people talk about a row
  /// they are looking at, not an id.
  final bool showRowNumbers;
  final String rowNumberLabel;

  /// Draws one card in tablet mode. Leave null and a card is built from the
  /// columns — see the header of this file.
  final Widget Function(BuildContext context, T row)? cardBuilder;

  /// Tablets get cards. Set false ONLY for a table whose columns are a matrix
  /// (a grade sheet), where a card per row says less than the grid does.
  final bool cardsOnTablet;

  /// Cards on every device, including the desktop console.
  final bool forceCards;

  /// Card height, in design pixels. Null measures it from the columns.
  final double? cardExtent;

  /// The width below which a card stops being readable; the column count is
  /// brought down to respect it. See [CrossAxisCountHelper.gridDelegate].
  final double cardMinWidth;

  /// The narrowest box this table will still draw COLUMNS in. Below it the
  /// table is cards even inside a wide window — a five-column table in a
  /// 600pt panel is five columns of ellipsis.
  static const double minTableWidth = 720;

  /// True when this table should draw itself as a grid of cards. [width] is
  /// the space the table was actually given.
  ///
  /// Two ways to qualify: the WINDOW is a tablet layout (a real tablet, or a
  /// desktop window under [PlatformHelper.desktopLayoutWidth] — the case that
  /// matters when the console is run in a half-width Mac window), or this
  /// table's own box is under [minTableWidth].
  bool asCards(BuildContext context, double width) =>
      forceCards ||
      (cardsOnTablet &&
          (PlatformHelper.isTabletLayout(context) || width < minTableWidth));

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints c) {
        final double width =
            c.hasBoundedWidth ? c.maxWidth : MediaQuery.sizeOf(context).width;
        if (asCards(context, width)) {
          return _CardGrid<T>(table: this, width: width);
        }
        return _table(context);
      },
    );
  }

  Widget _table(BuildContext context) {
    final double padding = horizontalPadding ?? AppPadding.h;
    final double? numberWidth = showRowNumbers ? 56.sp : null;

    final Widget body = rows.isEmpty
        ? (emptyState ?? const CustomEmptyState())
        : ListView.builder(
            controller: scrollController,
            shrinkWrap: shrinkWrap,
            physics: shrinkWrap
                ? const NeverScrollableScrollPhysics()
                : const ClampingScrollPhysics(),
            padding: EdgeInsets.zero,
            itemCount: rows.length,
            itemBuilder: (BuildContext context, int index) {
              final T row = rows[index];
              return FadeSlideIn(delay: staggerDelay(index < 15 ? index : 0, stepMs: 30), offset: const Offset(0, 12), scale: 1, child: _Row<T>(
                row: row,
                columns: columns,
                index: index,
                rowNumberWidth: numberWidth,
                height: (rowHeight ?? 52).sp,
                horizontalPadding: padding,
                selected: isRowSelected?.call(row) ?? false,
                onTap: onRowTap == null ? null : () => onRowTap!(row),
              ));
            },
          );

    return ClipRRect(
      borderRadius: AppRadius.containerR,
      child: Column(
        mainAxisSize: shrinkWrap ? MainAxisSize.min : MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _Header<T>(
            columns: columns,
            rowNumberWidth: numberWidth,
            rowNumberLabel: rowNumberLabel,
            height: (headerHeight ?? 44).sp,
            horizontalPadding: padding,
            sortKey: sortKey,
            sortAscending: sortAscending,
            onSort: onSort,
          ),
          if (shrinkWrap) body else Expanded(child: body),
        ],
      ),
    );
  }
}

class _Header<T> extends StatelessWidget {
  const _Header({
    required this.columns,
    required this.rowNumberWidth,
    required this.rowNumberLabel,
    required this.height,
    required this.horizontalPadding,
    required this.sortKey,
    required this.sortAscending,
    required this.onSort,
  });

  final List<AppTableColumn<T>> columns;
  final double? rowNumberWidth;
  final String rowNumberLabel;
  final double height;
  final double horizontalPadding;
  final String? sortKey;
  final bool sortAscending;
  final void Function(String key)? onSort;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      // ROLE-MANAGEMENT STYLE 18/9/2026. The header used to be
      // `AppColors.background` — the page colour, so it read as part of the
      // frame. knowticed's role-management table fills it instead, and that
      // is the look this app standardised on: a solid `blackShadow` bar with
      // white labels, so the header is unmistakably a header in both themes
      // and on both zebra shades.
      // 03/11/2026: the primary colour, like the Flexible Duct table.
      color: AppColors.primary,
      child: Row(
        children: <Widget>[
          if (rowNumberWidth != null)
            SizedBox(
              width: rowNumberWidth,
              child: Text(
                FormatHelper.capitalize(rowNumberLabel),
                style: StyleText.fontSize14Weight500
                    .copyWith(color: AppColors.textButton),
              ),
            ),
          for (final AppTableColumn<T> column in columns)
            _Cell(
              column: column,
              child: _HeaderLabel(
                column: column,
                isSorted: column.sortKey != null && column.sortKey == sortKey,
                ascending: sortAscending,
                onTap: (column.sortKey == null || onSort == null)
                    ? null
                    : () => onSort!(column.sortKey!),
              ),
            ),
        ],
      ),
    );
  }
}

class _HeaderLabel<T> extends StatelessWidget {
  const _HeaderLabel({
    required this.column,
    required this.isSorted,
    required this.ascending,
    required this.onTap,
  });

  final AppTableColumn<T> column;
  final bool isSorted;
  final bool ascending;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final Widget label = Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Flexible(
          child: Text(
            FormatHelper.capitalize(column.label),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: StyleText.fontSize14Weight500.copyWith(
              color: AppColors.textButton,
              fontWeight: isSorted ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
        // The caret appears only on the sorted column. A permanent pair of
        // arrows on every sortable header is six pieces of chrome saying
        // nothing about the current state.
        //
        // One asset, flipped: `chevronDown` turned half a turn is the ascending
        // caret, so there is no second file to keep in visual step with it.
        if (isSorted) ...<Widget>[
          SizedBox(width: 4.sp),
          RotatedBox(
            quarterTurns: ascending ? 2 : 0,
            child: CustomSvgImage(
              assetPath: AppAssets.chevronDown,
              width: 12.sp,
              height: 12.sp,
              color: AppColors.textButton,
            ),
          ),
        ],
      ],
    );

    if (onTap == null) return label;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(onTap: onTap, child: label),
    );
  }
}

class _Row<T> extends StatefulWidget {
  const _Row({
    required this.row,
    required this.columns,
    required this.index,
    required this.rowNumberWidth,
    required this.height,
    required this.horizontalPadding,
    required this.selected,
    required this.onTap,
  });

  final T row;
  final List<AppTableColumn<T>> columns;
  final int index;
  final double? rowNumberWidth;
  final double height;
  final double horizontalPadding;
  final bool selected;
  final VoidCallback? onTap;

  @override
  State<_Row<T>> createState() => _RowState<T>();
}

class _RowState<T> extends State<_Row<T>> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    // 03/11/2026: no zebra — every row the card colour, a thin line
    // between rows (the Flexible Duct table's look).
    final Color zebra = AppColors.card;

    final Color background = widget.selected
        ? AppColors.primary.withOpacity(0.18)
        : _hovered
            ? AppColors.primary.withOpacity(0.08)
            : zebra;

    final Widget row = Container(
      height: widget.height,
      padding: EdgeInsets.symmetric(horizontal: widget.horizontalPadding),
      decoration: BoxDecoration(
        color: background,
        border: widget.index == 0
            ? null
            : Border(top: BorderSide(color: AppColors.secondaryText.withOpacity(0.12))),
      ),
      child: Row(
        children: <Widget>[
          if (widget.rowNumberWidth != null)
            SizedBox(
              width: widget.rowNumberWidth,
              child: Text(
                FormatHelper.capitalize(LocalizedNumber.of(context, widget.index + 1)),
                style: StyleText.fontSize12Weight600
                    .copyWith(color: AppColors.secondaryText),
              ),
            ),
          for (final AppTableColumn<T> column in widget.columns)
            _Cell(
              column: column,
              child: column.cell(context, widget.row),
            ),
        ],
      ),
    );

    if (widget.onTap == null) return row;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: row,
      ),
    );
  }
}

/// Lays one cell out under its column's width rule. Shared by the header and
/// the body so a header can never drift out of line with its column.
class _Cell<T> extends StatelessWidget {
  const _Cell({required this.column, required this.child});

  final AppTableColumn<T> column;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final Widget padded = Padding(
      padding: EdgeInsets.only(right: AppPadding.h),
      child: Align(alignment: column.alignment, child: child),
    );

    if (column.fixedWidth != null) {
      return SizedBox(width: column.fixedWidth, child: padded);
    }
    return Expanded(flex: column.flex, child: padded);
  }
}

// ── Tablet: the same table, as cards ────────────────────────────────────────

/// The tablet face of [AppDataTable]: one card per row, in a
/// `SliverGridDelegateWithFixedCrossAxisCount` grid counted by
/// [CrossAxisCountHelper.getCrossAxisCountForDefaultTablet2].
class _CardGrid<T> extends StatelessWidget {
  const _CardGrid({required this.table, required this.width});

  final AppDataTable<T> table;

  /// The space the grid has — measured by [AppDataTable.build], so the column
  /// count answers for THIS box rather than for the whole window.
  final double width;

  /// Height of the card's heading line, its body lines and its footer, in
  /// design pixels. The grid needs ONE height for every cell, so the card is
  /// measured from its columns rather than left to size itself — a ragged
  /// grid of cards was the thing the table was replaced to avoid.
  static const double _titleHeight = 46;
  static const double _lineHeight = 26;
  static const double _footerHeight = 50;
  static const double _verticalPadding = 12;

  double _extent(List<AppTableColumn<T>> body, bool hasFooter) {
    if (table.cardExtent != null) return table.cardExtent!;
    return _verticalPadding * 2 +
        _titleHeight +
        body.length * _lineHeight +
        (hasFooter ? _footerHeight : 0);
  }

  @override
  Widget build(BuildContext context) {
    if (table.rows.isEmpty) {
      return table.emptyState ?? const CustomEmptyState();
    }

    final List<AppTableColumn<T>> title = <AppTableColumn<T>>[];
    final List<AppTableColumn<T>> body = <AppTableColumn<T>>[];
    final List<AppTableColumn<T>> trailing = <AppTableColumn<T>>[];
    for (int i = 0; i < table.columns.length; i++) {
      final AppTableColumn<T> column = table.columns[i];
      switch (column.resolvedSlot(i)) {
        case AppTableCardSlot.title:
          title.add(column);
        case AppTableCardSlot.body:
          body.add(column);
        case AppTableCardSlot.trailing:
          trailing.add(column);
        case AppTableCardSlot.hidden:
        case AppTableCardSlot.auto:
          break;
      }
    }

    final double extent = _extent(body, trailing.isNotEmpty);

    final Widget grid = GridView.builder(
      controller: table.scrollController,
      shrinkWrap: table.shrinkWrap,
      physics: table.shrinkWrap
          ? const NeverScrollableScrollPhysics()
          : const ClampingScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: AppPadding.h, vertical: 14.h),
      gridDelegate: CrossAxisCountHelper.gridDelegate(
        context,
        mainAxisExtent: extent,
        // Design pixels: `gridDelegate` scales them.
        spacing: 12,
        minCellWidth: table.cardMinWidth,
        availableWidth: width,
      ),
      itemCount: table.rows.length,
      itemBuilder: (BuildContext context, int index) {
        final T row = table.rows[index];
        if (table.cardBuilder != null) {
          return FadeSlideIn(
            delay: staggerDelay(index, stepMs: 45),
            child: table.cardBuilder!(context, row),
          );
        }
        return FadeSlideIn(delay: staggerDelay(index, stepMs: 45), child: _RecordCard<T>(
          row: row,
          index: index,
          title: title,
          body: body,
          trailing: trailing,
          showNumber: table.showRowNumbers,
          selected: table.isRowSelected?.call(row) ?? false,
          onTap: table.onRowTap == null ? null : () => table.onRowTap!(row),
          titleHeight: _titleHeight,
          lineHeight: _lineHeight,
          footerHeight: _footerHeight,
          verticalPadding: _verticalPadding,
        ));
      },
    );

    // A card grid has no header row, so a sortable table would lose its sort
    // entirely on a tablet. The header's job moves to a chip bar above the
    // grid — same keys, same callback.
    final Widget? sortBar = _sortBar(context);
    if (sortBar == null) return grid;

    return Column(
      mainAxisSize: table.shrinkWrap ? MainAxisSize.min : MainAxisSize.max,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        sortBar,
        if (table.shrinkWrap) grid else Expanded(child: grid),
      ],
    );
  }

  Widget? _sortBar(BuildContext context) {
    if (table.onSort == null) return null;
    final List<AppTableColumn<T>> sortable = table.columns
        .where((AppTableColumn<T> c) => c.sortKey != null && c.label.isNotEmpty)
        .toList();
    if (sortable.isEmpty) return null;

    return Padding(
      padding: EdgeInsets.fromLTRB(AppPadding.h, 14.h, AppPadding.h, 0),
      child: Wrap(
        spacing: 8.w,
        runSpacing: 8.h,
        children: <Widget>[
          for (final AppTableColumn<T> column in sortable)
            _SortChip(
              label: column.label,
              active: column.sortKey == table.sortKey,
              ascending: table.sortAscending,
              onTap: () => table.onSort!(column.sortKey!),
            ),
        ],
      ),
    );
  }
}

/// One row of the table, as a card: heading, `label  value` lines, actions.
class _RecordCard<T> extends StatelessWidget {
  const _RecordCard({
    required this.row,
    required this.index,
    required this.title,
    required this.body,
    required this.trailing,
    required this.showNumber,
    required this.selected,
    required this.onTap,
    required this.titleHeight,
    required this.lineHeight,
    required this.footerHeight,
    required this.verticalPadding,
  });

  final T row;
  final int index;
  final List<AppTableColumn<T>> title;
  final List<AppTableColumn<T>> body;
  final List<AppTableColumn<T>> trailing;
  final bool showNumber;
  final bool selected;
  final VoidCallback? onTap;
  final double titleHeight;
  final double lineHeight;
  final double footerHeight;
  final double verticalPadding;

  @override
  Widget build(BuildContext context) {
    // The tables in this app sit inside an `AppColors.card` panel, so a card
    // drawn in the card colour would be invisible. The page fill is the
    // contrast, exactly as it is the other way round elsewhere.
    final Color fill = selected
        ? AppColors.primary.withOpacity(0.18)
        : AppColors.background;

    final Widget card = Container(
      padding: EdgeInsets.symmetric(horizontal: AppPadding.h,
        vertical: verticalPadding.h),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: AppRadius.containerR,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          SizedBox(
            height: titleHeight.h,
            child: Row(
              children: <Widget>[
                if (showNumber) ...<Widget>[
                  Text(
                    FormatHelper.capitalize(LocalizedNumber.of(context, index + 1)),
                    style: StyleText.fontSize12Weight600
                        .copyWith(color: AppColors.secondaryText),
                  ),
                  SizedBox(width: 10.w),
                ],
                for (final AppTableColumn<T> column in title)
                Expanded(child: column.cell(context, row)),
              ],
            ),
          ),
          for (final AppTableColumn<T> column in body)
          SizedBox(
              height: lineHeight.h,
              child: Row(
                children: <Widget>[
                SizedBox(
                    width: 96.w,
                    child: Text(
                      FormatHelper.capitalize(column.label),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: StyleText.fontSize12Weight500
                          .copyWith(color: AppColors.secondaryText),
                    ),
                  ),
                Expanded(
                    child: Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: column.cell(context, row),
                    ),
                  ),
                ],
              ),
            ),
          if (trailing.isNotEmpty)
          SizedBox(
              height: footerHeight.h,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  for (final AppTableColumn<T> column in trailing)
                    column.cell(context, row),
                ],
              ),
            ),
        ],
      ),
    );

    if (onTap == null) return card;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: card,
      ),
    );
  }
}

/// One sort key, as a tappable chip — the card grid's answer to a sortable
/// column header.
class _SortChip extends StatelessWidget {
  const _SortChip({
    required this.label,
    required this.active,
    required this.ascending,
    required this.onTap,
  });

  final String label;
  final bool active;
  final bool ascending;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: AppPadding.h, vertical: 7.h),
        decoration: BoxDecoration(
          color: active
              ? AppColors.primary.withOpacity(0.16)
              : AppColors.background,
          borderRadius: AppRadius.buttonR,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              FormatHelper.capitalize(label),
              style: StyleText.fontSize12Weight600.copyWith(
                color: active ? AppColors.text : AppColors.secondaryText,
              ),
            ),
            if (active) ...<Widget>[
              SizedBox(width: 6.w),
              RotatedBox(
                quarterTurns: ascending ? 2 : 0,
                child: CustomSvgImage(
                  assetPath: AppAssets.chevronDown,
                  width: 10.sp,
                  height: 10.sp,
                  color: AppColors.text,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
