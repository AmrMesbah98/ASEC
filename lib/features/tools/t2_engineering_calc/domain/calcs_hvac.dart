/// Module: tools / t2_engineering_calc
///
///*************************** FILE INFO ****************************///
/// File Name: calcs_hvac.dart
/// Purpose: The HVAC / air-conditioning calculators — cooling load, ASHRAE
///          62.1 ventilation, air changes, supply air, duct sizing, external
///          static pressure (ESP), chilled-water pump head and expansion tank.
/// Author: ASEC team
/// Created: 4/10/2026
///
/// Every compute function receives and returns BASE SI units
/// (see calc_model.dart): m, m², m³, m³/s, Pa, W, K, m/s.

import 'dart:math' as math;

import 'package:asec/features/tools/t2_engineering_calc/domain/calc_model.dart';
import 'package:asec/features/tools/t2_engineering_calc/domain/calc_units.dart';

// ── Shared physics ─────────────────────────────────────────────────────────

/// Standard air: ρ·cp = 1.21 kJ/m³·K (= the 1.08 of the IP formula) and
/// latent 3.0 kJ/m³ per g/kg (= the 0.68 of the IP formula).
const double _airSensible = 1210; // W per (m³/s · K)
const double _airLatent = 3000; // W per (m³/s · g/kg)

const double _airRho = 1.2; // kg/m³
const double _airNu = 1.5e-5; // m²/s
const double _ductRoughness = 0.00009; // m, galvanized steel

/// Darcy friction factor: laminar below Re 2300, Swamee–Jain above.
double darcyFactor(double re, double relRoughness) {
  if (re <= 0) return double.nan;
  if (re < 2300) return 64 / re;
  final double l = math.log(relRoughness / 3.7 + 5.74 / math.pow(re, 0.9)) / math.ln10;
  return 0.25 / (l * l);
}

/// Duct friction (Pa/m) for flow q (m³/s) in a round duct of diameter d (m)
/// — ASHRAE Fundamentals, Altshul–Tsal friction factor.
double ductFrictionRate(double q, double d) {
  final double a = math.pi * d * d / 4;
  final double v = q / a;
  final double re = v * d / _airNu;
  double f = 0.11 * math.pow(_ductRoughness / d + 68 / re, 0.25).toDouble();
  if (f < 0.018) f = 0.85 * f + 0.0028;
  return f / d * _airRho * v * v / 2;
}

/// Huebscher: round diameter with the same friction as an a × b rectangle.
double equivalentDiameter(double a, double b) =>
    1.30 * math.pow(a * b, 0.625) / math.pow(a + b, 0.25);

/// Solves f(x) = target for x in [lo, hi], f increasing (bisection).
double solveIncreasing(double Function(double) f, double target, double lo, double hi) {
  final double fLo = f(lo);
  final double fHi = f(hi);
  if (target.isNaN || fLo.isNaN || fHi.isNaN || fLo > target || fHi < target) {
    return double.nan;
  }
  for (int i = 0; i < 100; i++) {
    final double mid = (lo + hi) / 2;
    if (f(mid) < target) {
      lo = mid;
    } else {
      hi = mid;
    }
  }
  return (lo + hi) / 2;
}

/// Density of water (kg/m³) at t °C, 0–100 °C (Thiesen / Tanaka form).
double waterDensity(double tC) =>
    1000 * (1 - (tC + 288.9414) / (508929.2 * (tC + 68.12963)) * math.pow(tC - 3.9863, 2));

// ── 1. Cooling load ────────────────────────────────────────────────────────

Map<String, double> _coolingLoad(Map<String, double> v) {
  final double dT = v['outdoorT']! - v['indoorT']!;
  final double sf = 1 + v['safety']! / 100;
  final double glass = v['glassArea']! * (v['solarGain']! + v['glassU']! * dT);
  final double walls = v['wallArea']! * v['wallU']! * dT;
  final double roof = v['roofArea']! * v['roofU']! * (dT + 8);
  final double peopleS = v['people']! * v['sensPerPerson']!;
  final double peopleL = v['people']! * v['latPerPerson']!;
  final double lights = v['area']! * v['lighting']!;
  final double equip = v['area']! * v['equipment']!;
  final double oa = v['outdoorAir']!;
  final double oaS = _airSensible * oa * dT;
  final double oaL = _airLatent * oa * math.max(0, v['outdoorW']! - v['indoorW']!);

  final double roomSensible = (glass + walls + roof + peopleS + lights + equip) * sf;
  final double sensible = roomSensible + oaS * sf;
  final double latent = (peopleL + oaL) * sf;
  final double total = sensible + latent;
  return <String, double>{
    'sensible': sensible,
    'latent': latent,
    'total': total,
    'totalTR': total,
    'shr': sensible / total,
    'areaPerTR': v['area']! / (total / K.ton),
    'supplyAir': roomSensible / (_airSensible * v['supplyDT']!),
  };
}

const EngCalc coolingLoad = EngCalc(
  id: 'coolingLoad',
  en: 'Cooling load',
  ar: 'حمل التبريد',
  fields: <CalcField>[
    CalcField('area', 'Floor area', 'مساحة الأرضية', qty: Q.area, def: 100),
    CalcField('people', 'Number of people', 'عدد الأشخاص', def: 10),
    CalcField('sensPerPerson', 'Sensible heat per person', 'الحرارة المحسوسة لكل شخص', qty: Q.watts, def: 75),
    CalcField('latPerPerson', 'Latent heat per person', 'الحرارة الكامنة لكل شخص', qty: Q.watts, def: 55),
    CalcField('lighting', 'Lighting', 'الإضاءة', qty: Q.heatFlux, def: 12),
    CalcField('equipment', 'Equipment', 'الأجهزة', qty: Q.heatFlux, def: 15),
    CalcField('glassArea', 'Glass area', 'مساحة الزجاج', qty: Q.area, def: 10),
    CalcField('solarGain', 'Solar gain through glass', 'الكسب الشمسي عبر الزجاج', qty: Q.heatFlux, def: 200),
    CalcField('glassU', 'Glass U-value', 'معامل U للزجاج', qty: Q.uValue, def: 3),
    CalcField('wallArea', 'External wall area (net)', 'مساحة الحوائط الخارجية (صافي)', qty: Q.area, def: 30),
    CalcField('wallU', 'Wall U-value', 'معامل U للحائط', qty: Q.uValue, def: 1),
    CalcField('roofArea', 'Exposed roof area', 'مساحة السقف المعرض للشمس', qty: Q.area, def: 0),
    CalcField('roofU', 'Roof U-value', 'معامل U للسقف', qty: Q.uValue, def: 0.5),
    CalcField('outdoorT', 'Outdoor design temperature', 'درجة الحرارة الخارجية التصميمية', qty: Q.temp, def: 43),
    CalcField('indoorT', 'Indoor design temperature', 'درجة الحرارة الداخلية التصميمية', qty: Q.temp, def: 24),
    CalcField('outdoorAir', 'Fresh (outdoor) air', 'الهواء النقي (الخارجي)', qty: Q.airFlow, def: 100),
    CalcField('outdoorW', 'Outdoor humidity ratio', 'نسبة الرطوبة الخارجية', qty: Q.humidity, def: 14),
    CalcField('indoorW', 'Indoor humidity ratio', 'نسبة الرطوبة الداخلية', qty: Q.humidity, def: 9.3),
    CalcField('supplyDT', 'Supply air ΔT (room − supply)', 'فرق حرارة هواء الإمداد (الغرفة − الإمداد)', qty: Q.tempDiff, def: 11),
    CalcField('safety', 'Safety factor', 'معامل الأمان', unit: '%', def: 10),
  ],
  results: <CalcResult>[
    CalcResult('sensible', 'Sensible load', 'الحمل المحسوس', qty: Q.load),
    CalcResult('latent', 'Latent load', 'الحمل الكامن', qty: Q.load),
    CalcResult('total', 'Total load', 'الحمل الكلي', qty: Q.loadTons, primary: true),
    CalcResult('totalTR', 'Total load (tons)', 'الحمل الكلي (طن تبريد)', qty: Q.tons, primary: true),
    CalcResult('shr', 'Sensible heat ratio (SHR)', 'نسبة الحرارة المحسوسة (SHR)'),
    CalcResult('areaPerTR', 'Area per ton (check)', 'المساحة لكل طن (للمراجعة)', qty: Q.areaPerTon),
    CalcResult('supplyAir', 'Supply air flow', 'كمية هواء الإمداد', qty: Q.airFlow, primary: true),
  ],
  compute: _coolingLoad,
  formula: 'Glass = A·(SG + U·ΔT)   Walls = U·A·ΔT   Roof = U·A·(ΔT + 8)\n'
      'People = n·(qs + ql)   Lights, equipment = W/m² × area\n'
      'Fresh air: qs = 1.21·L/s·ΔT   ql = 3.0·L/s·Δw\n'
      'Supply air (L/s) = room sensible ÷ (1.21 × ΔT supply)',
  noteEn: 'Quick block-load estimate. Typical sun on unshaded glass is 150–500 W/m² '
      '(west worst). Roof uses ΔT + 8 K for sun on the slab. Fresh-air load is on the '
      'coil, so supply air uses the room sensible load only. Offices usually land '
      'around 15–25 m² per TR in hot climates.',
  noteAr: 'تقدير سريع للحمل. الكسب الشمسي على زجاج بدون تظليل عادة 150–500 وات/م² '
      '(الغرب الأسوأ). السقف يُحسب بفرق حرارة + 8 كلفن بسبب الشمس. حمل الهواء النقي '
      'على ملف التبريد، لذلك هواء الإمداد يُحسب من الحمل المحسوس للغرفة فقط. المكاتب '
      'غالبًا 15–25 م² لكل طن في المناخ الحار.',
);

// ── 2. Ventilation — ASHRAE 62.1 ───────────────────────────────────────────

Map<String, double> _ventilation(Map<String, double> v) {
  final double people = v['people']!;
  final double area = v['area']!;
  final double vbz = v['rp']! * people + v['ra']! * area; // L/s
  final double voz = vbz / v['ez']!;
  return <String, double>{
    'vbz': vbz / 1000,
    'voz': voz / 1000,
    'perPerson': people > 0 ? voz / people : double.nan,
    'ach': voz / 1000 * 3600 / (area * v['height']!),
  };
}

const EngCalc ventilation = EngCalc(
  id: 'ventilation',
  en: 'Ventilation (ASHRAE 62.1)',
  ar: 'التهوية (ASHRAE 62.1)',
  fields: <CalcField>[
    CalcField.choice('space', 'Space type', 'نوع الفراغ', <CalcChoice>[
      CalcChoice('Office', 'مكتب', <String, double>{'rp': 2.5, 'ra': 0.3}),
      CalcChoice('Conference / meeting room', 'قاعة اجتماعات', <String, double>{'rp': 2.5, 'ra': 0.3}),
      CalcChoice('Classroom (age 9+)', 'فصل دراسي (9 سنوات فأكثر)', <String, double>{'rp': 5, 'ra': 0.6}),
      CalcChoice('Lecture hall (fixed seats)', 'مدرج محاضرات', <String, double>{'rp': 3.8, 'ra': 0.3}),
      CalcChoice('Retail sales', 'محل تجاري', <String, double>{'rp': 3.8, 'ra': 0.6}),
      CalcChoice('Restaurant dining', 'صالة مطعم', <String, double>{'rp': 3.8, 'ra': 0.9}),
      CalcChoice('Hotel bedroom', 'غرفة فندقية', <String, double>{'rp': 2.5, 'ra': 0.3}),
      CalcChoice('Gym / health club', 'صالة رياضية', <String, double>{'rp': 10, 'ra': 0.3}),
      CalcChoice('Main lobby', 'بهو رئيسي', <String, double>{'rp': 2.5, 'ra': 0.3}),
      CalcChoice('Corridor', 'ممر', <String, double>{'rp': 0, 'ra': 0.3}),
      CalcChoice('Custom', 'قيم مخصصة'),
    ]),
    CalcField('rp', 'Rp — outdoor air per person', 'Rp — هواء نقي لكل شخص', qty: Q.ventPerson, def: 2.5),
    CalcField('ra', 'Ra — outdoor air per area', 'Ra — هواء نقي لكل م²', qty: Q.ventArea, def: 0.3),
    CalcField('people', 'Number of people (Pz)', 'عدد الأشخاص (Pz)', def: 10),
    CalcField('area', 'Floor area (Az)', 'مساحة الأرضية (Az)', qty: Q.area, def: 100),
    CalcField('height', 'Room height', 'ارتفاع الغرفة', qty: Q.length, def: 3),
    CalcField('ez', 'Air distribution effectiveness Ez', 'كفاءة توزيع الهواء Ez', def: 1),
  ],
  results: <CalcResult>[
    CalcResult('vbz', 'Breathing-zone outdoor air (Vbz)', 'الهواء النقي لمنطقة التنفس (Vbz)', qty: Q.airFlow),
    CalcResult('voz', 'Zone outdoor air (Voz)', 'الهواء النقي للمنطقة (Voz)', qty: Q.airFlow, primary: true),
    CalcResult('perPerson', 'Outdoor air per person', 'الهواء النقي لكل شخص', qty: Q.ventPerson),
    CalcResult('ach', 'Outdoor air changes per hour', 'معدل تغيير الهواء النقي في الساعة', unit: 'ACH'),
  ],
  compute: _ventilation,
  formula: 'Vbz = Rp·Pz + Ra·Az\nVoz = Vbz ÷ Ez',
  noteEn: 'Rp and Ra come from ASHRAE 62.1 Table 6-1 for the chosen space. Ez = 1.0 for '
      'ceiling supply of cool air, 0.8 for ceiling supply of warm air, 1.2 for floor / '
      'displacement supply.',
  noteAr: 'قيم Rp و Ra من جدول 6-1 في ASHRAE 62.1 حسب نوع الفراغ. Ez = 1.0 للإمداد '
      'البارد من السقف، 0.8 للإمداد الدافئ من السقف، 1.2 للإمداد من الأرضية.',
);

// ── 3. Air changes ─────────────────────────────────────────────────────────

Map<String, double> _airChanges(Map<String, double> v) {
  final double vol = v['length']! * v['width']! * v['height']!;
  final double q = vol * v['ach']! / 3600;
  return <String, double>{'volume': vol, 'flow': q, 'flowM3h': q};
}

const EngCalc airChanges = EngCalc(
  id: 'airChanges',
  en: 'Air changes (ACH)',
  ar: 'معدل تغيير الهواء',
  fields: <CalcField>[
    CalcField.choice('room', 'Room type', 'نوع الغرفة', <CalcChoice>[
      CalcChoice('Toilets', 'حمامات', <String, double>{'ach': 10}),
      CalcChoice('Domestic kitchen', 'مطبخ منزلي', <String, double>{'ach': 15}),
      CalcChoice('Commercial kitchen', 'مطبخ تجاري', <String, double>{'ach': 30}),
      CalcChoice('Car park — normal', 'جراج — تشغيل عادي', <String, double>{'ach': 6}),
      CalcChoice('Car park — smoke', 'جراج — شفط الدخان', <String, double>{'ach': 10}),
      CalcChoice('Electrical / pump room', 'غرفة كهرباء / طلمبات', <String, double>{'ach': 10}),
      CalcChoice('Storage', 'مخزن', <String, double>{'ach': 4}),
      CalcChoice('Office (general)', 'مكتب (عام)', <String, double>{'ach': 6}),
      CalcChoice('Custom', 'قيمة مخصصة'),
    ]),
    CalcField('length', 'Room length', 'طول الغرفة', qty: Q.length, def: 5),
    CalcField('width', 'Room width', 'عرض الغرفة', qty: Q.length, def: 4),
    CalcField('height', 'Room height', 'ارتفاع الغرفة', qty: Q.length, def: 3),
    CalcField('ach', 'Air changes per hour', 'عدد مرات تغيير الهواء في الساعة', unit: 'ACH', def: 10),
  ],
  results: <CalcResult>[
    CalcResult('volume', 'Room volume', 'حجم الغرفة', qty: Q.roomVolume),
    CalcResult('flow', 'Air flow', 'كمية الهواء', qty: Q.airFlow, primary: true),
    CalcResult('flowM3h', 'Air flow', 'كمية الهواء', qty: Q.airFlowM3h, primary: true),
  ],
  compute: _airChanges,
  formula: 'V = L × W × H\nQ = V × ACH ÷ 3600',
  noteEn: 'Room presets are common rules of thumb — the local code or the authority may '
      'ask for more (car-park smoke extract is often set by the fire authority).',
  noteAr: 'القيم الجاهزة قواعد تقريبية شائعة — الكود المحلي أو الجهة المختصة قد تطلب '
      'أكثر (شفط دخان الجراجات غالبًا تحدده جهة الدفاع المدني).',
);

// ── 4. Supply air from load ────────────────────────────────────────────────

Map<String, double> _supplyAir(Map<String, double> v) {
  final double qs = v['sensible']!;
  final double ql = v['latent']!;
  final double flow = qs / (_airSensible * v['dT']!);
  return <String, double>{
    'flow': flow,
    'flowM3h': flow,
    'shr': qs / (qs + ql),
    'dw': ql / (_airLatent * flow),
  };
}

const EngCalc supplyAir = EngCalc(
  id: 'supplyAir',
  en: 'Supply air from load',
  ar: 'هواء الإمداد من الحمل',
  fields: <CalcField>[
    CalcField('sensible', 'Room sensible load', 'الحمل المحسوس للغرفة', qty: Q.load, def: 10),
    CalcField('latent', 'Room latent load', 'الحمل الكامن للغرفة', qty: Q.load, def: 2),
    CalcField('dT', 'Supply air ΔT (room − supply)', 'فرق حرارة هواء الإمداد (الغرفة − الإمداد)', qty: Q.tempDiff, def: 11),
  ],
  results: <CalcResult>[
    CalcResult('flow', 'Supply air flow', 'كمية هواء الإمداد', qty: Q.airFlow, primary: true),
    CalcResult('flowM3h', 'Supply air flow', 'كمية هواء الإمداد', qty: Q.airFlowM3h, primary: true),
    CalcResult('shr', 'Room sensible heat ratio', 'نسبة الحرارة المحسوسة للغرفة'),
    CalcResult('dw', 'Moisture the supply air must pick up', 'الرطوبة التي يجب أن يمتصها الهواء', qty: Q.humidity),
  ],
  compute: _supplyAir,
  formula: 'SI:  L/s = qs (W) ÷ (1.21 × ΔT)\nIP:  CFM = qs (BTU/h) ÷ (1.08 × ΔT °F)\n'
      'Δw = ql ÷ (3.0 × L/s)',
  noteEn: 'ΔT of 10–12 K is usual for comfort cooling (supply ≈ 13 °C to a 24 °C room).',
  noteAr: 'فرق الحرارة 10–12 كلفن معتاد في تكييف الراحة (إمداد ≈ 13 °م لغرفة 24 °م).',
);

// ── 5. Duct sizing ─────────────────────────────────────────────────────────

Map<String, double> _ductSize(Map<String, double> v) {
  final double q = v['flow']!;
  final double d;
  if (v['method']! == 0) {
    d = math.sqrt(4 * q / (math.pi * v['velocity']!));
  } else {
    // Friction falls as the duct grows: solve on −friction.
    final double target = v['friction']!;
    d = solveIncreasing((double x) => -ductFrictionRate(q, x), -target, 0.02, 5);
  }
  final double a = v['width']!;
  final double b = solveIncreasing((double x) => equivalentDiameter(a, x), d, 0.01, 10);
  return <String, double>{
    'diameter': d,
    'velocity': q / (math.pi * d * d / 4),
    'friction': ductFrictionRate(q, d),
    'height': b,
    'rectVelocity': q / (a * b),
    'aspect': math.max(a, b) / math.min(a, b),
  };
}

const EngCalc ductSize = EngCalc(
  id: 'ductSize',
  en: 'Duct sizing',
  ar: 'تصميم مقاسات الدكت',
  fields: <CalcField>[
    CalcField('flow', 'Air flow', 'كمية الهواء', qty: Q.airFlow, def: 1000),
    CalcField.choice('method', 'Sizing method', 'طريقة التصميم', <CalcChoice>[
      CalcChoice('By velocity', 'بالسرعة'),
      CalcChoice('By friction rate (equal friction)', 'بمعدل الاحتكاك (الاحتكاك المتساوي)'),
    ]),
    CalcField('velocity', 'Design velocity', 'السرعة التصميمية', qty: Q.airSpeed, def: 6, showIf: ('method', 0)),
    CalcField('friction', 'Friction rate', 'معدل الاحتكاك', qty: Q.ductFriction, def: 1, showIf: ('method', 1)),
    CalcField('width', 'Rectangular duct width', 'عرض الدكت المستطيل', qty: Q.diameter, def: 600),
  ],
  results: <CalcResult>[
    CalcResult('diameter', 'Round duct diameter', 'قطر الدكت الدائري', qty: Q.diameter, primary: true),
    CalcResult('velocity', 'Velocity (round)', 'السرعة (دائري)', qty: Q.airSpeed),
    CalcResult('friction', 'Friction rate', 'معدل الاحتكاك', qty: Q.ductFriction),
    CalcResult('height', 'Rectangular duct height', 'ارتفاع الدكت المستطيل', qty: Q.diameter, primary: true),
    CalcResult('rectVelocity', 'Velocity (rectangular)', 'السرعة (مستطيل)', qty: Q.airSpeed),
    CalcResult('aspect', 'Aspect ratio', 'نسبة الأبعاد'),
  ],
  compute: _ductSize,
  formula: 'D = √(4Q ÷ πV)\n'
      'Δp/L = f/D · ρV²/2   (Altshul–Tsal, galvanized ε = 0.09 mm)\n'
      'De = 1.30·(a·b)^0.625 ÷ (a + b)^0.25',
  noteEn: 'Usual design: 0.8–1.0 Pa/m (≈ 0.1 inwg/100ft); main ducts 5–8 m/s, branches '
      '3–5 m/s in offices. Keep the aspect ratio under 4:1. Round the size up to a '
      'standard duct size.',
  noteAr: 'المعتاد: 0.8–1.0 باسكال/متر (≈ 0.1 بوصة ماء/100 قدم)؛ الخطوط الرئيسية 5–8 م/ث '
      'والفرعية 3–5 م/ث في المكاتب. اجعل نسبة الأبعاد أقل من 4:1. قرّب المقاس لأقرب '
      'مقاس قياسي أكبر.',
);

// ── 6. External static pressure (ESP) ──────────────────────────────────────

Map<String, double> _esp(Map<String, double> v) {
  final double straight = (v['supplyLen']! + v['returnLen']!) * v['friction']!;
  final double fittings = straight * v['fittings']! / 100;
  final double terminals = v['diffuser']! + v['grille']! + v['dampers']! + v['other']!;
  return <String, double>{
    'straight': straight,
    'fittingsLoss': fittings,
    'terminals': terminals,
    'esp': (straight + fittings + terminals) * (1 + v['safety']! / 100),
  };
}

const EngCalc esp = EngCalc(
  id: 'esp',
  en: 'External static pressure (ESP)',
  ar: 'الضغط الاستاتيكي الخارجي (ESP)',
  fields: <CalcField>[
    CalcField('supplyLen', 'Supply duct — longest run', 'دكت الإمداد — أطول مسار', qty: Q.length, def: 40),
    CalcField('returnLen', 'Return duct — longest run', 'دكت الراجع — أطول مسار', qty: Q.length, def: 20),
    CalcField('friction', 'Duct friction rate', 'معدل الاحتكاك في الدكت', qty: Q.ductFriction, def: 1),
    CalcField('fittings', 'Fittings allowance (of straight duct)', 'نسبة القطع (من الدكت المستقيم)', unit: '%', def: 50),
    CalcField('diffuser', 'Supply diffuser', 'فتحة الإمداد (ديفيوزر)', qty: Q.airPressure, def: 25),
    CalcField('grille', 'Return grille', 'فتحة الراجع (جريل)', qty: Q.airPressure, def: 15),
    CalcField('dampers', 'Volume / fire dampers', 'دامبرات التحكم / الحريق', qty: Q.airPressure, def: 25),
    CalcField('other', 'Other external items (filter, silencer, heater)', 'عناصر خارجية أخرى (فلتر، كاتم صوت، سخان)', qty: Q.airPressure, def: 0),
    CalcField('safety', 'Safety factor', 'معامل الأمان', unit: '%', def: 10),
  ],
  results: <CalcResult>[
    CalcResult('straight', 'Straight duct loss', 'الفقد في الدكت المستقيم', qty: Q.airPressure),
    CalcResult('fittingsLoss', 'Fittings loss', 'الفقد في القطع', qty: Q.airPressure),
    CalcResult('terminals', 'Terminals & accessories', 'الفتحات والملحقات', qty: Q.airPressure),
    CalcResult('esp', 'External static pressure', 'الضغط الاستاتيكي الخارجي', qty: Q.airPressure, primary: true),
  ],
  compute: _esp,
  formula: 'ESP = [ (Ls + Lr)·Δp/L · (1 + fittings%) + Σ terminals ] × (1 + safety%)',
  noteEn: 'ESP is everything OUTSIDE the unit. The unit\'s own coil and filter are inside '
      'the manufacturer\'s rating — only add a filter here if it is installed in the '
      'ductwork. Fittings are often 50–100% of the straight-duct loss.',
  noteAr: 'الـ ESP هو كل ما هو خارج الوحدة. ملف التبريد والفلتر الداخلي محسوبان في '
      'بيانات المصنع — أضف الفلتر هنا فقط إذا كان مركبًا على الدكت. القطع غالبًا '
      '50–100% من فقد الدكت المستقيم.',
);

// ── 7. Pump head (closed hydronic loop) ────────────────────────────────────

const List<double> _pipeRoughness = <double>[0.045e-3, 0.0015e-3, 0.007e-3];
const List<double> _waterNu = <double>[1.43e-6, 0.80e-6, 0.365e-6];
const List<double> _waterRho = <double>[999.9, 995.7, 971.8];

Map<String, double> _pumpHead(Map<String, double> v) {
  final int mat = v['material']!.round();
  final int t = v['water']!.round();
  final double q = v['flow']!;
  final double d = v['diameter']!;
  final double rho = _waterRho[t];
  final double vel = q / (math.pi * d * d / 4);
  final double re = vel * d / _waterNu[t];
  final double grad = darcyFactor(re, _pipeRoughness[mat] / d) / d * rho * vel * vel / 2;
  final double pipe = grad * v['length']! * (1 + v['fittings']! / 100);
  final double total = (pipe +
          v['chillerDp']! +
          v['coilDp']! +
          v['valveDp']! +
          v['otherDp']! +
          rho * K.g * v['staticH']!) *
      (1 + v['safety']! / 100);
  final double hyd = q * total;
  return <String, double>{
    'velocity': vel,
    'frictionRate': grad,
    'pipeLoss': pipe,
    'head': total,
    'pressure': total,
    'hydPower': hyd,
    'shaftPower': hyd / (v['eff']! / 100),
  };
}

const EngCalc pumpHead = EngCalc(
  id: 'pumpHead',
  en: 'Pump head (chilled / hot water)',
  ar: 'رفع الطلمبة (مياه مثلجة / ساخنة)',
  fields: <CalcField>[
    CalcField('flow', 'Water flow', 'تصرف المياه', qty: Q.waterFlow, def: 10),
    CalcField.choice('material', 'Pipe material', 'خامة المواسير', <CalcChoice>[
      CalcChoice('Steel', 'حديد (صلب)'),
      CalcChoice('Copper', 'نحاس'),
      CalcChoice('PPR / PVC / HDPE', 'PPR / PVC / HDPE'),
    ]),
    CalcField.choice('water', 'Water', 'نوع المياه', <CalcChoice>[
      CalcChoice('Chilled water (7 °C)', 'مياه مثلجة (7 °م)'),
      CalcChoice('Condenser water (30 °C)', 'مياه تبريد المكثف (30 °م)'),
      CalcChoice('Hot water (80 °C)', 'مياه ساخنة (80 °م)'),
    ]),
    CalcField('diameter', 'Pipe internal diameter', 'القطر الداخلي للماسورة', qty: Q.diameter, def: 100),
    CalcField('length', 'Index circuit length (supply + return)', 'طول أبعد دائرة (ذهاب + عودة)', qty: Q.length, def: 200),
    CalcField('fittings', 'Fittings allowance (of pipe loss)', 'نسبة القطع (من فقد المواسير)', unit: '%', def: 50),
    CalcField('chillerDp', 'Chiller / evaporator pressure drop', 'فقد الضغط في الشيلر / المبخر', qty: Q.waterDp, def: 50),
    CalcField('coilDp', 'Farthest coil (AHU / FCU)', 'أبعد ملف (AHU / FCU)', qty: Q.waterDp, def: 40),
    CalcField('valveDp', 'Control valve', 'محبس التحكم', qty: Q.waterDp, def: 30),
    CalcField('otherDp', 'Strainer, check valve, meters', 'المصفاة، محبس عدم الرجوع، العدادات', qty: Q.waterDp, def: 20),
    CalcField('staticH', 'Static lift (open systems only)', 'الرفع الاستاتيكي (للدوائر المفتوحة فقط)', qty: Q.length, def: 0),
    CalcField('safety', 'Safety factor', 'معامل الأمان', unit: '%', def: 10),
    CalcField('eff', 'Pump efficiency', 'كفاءة الطلمبة', unit: '%', def: 70),
  ],
  results: <CalcResult>[
    CalcResult('velocity', 'Water velocity', 'سرعة المياه', qty: Q.waterSpeed),
    CalcResult('frictionRate', 'Pipe friction rate', 'معدل الاحتكاك', qty: Q.pipeFriction),
    CalcResult('pipeLoss', 'Pipe + fittings loss', 'فقد المواسير والقطع', qty: Q.waterDp),
    CalcResult('head', 'Pump head', 'رفع الطلمبة', qty: Q.head, primary: true),
    CalcResult('pressure', 'Pump pressure', 'ضغط الطلمبة', qty: Q.kPaPsi),
    CalcResult('hydPower', 'Hydraulic power', 'القدرة الهيدروليكية', qty: Q.motor),
    CalcResult('shaftPower', 'Shaft power', 'قدرة عمود الطلمبة', qty: Q.motor, primary: true),
  ],
  compute: _pumpHead,
  formula: 'Δp/L = f/D · ρV²/2   (Darcy–Weisbach, Swamee–Jain f)\n'
      'H = [pipe·(1 + fittings%) + Σ equipment Δp + ρ·g·h] × (1 + safety%)\n'
      'P = Q·H ÷ η',
  noteEn: 'In a closed loop the static height cancels out — leave it 0. Aim for 100–400 '
      'Pa/m friction and under 3 m/s. Take equipment pressure drops from the '
      'manufacturer\'s data.',
  noteAr: 'في الدائرة المغلقة الارتفاع الاستاتيكي يلغي نفسه — اتركه 0. المعتاد احتكاك '
      '100–400 باسكال/متر وسرعة أقل من 3 م/ث. خذ فقد الضغط للمعدات من كتالوج المصنع.',
);

// ── 8. Expansion tank (diaphragm) ──────────────────────────────────────────

const List<double> _pipeAlpha = <double>[11.7e-6, 17.1e-6]; // 1/K: steel, copper

Map<String, double> _expansionTank(Map<String, double> v) {
  final double t1 = v['t1']! - 273.15;
  final double t2 = v['t2']! - 273.15;
  final double vs = v['volume']!;
  final double alpha = _pipeAlpha[v['material']!.round()];
  final double ratio = waterDensity(t1) / waterDensity(t2); // v2 / v1
  final double net = vs * ((ratio - 1) - 3 * alpha * (t2 - t1));
  final double af = 1 - (v['p1']! + K.atm) / (v['p2']! + K.atm);
  return <String, double>{
    'expansion': net,
    'acceptance': af,
    'tank': af > 0 ? net / af : double.nan,
  };
}

const EngCalc expansionTank = EngCalc(
  id: 'expansionTank',
  en: 'Expansion tank',
  ar: 'خزان التمدد',
  fields: <CalcField>[
    CalcField.choice('system', 'System', 'نوع الدائرة', <CalcChoice>[
      CalcChoice('Chilled water', 'مياه مثلجة', <String, double>{'t1': 7, 't2': 40}),
      CalcChoice('Heating hot water', 'مياه تسخين', <String, double>{'t1': 10, 't2': 82}),
      CalcChoice('Custom', 'قيم مخصصة'),
    ]),
    CalcField('volume', 'System water volume', 'حجم المياه في الدائرة', qty: Q.liters, def: 5000),
    CalcField('t1', 'Lowest water temperature', 'أقل درجة حرارة للمياه', qty: Q.temp, def: 7),
    CalcField('t2', 'Highest water temperature', 'أعلى درجة حرارة للمياه', qty: Q.temp, def: 40),
    CalcField.choice('material', 'Pipe material', 'خامة المواسير', <CalcChoice>[
      CalcChoice('Steel', 'حديد (صلب)'),
      CalcChoice('Copper', 'نحاس'),
    ]),
    CalcField('p1', 'Fill / pre-charge pressure at the tank (gauge)', 'ضغط الملء / الشحن المسبق عند الخزان (عياري)', qty: Q.barPsi, def: 1.5),
    CalcField('p2', 'Maximum pressure at the tank (gauge)', 'أقصى ضغط عند الخزان (عياري)', qty: Q.barPsi, def: 3.5),
  ],
  results: <CalcResult>[
    CalcResult('expansion', 'Net water expansion', 'صافي تمدد المياه', qty: Q.liters),
    CalcResult('acceptance', 'Acceptance factor', 'معامل القبول'),
    CalcResult('tank', 'Minimum tank volume', 'أقل حجم للخزان', qty: Q.liters, primary: true),
  ],
  compute: _expansionTank,
  formula: 'Vt = Vs·[(v2/v1 − 1) − 3α·(t2 − t1)] ÷ (1 − P1/P2)\n'
      '(P1, P2 absolute;  ASHRAE diaphragm tank)',
  noteEn: 'Chilled water: the highest temperature is the plant room / ambient when the '
      'system is off. Fill pressure = static height above the tank + about 0.3 bar. '
      'Maximum pressure = relief valve setting minus 10%. Pick the next standard tank size.',
  noteAr: 'للمياه المثلجة: أعلى درجة حرارة هي حرارة غرفة الماكينات / الجو عند توقف '
      'النظام. ضغط الملء = الارتفاع الاستاتيكي فوق الخزان + حوالي 0.3 بار. أقصى ضغط = '
      'ضبط محبس الأمان ناقص 10%. اختر أقرب مقاس قياسي أكبر.',
);

const List<EngCalc> hvacCalcs = <EngCalc>[
  coolingLoad,
  ventilation,
  airChanges,
  supplyAir,
  ductSize,
  esp,
  pumpHead,
  expansionTank,
];
