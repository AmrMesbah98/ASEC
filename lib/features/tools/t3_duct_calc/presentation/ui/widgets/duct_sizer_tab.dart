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
/// Updated: 29/10/2026 - Switching units converts the typed values instead
///          of clearing them.
/// Updated: 23/10/2026 - Duct side B fills itself from the result table
///          (the sized rectangle) until the user types their own value;
///          emptying it hands it back to auto.
library;

import 'package:asec/core/helper/main_helper/format_helper.dart';
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

  /// Whole numbers in the Duct Sizer — EXCEPT head loss, which is below 1
  /// (0.08 inwg/100ft) and would show as 0: 3 decimals (inch), 2 (metric).
  int _decimals(SizerField f) {
    if (f == SizerField.headLoss) return _units == SizerUnits.ip ? 3 : 2;
    return 0;
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

  /// Switching units converts what is already typed instead of clearing it,
  /// then solves again in the new system.
  void _setUnits(SizerUnits u) {
    final SizerUnits from = _units;
    _units = u;
    for (final SizerField f in _ticked) {
      final double? v = parseNumber(_fields[f]!.text);
      if (v != null) {
        _fields[f]!.text = fmt(SizerConvert.field(f, v, from, u), _decimals(f));
      }
    }
    const int lenDecimals = 0;
    final double? a = parseNumber(_sideA.text);
    if (a != null) _sideA.text = fmt(SizerConvert.length(a, from, u), lenDecimals);
    if (!_sideBAuto) {
      final double? b = parseNumber(_sideB.text);
      if (b != null) _sideB.text = fmt(SizerConvert.length(b, from, u), lenDecimals);
    }
    // Nothing typed yet: just relabel, don't show "enter a value" errors.
    final bool anyInput =
        _ticked.any((SizerField f) => _fields[f]!.text.trim().isNotEmpty);
    if (anyInput) {
      _recompute();
    } else {
      setState(() {});
    }
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
        _sideB.text = fmt(r.rectSideB, 0);
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
          '${fmt(r.rectSideA, 0)} × ${fmt(r.rectSideB, 0)}',
          len,
        ),
        ResultItem('Equivalent diameter', fmt(r.rectEquivalentDiameter, 0), len),
      ],
      // 31/10/2026 (Eng. Ahmed Shuhayb): velocity and head loss only —
      // flow area, Reynolds, friction factor and velocity pressure removed.
      ResultItem('Fluid velocity', fmt(r.velocity, 0), ip ? 'ft/min' : 'm/s'),
      ResultItem('Head loss', fmt(r.headLoss, ip ? 3 : 2), ip ? 'inwg/100ft' : 'Pa/m'),
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
                      _setUnits(u);
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
            Text(FormatHelper.capitalize('Tick any two values; the other two are solved.')),
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
            Text(FormatHelper.capitalize('Enter one side to size the other, or both to get their equivalent diameter.')),
            const SizedBox(height: 16),
            if (_error != null) Text(FormatHelper.capitalize(_error!)),
            if (r != null) ResultTable(items: _resultItems(r)),
          ],
        );
      },
    );
  }
}
