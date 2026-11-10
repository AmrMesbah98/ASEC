/// Module: tools / t2_engineering_calc
///
///*************************** FILE INFO ****************************///
/// File Name: calcs_fire.dart
/// Purpose: The fire-fighting calculators — sprinkler head (K-factor),
///          sprinkler system demand & fire water tank (NFPA 13), standpipe
///          demand (NFPA 14), fire pump (NFPA 20) and Hazen–Williams pipe
///          friction (also used by the plumbing tab).
/// Author: ASEC team
/// Created: 4/10/2026
///
/// Every compute function receives and returns BASE SI units
/// (see calc_model.dart). K-factor base: L/min per √bar; density base:
/// mm/min (= L/min per m²).

import 'dart:math' as math;

import 'package:asec/features/tools/t2_engineering_calc/domain/calc_model.dart';
import 'package:asec/features/tools/t2_engineering_calc/domain/calc_units.dart';

/// NFPA 13 minimum operating pressure at a sprinkler: 7 psi.
const double _minSprinklerBar = 0.48263;

// ── Hazard presets (NFPA 13 density / area curves, max coverage, hose) ─────

const List<CalcChoice> _hazards = <CalcChoice>[
  CalcChoice('Light hazard', 'خطورة خفيفة', <String, double>{
    'density': 4.1, 'designArea': 139, 'coverage': 20.9, 'hose': 379, 'duration': 30, //
  }),
  CalcChoice('Ordinary hazard — group 1', 'خطورة عادية — مجموعة 1', <String, double>{
    'density': 6.1, 'designArea': 139, 'coverage': 12.1, 'hose': 946, 'duration': 60, //
  }),
  CalcChoice('Ordinary hazard — group 2', 'خطورة عادية — مجموعة 2', <String, double>{
    'density': 8.1, 'designArea': 139, 'coverage': 12.1, 'hose': 946, 'duration': 60, //
  }),
  CalcChoice('Extra hazard — group 1', 'خطورة عالية — مجموعة 1', <String, double>{
    'density': 12.2, 'designArea': 232, 'coverage': 9.3, 'hose': 1893, 'duration': 90, //
  }),
  CalcChoice('Extra hazard — group 2', 'خطورة عالية — مجموعة 2', <String, double>{
    'density': 16.3, 'designArea': 232, 'coverage': 9.3, 'hose': 1893, 'duration': 120, //
  }),
  CalcChoice('Custom', 'قيم مخصصة'),
];

// ── 1. Sprinkler head ──────────────────────────────────────────────────────

Map<String, double> _sprinklerHead(Map<String, double> v) {
  final double k = v['kFactor']!; // L/min/√bar
  final double qDensity = v['density']! * v['coverage']!; // L/min
  final double qAtMin = k * math.sqrt(_minSprinklerBar);
  final double qReq = math.max(qDensity, qAtMin);
  final double pReq = math.pow(qReq / k, 2).toDouble(); // bar
  final double pAvail = math.max(0, v['available']!) / K.bar;
  return <String, double>{
    'qReq': qReq * K.lpm,
    'pReq': pReq * K.bar,
    'qAvail': k * math.sqrt(pAvail) * K.lpm,
  };
}

const EngCalc sprinklerHead = EngCalc(
  id: 'sprinklerHead',
  en: 'Sprinkler head (K-factor)',
  ar: 'رأس الرشاش (معامل K)',
  fields: <CalcField>[
    CalcField.choice('hazard', 'Occupancy hazard', 'تصنيف الخطورة', _hazards),
    CalcField('kFactor', 'Sprinkler K-factor', 'معامل K للرشاش', qty: Q.kFactor, def: 80),
    CalcField('density', 'Design density', 'كثافة التصميم', qty: Q.density, def: 4.1),
    CalcField('coverage', 'Coverage area per sprinkler', 'مساحة التغطية لكل رشاش', qty: Q.area, def: 20.9),
    CalcField('available', 'Pressure available at the sprinkler', 'الضغط المتاح عند الرشاش', qty: Q.barPsi, def: 1),
  ],
  results: <CalcResult>[
    CalcResult('qReq', 'Minimum flow per sprinkler', 'أقل تصرف لكل رشاش', qty: Q.fireFlow, primary: true),
    CalcResult('pReq', 'Minimum pressure at the sprinkler', 'أقل ضغط عند الرشاش', qty: Q.barPsi, primary: true),
    CalcResult('qAvail', 'Flow at the available pressure', 'التصرف عند الضغط المتاح', qty: Q.fireFlow),
  ],
  compute: _sprinklerHead,
  formula: 'Q = K·√P\nQmin = density × coverage   (and never below 7 psi / 0.48 bar)\n'
      'Pmin = (Qmin ÷ K)²',
  noteEn: 'K 80 metric = K 5.6 US (½" standard sprinkler); K 115 = K 8.0. Coverage values '
      'in the presets are the NFPA 13 maximum per sprinkler — the real spacing on your '
      'layout is usually smaller.',
  noteAr: 'K 80 متري = K 5.6 أمريكي (رشاش ½ بوصة قياسي)؛ K 115 = K 8.0. مساحات التغطية '
      'في القيم الجاهزة هي الحد الأقصى في NFPA 13 — التباعد الفعلي في الرسم غالبًا أقل.',
);

// ── 2. Sprinkler demand & fire water tank ──────────────────────────────────

Map<String, double> _sprinklerDemand(Map<String, double> v) {
  final double area = v['designArea']!;
  final double sprinkler = v['density']! * area * (1 + v['overage']! / 100); // L/min
  final double hose = v['hose']! / K.lpm; // L/min
  final double total = sprinkler + hose;
  final double minutes = v['duration']! / 60;
  return <String, double>{
    'heads': (area / v['coverage']!).ceilToDouble(),
    'sprinklerFlow': sprinkler * K.lpm,
    'totalFlow': total * K.lpm,
    'tank': total * minutes / 1000,
  };
}

const EngCalc sprinklerDemand = EngCalc(
  id: 'sprinklerDemand',
  en: 'Sprinkler demand & fire tank',
  ar: 'احتياج الرشاشات وخزان الحريق',
  fields: <CalcField>[
    CalcField.choice('hazard', 'Occupancy hazard', 'تصنيف الخطورة', _hazards),
    CalcField('density', 'Design density', 'كثافة التصميم', qty: Q.density, def: 4.1),
    CalcField('designArea', 'Design (remote) area', 'مساحة التصميم (الأبعد)', qty: Q.area, def: 139),
    CalcField('coverage', 'Coverage area per sprinkler', 'مساحة التغطية لكل رشاش', qty: Q.area, def: 20.9),
    CalcField('hose', 'Hose stream allowance', 'تصرف خراطيم الحريق', qty: Q.fireFlow, def: 379),
    CalcField('duration', 'Water supply duration', 'مدة إمداد المياه', qty: Q.minutes, def: 30),
    CalcField('overage', 'Hydraulic overage (imbalance)', 'زيادة هيدروليكية (عدم الاتزان)', unit: '%', def: 10),
  ],
  results: <CalcResult>[
    CalcResult('heads', 'Sprinklers operating in design area', 'عدد الرشاشات العاملة في مساحة التصميم'),
    CalcResult('sprinklerFlow', 'Sprinkler demand', 'احتياج الرشاشات', qty: Q.fireFlow),
    CalcResult('totalFlow', 'Total demand (with hose)', 'الاحتياج الكلي (مع الخراطيم)', qty: Q.fireFlow, primary: true),
    CalcResult('tank', 'Fire water tank volume', 'حجم خزان مياه الحريق', qty: Q.tank, primary: true),
  ],
  compute: _sprinklerDemand,
  formula: 'Qs = density × design area × (1 + overage%)\nQt = Qs + hose allowance\n'
      'Tank = Qt × duration',
  noteEn: 'Hose allowance and duration follow NFPA 13: light 100 gpm / 30 min, ordinary '
      '250 gpm / 60–90 min, extra 500 gpm / 90–120 min. If standpipes share the tank, '
      'check the standpipe demand too and use the larger.',
  noteAr: 'تصرف الخراطيم والمدة حسب NFPA 13: خفيفة 100 جالون/د لمدة 30 دقيقة، عادية 250 '
      'جالون/د لمدة 60–90 دقيقة، عالية 500 جالون/د لمدة 90–120 دقيقة. إذا كانت '
      'الصواعد تشترك في نفس الخزان، احسب احتياجها أيضًا وخذ الأكبر.',
);

// ── 3. Standpipe (NFPA 14) ─────────────────────────────────────────────────

Map<String, double> _standpipe(Map<String, double> v) {
  final bool classII = v['class']!.round() == 1;
  final int n = v['count']!.round();
  double gpm;
  if (classII) {
    gpm = 100;
  } else if (n <= 0) {
    gpm = double.nan;
  } else {
    gpm = 500 + 250.0 * (n - 1);
    gpm = math.min(gpm, v['sprinklered']!.round() == 0 ? 1000.0 : 1250.0);
  }
  final double residual = (classII ? 65 : 100) * K.psi;
  return <String, double>{
    'flow': gpm * K.gpm,
    'residual': residual,
    'pumpPressure': residual + 1000 * K.g * v['height']! + v['friction']!,
  };
}

const EngCalc standpipe = EngCalc(
  id: 'standpipe',
  en: 'Standpipe demand (NFPA 14)',
  ar: 'احتياج صواعد الحريق (NFPA 14)',
  fields: <CalcField>[
    CalcField.choice('class', 'Standpipe class', 'فئة الصاعد', <CalcChoice>[
      CalcChoice('Class I / III (2½" hose valves)', 'الفئة I / III (محابس 2½ بوصة)'),
      CalcChoice('Class II (1½" hose stations)', 'الفئة II (صناديق خراطيم 1½ بوصة)'),
    ]),
    CalcField('count', 'Number of standpipes', 'عدد الصواعد', def: 2),
    CalcField.choice('sprinklered', 'Building', 'المبنى', <CalcChoice>[
      CalcChoice('Fully sprinklered', 'مزود بالكامل برشاشات'),
      CalcChoice('Not sprinklered', 'غير مزود برشاشات'),
    ]),
    CalcField('height', 'Height of the top outlet above the pump', 'ارتفاع أعلى مخرج فوق الطلمبة', qty: Q.length, def: 30),
    CalcField('friction', 'Pipe friction losses', 'فقد الاحتكاك في المواسير', qty: Q.barPsi, def: 1),
  ],
  results: <CalcResult>[
    CalcResult('flow', 'Standpipe system demand', 'احتياج نظام الصواعد', qty: Q.fireFlow, primary: true),
    CalcResult('residual', 'Residual pressure at top outlet', 'الضغط المتبقي عند أعلى مخرج', qty: Q.barPsi),
    CalcResult('pumpPressure', 'Pressure needed at the pump', 'الضغط المطلوب عند الطلمبة', qty: Q.barPsi, primary: true),
  ],
  compute: _standpipe,
  formula: 'Class I/III: 500 gpm first standpipe + 250 gpm each extra\n'
      '   max 1000 gpm (sprinklered) / 1250 gpm (not)\n'
      'Class II: 100 gpm at 65 psi\n'
      'P pump = P residual + ρ·g·h + friction',
  noteEn: 'Residual pressure at the hydraulically most remote outlet: 100 psi (6.9 bar) for '
      'Class I / III, 65 psi (4.5 bar) for Class II.',
  noteAr: 'الضغط المتبقي عند أبعد مخرج هيدروليكيًا: 100 psi (6.9 بار) للفئة I / III، '
      'و65 psi (4.5 بار) للفئة II.',
);

// ── 4. Fire pump (NFPA 20) ─────────────────────────────────────────────────

const List<double> _nfpa20Ratings = <double>[
  25, 50, 100, 150, 200, 250, 300, 400, 450, 500, 750, 1000, 1250, 1500, //
  2000, 2500, 3000, 3500, 4000, 4500, 5000,
];

String _ratingText(double gpm) =>
    gpm.isNaN ? '—' : '${gpm.round()} gpm · ${(gpm * 3.785411784).round()} l/min';

Map<String, double> _firePump(Map<String, double> v) {
  final double demandGpm = v['flow']! / K.gpm;
  final double rated = _nfpa20Ratings.firstWhere(
    (double r) => r >= demandGpm - 1e-6,
    orElse: () => double.nan,
  );
  final double net = v['pressure']! - v['suction']!;
  final double q = rated * K.gpm;
  return <String, double>{
    'net': net,
    'head': net,
    'rated': rated,
    'p150': net * 0.65,
    'churn': net * 1.40,
    'power': q * net / (v['eff']! / 100),
    'jockeyFlow': q * 0.01,
    'jockeyP': net + 10 * K.psi,
  };
}

const EngCalc firePump = EngCalc(
  id: 'firePump',
  en: 'Fire pump (NFPA 20)',
  ar: 'طلمبة الحريق (NFPA 20)',
  fields: <CalcField>[
    CalcField('flow', 'Required flow', 'التصرف المطلوب', qty: Q.fireFlow, def: 1893),
    CalcField('pressure', 'Required pressure at pump discharge', 'الضغط المطلوب عند طرد الطلمبة', qty: Q.barPsi, def: 7),
    CalcField('suction', 'Suction pressure (+ flooded / − lift)', 'ضغط السحب (+ سحب موجب / − رفع)', qty: Q.barPsi, def: 0),
    CalcField('eff', 'Pump efficiency', 'كفاءة الطلمبة', unit: '%', def: 65),
  ],
  results: <CalcResult>[
    CalcResult('rated', 'Standard rated capacity', 'السعة القياسية للطلمبة', text: _ratingText, primary: true),
    CalcResult('net', 'Rated (net) pressure', 'الضغط المقنن (الصافي)', qty: Q.barPsi, primary: true),
    CalcResult('head', 'Rated head', 'الرفع المقنن', qty: Q.head),
    CalcResult('p150', 'Minimum pressure at 150% flow (65%)', 'أقل ضغط عند 150% من التصرف (65%)', qty: Q.barPsi),
    CalcResult('churn', 'Maximum churn pressure (140%)', 'أقصى ضغط عند الغلق (140%)', qty: Q.barPsi),
    CalcResult('power', 'Shaft power at rated point', 'قدرة العمود عند نقطة التشغيل', qty: Q.motor, primary: true),
    CalcResult('jockeyFlow', 'Jockey pump flow (≈ 1% of rated)', 'تصرف طلمبة الجوكي (≈ 1% من المقنن)', qty: Q.fireFlow),
    CalcResult('jockeyP', 'Jockey pump pressure (+10 psi)', 'ضغط طلمبة الجوكي (+10 psi)', qty: Q.barPsi),
  ],
  compute: _firePump,
  formula: 'P net = P discharge − P suction\n'
      'Rated capacity = next NFPA 20 size ≥ demand\n'
      'At 150% flow ≥ 65% of rated pressure;  churn ≤ 140%\n'
      'Power = Q·P ÷ η',
  noteEn: 'Size the driver for the whole pump curve, not only the rated point — take the '
      'final motor size from the pump manufacturer. Jockey pump values are common '
      'practice, not code minimums.',
  noteAr: 'اختر المحرك على أساس منحنى الطلمبة كله وليس نقطة التشغيل فقط — خذ مقاس '
      'المحرك النهائي من المصنع. قيم طلمبة الجوكي عرف شائع وليست حدًا أدنى في الكود.',
);

// ── 5. Pipe friction — Hazen–Williams ──────────────────────────────────────

const List<double> _hazenC = <double>[120, 100, 150, 150, 140];

Map<String, double> _pipeFriction(Map<String, double> v) {
  final double q = v['flow']!;
  final double d = v['diameter']!;
  final double c = _hazenC[v['material']!.round()];
  // SI Hazen–Williams: head loss (m per m) = 10.67·Q^1.852 ÷ (C^1.852·D^4.8704)
  final double hl = 10.67 * math.pow(q, 1.852) / (math.pow(c, 1.852) * math.pow(d, 4.8704));
  final double rate = hl * 1000 * K.g; // Pa/m
  return <String, double>{
    'velocity': q / (math.pi * d * d / 4),
    'frictionRate': rate,
    'loss': rate * v['length']! * (1 + v['fittings']! / 100),
  };
}

const EngCalc pipeFriction = EngCalc(
  id: 'pipeFriction',
  en: 'Pipe friction (Hazen–Williams)',
  ar: 'الفقد في المواسير (هازن–ويليامز)',
  fields: <CalcField>[
    CalcField.choice('material', 'Pipe', 'نوع الماسورة', <CalcChoice>[
      CalcChoice('Steel — wet sprinkler / water (C 120)', 'حديد — رشاشات رطبة / مياه (C 120)'),
      CalcChoice('Steel — dry sprinkler (C 100)', 'حديد — رشاشات جافة (C 100)'),
      CalcChoice('Copper / stainless (C 150)', 'نحاس / ستانلس (C 150)'),
      CalcChoice('CPVC / PVC / PPR (C 150)', 'CPVC / PVC / PPR (C 150)'),
      CalcChoice('Ductile iron, cement lined (C 140)', 'حديد دكتايل مبطن بالأسمنت (C 140)'),
    ]),
    CalcField('flow', 'Flow', 'التصرف', qty: Q.waterFlow, def: 5),
    CalcField('diameter', 'Pipe internal diameter', 'القطر الداخلي للماسورة', qty: Q.diameter, def: 80),
    CalcField('length', 'Pipe length', 'طول الماسورة', qty: Q.length, def: 100),
    CalcField('fittings', 'Fittings allowance (equivalent length)', 'نسبة القطع (طول مكافئ)', unit: '%', def: 30),
  ],
  results: <CalcResult>[
    CalcResult('velocity', 'Velocity', 'السرعة', qty: Q.waterSpeed),
    CalcResult('frictionRate', 'Friction loss per length', 'الفقد لكل وحدة طول', qty: Q.firePipeFriction),
    CalcResult('loss', 'Total friction loss', 'إجمالي فقد الاحتكاك', qty: Q.barPsi, primary: true),
  ],
  compute: _pipeFriction,
  formula: 'SI:  hf/L = 10.67·Q^1.852 ÷ (C^1.852·D^4.87)   (Q m³/s, D m)\n'
      'IP:  p = 4.52·Q^1.85 ÷ (C^1.85·d^4.87)   (psi/ft, gpm, in)',
  noteEn: 'Use the INTERNAL diameter of the pipe schedule you are using. Fire mains are '
      'usually kept under about 4.5 m/s (15 FPS); domestic water under 2–2.5 m/s.',
  noteAr: 'استخدم القطر الداخلي حسب سُمك الماسورة المستخدمة. خطوط الحريق غالبًا أقل من '
      '4.5 م/ث (15 قدم/ث)، والمياه المنزلية أقل من 2–2.5 م/ث.',
);

const List<EngCalc> fireCalcs = <EngCalc>[
  sprinklerHead,
  sprinklerDemand,
  standpipe,
  firePump,
  pipeFriction,
];
