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

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:asec/core/custom/100-custom_data_table.dart';
import 'package:asec/core/custom/114-app_messenger.dart';
import 'package:asec/core/custom/2-custom_textfield.dart';
import 'package:asec/core/custom/5-custom_button.dart';
import 'package:asec/features/tools/t2_engineering_calc/data/calc_export.dart';
import 'package:asec/generated/l10n.dart';
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
///
/// EXPORT (09/11/2026): give [exportTitle] and the table gets "Export PDF"
/// and "Export Excel" under it — the same report files as the HVAC
/// calculator (CalcExport). [inputs] are printed above the results.
class ResultTable extends StatelessWidget {
  const ResultTable({
    super.key,
    required this.items,
    this.exportTitle,
    this.discipline = '',
    this.inputs = const <ResultItem>[],
    this.exportResults,
    this.method = '',
    this.note = '',
    this.extraTitle = '',
    this.extraHeaders = const <String>[],
    this.extraRows = const <List<String>>[],
    this.imageAsset,
    this.imageCaption = '',
  });

  /// The method (formulas) printed in the files.
  final String method;
  final String note;

  /// A second table and a drawing for the files (see CalcReport).
  final String extraTitle;
  final List<String> extraHeaders;
  final List<List<String>> extraRows;
  final String? imageAsset;
  final String imageCaption;

  final List<ResultItem> items;

  /// What the files list as results; null = [items]. For a page whose
  /// answer is split over several tables.
  final List<ResultItem>? exportResults;

  /// The report's title (e.g. "Duct sizer"); null = no export buttons.
  final String? exportTitle;
  final String discipline;
  final List<ResultItem> inputs;

  @override
  Widget build(BuildContext context) {
    final Widget table = _table();
    if (exportTitle == null) return table;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        table,
        const SizedBox(height: 12),
        _ExportButtons(table: this),
      ],
    );
  }

  Widget _table() {
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

/// "Export PDF" / "Export Excel" for a [ResultTable] — the same files as the
/// HVAC calculator (CalcExport), saved through the system Save dialog.
class _ExportButtons extends StatefulWidget {
  const _ExportButtons({required this.table});

  final ResultTable table;

  @override
  State<_ExportButtons> createState() => _ExportButtonsState();
}

class _ExportButtonsState extends State<_ExportButtons> {
  bool _busy = false;

  static CalcRow _row(ResultItem r, {bool primary = false}) {
    final double? n = double.tryParse(r.value.replaceAll(',', ''));
    return CalcRow(
      label: titleCase(r.label),
      text: r.unit.isEmpty ? r.value : '${r.value} ${r.unit}',
      number: n,
      unit: r.unit,
      primary: primary,
    );
  }

  CalcReport _report(S s, bool ar) {
    final ResultTable t = widget.table;
    return CalcReport(
        id: t.exportTitle!.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-'),
        title: titleCase(t.exportTitle!),
        discipline: t.discipline,
        arabic: ar,
        inputs: <CalcRow>[for (final ResultItem r in t.inputs) _row(r)],
        results: <CalcRow>[for (final ResultItem r in t.exportResults ?? t.items) _row(r)],
        formula: t.method,
        note: t.note,
        extraTitle: t.extraTitle,
        extraHeaders: t.extraHeaders,
        extraRows: t.extraRows,
        imageAsset: t.imageAsset,
        imageCaption: t.imageCaption,
        labels: CalcReportLabels(
          inputs: s.calcInputs,
          results: s.calcResults,
          method: s.calcFormula,
          item: s.calcItem,
          value: s.calcValue,
          unit: s.calcUnit,
          date: s.calcDate,
          disclaimer: s.calcDisclaimer,
        ),
      );
  }

  Future<void> _export({required bool excel}) async {
    if (_busy) return;
    final S s = S.of(context);
    final bool ar = Localizations.localeOf(context).languageCode == 'ar';
    final AppMessenger messenger = AppMessenger.of(context);
    final CalcReport report = _report(s, ar);
    final String fileName = '${report.fileBase}.${excel ? 'xlsx' : 'pdf'}';
    setState(() => _busy = true);
    try {
      final String? saved = excel
          ? await CalcExport.saveExcel(report, fileName: fileName, dialogTitle: s.calcExportExcel)
          : await CalcExport.savePdf(report, fileName: fileName, dialogTitle: s.calcExportPdf);
      if (saved != null) {
        messenger
          ..hide()
          ..show(AppMessage(content: Text(FormatHelper.capitalize(s.calcSaved(saved)))));
      }
    } catch (e) {
      messenger.show(AppMessage(
        content: Text(FormatHelper.capitalize(kDebugMode ? '${s.errUnknown}\n$e' : s.errUnknown)),
        duration: const Duration(seconds: 6),
      ));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final S s = S.of(context);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: <Widget>[
        for (final (bool excel, String label) in <(bool, String)>[
          (false, s.calcExportPdf),
          (true, s.calcExportExcel),
        ])
          customButton(
            title: label,
            function: () => _export(excel: excel),
            wrapContent: true,
          ),
      ],
    );
  }
}
