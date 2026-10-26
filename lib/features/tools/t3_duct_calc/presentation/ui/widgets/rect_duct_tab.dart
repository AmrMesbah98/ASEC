/// Module: tools / t3_duct_calc
///
///*************************** FILE INFO ****************************///
/// File Name: rect_duct_tab.dart
/// Purpose: Rectangular Duct tab — air flow (l/s), two sides (mm) and
///          length (m) in; equivalent diameter, velocity, Pa/m, total Pa
///          and velocity pressure out.
/// Author: ASEC team
/// Created: 21/10/2026
library;

import 'package:flutter/material.dart';

import 'package:asec/features/tools/t3_duct_calc/domain/duct_calculator.dart';
import 'package:asec/features/tools/t3_duct_calc/presentation/ui/widgets/duct_fields.dart';

class RectDuctTab extends StatefulWidget {
  const RectDuctTab({super.key});

  @override
  State<RectDuctTab> createState() => _RectDuctTabState();
}

class _RectDuctTabState extends State<RectDuctTab> {
  final TextEditingController _flow = TextEditingController(text: '183.7');
  final TextEditingController _sideA = TextEditingController(text: '212');
  final TextEditingController _sideB = TextEditingController(text: '212');
  final TextEditingController _length = TextEditingController(text: '1');

  @override
  void dispose() {
    _flow.dispose();
    _sideA.dispose();
    _sideB.dispose();
    _length.dispose();
    super.dispose();
  }

  RectDuctResult? _result() {
    final double? q = parseNumber(_flow.text);
    final double? a = parseNumber(_sideA.text);
    final double? b = parseNumber(_sideB.text);
    final double? l = parseNumber(_length.text);
    if (q == null || a == null || b == null || l == null) return null;
    if (q <= 0 || a <= 0 || b <= 0 || l < 0) return null;
    return DuctCalculator.rectangular(
      flowLs: q,
      sideAMm: a,
      sideBMm: b,
      lengthM: l,
    );
  }

  @override
  Widget build(BuildContext context) {
    final RectDuctResult? r = _result();
    void changed(String _) => setState(() {});

    return ListView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.symmetric(vertical: 16),
      children: <Widget>[
        ResponsiveFields(
          children: <Widget>[
            NumberField(controller: _flow, label: 'Air volume flow', unit: 'l/s', onChanged: changed),
            NumberField(controller: _sideA, label: 'Side A', unit: 'mm', onChanged: changed),
            NumberField(controller: _sideB, label: 'Side B', unit: 'mm', onChanged: changed),
            NumberField(controller: _length, label: 'Duct length', unit: 'm', onChanged: changed),
          ],
        ),
        const SizedBox(height: 16),
        if (r == null)
          const Text('Enter the air flow, both sides and the length.')
        else
          ResultTable(
            items: <ResultItem>[
              ResultItem('Equivalent diameter', fmt(r.equivalentDiameterMm, 0), 'mm'),
              ResultItem('Velocity', fmt(r.velocity, 2), 'm/s'),
              ResultItem('Pressure drop', fmt(r.pressureDropPerMetre, 1), 'Pa/m'),
              ResultItem('Total pressure drop', fmt(r.totalPressureDrop, 1), 'Pa'),
              ResultItem('Velocity pressure', fmt(r.velocityPressure, 1), 'Pa'),
            ],
          ),
      ],
    );
  }
}
