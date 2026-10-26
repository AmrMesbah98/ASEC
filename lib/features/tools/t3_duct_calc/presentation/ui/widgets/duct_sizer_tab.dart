/// Module: tools / t3_duct_calc
///
///*************************** FILE INFO ****************************///
/// File Name: duct_sizer_tab.dart
/// Purpose: Duct Sizer tab — pick the air condition and units, tick any
///          two of flow / head loss / velocity / diameter, type them, and
///          the other two plus Reynolds number, friction factor, velocity
///          pressure and an equivalent rectangle are solved.
/// Author: ASEC team
/// Created: 21/10/2026
/// Updated: 22/10/2026 - Clear uses the core `customButton`.
/// Updated: 23/10/2026 - Duct side B fills itself from the result table
///          (the sized rectangle) until the user types their own value;
///          emptying it hands it back to auto.
library;

import 'package:flutter/material.dart';

import 'package:asec/core/custom/1-custom_dropdown.dart';
import 'package:asec/core/custom/23-custom_check_box.dart';
import 'package:asec/core/custom/5-custom_button.dart';
import 'package:asec/core/theme/app_colors.dart';
import 'package:asec/features/tools/t3_duct_calc/domain/duct_data.dart';
import 'package:asec/features/tools/t3_duct_calc/domain/duct_sizer_calculator.dart';
import 'package:asec/features/tools/t3_duct_calc/presentation/ui/widgets/duct_fields.dart';

class DuctSizerTab extends StatefulWidget {
  const DuctSizerTab({super.key});

  @override
  State<DuctSizerTab> createState() => _DuctSizerTabState();
}

class _DuctSizerTabState extends State<DuctSizerTab> {
  final Map<SizerField, TextEditingController> _fields =
      <SizerField, TextEditingController>{
    for (final SizerField f in SizerField.values) f: TextEditingController(),
  };
  final TextEditingController _sideA = TextEditingController();
  final TextEditingController _sideB = TextEditingController();

  /// True while side B shows the solved value; false once the user types
  /// their own. Emptying the field (or Clear) switches back to auto.
  bool _sideBAuto = true;

  /// The two ticked inputs, oldest first. Ticking a third drops the oldest.
  final List<SizerField> _ticked = <SizerField>[
    SizerField.flow,
    SizerField.headLoss,
  ];

  SizerUnits _units = SizerUnits.ip;
  int _air = 0;
  SizerResult? _result;
  String? _error;

  @override
  void dispose() {
    for (final TextEditingController c in _fields.values) {
      c.dispose();
    }
    _sideA.dispose();
    _sideB.dispose();
    super.dispose();
  }

  /// Decimals shown for each field, per unit system.
  int _decimals(SizerField f) {
    final bool ip = _units == SizerUnits.ip;
    switch (f) {
      case SizerField.flow:
        return ip ? 0 : 1;
      case SizerField.headLoss:
        return ip ? 3 : 2;
      case SizerField.velocity:
        return 1;
      case SizerField.diameter:
        return ip ? 1 : 0;
    }
  }

  void _toggle(SizerField f) {
    setState(() {
      if (_ticked.contains(f)) {
        _ticked.remove(f);
      } else {
        _ticked.add(f);
        if (_ticked.length > 2) _ticked.removeAt(0);
      }
    });
    _recompute();
  }

  void _clear() {
    for (final TextEditingController c in _fields.values) {
      c.clear();
    }
    _sideA.clear();
    _sideB.clear();
    _sideBAuto = true;
    setState(() {
      _result = null;
      _error = null;
    });
  }

  void _recompute() {
    // Boxes that are not ticked only ever show solved values.
    for (final SizerField f in SizerField.values) {
      if (!_ticked.contains(f)) _fields[f]!.clear();
    }
    // An auto side B is solved again, never fed back in as an input.
    if (_sideBAuto) _sideB.clear();
    if (_ticked.length != 2) {
      setState(() {
        _result = null;
        _error = 'Tick two values to solve the other two.';
      });
      return;
    }
    final Map<SizerField, double> given = <SizerField, double>{};
    for (final SizerField f in _ticked) {
      final double? v = parseNumber(_fields[f]!.text);
      if (v == null || v <= 0) {
        setState(() {
          _result = null;
          _error = 'You must enter a ${SizerLabels.name(f).toLowerCase()}.';
        });
        return;
      }
      given[f] = v;
    }
    try {
      final SizerResult r = DuctSizerCalculator.solve(
        given: given,
        air: kAirConditions[_air],
        units: _units,
        sideA: parseNumber(_sideA.text),
        sideB: _sideBAuto ? null : parseNumber(_sideB.text),
      );
      if (_sideBAuto && r.rectSideB != null) {
        _sideB.text = fmt(r.rectSideB, _units == SizerUnits.ip ? 1 : 0);
      }
      for (final SizerField f in SizerField.values) {
        if (!_ticked.contains(f)) {
          _fields[f]!.text = fmt(r.fields[f], _decimals(f));
        }
      }
      setState(() {
        _result = r;
        _error = null;
      });
    } on DuctSizerException catch (e) {
      setState(() {
        _result = null;
        _error = e.message;
      });
    }
  }

  /// Tick box + field. On a phone the field fills the rest of the line.
  Widget _fieldRow(SizerField f, bool narrow) {
    final bool ticked = _ticked.contains(f);
    final Widget field = NumberField(
      controller: _fields[f]!,
      label: SizerLabels.name(f),
      unit: SizerLabels.unit(f, _units),
      readOnly: !ticked,
      width: 280,
      onChanged: (_) => _recompute(),
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _toggle(f),
              child: CustomCheckBox(isSelected: ticked),
            ),
          ),
          const SizedBox(width: 12),
          if (narrow) Expanded(child: field) else field,
        ],
      ),
    );
  }

  List<ResultItem> _resultItems(SizerResult r) {
    final bool ip = _units == SizerUnits.ip;
    final String len = ip ? 'in' : 'mm';
    return <ResultItem>[
      if (r.rectEquivalentDiameter != null) ...<ResultItem>[
        ResultItem(
          'Rectangle',
          '${fmt(r.rectSideA, ip ? 1 : 0)} × ${fmt(r.rectSideB, ip ? 1 : 0)}',
          len,
        ),
        ResultItem('Equivalent diameter', fmt(r.rectEquivalentDiameter, ip ? 1 : 0), len),
      ],
      ResultItem('Flow area', fmt(r.flowArea, 4), ip ? 'ft²' : 'm²'),
      ResultItem('Fluid velocity', fmt(r.velocity, ip ? 1 : 2), ip ? 'ft/min' : 'm/s'),
      ResultItem('Reynolds number', fmtGrouped(r.reynolds)),
      ResultItem('Friction factor', fmt(r.frictionFactor, 5)),
      ResultItem('Velocity pressure', fmt(r.velocityPressure, ip ? 4 : 1), ip ? 'in.WC' : 'Pa'),
      ResultItem('Head loss', fmt(r.headLoss, ip ? 3 : 2), ip ? 'in.WC/100 ft' : 'Pa/m'),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final bool ip = _units == SizerUnits.ip;
    final SizerResult? r = _result;
    final String len = ip ? 'in' : 'mm';

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints c) {
        // 32 = the ListView's own padding on both sides.
        final bool narrow = c.maxWidth - 32 < kDuctNarrowWidth;

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
                      DropdownItem<SizerUnits>(value: SizerUnits.ip, label: 'Imperial'),
                      DropdownItem<SizerUnits>(value: SizerUnits.si, label: 'Metric'),
                    ],
                    onChanged: (SizerUnits? u) {
                      if (u == null || u == _units) return;
                      setState(() => _units = u);
                      _clear();
                    },
                  ),
                ),
                SizedBox(
                  width: 320,
                  child: CustomDropdown<int>(
                    fillColor: AppColors.card,
                    label: 'Fluid',
                    value: _air,
                    items: <DropdownItem<int>>[
                      for (int i = 0; i < kAirConditions.length; i++)
                        DropdownItem<int>(
                          value: i,
                          label: ip ? kAirConditions[i].ipLabel : kAirConditions[i].siLabel,
                        ),
                    ],
                    onChanged: (int? i) {
                      if (i == null) return;
                      setState(() => _air = i);
                      _recompute();
                    },
                  ),
                ),
                // Core button (22/10/2026 — was a Material TextButton), in the
                // secondary look the calculators use for Cancel.
                customButton(
                  title: 'Clear',
                  function: _clear,
                  wrapContent: true,
                  color: AppColors.card,
                  textColor: AppColors.text,
                ),
              ],
            ),
            // 26/10/2026: the fluid properties table (density, viscosity,
            // specific heat, energy factor) is no longer shown.
            const SizedBox(height: 16),
            const Text('Tick any two values; the other two are solved.'),
            const SizedBox(height: 8),
            for (final SizerField f in SizerField.values) _fieldRow(f, narrow),
            ResponsiveFields(
              children: <Widget>[
                NumberField(controller: _sideA, label: 'Duct side A', unit: len, onChanged: (_) => _recompute()),
                NumberField(
                  controller: _sideB,
                  label: 'Duct side B',
                  unit: len,
                  onChanged: (String v) {
                    // Typing takes over; emptying the box returns it to auto.
                    _sideBAuto = v.trim().isEmpty;
                    _recompute();
                  },
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Text('Enter one side to size the other, or both to get their equivalent diameter.'),
            const SizedBox(height: 16),
            if (_error != null) Text(_error!),
            if (r != null) ResultTable(items: _resultItems(r)),
          ],
        );
      },
    );
  }
}
