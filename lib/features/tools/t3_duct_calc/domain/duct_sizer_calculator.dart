/// Module: tools / t3_duct_calc
///
///*************************** FILE INFO ****************************///
/// File Name: duct_sizer_calculator.dart
/// Purpose: The "DuctSizer" maths — give any two of flow, head loss,
///          velocity and diameter and it solves the other two, then sizes
///          an equivalent rectangle.
/// Author: ASEC team
/// Created: 21/10/2026
///
/// Pure Dart, works offline. Same method as McQuay DuctSizer 6.4:
///   • works internally in IP units (cfm, in, fpm, in.wg/100 ft)
///   • Re = ρ·V·D/μ   (ρ lb/ft³, V ft/h, D ft, μ lb/ft·h)
///   • f  = 64/Re below Re 2000, otherwise Colebrook
///       1/√f = −2·log10(ε/(3.7·D) + 2.51/(Re·√f)),  ε = 0.0007 ft
///   • Pv = ρ·(V/1097)²  in.wg
///   • head loss = f · (100/D) · Pv   in.wg per 100 ft
///   • a SOLVED diameter is rounded (0.1 in, or 1 mm in SI) and the results
///     are re-evaluated with the rounded size, like the original
///   • rectangle: Huebscher De = 1.30·(a·b)^0.625 / (a+b)^0.25
///   • both sides typed (29/10/2026): area, velocity, Pv, Re, f and head
///     loss are all re-evaluated for that rectangle at the same flow
library;

import 'dart:math' as math;

import 'package:asec/features/tools/t3_duct_calc/domain/duct_data.dart';

enum SizerUnits { ip, si }

enum SizerField { flow, headLoss, velocity, diameter }

/// Unit labels per field and unit system.
class SizerLabels {
  const SizerLabels._();

  static String unit(SizerField f, SizerUnits u) {
    final bool ip = u == SizerUnits.ip;
    switch (f) {
      case SizerField.flow:
        return ip ? 'CFM' : 'l/s';
      case SizerField.headLoss:
        return ip ? 'inwg/100 ft' : 'Pa/m';
      case SizerField.velocity:
        return ip ? 'FPM' : 'm/s';
      case SizerField.diameter:
        return ip ? 'in' : 'mm';
    }
  }

  static String name(SizerField f) {
    switch (f) {
      case SizerField.flow:
        // 09/11/2026: "Air Volume Flow (l/s)", as on the reference sheet.
        return 'Air volume flow';
      case SizerField.headLoss:
        return 'Head loss';
      case SizerField.velocity:
        return 'Velocity';
      case SizerField.diameter:
        return 'Equivalent diameter';
    }
  }
}

/// IP ⇄ SI factors (SI value = IP value × factor).
class _Si {
  static const double flow = 0.471947443; // cfm → L/s
  static const double headLoss = 249.0889 / 30.48; // in.wg/100ft → Pa/m
  static const double velocity = 0.00508; // fpm → m/s
  static const double length = 25.4; // in → mm
  static const double area = 0.09290304; // ft² → m²
  static const double pressure = 249.0889; // in.wg → Pa
  static const double density = 16.018463; // lb/ft³ → kg/m³
  static const double viscosity = 0.000413378942; // lb/(ft·h) → Pa·s
  static const double specificHeat = 4.1868; // Btu/(lb·°F) → kJ/(kg·K)

  static double factor(SizerField f) {
    switch (f) {
      case SizerField.flow:
        return flow;
      case SizerField.headLoss:
        return headLoss;
      case SizerField.velocity:
        return velocity;
      case SizerField.diameter:
        return length;
    }
  }
}

/// Converts a field value typed in one unit system to the other.
class SizerConvert {
  const SizerConvert._();

  static double field(SizerField f, double v, SizerUnits from, SizerUnits to) {
    if (from == to) return v;
    return to == SizerUnits.si ? v * _Si.factor(f) : v / _Si.factor(f);
  }

  /// Duct side lengths (in ⇄ mm).
  static double length(double v, SizerUnits from, SizerUnits to) {
    if (from == to) return v;
    return to == SizerUnits.si ? v * _Si.length : v / _Si.length;
  }
}

/// Fluid properties as displayed (in the chosen unit system).
class FluidProperties {
  const FluidProperties({
    required this.density,
    required this.viscosity,
    required this.specificHeat,
    required this.energyFactor,
    required this.densityUnit,
    required this.viscosityUnit,
    required this.specificHeatUnit,
    required this.energyFactorUnit,
  });

  final double density;
  final double viscosity;
  final double specificHeat;

  /// ρ·cp·60 (IP, Btu/h·°F·cfm) or ρ·cp (SI, W per L/s per K).
  final double energyFactor;

  final String densityUnit;
  final String viscosityUnit;
  final String specificHeatUnit;
  final String energyFactorUnit;

  factory FluidProperties.of(AirCondition air, SizerUnits units) {
    if (units == SizerUnits.ip) {
      return FluidProperties(
        density: air.densityLbFt3,
        viscosity: air.viscosityLbFtH,
        specificHeat: air.specificHeatBtuLbF,
        energyFactor: air.densityLbFt3 * air.specificHeatBtuLbF * 60,
        densityUnit: 'lb/ft³',
        viscosityUnit: 'lb/ft·h',
        specificHeatUnit: 'Btu/lb·°F',
        energyFactorUnit: 'Btu/h·°F·cfm',
      );
    }
    final double rho = air.densityLbFt3 * _Si.density;
    final double cp = air.specificHeatBtuLbF * _Si.specificHeat;
    return FluidProperties(
      density: rho,
      viscosity: air.viscosityLbFtH * _Si.viscosity,
      specificHeat: cp,
      energyFactor: rho * cp,
      densityUnit: 'kg/m³',
      viscosityUnit: 'Pa·s',
      specificHeatUnit: 'kJ/kg·K',
      energyFactorUnit: 'W/(l/s)·K',
    );
  }
}

/// Everything DuctSizer shows after a solve, in the chosen unit system.
class SizerResult {
  const SizerResult({
    required this.fields,
    required this.flowArea,
    required this.velocity,
    required this.reynolds,
    required this.frictionFactor,
    required this.velocityPressure,
    required this.headLoss,
    this.rectSideA,
    this.rectSideB,
    this.rectEquivalentDiameter,
  });

  /// Values for the four input boxes (given ones echoed, solved ones filled).
  final Map<SizerField, double> fields;

  /// ft² or m²
  final double flowArea;

  /// fpm or m/s (re-evaluated with the rounded diameter)
  final double velocity;
  final double reynolds;
  final double frictionFactor;

  /// in.wg or Pa
  final double velocityPressure;

  /// in.wg/100 ft or Pa/m
  final double headLoss;

  /// Rectangle sides and their equivalent diameter, in or mm.
  final double? rectSideA;
  final double? rectSideB;
  final double? rectEquivalentDiameter;
}

class DuctSizerException implements Exception {
  const DuctSizerException(this.message);
  final String message;
  @override
  String toString() => message;
}

class DuctSizerCalculator {
  const DuctSizerCalculator._();

  /// Absolute roughness, ft (galvanised steel).
  static const double roughnessFt = 0.0007;

  /// Velocity-pressure constant: Pv(in.wg) = ρ·(V/1097)².
  static const double vpConstant = 1097;

  // ── core relations (IP) ──────────────────────────────────────────────────

  static double areaFt2(double diameterIn) {
    final double d = diameterIn / 12.0;
    return math.pi * d * d / 4;
  }

  static double reynolds(double velocityFpm, double diameterIn, AirCondition air) =>
      air.densityLbFt3 * velocityFpm * 60 * (diameterIn / 12.0) / air.viscosityLbFtH;

  /// Darcy friction factor: laminar below Re 2000, Colebrook above.
  static double frictionFactor(double re, double diameterIn) {
    if (re <= 0) return 0;
    if (re < 2000) return 64 / re;
    final double relRough = roughnessFt / (diameterIn / 12.0);
    double f = 0.02;
    for (int i = 0; i < 100; i++) {
      final double x = -2 *
          math.log(relRough / 3.7 + 2.51 / (re * math.sqrt(f))) /
          math.ln10;
      final double next = 1 / (x * x);
      if ((next - f).abs() < 1e-7) return next;
      f = next;
    }
    throw const DuctSizerException('Friction not converged');
  }

  static double velocityPressure(double velocityFpm, AirCondition air) =>
      air.densityLbFt3 * math.pow(velocityFpm / vpConstant, 2).toDouble();

  /// in.wg per 100 ft for a velocity and diameter.
  static double headLossFor(double velocityFpm, double diameterIn, AirCondition air) {
    if (velocityFpm <= 0 || diameterIn <= 0) return 0;
    final double f = frictionFactor(reynolds(velocityFpm, diameterIn, air), diameterIn);
    return f * (100 / (diameterIn / 12.0)) * velocityPressure(velocityFpm, air);
  }

  /// Huebscher equivalent diameter of an a×b rectangle (any one unit).
  static double huebscher(double a, double b) {
    if (a <= 0 || b <= 0) return 0;
    return 1.30 * math.pow(a * b, 0.625) / math.pow(a + b, 0.25);
  }

  // ── solving ──────────────────────────────────────────────────────────────

  /// Bisection (geometric) for a monotonic g on [lo, hi] with g(x) = target.
  static double _solve(
    double Function(double) g,
    double target,
    double lo,
    double hi, {
    required bool increasing,
  }) {
    double a = lo, b = hi;
    for (int i = 0; i < 200; i++) {
      final double mid = math.sqrt(a * b); // geometric: ranges span decades
      final double v = g(mid);
      final bool tooHigh = v > target;
      if (tooHigh == increasing) {
        b = mid;
      } else {
        a = mid;
      }
      if ((b - a) / b < 1e-12) break;
    }
    return math.sqrt(a * b);
  }

  /// Solves from exactly two [given] fields (values in [units]).
  ///
  /// [sideA] / [sideB] (in or mm, optional): give one to size the other
  /// side of an equivalent rectangle, or both to get their equivalent
  /// diameter.
  static SizerResult solve({
    required Map<SizerField, double> given,
    required AirCondition air,
    required SizerUnits units,
    double? sideA,
    double? sideB,
  }) {
    if (given.length != 2) {
      throw const DuctSizerException('Tick exactly two values');
    }
    for (final MapEntry<SizerField, double> e in given.entries) {
      if (!(e.value > 0)) {
        throw DuctSizerException('You must enter a ${SizerLabels.name(e.key).toLowerCase()}');
      }
    }
    final bool si = units == SizerUnits.si;
    double toIp(SizerField f, double v) => si ? v / _Si.factor(f) : v;
    double fromIp(SizerField f, double v) => si ? v * _Si.factor(f) : v;

    double? q = given.containsKey(SizerField.flow) ? toIp(SizerField.flow, given[SizerField.flow]!) : null;
    double? h = given.containsKey(SizerField.headLoss) ? toIp(SizerField.headLoss, given[SizerField.headLoss]!) : null;
    double? v = given.containsKey(SizerField.velocity) ? toIp(SizerField.velocity, given[SizerField.velocity]!) : null;
    double? d = given.containsKey(SizerField.diameter) ? toIp(SizerField.diameter, given[SizerField.diameter]!) : null;
    final bool diameterSolved = d == null;

    // Fill the missing pair at full precision.
    if (q != null && v != null) {
      d = math.sqrt(4 * (q / v) / math.pi) * 12;
    } else if (q != null && d != null) {
      v = q / areaFt2(d);
    } else if (v != null && d != null) {
      q = v * areaFt2(d);
    } else if (q != null && h != null) {
      final double qq = q;
      d = _solve((double x) => headLossFor(qq / areaFt2(x), x, air), h, 0.01, 5000, increasing: false);
      v = q / areaFt2(d);
    } else if (v != null && h != null) {
      final double vv = v;
      d = _solve((double x) => headLossFor(vv, x, air), h, 0.01, 5000, increasing: false);
      q = v * areaFt2(d);
    } else if (d != null && h != null) {
      final double dd = d;
      v = _solve((double x) => headLossFor(x, dd, air), h, 1e-4, 1e6, increasing: true);
      q = v * areaFt2(d);
    }
    final double qIp = q!;
    final double vIp = v!;
    final double dExact = d!;
    final double hBox = h ?? headLossFor(vIp, dExact, air);

    // Round a solved diameter the way it is displayed, then re-evaluate.
    double dIp = dExact;
    if (diameterSolved) {
      final double rounded = si
          ? (dExact * _Si.length).roundToDouble() / _Si.length
          : (dExact * 10).roundToDouble() / 10;
      if (rounded > 0) dIp = rounded;
    }
    double area = areaFt2(dIp);
    double vRes = qIp / area;
    double re = reynolds(vRes, dIp, air);
    double f = frictionFactor(re, dIp);
    double pv = velocityPressure(vRes, air);
    double hRes = f * (100 / (dIp / 12.0)) * pv;

    // Equivalent rectangle.
    double? a = (sideA != null && sideA > 0) ? (si ? sideA / _Si.length : sideA) : null;
    double? b = (sideB != null && sideB > 0) ? (si ? sideB / _Si.length : sideB) : null;
    double? rectDe;
    if (a != null && b != null) {
      rectDe = huebscher(a, b);
      // 29/10/2026 — BOTH SIDES TYPED: the whole table follows THIS duct,
      // not the round one above. Same flow rate:
      //   • flow area = a·b, velocity = Q / (a·b), Pv from that velocity
      //   • Reynolds, friction and head loss on its equivalent diameter
      //     (Huebscher De carries the same flow at the same friction).
      if (rectDe > 0) {
        area = a * b / 144;
        vRes = qIp / area;
        pv = velocityPressure(vRes, air);
        final double vRound = qIp / areaFt2(rectDe);
        re = reynolds(vRound, rectDe, air);
        f = frictionFactor(re, rectDe);
        hRes = f * (100 / (rectDe / 12.0)) * velocityPressure(vRound, air);
      }
    } else if (a != null || b != null) {
      final double known = (a ?? b)!;
      final double other = _solve((double x) => huebscher(known, x), dIp, 1e-3, 1e6, increasing: true);
      if (a == null) {
        a = other;
      } else {
        b = other;
      }
      rectDe = huebscher(a, b!);
    }
    double? len(double? x) => x == null ? null : (si ? x * _Si.length : x);

    return SizerResult(
      fields: <SizerField, double>{
        SizerField.flow: fromIp(SizerField.flow, qIp),
        SizerField.headLoss: fromIp(SizerField.headLoss, hBox),
        SizerField.velocity: fromIp(SizerField.velocity, vIp),
        SizerField.diameter: fromIp(SizerField.diameter, dIp),
      },
      flowArea: si ? area * _Si.area : area,
      velocity: fromIp(SizerField.velocity, vRes),
      reynolds: re,
      frictionFactor: f,
      velocityPressure: si ? pv * _Si.pressure : pv,
      headLoss: fromIp(SizerField.headLoss, hRes),
      rectSideA: len(a),
      rectSideB: len(b),
      rectEquivalentDiameter: len(rectDe),
    );
  }
}
