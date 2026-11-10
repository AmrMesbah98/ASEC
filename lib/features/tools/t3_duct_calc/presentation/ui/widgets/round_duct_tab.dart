/// Module: tools / t3_duct_calc
///
///*************************** FILE INFO ****************************///
/// File Name: round_duct_tab.dart
/// Purpose: Flexible Duct tab — air flow (l/s) and a diameter
///          (100 / 150 / 200 / 250 / 300 mm) in; velocity and pressure
///          drop per metre out. Always flexible duct, length fixed at 1 m.
/// Author: ASEC team
/// Created: 21/10/2026
/// Updated: 23/10/2026 - Renamed to Flexible Duct: duct length and duct
///          type removed (1 m, flexible), diameter picked from a dropdown,
///          only Vel and dP shown.
/// Updated: 25/10/2026 - Units: Metric (l/s, mm, m/s, Pa/m) or Inch
///          (CFM, in, fpm, in.wg/100 ft). Same calculation underneath.
/// Updated: 02/11/2026 - Every diameter of the old dropdown is a row of the
///          table (100 … 300 mm / 4 … 12 in), so all sizes compare at once;
///          the diameter dropdown is gone.
library;

import 'dart:math' as math;

import 'package:asec/core/helper/main_helper/format_helper.dart';
import 'package:flutter/material.dart';

import 'package:asec/core/custom/1-custom_dropdown.dart';
import 'package:asec/core/theme/app_theme.dart';
import 'package:asec/core/theme/app_colors.dart';
import 'package:asec/features/tools/t3_duct_calc/domain/duct_calculator.dart';
import 'package:asec/features/tools/t3_duct_calc/domain/duct_sizer_calculator.dart' show SizerUnits;
import 'package:asec/features/tools/t3_duct_calc/domain/duct_data.dart';
import 'package:asec/features/tools/t3_duct_calc/presentation/ui/widgets/duct_fields.dart';

/// Diameters offered by the Flexible Duct dropdown — the same five sizes in
/// each unit system (100 mm ≈ 4 in, … 300 mm ≈ 12 in).
const List<int> kFlexibleDuctDiametersMm = <int>[100, 150, 200, 250, 300];
const List<int> kFlexibleDuctDiametersIn = <int>[4, 6, 8, 10, 12];

/// Unit conversions used by the Inch mode.
const double _lsPerCfm = 0.4719474;
const double _mPerIn = 0.0254;
const double _fpmPerMs = 196.8504;

/// Pa/m → in.wg per 100 ft (100 ft = 30.48 m, 1 in.wg = 249.089 Pa).
const double _inwgPer100ftPerPaM = 30.48 / 249.089;

class _FlexRow {
  const _FlexRow(this.diameter, this.velocity, this.pressureDrop);

  /// "Ø 150 mm" / "Ø 6 in"
  final String diameter;

  /// m/s or fpm
  final double velocity;

  /// Pa/m or in.wg/100 ft
  final double pressureDrop;
}

class FlexibleDuctTab extends StatefulWidget {
  const FlexibleDuctTab({super.key});

  @override
  State<FlexibleDuctTab> createState() => _FlexibleDuctTabState();
}

class _FlexibleDuctTabState extends State<FlexibleDuctTab> {
  SizerUnits _units = SizerUnits.si;

  final TextEditingController _flow = TextEditingController(text: '183.7');

  bool get _ip => _units == SizerUnits.ip;

  @override
  void dispose() {
    _flow.dispose();
    super.dispose();
  }

  /// Switching units converts the airflow already typed.
  void _setUnits(SizerUnits u) {
    if (u == _units) return;
    final double? q = parseNumber(_flow.text);
    setState(() {
      _units = u;
      if (q != null) {
        _flow.text = u == SizerUnits.ip ? fmt(q / _lsPerCfm, 0) : fmt(q * _lsPerCfm, 1);
      }
    });
  }

  List<_FlexRow> _rows() {
    final double? q = parseNumber(_flow.text);
    if (q == null || q <= 0) return const <_FlexRow>[];

    final double flowM3s = (_ip ? q * _lsPerCfm : q) / 1000.0;

    // One row per diameter (the sizes the dropdown used to offer).
    return <_FlexRow>[
      for (int i = 0; i < kFlexibleDuctDiametersMm.length; i++) _row(flowM3s, i),
    ];
  }

  _FlexRow _row(double flowM3s, int i) {
    final double dM = _ip
        ? kFlexibleDuctDiametersIn[i] * _mPerIn
        : kFlexibleDuctDiametersMm[i] / 1000.0;
    final double v = flowM3s / (math.pi * dM * dM / 4);
    final double dpm = DuctCalculator.roundPressureDropPerMetre(
      flowM3s: flowM3s,
      diameterM: dM,
      roughnessM: RoundDuctType.flexible.roughnessM,
    );
    return _ip
        ? _FlexRow('${kFlexibleDuctDiametersIn[i]}', v * _fpmPerMs, dpm * _inwgPer100ftPerPaM)
        : _FlexRow('${kFlexibleDuctDiametersMm[i]}', v, dpm);
  }

  @override
  Widget build(BuildContext context) {
    final List<_FlexRow> rows = _rows();

    return ListView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.symmetric(vertical: 16),
      children: <Widget>[
        ResponsiveFields(
          children: <Widget>[
            SizedBox(
              width: 200,
              child: CustomDropdown<SizerUnits>(
                fillColor: AppColors.card,
                label: 'Units',
                value: _units,
                items: const <DropdownItem<SizerUnits>>[
                  DropdownItem<SizerUnits>(value: SizerUnits.si, label: 'Metric'),
                  DropdownItem<SizerUnits>(value: SizerUnits.ip, label: 'Imperial'),
                ],
                onChanged: (SizerUnits? u) {
                  if (u != null) _setUnits(u);
                },
              ),
            ),
            NumberField(
              controller: _flow,
              label: 'Air volume flow',
              unit: _ip ? 'CFM' : 'l/s',
              onChanged: (_) => setState(() {}),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (rows.isEmpty)
          Text(FormatHelper.capitalize('Enter the air flow.'))
        else
          // A REAL TABLE on every screen (03/11/2026): AppDataTable turns
          // into one card per row below 720 px; three short columns fit a
          // phone, so all diameters read side by side.
          _FlexTable(rows: rows, ip: _ip),
      ],
    );
  }
}

/// Ø | Vel | dP — header row, then one row per diameter, theme colours.
class _FlexTable extends StatelessWidget {
  const _FlexTable({required this.rows, required this.ip});

  final List<_FlexRow> rows;
  final bool ip;

  @override
  Widget build(BuildContext context) {
    final TextStyle head = StyleText.fontSize13Weight600.copyWith(color: AppColors.textButton);
    final TextStyle cell = StyleText.fontSize14Weight500.copyWith(color: AppColors.text);
    final TextStyle first = StyleText.fontSize14Weight600.copyWith(color: AppColors.text);

    Widget pad(Widget child) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          child: child,
        );
    Widget text(String v, TextStyle style) =>
        pad(Text(v, textAlign: TextAlign.center, style: style));

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.card,
          border: Border.all(color: AppColors.secondaryText.withOpacity(0.12)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Table(
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          border: TableBorder(
            horizontalInside: BorderSide(color: AppColors.secondaryText.withOpacity(0.12)),
          ),
          children: <TableRow>[
            TableRow(
              decoration: BoxDecoration(color: AppColors.primary),
              children: <Widget>[
                text(ip ? 'Ø (in)' : 'Ø (mm)', head),
                text(ip ? 'Vel (FPM)' : 'Vel (m/s)', head),
                text(ip ? 'dP (in.wg/100ft)' : 'dP (Pa/m)', head),
              ],
            ),
            for (final _FlexRow r in rows)
              TableRow(
                children: <Widget>[
                  text(r.diameter, first),
                  text(fmt(r.velocity, ip ? 0 : 2), cell),
                  text(fmt(r.pressureDrop, ip ? 3 : 1), cell),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
