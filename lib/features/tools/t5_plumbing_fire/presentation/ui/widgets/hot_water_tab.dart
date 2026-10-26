/// Module: tools / t5_plumbing_fire
///
///*************************** FILE INFO ****************************///
/// File Name: hot_water_tab.dart
/// Purpose: Hot Water tab — building type, inlet / outlet temperature and
///          up to 8 fixture lines in; total and probable demand, storage
///          tank and heater power out.
/// Author: ASEC team
/// Created: 22/10/2026
library;

import 'package:flutter/material.dart';

import 'package:asec/core/custom/1-custom_dropdown.dart';
import 'package:asec/core/custom/100-custom_data_table.dart';
import 'package:asec/core/custom/5-custom_button.dart';
import 'package:asec/core/theme/app_colors.dart';
import 'package:asec/features/tools/t3_duct_calc/presentation/ui/widgets/duct_fields.dart';
import 'package:asec/features/tools/t5_plumbing_fire/domain/hot_water.dart';

class HotWaterTab extends StatefulWidget {
  const HotWaterTab({super.key});

  @override
  State<HotWaterTab> createState() => _HotWaterTabState();
}

class _HotWaterTabState extends State<HotWaterTab> {
  final TextEditingController _inlet = TextEditingController(text: '10');
  final TextEditingController _outlet = TextEditingController(text: '60');
  final TextEditingController _qty = TextEditingController(text: '1');
  int _building = 0;
  HotWaterFixture _fixture = HotWaterFixture.privateLavatory;

  /// Fixture lines, in the order they were added.
  final Map<HotWaterFixture, int> _lines = <HotWaterFixture, int>{};
  String? _message;

  @override
  void dispose() {
    _inlet.dispose();
    _outlet.dispose();
    _qty.dispose();
    super.dispose();
  }

  HotWaterBuilding get _b => kHotWaterBuildings[_building];

  void _add() {
    final int? q = int.tryParse(_qty.text.trim());
    setState(() {
      if (q == null || q <= 0) {
        _message = 'Please enter the fixture quantity.';
      } else if (!_lines.containsKey(_fixture) && _lines.length >= kMaxFixtureLines) {
        _message = "You can't add more than $kMaxFixtureLines fixture types.";
      } else {
        _lines[_fixture] = (_lines[_fixture] ?? 0) + q;
        _message = null;
      }
    });
  }

  void _remove(HotWaterFixture f) => setState(() => _lines.remove(f));

  @override
  Widget build(BuildContext context) {
    final double? tin = parseNumber(_inlet.text);
    final double? tout = parseNumber(_outlet.text);
    String? error = _message;
    HotWaterResult? r;
    if (_lines.isEmpty) {
      error ??= 'Add at least one fixture.';
    } else if (tin == null || tout == null) {
      error ??= 'Please enter the inlet and outlet temperatures.';
    } else if (tout <= tin) {
      error ??= 'The outlet temperature must be above the inlet.';
    } else {
      r = HotWater.calculate(building: _b, fixtures: _lines, inletC: tin, outletC: tout);
    }
    final List<MapEntry<HotWaterFixture, int>> lines = _lines.entries.toList();

    return ListView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.symmetric(vertical: 16),
      children: <Widget>[
        ResponsiveFields(
          children: <Widget>[
            SizedBox(
              width: 240,
              child: CustomDropdown<int>(
                fillColor: AppColors.card,
                label: 'Building Type',
                value: _building,
                maxOverlayHeight: 360,
                items: <DropdownItem<int>>[
                  for (int i = 0; i < kHotWaterBuildings.length; i++)
                    DropdownItem<int>(value: i, label: kHotWaterBuildings[i].label),
                ],
                onChanged: (int? i) {
                  if (i != null) setState(() => _building = i);
                },
              ),
            ),
            NumberField(controller: _inlet, label: 'Inlet temperature', unit: '°C', onChanged: (_) => setState(() {})),
            NumberField(controller: _outlet, label: 'Outlet temperature', unit: '°C', onChanged: (_) => setState(() {})),
          ],
        ),
        const SizedBox(height: 16),
        ResponsiveFields(
          children: <Widget>[
            SizedBox(
              width: 240,
              child: CustomDropdown<HotWaterFixture>(
                fillColor: AppColors.card,
                label: 'Fixture Type',
                value: _fixture,
                maxOverlayHeight: 360,
                items: <DropdownItem<HotWaterFixture>>[
                  for (final HotWaterFixture f in HotWaterFixture.values)
                    DropdownItem<HotWaterFixture>(value: f, label: f.label),
                ],
                onChanged: (HotWaterFixture? f) {
                  if (f != null) setState(() => _fixture = f);
                },
              ),
            ),
            NumberField(controller: _qty, label: 'Fixture quantity'),
            customButton(title: 'Add', function: _add, wrapContent: true),
          ],
        ),
        const SizedBox(height: 16),
        if (lines.isNotEmpty) ...<Widget>[
          AppDataTable<MapEntry<HotWaterFixture, int>>(
            shrinkWrap: true,
            cardsOnTablet: false,
            rows: lines,
            columns: <AppTableColumn<MapEntry<HotWaterFixture, int>>>[
              AppTableColumn<MapEntry<HotWaterFixture, int>>(
                label: 'Fixture Type',
                flex: 3,
                cell: (BuildContext c, MapEntry<HotWaterFixture, int> e) =>
                    AppTableCellText(e.key.label, emphasis: true),
              ),
              AppTableColumn<MapEntry<HotWaterFixture, int>>(
                label: 'Qty',
                cell: (BuildContext c, MapEntry<HotWaterFixture, int> e) =>
                    AppTableCellText('${e.value}'),
              ),
              AppTableColumn<MapEntry<HotWaterFixture, int>>(
                label: 'L/h',
                flex: 2,
                cell: (BuildContext c, MapEntry<HotWaterFixture, int> e) {
                  final double each = _b.demandOf(e.key);
                  return AppTableCellText(
                    each == 0 ? 'not used here' : fmt(each * e.value, 1),
                  );
                },
              ),
              AppTableColumn<MapEntry<HotWaterFixture, int>>(
                label: '',
                fixedWidth: 48,
                cell: (BuildContext c, MapEntry<HotWaterFixture, int> e) => IconButton(
                  tooltip: 'Remove',
                  icon: Icon(Icons.close_rounded, color: AppColors.red, size: 18),
                  onPressed: () => _remove(e.key),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
        if (error != null)
          Text(error)
        else if (r != null)
          ResultTable(
            items: <ResultItem>[
              ResultItem('Total possible max demand', fmt(r.totalDemand, 1), 'L/h'),
              ResultItem('Demand factor', fmt(r.demandFactor, 2)),
              ResultItem('Probable max demand', fmt(r.probableDemand, 1), 'L/h'),
              ResultItem('Storage factor', fmt(r.storageFactor, 2)),
              ResultItem('Storage heater tank capacity', fmt(r.tankCapacity, 0), 'L'),
              ResultItem('Power consumption (Q)', fmt(r.power, 0), 'kW'),
            ],
          ),
      ],
    );
  }
}
