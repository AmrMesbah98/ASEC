/// Module: tools / t5_plumbing_fire
///
///*************************** FILE INFO ****************************///
/// File Name: storm_water_tab.dart
/// Purpose: Storm Water tab — roof area, rainfall rate and slope in;
///          vertical / horizontal leader, gutter size and count out, plus
///          the "actual gutter" check (by number or by diameter).
/// Author: ASEC team
/// Created: 22/10/2026
library;

import 'package:asec/core/helper/main_helper/format_helper.dart';
import 'package:flutter/material.dart';

import 'package:asec/core/custom/1-custom_dropdown.dart';
import 'package:asec/core/theme/app_colors.dart';
import 'package:asec/features/tools/t3_duct_calc/presentation/ui/widgets/duct_fields.dart';
import 'package:asec/features/tools/t5_plumbing_fire/domain/storm_water.dart';

enum _AreaUnit { m2, ft2 }

enum _GutterMode { byNumber, byDiameter }

class StormWaterTab extends StatefulWidget {
  const StormWaterTab({super.key});

  @override
  State<StormWaterTab> createState() => _StormWaterTabState();
}

class _StormWaterTabState extends State<StormWaterTab> {
  final TextEditingController _area = TextEditingController(text: '500');
  final TextEditingController _count = TextEditingController(text: '2');
  _AreaUnit _unit = _AreaUnit.m2;
  int _rate = 2; // 2 in/h
  int _slope = 1; // 1 %
  _GutterMode _mode = _GutterMode.byNumber;
  double _diameter = 6;

  @override
  void dispose() {
    _area.dispose();
    _count.dispose();
    super.dispose();
  }

  double? _areaM2() {
    final double? a = parseNumber(_area.text);
    if (a == null || a <= 0) return null;
    return _unit == _AreaUnit.m2 ? a : a * StormWater.ft2ToM2;
  }

  String _in(double size) => '${_trim(size)}"';

  static String _trim(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toString();

  List<ResultItem> _actualItems(double areaM2) {
    if (_mode == _GutterMode.byNumber) {
      final int n = int.tryParse(_count.text.trim()) ?? 0;
      if (n <= 0) return const <ResultItem>[ResultItem('Actual gutter', 'Enter the number of gutters')];
      if (StormWater.gutterCountTooSmall(roofAreaM2: areaM2, rateIndex: _rate, count: n)) {
        return const <ResultItem>[ResultItem('Actual gutter', 'Not enough — use more gutters')];
      }
      final double size = StormWater.gutterSizeForCount(roofAreaM2: areaM2, rateIndex: _rate, count: n);
      return <ResultItem>[ResultItem('Actual diameter of gutters required', _in(size))];
    }
    final int n = StormWater.gutterCountForSize(roofAreaM2: areaM2, rateIndex: _rate, diameter: _diameter);
    return <ResultItem>[ResultItem('Actual number of gutters required', '$n', 'gutters')];
  }

  @override
  Widget build(BuildContext context) {
    final double? area = _areaM2();
    final StormResult? r = area == null
        ? null
        : StormWater.calculate(roofAreaM2: area, rateIndex: _rate, slopeIndex: _slope);
    void changed(String _) => setState(() {});

    return ListView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.symmetric(vertical: 16),
      children: <Widget>[
        ResponsiveFields(
          children: <Widget>[
            NumberField(controller: _area, label: 'Projected roof area', onChanged: changed),
            SizedBox(
              width: 140,
              child: CustomDropdown<_AreaUnit>(
                fillColor: AppColors.card,
                label: 'Area Unit',
                value: _unit,
                items: const <DropdownItem<_AreaUnit>>[
                  DropdownItem<_AreaUnit>(value: _AreaUnit.m2, label: 'm²'),
                  DropdownItem<_AreaUnit>(value: _AreaUnit.ft2, label: 'ft²'),
                ],
                onChanged: (_AreaUnit? u) {
                  if (u != null) setState(() => _unit = u);
                },
              ),
            ),
            SizedBox(
              width: 220,
              child: CustomDropdown<int>(
                fillColor: AppColors.card,
                label: 'Rainfall Rate',
                value: _rate,
                items: <DropdownItem<int>>[
                  for (int i = 0; i < kRainfallRatesInH.length; i++)
                    DropdownItem<int>(
                      value: i,
                      label: '${_trim(kRainfallRatesInH[i])} in/h (${(kRainfallRatesInH[i] * 25.4).round()} mm/h)',
                    ),
                ],
                onChanged: (int? i) {
                  if (i != null) setState(() => _rate = i);
                },
              ),
            ),
            SizedBox(
              width: 240,
              child: CustomDropdown<int>(
                fillColor: AppColors.card,
                label: 'Horizontal Pipes Slope',
                value: _slope,
                items: <DropdownItem<int>>[
                  for (int i = 0; i < kStormSlopes.length; i++)
                    DropdownItem<int>(value: i, label: kStormSlopes[i]),
                ],
                onChanged: (int? i) {
                  if (i != null) setState(() => _slope = i);
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (r == null || area == null)
          Text(FormatHelper.capitalize('Enter the projected roof area.'))
        else ...<Widget>[
          Text(FormatHelper.capitalize('Pipes')),
          const SizedBox(height: 8),
          ResultTable(
            items: <ResultItem>[
              ResultItem('Vertical conductor (leader)', _in(r.verticalLeader)),
              ResultItem('Horizontal conductor', _in(r.horizontalLeader)),
            ],
          ),
          const SizedBox(height: 24),
          Text(FormatHelper.capitalize('Gutters')),
          const SizedBox(height: 8),
          ResultTable(
            items: <ResultItem>[
              ResultItem('Calculated gutter diameter', _in(r.gutterSize)),
              ResultItem('Calculated number of gutters', '${r.gutterCount}', 'gutters'),
              ResultItem('Area ÷ gutter capacity', fmt(r.gutterRatio, 3)),
            ],
          ),
          const SizedBox(height: 24),
          Text(FormatHelper.capitalize('Actual Gutter')),
          const SizedBox(height: 8),
          ResponsiveFields(
            children: <Widget>[
              SizedBox(
                width: 200,
                child: CustomDropdown<_GutterMode>(
                  fillColor: AppColors.card,
                  label: 'Choose By',
                  value: _mode,
                  items: const <DropdownItem<_GutterMode>>[
                    DropdownItem<_GutterMode>(value: _GutterMode.byNumber, label: 'Number Of Gutters'),
                    DropdownItem<_GutterMode>(value: _GutterMode.byDiameter, label: 'Gutter Diameter'),
                  ],
                  onChanged: (_GutterMode? m) {
                    if (m != null) setState(() => _mode = m);
                  },
                ),
              ),
              if (_mode == _GutterMode.byNumber)
                NumberField(controller: _count, label: 'Number Of Gutters', onChanged: changed)
              else
                SizedBox(
                  width: 200,
                  child: CustomDropdown<double>(
                    fillColor: AppColors.card,
                    label: 'Gutter Diameter',
                    value: _diameter,
                    items: <DropdownItem<double>>[
                      for (final double d in kGutterSizes)
                        DropdownItem<double>(value: d, label: _in(d)),
                    ],
                    onChanged: (double? d) {
                      if (d != null) setState(() => _diameter = d);
                    },
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          ResultTable(items: _actualItems(area)),
          const SizedBox(height: 16),
          Text(FormatHelper.capitalize('As per the National Standard Plumbing Code (NSPC), tables 13.6.1 and 13.6.2.'),
          ),
        ],
      ],
    );
  }
}
