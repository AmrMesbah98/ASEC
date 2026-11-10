/// Module: tools / t1_unit_converter
///
///*************************** FILE INFO ****************************///
/// File Name: unit_catalog.dart
/// Purpose: Declares `UnitCategory`, `UnitDef` and `UnitCatalog` — the main
///          engineering units and their exact factors. Pure Dart, no
///          network: the converter works fully offline.
/// Author: ASEC team
/// Created: 1/10/2026
///
/// Every linear unit stores its size in the category's SI base unit
/// (m, m², m³, kg, Pa, m³/s, m/s, W, J, N, kg/m³, s, rad). Converting is
/// value × from.factor ÷ to.factor. Temperature is not linear, so its units
/// carry toBase / fromBase functions (base = kelvin).
///
/// Factors are the exact definitions (inch = 0.0254 m, pound = 0.45359237
/// kg, US gallon = 231 in³, BTU (IT), ton of refrigeration = 12 000 BTU/h…).

import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Symbols shown differently from how they are stored (03/11/2026).
/// 09/11/2026 (Eng. Ahmed Shuhayb's review): flow is written the way
/// engineers write it — l/s and l/min in lower case, and GPM with no (US) —
/// and foot per second is FPS, like FPM.
const Map<String, String> kUnitShown = <String, String>{
  'kW': 'KW',
  'BTU/h': 'BTU/HR',
  'L/s': 'l/s',
  'L/min': 'l/min',
  'GPM (US)': 'GPM',
  'GPM (UK)': 'GPM',
  'gal (US)': 'gal',
  'gal (UK)': 'gal',
  'ft/s': 'FPS',
  'L/s/person': 'l/s/person',
  'L/s/m²': 'l/s/m²',
  'L/min/bar½': 'l/min/bar½',
};

class UnitDef {
  const UnitDef(
    this.symbol,
    this.nameEn,
    this.nameAr,
    this.factor, {
    this.approx = false,
  })  : _toBase = null,
        _fromBase = null;

  const UnitDef.affine(
    this.symbol,
    this.nameEn,
    this.nameAr,
    double Function(double) toBase,
    double Function(double) fromBase,
  )   : factor = 1,
        approx = false,
        _toBase = toBase,
        _fromBase = fromBase;

  /// How the symbol is SHOWN (03/11/2026): KW, not kW; BTU/HR, not BTU/h.
  /// [symbol] stays the key other code looks units up by.
  String get shown => kUnitShown[symbol] ?? symbol;

  final String symbol;
  final String nameEn;
  final String nameAr;

  /// Size of one of this unit in the category's base unit.
  final double factor;

  /// A rounded, conventional value rather than an exact definition (the
  /// electric horsepower, 746 W). Relations with it are written "≈", not "=".
  final bool approx;

  final double Function(double)? _toBase;
  final double Function(double)? _fromBase;

  double toBase(double v) {
    final double Function(double)? f = _toBase;
    return f != null ? f(v) : v * factor;
  }

  double fromBase(double v) {
    final double Function(double)? f = _fromBase;
    return f != null ? f(v) : v / factor;
  }

  String name(bool arabic) => arabic ? nameAr : nameEn;
}

class UnitCategory {
  const UnitCategory({
    required this.id,
    required this.nameEn,
    required this.nameAr,
    required this.icon,
    required this.units,
    this.defaultFrom = 0,
    this.defaultTo = 1,
  });

  final String id;
  final String nameEn;
  final String nameAr;
  final IconData icon;
  final List<UnitDef> units;
  final int defaultFrom;
  final int defaultTo;

  String name(bool arabic) => arabic ? nameAr : nameEn;

  static double convert(double value, UnitDef from, UnitDef to) =>
      to.fromBase(from.toBase(value));
}

double _cToK(double c) => c + 273.15;
double _kToC(double k) => k - 273.15;
double _fToK(double f) => (f - 32) * 5 / 9 + 273.15;
double _kToF(double k) => (k - 273.15) * 9 / 5 + 32;
double _same(double k) => k;
double _rToK(double r) => r * 5 / 9;
double _kToR(double k) => k * 9 / 5;

abstract final class UnitCatalog {
  static const double _pi = math.pi;

  /// WHAT THE CONVERTER SHOWS — the units engineers on site actually use.
  /// [all] stays complete because the engineering calculators read their
  /// field units from it (W, PS, mmH₂O…); only the converter tabs are trimmed.
  ///
  /// id → (tab name override, kept symbols in order, default from, default to).
  static const List<(String, String?, String?, List<String>, String, String)> _shown =
      <(String, String?, String?, List<String>, String, String)>[
    ('length', null, null, <String>['m', 'cm', 'mm', 'in', 'ft'], 'm', 'ft'),
    ('area', null, null, <String>['m²', 'mm²', 'in²', 'ft²'], 'm²', 'ft²'),
    // 09/11/2026: both gallons, named "Gallon (US)" / "Gallon (UK)", symbol "gal".
    ('volume', null, null, <String>['m³', 'L', 'ft³', 'gal (US)', 'gal (UK)'], 'm³', 'L'),
    // 06/11/2026: Flow Rate and Velocity come right after Volume, Mass and
    // Temperature after Pressure; "Weight / Mass" → "Mass",
    // "Speed / Velocity" → "Velocity".
    // 09/11/2026: one gallon only — US vs UK does not matter in the field,
    // so the UK gallon is gone and the US one is just "GPM".
    ('flow', null, null, <String>['m³/s', 'm³/h', 'L/s', 'L/min', 'CFM', 'GPM (US)', 'GPM (UK)'], 'L/s', 'CFM'),
    ('speed', 'Velocity', 'السرعة', <String>['m/s', 'ft/s', 'FPM'], 'm/s', 'FPM'),
    ('pressure', null, null, <String>['Pa', 'kPa', 'bar', 'psi', 'atm', 'inwg'], 'bar', 'psi'),
    ('mass', 'Mass', 'الكتلة', <String>['kg', 'g', 'lb'], 'kg', 'lb'),
    ('temperature', null, null, <String>['°C', '°F', 'K'], '°C', '°F'),
    ('power', 'Cooling load', 'حمل التبريد', <String>['kW', 'BTU/h', 'TR', 'HP'], 'TR', 'kW'),
    ('density', null, null, <String>['kg/m³', 'lb/ft³', 'lb/gal'], 'kg/m³', 'lb/ft³'),
    ('time', null, null, <String>['s', 'min', 'h', 'd'], 'h', 'min'),
  ];

  /// The converter's tabs, built once from [all]. An empty symbol list keeps
  /// every unit of the category.
  ///
  /// A GETTER, not a cached `static final` (09/11/2026): a cached list kept
  /// the old units after a hot reload, so a removed unit (Gallon UK) stayed
  /// on screen until a full restart. It is small and cheap to rebuild.
  static List<UnitCategory> get converter => <UnitCategory>[
    for (final (String id, String? en, String? ar, List<String> keep, String from, String to)
        in _shown)
      _subset(id, en, ar, keep, from, to),
  ];

  static UnitCategory _subset(
    String id,
    String? nameEn,
    String? nameAr,
    List<String> keep,
    String from,
    String to,
  ) {
    final UnitCategory source = all.firstWhere((UnitCategory c) => c.id == id);
    final List<UnitDef> units = keep.isEmpty
        ? source.units
        : <UnitDef>[
            for (final String symbol in keep)
              source.units.firstWhere((UnitDef u) => u.symbol == symbol),
          ];
    int indexOf(String symbol) {
      final int i = units.indexWhere((UnitDef u) => u.symbol == symbol);
      return i < 0 ? 0 : i;
    }

    return UnitCategory(
      id: source.id,
      nameEn: nameEn ?? source.nameEn,
      nameAr: nameAr ?? source.nameAr,
      icon: source.icon,
      units: units,
      defaultFrom: indexOf(from),
      defaultTo: indexOf(to),
    );
  }

  static const List<UnitCategory> all = <UnitCategory>[
    UnitCategory(
      id: 'length',
      nameEn: 'Length',
      nameAr: 'الطول',
      icon: Icons.straighten_rounded,
      defaultFrom: 0,
      defaultTo: 6,
      units: <UnitDef>[
        UnitDef('m', 'Meter', 'متر', 1),
        UnitDef('km', 'Kilometer', 'كيلومتر', 1000),
        UnitDef('cm', 'Centimeter', 'سنتيمتر', 0.01),
        UnitDef('mm', 'Millimeter', 'ملليمتر', 0.001),
        UnitDef('µm', 'Micrometer', 'ميكرومتر', 1e-6),
        UnitDef('in', 'Inch', 'بوصة', 0.0254),
        UnitDef('ft', 'Foot', 'قدم', 0.3048),
        UnitDef('yd', 'Yard', 'ياردة', 0.9144),
        UnitDef('mi', 'Mile', 'ميل', 1609.344),
        UnitDef('nmi', 'Nautical mile', 'ميل بحري', 1852),
      ],
    ),
    UnitCategory(
      id: 'area',
      nameEn: 'Area',
      nameAr: 'المساحة',
      icon: Icons.crop_square_rounded,
      defaultFrom: 0,
      defaultTo: 6,
      units: <UnitDef>[
        UnitDef('m²', 'Square meter', 'متر مربع', 1),
        UnitDef('km²', 'Square kilometer', 'كيلومتر مربع', 1e6),
        UnitDef('cm²', 'Square centimeter', 'سنتيمتر مربع', 1e-4),
        UnitDef('mm²', 'Square millimeter', 'ملليمتر مربع', 1e-6),
        UnitDef('ha', 'Hectare', 'هكتار', 1e4),
        UnitDef('in²', 'Square inch', 'بوصة مربعة', 0.00064516),
        UnitDef('ft²', 'Square foot', 'قدم مربع', 0.09290304),
        UnitDef('yd²', 'Square yard', 'ياردة مربعة', 0.83612736),
        UnitDef('ac', 'Acre', 'أكر', 4046.8564224),
        UnitDef('feddan', 'Feddan', 'فدان', 4200),
      ],
    ),
    UnitCategory(
      id: 'volume',
      nameEn: 'Volume',
      nameAr: 'الحجم',
      icon: Icons.view_in_ar_rounded,
      defaultFrom: 0,
      defaultTo: 1,
      units: <UnitDef>[
        UnitDef('m³', 'Cubic meter', 'متر مكعب', 1),
        UnitDef('L', 'Liter', 'لتر', 0.001),
        UnitDef('mL', 'Milliliter', 'ملليلتر', 1e-6),
        UnitDef('cm³', 'Cubic centimeter', 'سنتيمتر مكعب', 1e-6),
        UnitDef('in³', 'Cubic inch', 'بوصة مكعبة', 1.6387064e-5),
        UnitDef('ft³', 'Cubic foot', 'قدم مكعب', 0.028316846592),
        UnitDef('yd³', 'Cubic yard', 'ياردة مكعبة', 0.764554857984),
        UnitDef('gal (US)', 'Gallon (US)', 'جالون أمريكي', 0.003785411784),
        UnitDef('gal (UK)', 'Gallon (UK)', 'جالون إنجليزي', 0.00454609),
        UnitDef('bbl', 'Barrel (oil)', 'برميل', 0.158987294928),
      ],
    ),
    UnitCategory(
      id: 'mass',
      nameEn: 'Weight / Mass',
      nameAr: 'الوزن / الكتلة',
      icon: Icons.scale_rounded,
      defaultFrom: 0,
      defaultTo: 4,
      units: <UnitDef>[
        UnitDef('kg', 'Kilogram', 'كيلوجرام', 1),
        UnitDef('g', 'Gram', 'جرام', 0.001),
        UnitDef('mg', 'Milligram', 'ملليجرام', 1e-6),
        UnitDef('t', 'Metric ton', 'طن متري', 1000),
        UnitDef('lb', 'Pound', 'رطل', 0.45359237),
        UnitDef('oz', 'Ounce', 'أوقية', 0.028349523125),
        UnitDef('ton (US)', 'Short ton (US)', 'طن أمريكي', 907.18474),
        UnitDef('ton (UK)', 'Long ton (UK)', 'طن إنجليزي', 1016.0469088),
      ],
    ),
    UnitCategory(
      id: 'temperature',
      nameEn: 'Temperature',
      nameAr: 'درجة الحرارة',
      icon: Icons.thermostat_rounded,
      defaultFrom: 0,
      defaultTo: 1,
      units: <UnitDef>[
        UnitDef.affine('°C', 'Celsius', 'سيلزيوس', _cToK, _kToC),
        UnitDef.affine('°F', 'Fahrenheit', 'فهرنهايت', _fToK, _kToF),
        UnitDef.affine('K', 'Kelvin', 'كلفن', _same, _same),
        UnitDef.affine('°R', 'Rankine', 'رانكين', _rToK, _kToR),
      ],
    ),
    UnitCategory(
      id: 'pressure',
      nameEn: 'Pressure',
      nameAr: 'الضغط',
      icon: Icons.speed_rounded,
      defaultFrom: 4,
      defaultTo: 5,
      units: <UnitDef>[
        UnitDef('Pa', 'Pascal', 'باسكال', 1),
        UnitDef('kPa', 'Kilopascal', 'كيلوباسكال', 1000),
        UnitDef('MPa', 'Megapascal', 'ميجاباسكال', 1e6),
        UnitDef('mbar', 'Millibar', 'ملليبار', 100),
        UnitDef('bar', 'Bar', 'بار', 1e5),
        UnitDef('psi', 'Pound per square inch', 'رطل لكل بوصة مربعة', 6894.757293168361),
        UnitDef('atm', 'Atmosphere', 'ضغط جوي', 101325),
        UnitDef('kgf/cm²', 'Kilogram-force per cm²', 'كجم قوة لكل سم²', 98066.5),
        UnitDef('mmHg', 'Millimeter of mercury', 'ملم زئبق', 133.322387415),
        // 03/11/2026: Inch of mercury removed from the pressure units.
        UnitDef('mmH₂O', 'Millimeter of water', 'ملم ماء', 9.80665),
        UnitDef('inwg', 'Inch water gauge', 'بوصة عمود ماء', 249.08891),
        UnitDef('ftH₂O', 'Foot of water', 'قدم ماء', 2989.06692),
        UnitDef('mH₂O', 'Meter of water (head)', 'متر ماء (عمود)', 9806.65),
      ],
    ),
    UnitCategory(
      id: 'flow',
      nameEn: 'Flow rate',
      nameAr: 'معدل التدفق',
      icon: Icons.air_rounded,
      defaultFrom: 4,
      defaultTo: 2,
      units: <UnitDef>[
        UnitDef('m³/s', 'Cubic meter per second', 'متر مكعب/ثانية', 1),
        UnitDef('m³/h', 'Cubic meter per hour', 'متر مكعب/ساعة', 1 / 3600),
        UnitDef('L/s', 'Liter per second', 'لتر/ثانية', 0.001),
        UnitDef('L/min', 'Liter per minute', 'لتر/دقيقة', 1 / 60000),
        UnitDef('CFM', 'Cubic foot per minute', 'قدم مكعب/دقيقة', 0.028316846592 / 60),
        UnitDef('GPM (US)', 'Gallon per minute (US)', 'جالون أمريكي/دقيقة', 0.003785411784 / 60),
        UnitDef('GPM (UK)', 'Gallon per minute (UK)', 'جالون إنجليزي/دقيقة', 0.00454609 / 60),
      ],
    ),
    UnitCategory(
      id: 'speed',
      nameEn: 'Speed / Velocity',
      nameAr: 'السرعة',
      icon: Icons.directions_run_rounded,
      defaultFrom: 0,
      defaultTo: 3,
      units: <UnitDef>[
        UnitDef('m/s', 'Meter per second', 'متر/ثانية', 1),
        UnitDef('km/h', 'Kilometer per hour', 'كيلومتر/ساعة', 1 / 3.6),
        UnitDef('ft/s', 'Foot per second', 'قدم/ثانية', 0.3048),
        UnitDef('FPM', 'Foot per minute', 'قدم/دقيقة', 0.00508),
        UnitDef('mph', 'Mile per hour', 'ميل/ساعة', 0.44704),
        UnitDef('kn', 'Knot', 'عقدة', 1852 / 3600),
      ],
    ),
    UnitCategory(
      id: 'power',
      nameEn: 'Power / Cooling load',
      nameAr: 'القدرة / حمل التبريد',
      icon: Icons.bolt_rounded,
      defaultFrom: 4,
      defaultTo: 3,
      units: <UnitDef>[
        UnitDef('W', 'Watt', 'وات', 1),
        UnitDef('kW', 'Kilowatt', 'كيلووات', 1000),
        UnitDef('MW', 'Megawatt', 'ميجاوات', 1e6),
        UnitDef('BTU/h', 'BTU per hour', 'وحدة حرارية/ساعة', 0.29307107017222),
        UnitDef('TR', 'Ton of refrigeration', 'طن تبريد', 3516.8528420667),
        UnitDef('HP', 'Horsepower (electric)', 'حصان كهربائي', 746, approx: true),
        UnitDef('PS', 'Horsepower (metric)', 'حصان متري', 735.49875),
        UnitDef('kcal/h', 'Kilocalorie per hour', 'كيلو سعر/ساعة', 1.163),
      ],
    ),
    UnitCategory(
      id: 'energy',
      nameEn: 'Energy',
      nameAr: 'الطاقة',
      icon: Icons.local_fire_department_rounded,
      defaultFrom: 4,
      defaultTo: 7,
      units: <UnitDef>[
        UnitDef('J', 'Joule', 'جول', 1),
        UnitDef('kJ', 'Kilojoule', 'كيلوجول', 1000),
        UnitDef('MJ', 'Megajoule', 'ميجاجول', 1e6),
        UnitDef('Wh', 'Watt-hour', 'وات ساعة', 3600),
        UnitDef('kWh', 'Kilowatt-hour', 'كيلووات ساعة', 3.6e6),
        UnitDef('cal', 'Calorie', 'سعر حراري', 4.184),
        UnitDef('kcal', 'Kilocalorie', 'كيلو سعر حراري', 4184),
        UnitDef('BTU', 'British thermal unit', 'وحدة حرارية بريطانية', 1055.05585262),
        UnitDef('thm', 'Therm', 'ثيرم', 105505585.262),
      ],
    ),
    UnitCategory(
      id: 'force',
      nameEn: 'Force',
      nameAr: 'القوة',
      icon: Icons.fitness_center_rounded,
      defaultFrom: 1,
      defaultTo: 3,
      units: <UnitDef>[
        UnitDef('N', 'Newton', 'نيوتن', 1),
        UnitDef('kN', 'Kilonewton', 'كيلونيوتن', 1000),
        UnitDef('kgf', 'Kilogram-force', 'كيلوجرام قوة', 9.80665),
        UnitDef('tf', 'Ton-force (metric)', 'طن قوة', 9806.65),
        UnitDef('lbf', 'Pound-force', 'رطل قوة', 4.4482216152605),
        UnitDef('kip', 'Kip', 'كيب', 4448.2216152605),
      ],
    ),
    UnitCategory(
      id: 'density',
      nameEn: 'Density',
      nameAr: 'الكثافة',
      icon: Icons.opacity_rounded,
      defaultFrom: 0,
      defaultTo: 3,
      units: <UnitDef>[
        UnitDef('kg/m³', 'Kilogram per cubic meter', 'كجم/متر مكعب', 1),
        UnitDef('g/cm³', 'Gram per cubic centimeter', 'جرام/سم مكعب', 1000),
        UnitDef('g/L', 'Gram per liter', 'جرام/لتر', 1),
        UnitDef('lb/ft³', 'Pound per cubic foot', 'رطل/قدم مكعب', 16.018463373960138),
        UnitDef('lb/gal', 'Pound per US gallon', 'رطل/جالون أمريكي', 119.82642731689663),
      ],
    ),
    UnitCategory(
      id: 'time',
      nameEn: 'Time',
      nameAr: 'الزمن',
      icon: Icons.schedule_rounded,
      defaultFrom: 3,
      defaultTo: 2,
      units: <UnitDef>[
        UnitDef('s', 'Second', 'ثانية', 1),
        UnitDef('ms', 'Millisecond', 'مللي ثانية', 0.001),
        UnitDef('min', 'Minute', 'دقيقة', 60),
        UnitDef('h', 'Hour', 'ساعة', 3600),
        UnitDef('d', 'Day', 'يوم', 86400),
        UnitDef('wk', 'Week', 'أسبوع', 604800),
        UnitDef('yr', 'Year (365 days)', 'سنة (365 يومًا)', 31536000),
      ],
    ),
    UnitCategory(
      id: 'angle',
      nameEn: 'Angle',
      nameAr: 'الزاوية',
      icon: Icons.architecture_rounded,
      defaultFrom: 0,
      defaultTo: 1,
      units: <UnitDef>[
        UnitDef('°', 'Degree', 'درجة', _pi / 180),
        UnitDef('rad', 'Radian', 'راديان', 1),
        UnitDef('grad', 'Gradian', 'جراد', _pi / 200),
        UnitDef('′', 'Minute of arc', 'دقيقة قوسية', _pi / 10800),
        UnitDef('″', 'Second of arc', 'ثانية قوسية', _pi / 648000),
        UnitDef('rev', 'Revolution', 'دورة كاملة', 2 * _pi),
      ],
    ),
  ];
}
