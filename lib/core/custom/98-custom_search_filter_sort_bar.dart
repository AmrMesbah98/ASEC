/// Module: core / custom
///
///*************************** FILE INFO ****************************///
/// File Name: 98-custom_search_filter_sort_bar.dart
/// Purpose: Declares `CustomSearchFilterSortBar` — the list-page toolbar.
/// Author: Manger Plus team
/// Created: 3/9/2026
///
/// Ported from knowticed_plus. The house rules it encodes:
///
///   * NO BORDERS. Every control is a filled `AppColors.card` rectangle at
///     radius 8. Separation comes from the background showing through the
///     gaps, never from an outline.
///   * Active means FILLED WITH PRIMARY, with `AppColors.textButton` content —
///     the one place brand yellow appears in a toolbar, so "something is
///     filtered" is legible at a glance across the whole console.
///   * Icons are SVGs from `AppAssets`, at a single 20.sp size.
///   * Controls are 38.sp tall and 100.sp wide on a pointer device; on a phone
///     they collapse to a 38.sp square showing the icon alone.

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:asec/core/constants/app_assets.dart';
import 'package:asec/core/custom/32-custom_svg.dart';
import 'package:asec/core/custom/35-custom_search_widget_custom.dart';
import 'package:asec/core/theme/app_colors.dart';
import 'package:asec/core/theme/app_radius.dart';
import 'package:asec/core/theme/app_theme.dart';
import 'package:asec/core/helper/main_helper/format_helper.dart';

/// A search field plus optional filter, sort and trailing actions.
///
/// Its private search field and action controls intentionally live in this
/// file, so changing this toolbar never changes any other shared widget.
class CustomSearchFilterSortBar<TFilter, TSort> extends StatelessWidget {
  CustomSearchFilterSortBar({
    super.key,
    required this.searchController,
    this.onSearchChanged,
    this.searchHint = 'Search',
    this.showFilter = false,
    this.filterItems,
    this.selectedFilter,
    this.filterLabelBuilder,
    this.onFilterChanged,
    this.filterDialogBuilder,
    this.onFilterTap,
    this.isFilterActive = false,
    this.filterTitle = 'Filter',
    this.showSort = false,
    this.sortItems,
    this.selectedSort,
    this.sortLabelBuilder,
    this.onSortChanged,
    this.sortTitle = 'Sort',
    this.trailingChildren = const <Widget>[],
    this.height,
    this.spacing,
    this.fillColor,
  })  : assert(!showFilter ||
            filterItems == null ||
            filterItems.isEmpty ||
            (filterLabelBuilder != null && onFilterChanged != null)),
        assert(!showSort ||
            (sortItems != null &&
                sortItems.isNotEmpty &&
                sortLabelBuilder != null &&
                onSortChanged != null)),
        assert(filterDialogBuilder == null || onFilterTap == null);

  final TextEditingController searchController;
  final ValueChanged<String>? onSearchChanged;
  final String searchHint;

  final bool showFilter;
  final List<TFilter>? filterItems;
  final TFilter? selectedFilter;
  final String Function(TFilter item)? filterLabelBuilder;
  final ValueChanged<TFilter?>? onFilterChanged;
  final WidgetBuilder? filterDialogBuilder;
  final VoidCallback? onFilterTap;
  final bool isFilterActive;
  final String filterTitle;

  final bool showSort;
  final List<TSort>? sortItems;
  final TSort? selectedSort;
  final String Function(TSort item)? sortLabelBuilder;
  final ValueChanged<TSort?>? onSortChanged;
  final String sortTitle;

  /// Page-specific actions — the "Add order" button, a view toggle, an export.
  final List<Widget> trailingChildren;

  /// Height of this toolbar's controls, as a RAW number — pass 38, never
  /// 38.sp. The `.sp` is applied inside, because [AppSearchTextField] scales
  /// its own height and a value that already carried `.sp` would be scaled
  /// twice, leaving the search box taller than the buttons beside it.
  final double? height;
  final double? spacing;
  final Color? fillColor;

  @override
  Widget build(BuildContext context) {
    final double rawHeight = height ?? 38;
    final double scaledHeight = rawHeight.sp;
    final double effectiveSpacing = spacing ?? 10.sp;

    final List<Widget> controls = <Widget>[
      if (showFilter)
        _buildFilter(context, scaledHeight, filterItems ?? <TFilter>[]),
      if (showSort) _buildSort(scaledHeight, sortItems ?? <TSort>[]),
      ...trailingChildren,
    ];

    // PHONE (12/11/2026): the search gets its own full-width row and the
    // filter / sort / page buttons go on the row under it — on one row the
    // search box was squeezed to a few letters.
    final bool isPhone = MediaQuery.sizeOf(context).shortestSide < 600;
    if (isPhone && controls.isNotEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          AppSearchTextField(
            controller: searchController,
            onChanged: onSearchChanged,
            hintText: searchHint,
            height: rawHeight,
            fillColor: fillColor,
            expanded: false,
          ),
          SizedBox(height: effectiveSpacing),
          Wrap(
            spacing: effectiveSpacing,
            runSpacing: effectiveSpacing,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: controls,
          ),
        ],
      );
    }

    return Row(
      children: <Widget>[
        // `35-custom_search_widget_custom` IS the app's search box. This
        // toolbar used to hand-roll its own `TextField` here, which is exactly
        // the duplication that widget exists to end — two search boxes, two
        // heights, two hint styles.
        AppSearchTextField(
          controller: searchController,
          onChanged: onSearchChanged,
          hintText: searchHint,
          height: rawHeight,
          fillColor: fillColor,
        ),
        for (final Widget control in controls) ...<Widget>[
          SizedBox(width: effectiveSpacing),
          control,
        ],
      ],
    );
  }

  Widget _buildFilter(
    BuildContext context,
    double effectiveHeight,
    List<TFilter> effectiveFilterItems,
  ) {
    // "All" and the empty string are the absence of a filter, not a filter —
    // highlighting them would leave the button permanently lit.
    final bool hasExplicitActive = isFilterActive ||
        (selectedFilter != null &&
            (selectedFilter is! String ||
                (selectedFilter.toString().isNotEmpty &&
                    selectedFilter.toString().toLowerCase() != 'all')));

    if (effectiveFilterItems.isNotEmpty) {
      return _ToolbarDropdownButton<TFilter>(
        value: selectedFilter,
        items: effectiveFilterItems,
        labelBuilder: filterLabelBuilder!,
        onChanged: onFilterChanged!,
        title: filterTitle,
        iconPath: AppAssets.filter,
        height: effectiveHeight,
        fillColor: fillColor,
        activeOverride: hasExplicitActive,
      );
    }

    return ToolbarActionButton(
      title: filterTitle,
      iconPath: AppAssets.filter,
      height: effectiveHeight,
      fillColor: fillColor,
      isActive: hasExplicitActive,
      onTap: () => _handleFilterTap(context),
    );
  }

  Widget _buildSort(double effectiveHeight, List<TSort> effectiveSortItems) {
    final bool hasSortActive = selectedSort != null &&
        (selectedSort is! String || selectedSort.toString().isNotEmpty);

    return _ToolbarDropdownButton<TSort>(
      value: selectedSort,
      items: effectiveSortItems,
      labelBuilder: sortLabelBuilder!,
      onChanged: onSortChanged!,
      title: sortTitle,
      iconPath: AppAssets.sort,
      height: effectiveHeight,
      fillColor: fillColor,
      activeOverride: hasSortActive,
    );
  }

  void _handleFilterTap(BuildContext context) {
    if (filterDialogBuilder != null) {
      showDialog<void>(context: context, builder: filterDialogBuilder!);
      return;
    }
    onFilterTap?.call();
  }
}

class _ToolbarDropdownButton<T> extends StatelessWidget {
  const _ToolbarDropdownButton({
    required this.value,
    required this.items,
    required this.labelBuilder,
    required this.onChanged,
    required this.title,
    required this.iconPath,
    required this.height,
    this.activeOverride,
    this.fillColor,
  });

  final T? value;
  final List<T> items;
  final String Function(T item) labelBuilder;
  final ValueChanged<T?> onChanged;
  final String title;
  final String iconPath;
  final double height;
  final bool? activeOverride;
  final Color? fillColor;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isActuallyActive = activeOverride ??
        (value != null &&
            (value is! String ||
                (value.toString().isNotEmpty &&
                    value.toString().toLowerCase() != 'all')));

    return Theme(
      data: theme.copyWith(
        hoverColor: AppColors.transparent,
        highlightColor: AppColors.transparent,
        splashColor: AppColors.transparent,
      ),
      child: PopupMenuButton<T>(
        tooltip: '',
        color: AppColors.card,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.buttonR,
        ),
        style: ButtonStyle(
          overlayColor:
              const WidgetStatePropertyAll<Color>(AppColors.transparent),
          splashFactory: NoSplash.splashFactory,
        ),
        offset: Offset(0, height),
        // Re-selecting the current value clears it. Without that there is no
        // way back to "everything" short of a reset button nobody looks for.
        onSelected: (T item) => onChanged(item == value ? null : item),
        itemBuilder: (BuildContext context) => items
            .map(
              (T item) => PopupMenuItem<T>(
                value: item,
                height: 40.sp,
                child: Text(
                  FormatHelper.capitalize(labelBuilder(item)),
                  // The chosen row is bolder; there is no tick and no
                  // highlight bar, because the button below already shows
                  // which value is active.
                  style: StyleText.fontSize14Weight500.copyWith(
                    color: AppColors.text,
                    fontWeight:
                        item == value ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ),
            )
            .toList(),
        child: ToolbarActionButton(
          title: title,
          iconPath: iconPath,
          height: height,
          fillColor: fillColor,
          isActive: isActuallyActive,
        ),
      ),
    );
  }
}

/// One toolbar control: filled rectangle, SVG glyph, optional label.
///
/// Public because pages build their own trailing actions ("Add order",
/// "Export") out of exactly this shape — a second, near-identical private
/// button in every page is how a toolbar stops looking like one toolbar.
class ToolbarActionButton extends StatelessWidget {
  const ToolbarActionButton({
    super.key,
    required this.title,
    required this.iconPath,
    this.height,
    this.width,
    this.isActive = false,
    this.fillColor,
    this.contentColor,
    this.onTap,
  });

  final String title;
  final String iconPath;
  final double? height;
  final double? width;
  final bool isActive;
  final Color? fillColor;

  /// Overrides the resting content colour — used by destructive actions, which
  /// stay red on a card fill rather than going yellow on primary.
  final Color? contentColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final bool isPhone = MediaQuery.sizeOf(context).shortestSide < 600;
    final double effectiveHeight = height ?? 38.sp;
    final Color resting = contentColor ?? AppColors.secondaryText;
    final Color content = isActive ? AppColors.textButton : resting;
    final Color background =
        isActive ? AppColors.primary : (fillColor ?? AppColors.card);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: isPhone ? effectiveHeight : (width ?? 100.sp),
        height: effectiveHeight,
        decoration: BoxDecoration(
          color: background,
          borderRadius: AppRadius.buttonR,
        ),
        child: Center(
          child: isPhone
              ? CustomSvgImage(
                  assetPath: iconPath,
                  width: 20.sp,
                  height: 20.sp,
                  color: content,
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    CustomSvgImage(
                      assetPath: iconPath,
                      width: 20.sp,
                      height: 20.sp,
                      color: content,
                    ),
                    SizedBox(width: 8.sp),
                    Flexible(
                      child: Text(
                        FormatHelper.capitalize(title),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: StyleText.fontSize14Weight500
                            .copyWith(color: content),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

/// Icon-only toolbar control — a 38.sp square. Refresh, close, the view
/// toggle: anything whose glyph is the whole message.
class ToolbarIconButton extends StatelessWidget {
  const ToolbarIconButton({
    super.key,
    required this.iconPath,
    required this.onTap,
    this.tooltip,
    this.isActive = false,
    this.fillColor,
    this.contentColor,
    this.size,
  });

  final String iconPath;
  final VoidCallback onTap;
  final String? tooltip;
  final bool isActive;
  final Color? fillColor;
  final Color? contentColor;
  final double? size;

  @override
  Widget build(BuildContext context) {
    final double dimension = size ?? 38.sp;
    final Color content = isActive
        ? AppColors.textButton
        : (contentColor ?? AppColors.secondaryText);

    final Widget button = GestureDetector(
      onTap: onTap,
      child: Container(
        width: dimension,
        height: dimension,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary : (fillColor ?? AppColors.card),
          borderRadius: AppRadius.buttonR,
        ),
        child: CustomSvgImage(
          assetPath: iconPath,
          width: 20.sp,
          height: 20.sp,
          color: content,
        ),
      ),
    );

    if (tooltip == null) return button;
    return Tooltip(message: tooltip!, child: button);
  }
}
