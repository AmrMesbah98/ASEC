/// Module: tools / t2_engineering_calc
///
///*************************** FILE INFO ****************************///
/// File Name: calc_model.dart
/// Purpose: Declares the building blocks every engineering calculator is
///          made of — `Qty` (what a value is measured in), `CalcField`
///          (an input), `CalcChoice` (an option of a drop-down input),
///          `CalcResult` (an output), `EngCalc` (one calculator) and
///          `CalcDiscipline` (a tab: HVAC, Fire, Plumbing, Medical gas).
/// Author: ASEC team
/// Created: 4/10/2026
///
/// HOW A CALCULATOR WORKS
/// ----------------------
/// A calculator is DATA plus one pure function. The page draws the fields,
/// converts whatever unit the user picked into the category's SI base unit
/// (the same base units as the unit converter: m, m², m³, m³/s, Pa, W, K…),
/// calls [EngCalc.compute] with those base values, and shows each result
/// converted to the unit the user picked for it. So a compute function
/// never sees a foot, a psi or a CFM — only base SI.
///
/// Choice fields reach [EngCalc.compute] as their option index (0, 1, 2…).
///
/// Defaults ([CalcField.def]) and presets ([CalcChoice.presets]) are written
/// in the field's SI DISPLAY unit (e.g. 25 for "25 Pa", 7 for "7 °C",
/// 1.5 for "1.5 bar") — whatever reads naturally to an engineer.

import 'package:flutter/material.dart';

import 'package:asec/features/tools/t1_unit_converter/domain/unit_catalog.dart';
import 'package:asec/features/tools/t2_engineering_calc/domain/calc_units.dart';

/// What a value is measured in: a unit category and the unit shown by
/// default in SI mode and in IP (inch-pound) mode.
class Qty {
  const Qty(this.categoryId, this.si, this.ip);

  final String categoryId;
  final String si;
  final String ip;

  UnitCategory get category => CalcUnits.category(categoryId);

  int indexOf(String symbol) {
    final int i = category.units.indexWhere((UnitDef u) => u.symbol == symbol);
    assert(i >= 0, 'Unit "$symbol" is not in category "$categoryId"');
    return i < 0 ? 0 : i;
  }

  int defaultIndex(bool imperial) => indexOf(imperial ? ip : si);

  double toBase(double v, int unit) => category.units[unit].toBase(v);

  double fromBase(double v, int unit) => category.units[unit].fromBase(v);

  /// A value written in the SI display unit → base unit.
  double siToBase(double v) => toBase(v, indexOf(si));
}

class CalcChoice {
  const CalcChoice(this.en, this.ar, [this.presets = const <String, double>{}]);

  final String en;
  final String ar;

  /// Picking this option fills these fields (values in each field's SI
  /// display unit). The user can still edit them afterwards.
  final Map<String, double> presets;

  String name(bool arabic) => arabic ? ar : en;
}

enum CalcFieldKind { number, choice }

class CalcField {
  /// A number. [qty] null = a plain number (a count, a %, a factor) with
  /// [unit] written beside it.
  const CalcField(
    this.id,
    this.en,
    this.ar, {
    this.qty,
    this.unit = '',
    this.def = 0,
    this.showIf,
  })  : kind = CalcFieldKind.number,
        options = const <CalcChoice>[],
        defOption = 0;

  const CalcField.choice(
    this.id,
    this.en,
    this.ar,
    this.options, {
    this.defOption = 0,
    this.showIf,
  })  : kind = CalcFieldKind.choice,
        qty = null,
        unit = '',
        def = 0;

  final String id;
  final String en;
  final String ar;
  final CalcFieldKind kind;
  final Qty? qty;
  final String unit;

  /// Default, in the SI display unit of [qty].
  final double def;

  final List<CalcChoice> options;
  final int defOption;

  /// Only shown (and only required) while choice field `$1` is on option
  /// `$2` — e.g. ('method', 0).
  final (String, int)? showIf;

  bool get isChoice => kind == CalcFieldKind.choice;

  String name(bool arabic) => arabic ? ar : en;

  double siToBase(double v) => qty == null ? v : qty!.siToBase(v);
}

class CalcResult {
  const CalcResult(
    this.id,
    this.en,
    this.ar, {
    this.qty,
    this.unit = '',
    this.text,
    this.primary = false,
  });

  final String id;
  final String en;
  final String ar;
  final Qty? qty;
  final String unit;

  /// Writes the whole answer itself (pipe sizes such as `DN 100 (4")`).
  final String Function(double v)? text;

  /// Highlighted — the answer the engineer came for.
  final bool primary;

  String name(bool arabic) => arabic ? ar : en;
}

class EngCalc {
  const EngCalc({
    required this.id,
    required this.en,
    required this.ar,
    required this.fields,
    required this.results,
    required this.compute,
    required this.formula,
    this.noteEn = '',
    this.noteAr = '',
  });

  final String id;
  final String en;
  final String ar;
  final List<CalcField> fields;
  final List<CalcResult> results;

  /// Base-unit inputs (choices as their index) → base-unit results.
  final Map<String, double> Function(Map<String, double> v) compute;

  /// The method, in symbols — shown left-to-right in both languages.
  final String formula;
  final String noteEn;
  final String noteAr;

  String name(bool arabic) => arabic ? ar : en;
  String note(bool arabic) => arabic ? noteAr : noteEn;
}

class CalcDiscipline {
  const CalcDiscipline({
    required this.id,
    required this.en,
    required this.ar,
    required this.icon,
    required this.calcs,
  });

  final String id;
  final String en;
  final String ar;
  final IconData icon;
  final List<EngCalc> calcs;

  String name(bool arabic) => arabic ? ar : en;
}

/// Numbers on screen: [digits] significant digits, no trailing zeros,
/// scientific notation only for extreme values.
String formatCalc(double v, {int digits = 4}) {
  if (v.isNaN || v.isInfinite) return '—';
  if (v == 0) return '0';
  final double a = v.abs();
  if (a >= 1e12 || a < 1e-6) {
    return v.toStringAsExponential(3).replaceFirst(RegExp(r'\.?0+e'), 'e');
  }
  // 03/11/2026: at most 2 digits after the point, trailing zeros dropped.
  // A value that would round to 0 keeps 2 significant digits (0.0042).
  String s = a < 0.005
      ? double.parse(v.toStringAsPrecision(2)).toString()
      : v.toStringAsFixed(2);
  if (s.contains('e')) return s;
  if (s.contains('.')) {
    s = s.replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '');
  }
  return s == '-0' ? '0' : s;
}
