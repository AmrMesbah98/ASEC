/// Module: tools / t3_duct_calc
///
///*************************** FILE INFO ****************************///
/// File Name: duct_fields.dart
/// Purpose: Shared pieces for the duct tabs, built on the app's own
///          controls — a numeric CustomTextField, a responsive field row,
///          a full-width card for AppDataTable on phones, a two-column
///          result table, and number helpers.
/// Author: ASEC team
/// Created: 21/10/2026
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:asec/core/custom/100-custom_data_table.dart';
import 'package:asec/core/custom/2-custom_textfield.dart';
import 'package:asec/core/helper/main_helper/format_helper.dart';
import 'package:asec/core/theme/app_colors.dart';
import 'package:asec/core/theme/app_padding.dart';
import 'package:asec/core/theme/app_radius.dart';
import 'package:asec/core/theme/app_theme.dart';

/// Below this width the inputs stack one per line, each full width.
const double kDuctNarrowWidth = 600;

/// Parses a user-typed number ("1,5" is accepted as 1.5). Null if invalid.
double? parseNumber(String text) {
  final String t = text.trim().replaceAll(',', '.');
  if (t.isEmpty) return null;
  return double.tryParse(t);
}

/// Every Word Capitalised — the calculators' labels (26/10/2026, Eng.
/// Ahmed Shuhayb). Only a lower-case first letter changes, so symbols,
/// units passed separately and words already in capitals ("CO₂", "FM-200") stay.
String titleCase(String text) => text.splitMapJoin(
      RegExp(r'[A-Za-z][^\s/()\-]*'),
      onMatch: (Match m) {
        final String w = m[0]!;
        // A unit in brackets stays as written: "Volume (gal)", "(in)".
        if (m.start > 0 && text[m.start - 1] == '(') return w;
        // Small joining words stay small inside a label: "Flow per Area".
        if (m.start > 0 && isSmallWord(w)) return lowerSmallWord(w);
        final String first = w[0];
        return first == first.toLowerCase() && first != first.toUpperCase()
            ? '${first.toUpperCase()}${w.substring(1)}'
            : w;
      },
    );

/// At most [decimals] — and never more than 2 — decimals, trailing zeros
/// dropped (14.50 → 14.5, 3.00 → 3); "-" for NaN / infinity / null.
/// (03/11/2026: two digits after the point, no useless zeros.)
String fmt(double? value, int decimals) {
  if (value == null || !value.isFinite) return '-';
  final String s = value.toStringAsFixed(decimals > 2 ? 2 : decimals);
  final String t = s.contains('.') ? s.replaceFirst(RegExp(r'\.?0+$'), '') : s;
  return t == '-0' ? '0' : t;
}

/// Whole number with thousands separators (Reynolds number).
String fmtGrouped(double? value) {
  if (value == null || !value.isFinite) return '-';
  final String digits = value.round().abs().toString();
  final StringBuffer out = StringBuffer(value < 0 ? '-' : '');
  for (int i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) out.write(',');
    out.write(digits[i]);
  }
  return out.toString();
}

/// A numeric [CustomTextField]; the unit goes in the label: "Flow (l/s)".
/// [width] is used on wide screens; inside [ResponsiveFields] on a phone
/// the field is stretched to the full width.
class NumberField extends StatelessWidget {
  const NumberField({
    super.key,
    required this.controller,
    required this.label,
    this.unit,
    this.onChanged,
    this.readOnly = false,
    this.width = 200,
  });

  final TextEditingController controller;
  final String label;
  final String? unit;
  final ValueChanged<String>? onChanged;
  final bool readOnly;
  final double width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: CustomTextField(
        controller: controller,
        fillColor: AppColors.card,
        label: (unit == null || unit!.isEmpty) ? titleCase(label) : '${titleCase(label)} ($unit)',
        readOnly: readOnly,
        onChanged: onChanged,
        textDirection: TextDirection.ltr,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: <TextInputFormatter>[
          FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
        ],
      ),
    );
  }
}

/// Inputs side by side on a wide screen; on a phone one per line, each
/// stretched to the full width (a tight width overrides the child's own).
class ResponsiveFields extends StatelessWidget {
  const ResponsiveFields({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints c) {
        if (c.maxWidth >= kDuctNarrowWidth) {
          return Wrap(
            spacing: 16,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.end,
            children: children,
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            for (int i = 0; i < children.length; i++) ...<Widget>[
              if (i > 0) const SizedBox(height: 12),
              SizedBox(width: c.maxWidth, child: children[i]),
            ],
          ],
        );
      },
    );
  }
}

/// The card AppDataTable draws on a phone / tablet, full width: the first
/// column is the heading, every other column is a line with its label on
/// the left and its value on the right edge.
///
/// Heights match AppDataTable's own card measure (12 + 46 + 26 per line +
/// 12) so the grid cell always fits.
Widget ductCard<T>(
  BuildContext context,
  T row,
  List<AppTableColumn<T>> columns,
) {
  return Container(
    padding: EdgeInsets.symmetric(horizontal: AppPadding.h, vertical: 12),
    decoration: BoxDecoration(
      color: AppColors.background,
      borderRadius: AppRadius.containerR,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        SizedBox(
          height: 46,
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: columns.first.cell(context, row),
          ),
        ),
        for (final AppTableColumn<T> column in columns.skip(1))
          SizedBox(
            height: 26,
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    FormatHelper.capitalize(column.label),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: StyleText.fontSize12Weight500
                        .copyWith(color: AppColors.secondaryText),
                  ),
                ),
                const SizedBox(width: 12),
                column.cell(context, row),
              ],
            ),
          ),
      ],
    ),
  );
}

/// One line of a [ResultTable].
class ResultItem {
  const ResultItem(this.label, this.value, [this.unit = '']);

  final String label;
  final String value;
  final String unit;
}

/// Results as a two-column table (Item | Value), in the same look as the
/// Flexible Duct table (03/11/2026): a header row in the primary colour,
/// card-coloured rows with thin lines between them, rounded corners.
class ResultTable extends StatelessWidget {
  const ResultTable({super.key, required this.items});

  final List<ResultItem> items;

  @override
  Widget build(BuildContext context) {
    final TextStyle head = StyleText.fontSize13Weight600.copyWith(color: AppColors.textButton);
    final TextStyle label = StyleText.fontSize14Weight600.copyWith(color: AppColors.text);
    final TextStyle value = StyleText.fontSize14Weight500.copyWith(color: AppColors.text);

    Widget cell(String text, TextStyle style) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Text(text, style: style),
        );

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: ColoredBox(
        color: AppColors.card,
        child: Table(
          columnWidths: const <int, TableColumnWidth>{
            0: FlexColumnWidth(3),
            1: FlexColumnWidth(2),
          },
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          border: TableBorder(
            horizontalInside: BorderSide(color: AppColors.secondaryText.withOpacity(0.12)),
          ),
          children: <TableRow>[
            TableRow(
              decoration: BoxDecoration(color: AppColors.primary),
              children: <Widget>[cell('Item', head), cell('Value', head)],
            ),
            for (final ResultItem r in items)
              TableRow(
                children: <Widget>[
                  cell(titleCase(r.label), label),
                  cell(r.unit.isEmpty ? r.value : '${r.value} ${r.unit}', value),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
