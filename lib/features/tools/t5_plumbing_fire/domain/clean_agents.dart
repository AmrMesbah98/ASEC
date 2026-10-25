/// Module: tools / t5_plumbing_fire
///
///*************************** FILE INFO ****************************///
/// File Name: clean_agents.dart
/// Purpose: Novec (FK-5-1-12), condensed aerosol and CO₂ total flooding —
///          the formulas of "ASEC_Fire_Suppression_Gas_Calculator.xlsx"
///          (Eng. Ahmed Shuhayb), with every assumption editable.
/// Author: ASEC team
/// Created: 25/10/2026
///
/// PRELIMINARY SIZING ONLY — verify hazard, approved manufacturer listing,
/// hydraulic calculations and AHJ requirements.
///
/// Net volume:  V = max(0, L × W × H + voids − excluded)
/// Novec:       S = k₁ + k₂ × Tmin
///              W = V / S × C / (100 − C) × atm × (1 + allowance / 100)
///              cylinders = ⌈W / fill⌉, installed = cylinders × fill
///              actual C = 100 × (m·S/V) / (1 + m·S/V), m = installed
/// Aerosol:     M = V × density × (1 + allowance / 100) [g],
///              generators = ⌈M / generator mass⌉
/// CO₂:         W = (min(V, band) × c₁ + max(0, V − band) × c₂)
///                  × (1 + allowance / 100),  cylinders = ⌈W / fill⌉
///              Concept only — NOT an NFPA 12 calculation.
library;

import 'dart:math' as math;

/// L × W × H + additional voids − permanently excluded volume, never < 0.
double netVolume({
  required double length,
  required double width,
  required double height,
  double voids = 0,
  double excluded = 0,
}) =>
    math.max(0, length * width * height + voids - excluded);

// ── Novec (FK-5-1-12) ─────────────────────────────────────────────────────

class NovecResult {
  const NovecResult({
    required this.volume,
    required this.specificVolume,
    required this.agentMass,
    required this.adjustedMass,
    required this.cylinders,
    required this.installedMass,
    required this.actualConcentration,
  });

  /// m³
  final double volume;

  /// m³/kg at the minimum design temperature
  final double specificVolume;

  /// kg at design conditions
  final double agentMass;

  /// kg after the atmospheric factor and the allowance
  final double adjustedMass;

  /// Indicative cylinder count
  final int cylinders;

  /// kg = cylinders × nominal fill
  final double installedMass;

  /// % vol. at the design temperature with the installed mass
  final double actualConcentration;
}

abstract final class Novec {
  // Workbook defaults — examples, not hazard-specific selections.
  static const double concentration = 4.5; // % vol.
  static const double minTempC = 20;
  static const double atmFactor = 1;
  static const double allowancePct = 0;
  static const double cylinderFillKg = 80;
  static const double k1 = 0.0664; // m³/kg
  static const double k2 = 0.0002741; // m³/kg·°C

  /// Null when an input is out of range (V ≤ 0, C ∉ (0, 100), S ≤ 0).
  static NovecResult? calculate({
    required double volume,
    double concentration = Novec.concentration,
    double minTempC = Novec.minTempC,
    double atmFactor = Novec.atmFactor,
    double allowancePct = Novec.allowancePct,
    double cylinderFillKg = Novec.cylinderFillKg,
    double k1 = Novec.k1,
    double k2 = Novec.k2,
  }) {
    final double s = k1 + k2 * minTempC;
    if (volume <= 0 || concentration <= 0 || concentration >= 100 || s <= 0) return null;
    final double w = volume / s * concentration / (100 - concentration);
    final double adjusted = w * atmFactor * (1 + allowancePct / 100);
    final int n = cylinderFillKg <= 0 ? 0 : (adjusted / cylinderFillKg).ceil();
    final double installed = n * cylinderFillKg;
    final double x = installed * s / volume;
    return NovecResult(
      volume: volume,
      specificVolume: s,
      agentMass: w,
      adjustedMass: adjusted,
      cylinders: n,
      installedMass: installed,
      actualConcentration: 100 * x / (1 + x),
    );
  }
}

// ── Condensed aerosol ─────────────────────────────────────────────────────

class AerosolResult {
  const AerosolResult({
    required this.volume,
    required this.baseMass,
    required this.adjustedMass,
    required this.generators,
    required this.totalMass,
  });

  /// m³
  final double volume;

  /// g = V × design density
  final double baseMass;

  /// g after the allowance
  final double adjustedMass;

  /// Indicative generator quantity
  final int generators;

  /// g = generators × generator mass
  final double totalMass;
}

abstract final class Aerosol {
  /// 109.2 g/m³ comes from the sample file for comparison ONLY — replace
  /// with the approved product's listed design density.
  static const double densityGm3 = 109.2;
  static const double allowancePct = 0;
  static const double generatorGrams = 1000;

  static AerosolResult? calculate({
    required double volume,
    double densityGm3 = Aerosol.densityGm3,
    double allowancePct = Aerosol.allowancePct,
    double generatorGrams = Aerosol.generatorGrams,
  }) {
    if (volume <= 0 || densityGm3 <= 0) return null;
    final double base = volume * densityGm3;
    final double adjusted = base * (1 + allowancePct / 100);
    final int n = generatorGrams <= 0 ? 0 : (adjusted / generatorGrams).ceil();
    return AerosolResult(
      volume: volume,
      baseMass: base,
      adjustedMass: adjusted,
      generators: n,
      totalMass: n * generatorGrams,
    );
  }
}

// ── CO₂ (concept only) ────────────────────────────────────────────────────

class Co2BandResult {
  const Co2BandResult({
    required this.volume,
    required this.firstBandVolume,
    required this.excessVolume,
    required this.weight,
    required this.cylinders,
  });

  /// m³
  final double volume;

  /// m³ charged at the first-band coefficient
  final double firstBandVolume;

  /// m³ charged at the excess-band coefficient
  final double excessVolume;

  /// kg
  final double weight;

  /// Indicative cylinder count
  final int cylinders;
}

abstract final class Co2Band {
  static const double firstBandM3 = 56.5;
  static const double firstCoefficient = 1.6; // kg/m³
  static const double excessCoefficient = 1.33; // kg/m³
  static const double allowancePct = 0;
  static const double cylinderKg = 45;

  static Co2BandResult? calculate({
    required double volume,
    double firstBandM3 = Co2Band.firstBandM3,
    double firstCoefficient = Co2Band.firstCoefficient,
    double excessCoefficient = Co2Band.excessCoefficient,
    double allowancePct = Co2Band.allowancePct,
    double cylinderKg = Co2Band.cylinderKg,
  }) {
    if (volume <= 0) return null;
    final double first = math.min(volume, firstBandM3);
    final double excess = math.max(0, volume - firstBandM3);
    final double w = (first * firstCoefficient + excess * excessCoefficient) * (1 + allowancePct / 100);
    return Co2BandResult(
      volume: volume,
      firstBandVolume: first,
      excessVolume: excess,
      weight: w,
      cylinders: cylinderKg <= 0 ? 0 : (w / cylinderKg).ceil(),
    );
  }
}
