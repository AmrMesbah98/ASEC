/// Module: tools / t2_engineering_calc
///
///*************************** FILE INFO ****************************///
/// File Name: calc_units.dart
/// Purpose: Declares `CalcUnits` — the unit categories the calculators use:
///          every category of the unit converter (UnitCatalog) plus the
///          engineering-only ones that make no sense as converter tabs
///          (temperature DIFFERENCE, duct friction rate, K-factor, sprinkler
///          density, U-value…) — and `Q`, the quantities the calculator
///          fields are measured in, each with its SI and IP default unit.
/// Author: ASEC team
/// Created: 4/10/2026
///
/// Base units of the extra categories (what compute functions receive):
///   tempDiff K · ductFriction Pa/m · pipeFriction Pa/m · heatFlux W/m² ·
///   uValue W/m²·K · ventPerson L/s per person · ventArea L/s per m² ·
///   kFactor (L/min)/bar½ · sprinklerDensity mm/min (= L/min per m²) ·
///   humidity g/kg · perCapita L/person/day · rainfall mm/h · areaPerTon m²/TR

import 'package:flutter/material.dart';

import 'package:asec/features/tools/t1_unit_converter/domain/unit_catalog.dart';
import 'package:asec/features/tools/t2_engineering_calc/domain/calc_model.dart';

abstract final class CalcUnits {
  static const List<UnitCategory> extra = <UnitCategory>[
    UnitCategory(
      id: 'tempDiff',
      nameEn: 'Temperature difference',
      nameAr: 'فرق درجات الحرارة',
      icon: Icons.thermostat_rounded,
      units: <UnitDef>[
        UnitDef('Δ°C', 'Celsius degrees', 'درجات سيلزيوس', 1),
        UnitDef('ΔK', 'Kelvin', 'كلفن', 1),
        UnitDef('Δ°F', 'Fahrenheit degrees', 'درجات فهرنهايت', 5 / 9),
      ],
    ),
    UnitCategory(
      id: 'ductFriction',
      nameEn: 'Duct friction rate',
      nameAr: 'معدل الاحتكاك في الدكت',
      icon: Icons.air_rounded,
      units: <UnitDef>[
        UnitDef('Pa/m', 'Pascal per meter', 'باسكال/متر', 1),
        UnitDef('inwg/100ft', 'Inch water gauge per 100 ft', 'بوصة عمود ماء/100 قدم', 249.08891 / 30.48),
        UnitDef('mmH₂O/m', 'mm of water per meter', 'ملم ماء/متر', 9.80665),
      ],
    ),
    UnitCategory(
      id: 'pipeFriction',
      nameEn: 'Pipe friction rate',
      nameAr: 'معدل الاحتكاك في المواسير',
      icon: Icons.plumbing_rounded,
      units: <UnitDef>[
        UnitDef('Pa/m', 'Pascal per meter', 'باسكال/متر', 1),
        UnitDef('kPa/100 m', 'kPa per 100 m', 'كيلوباسكال/100 متر', 10),
        UnitDef('bar/100 m', 'bar per 100 m', 'بار/100 متر', 1000),
        UnitDef('m/100 m', 'Meter of water per 100 m', 'متر ماء/100 متر', 98.0665),
        UnitDef('ft/100 ft', 'Foot of water per 100 ft', 'قدم ماء/100 قدم', 98.0665),
        UnitDef('psi/100 ft', 'psi per 100 ft', 'psi/100 قدم', 6894.757293168361 / 30.48),
      ],
    ),
    UnitCategory(
      id: 'heatFlux',
      nameEn: 'Heat per area',
      nameAr: 'حرارة لكل مساحة',
      icon: Icons.wb_sunny_rounded,
      units: <UnitDef>[
        UnitDef('W/m²', 'Watt per m²', 'وات/م²', 1),
        UnitDef('BTU/h·ft²', 'BTU/h per ft²', 'BTU/h لكل قدم²', 3.1545907),
        UnitDef('W/ft²', 'Watt per ft²', 'وات/قدم²', 1 / 0.09290304),
      ],
    ),
    UnitCategory(
      id: 'uValue',
      nameEn: 'U-value',
      nameAr: 'معامل الانتقال الحراري',
      icon: Icons.layers_rounded,
      units: <UnitDef>[
        UnitDef('W/m²·K', 'W per m²·K', 'وات/م²·كلفن', 1),
        UnitDef('BTU/h·ft²·°F', 'BTU/h per ft²·°F', 'BTU/h لكل قدم²·°ف', 5.678263),
      ],
    ),
    UnitCategory(
      id: 'ventPerson',
      nameEn: 'Air per person',
      nameAr: 'هواء لكل شخص',
      icon: Icons.person_rounded,
      units: <UnitDef>[
        UnitDef('L/s/person', 'l/s per person', 'لتر/ث لكل شخص', 1),
        UnitDef('CFM/person', 'CFM per person', 'CFM لكل شخص', 0.47194745),
        UnitDef('m³/h/person', 'm³/h per person', 'م³/س لكل شخص', 1 / 3.6),
      ],
    ),
    UnitCategory(
      id: 'ventArea',
      nameEn: 'Air per area',
      nameAr: 'هواء لكل مساحة',
      icon: Icons.crop_square_rounded,
      units: <UnitDef>[
        UnitDef('L/s/m²', 'l/s per m²', 'لتر/ث لكل م²', 1),
        UnitDef('CFM/ft²', 'CFM per ft²', 'CFM لكل قدم²', 0.47194745 / 0.09290304),
        UnitDef('m³/h/m²', 'm³/h per m²', 'م³/س لكل م²', 1 / 3.6),
      ],
    ),
    UnitCategory(
      id: 'kFactor',
      nameEn: 'Sprinkler K-factor',
      nameAr: 'معامل K للرشاش',
      icon: Icons.shower_rounded,
      units: <UnitDef>[
        UnitDef('L/min/bar½', 'l/min per √bar', 'لتر/د لكل √بار', 1),
        UnitDef('gpm/psi½', 'gpm per √psi', 'جالون/د لكل √psi', 14.4163),
      ],
    ),
    UnitCategory(
      id: 'sprinklerDensity',
      nameEn: 'Design density',
      nameAr: 'كثافة التصميم',
      icon: Icons.water_drop_rounded,
      units: <UnitDef>[
        UnitDef('mm/min', 'mm/min (l/min·m²)', 'مم/د (لتر/د·م²)', 1),
        UnitDef('gpm/ft²', 'gpm per ft²', 'جالون/د لكل قدم²', 40.7458),
      ],
    ),
    UnitCategory(
      id: 'humidity',
      nameEn: 'Humidity ratio',
      nameAr: 'نسبة الرطوبة',
      icon: Icons.water_rounded,
      units: <UnitDef>[
        UnitDef('g/kg', 'Gram per kg dry air', 'جرام/كجم هواء جاف', 1),
        UnitDef('gr/lb', 'Grain per lb dry air', 'جرين/رطل هواء جاف', 1 / 7),
      ],
    ),
    UnitCategory(
      id: 'perCapita',
      nameEn: 'Water use per person',
      nameAr: 'استهلاك المياه للفرد',
      icon: Icons.person_rounded,
      units: <UnitDef>[
        UnitDef('L/person/day', 'Liter per person per day', 'لتر/فرد/يوم', 1),
        UnitDef('gal/person/day', 'US gallon per person per day', 'جالون/فرد/يوم', 3.785411784),
      ],
    ),
    UnitCategory(
      id: 'rainfall',
      nameEn: 'Rainfall intensity',
      nameAr: 'شدة المطر',
      icon: Icons.umbrella_rounded,
      units: <UnitDef>[
        UnitDef('mm/h', 'Millimeter per hour', 'مم/ساعة', 1),
        UnitDef('in/h', 'Inch per hour', 'بوصة/ساعة', 25.4),
      ],
    ),
    UnitCategory(
      id: 'areaPerTon',
      nameEn: 'Area per ton',
      nameAr: 'مساحة لكل طن',
      icon: Icons.crop_square_rounded,
      units: <UnitDef>[
        UnitDef('m²/TR', 'm² per ton of refrigeration', 'م² لكل طن تبريد', 1),
        UnitDef('ft²/TR', 'ft² per ton of refrigeration', 'قدم² لكل طن تبريد', 0.09290304),
      ],
    ),
  ];

  static final Map<String, UnitCategory> _byId = <String, UnitCategory>{
    for (final UnitCategory c in <UnitCategory>[...UnitCatalog.all, ...extra]) c.id: c,
  };

  static UnitCategory category(String id) {
    final UnitCategory? c = _byId[id];
    assert(c != null, 'Unknown unit category "$id"');
    return c ?? UnitCatalog.all.first;
  }
}

/// The quantities calculator fields and results are measured in.
abstract final class Q {
  static const Qty length = Qty('length', 'm', 'ft');
  static const Qty diameter = Qty('length', 'mm', 'in');
  static const Qty area = Qty('area', 'm²', 'ft²');
  static const Qty roomVolume = Qty('volume', 'm³', 'ft³');
  static const Qty liters = Qty('volume', 'L', 'gal (US)');
  static const Qty tank = Qty('volume', 'm³', 'gal (US)');
  static const Qty gasContent = Qty('volume', 'L', 'ft³');
  static const Qty airFlow = Qty('flow', 'L/s', 'CFM');
  static const Qty airFlowM3h = Qty('flow', 'm³/h', 'CFM');
  static const Qty waterFlow = Qty('flow', 'L/s', 'GPM (US)');
  static const Qty fireFlow = Qty('flow', 'L/min', 'GPM (US)');
  static const Qty gasFlow = Qty('flow', 'L/min', 'CFM');
  static const Qty airPressure = Qty('pressure', 'Pa', 'inwg');
  static const Qty waterDp = Qty('pressure', 'kPa', 'ftH₂O');
  static const Qty head = Qty('pressure', 'mH₂O', 'ftH₂O');
  static const Qty kPaPsi = Qty('pressure', 'kPa', 'psi');
  static const Qty barPsi = Qty('pressure', 'bar', 'psi');
  static const Qty watts = Qty('power', 'W', 'BTU/h');
  static const Qty load = Qty('power', 'kW', 'BTU/h');
  static const Qty loadTons = Qty('power', 'kW', 'TR');
  static const Qty tons = Qty('power', 'TR', 'TR');
  static const Qty motor = Qty('power', 'kW', 'HP');
  static const Qty temp = Qty('temperature', '°C', '°F');
  static const Qty tempDiff = Qty('tempDiff', 'Δ°C', 'Δ°F');
  static const Qty airSpeed = Qty('speed', 'm/s', 'FPM');
  static const Qty waterSpeed = Qty('speed', 'm/s', 'ft/s');
  static const Qty minutes = Qty('time', 'min', 'min');
  static const Qty hours = Qty('time', 'h', 'h');
  static const Qty days = Qty('time', 'd', 'd');
  static const Qty ductFriction = Qty('ductFriction', 'Pa/m', 'inwg/100ft');
  static const Qty pipeFriction = Qty('pipeFriction', 'kPa/100 m', 'ft/100 ft');
  static const Qty firePipeFriction = Qty('pipeFriction', 'bar/100 m', 'psi/100 ft');
  static const Qty heatFlux = Qty('heatFlux', 'W/m²', 'BTU/h·ft²');
  static const Qty uValue = Qty('uValue', 'W/m²·K', 'BTU/h·ft²·°F');
  static const Qty ventPerson = Qty('ventPerson', 'L/s/person', 'CFM/person');
  static const Qty ventArea = Qty('ventArea', 'L/s/m²', 'CFM/ft²');
  static const Qty kFactor = Qty('kFactor', 'L/min/bar½', 'gpm/psi½');
  static const Qty density = Qty('sprinklerDensity', 'mm/min', 'gpm/ft²');
  static const Qty humidity = Qty('humidity', 'g/kg', 'gr/lb');
  static const Qty perCapita = Qty('perCapita', 'L/person/day', 'gal/person/day');
  static const Qty rainfall = Qty('rainfall', 'mm/h', 'in/h');
  static const Qty areaPerTon = Qty('areaPerTon', 'm²/TR', 'ft²/TR');
}

/// Shared constants (base SI).
abstract final class K {
  static const double g = 9.80665;
  static const double atm = 101325;
  static const double bar = 1e5;
  static const double psi = 6894.757293168361;
  static const double ton = 3516.8528420667; // W per TR
  static const double gpm = 0.003785411784 / 60; // m³/s per US gpm
  static const double lpm = 0.001 / 60; // m³/s per L/min
}
