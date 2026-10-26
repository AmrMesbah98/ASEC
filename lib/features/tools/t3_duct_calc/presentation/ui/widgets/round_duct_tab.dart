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
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:asec/core/custom/1-custom_dropdown.dart';
import 'package:asec/core/custom/100-custom_data_table.dart';
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

  /// Index into the diameter lists, so switching units keeps the same size.
  int _diameter = 0;

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
    final double dM = _ip
        ? kFlexibleDuctDiametersIn[_diameter] * _mPerIn
        : kFlexibleDuctDiametersMm[_diameter] / 1000.0;
    final double v = flowM3s / (math.pi * dM * dM / 4);
    final double dpm = DuctCalculator.roundPressureDropPerMetre(
      flowM3s: flowM3s,
      diameterM: dM,
      roughnessM: RoundDuctType.flexible.roughnessM,
    );

    return <_FlexRow>[
      _ip
          ? _FlexRow('Ø ${kFlexibleDuctDiametersIn[_diameter]} in', v * _fpmPerMs,
              dpm * _inwgPer100ftPerPaM)
          : _FlexRow('Ø ${kFlexibleDuctDiametersMm[_diameter]} mm', v, dpm),
    ];
  }

  List<AppTableColumn<_FlexRow>> _columns() {
    AppTableColumn<_FlexRow> col(
      String label,
      String Function(_FlexRow r) value, {
      bool emphasis = false,
    }) {
      return AppTableColumn<_FlexRow>(
        label: label,
        cell: (BuildContext context, _FlexRow r) =>
            AppTableCellText(value(r), emphasis: emphasis),
      );
    }

    return <AppTableColumn<_FlexRow>>[
      col(_ip ? 'Ø (in)' : 'Ø (mm)', (_FlexRow r) => r.diameter, emphasis: true),
      _ip
          ? col('Vel (fpm)', (_FlexRow r) => fmt(r.velocity, 0))
          : col('Vel (m/s)', (_FlexRow r) => fmt(r.velocity, 2)),
      _ip
          ? col('dP (in.wg/100 ft)', (_FlexRow r) => fmt(r.pressureDrop, 3))
          : col('dP (Pa/m)', (_FlexRow r) => fmt(r.pressureDrop, 1)),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final List<_FlexRow> rows = _rows();
    final List<AppTableColumn<_FlexRow>> columns = _columns();
    final List<int> sizes = _ip ? kFlexibleDuctDiametersIn : kFlexibleDuctDiametersMm;

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
            SizedBox(
              width: 240,
              child: CustomDropdown<int>(
                fillColor: AppColors.card,
                label: _ip ? 'Diameter (in)' : 'Diameter (mm)',
                value: _diameter,
                items: <DropdownItem<int>>[
                  for (int i = 0; i < sizes.length; i++)
                    DropdownItem<int>(value: i, label: '${sizes[i]}'),
                ],
                onChanged: (int? i) {
                  if (i != null) setState(() => _diameter = i);
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (rows.isEmpty)
          const Text('Enter the air flow.')
        else
          AppDataTable<_FlexRow>(
            shrinkWrap: true,
            rows: rows,
            columns: columns,
            // Phone / tablet: one full-width card.
            cardBuilder: (BuildContext context, _FlexRow r) =>
                ductCard<_FlexRow>(context, r, columns),
          ),
      ],
    );
  }
}
