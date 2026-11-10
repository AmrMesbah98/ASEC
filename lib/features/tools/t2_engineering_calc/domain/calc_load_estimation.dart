/// Module: tools / t2_engineering_calc
///
///*************************** FILE INFO ****************************///
/// File Name: calc_load_estimation.dart
/// Purpose: Declares `loadEstimation` — the quick cooling-load estimate by
///          the RULE OF THUMB (m² per TR), from Eng. Ahmed Shuhayb's sheet
///          (review of 9 Nov 2026).
/// Author: ASEC team
/// Created: 9/11/2026
///
/// HOW IT WORKS
/// ------------
/// 1. Application: each one has a range of m²/TR. THE RANGE IS HIDDEN — the
///    user only picks the application.
/// 2. Level: High load uses the SMALL end of the range (fewer m² per ton =
///    more tons), Low uses the BIG end, Medium the middle:
///    offices perimeter 22.5–27.5 → high 22.5, medium 25, low 27.5.
/// 3. Room dimensions: length × width = area. The area is HIDDEN too.
/// 4. Estimated load: TR = area ÷ (m²/TR); kW = TR × 3.517.
/// 5. Summary: the unit type picked, the total load in TR and the air flow
///    as a RANGE, TR × 300 to TR × 400 CFM.

import 'package:asec/features/tools/t2_engineering_calc/domain/calc_model.dart';
import 'package:asec/features/tools/t2_engineering_calc/domain/calc_units.dart';

/// One application and its m²/TR range: (English, Arabic, low end, high end).
const List<(String, String, double, double)> _applications =
    <(String, String, double, double)>[
  ('Offices (perimeter)', 'مكاتب (محيطية)', 22.5, 27.5),
  ('Offices (interior)', 'مكاتب (داخلية)', 30, 35),
  ('Mall (public area)', 'مول (منطقة عامة)', 15, 35),
  ('Patient room', 'غرفة مريض', 25, 30),
  ('Hotel (public area)', 'فندق (منطقة عامة)', 25, 30),
  ('Supermarket', 'سوبر ماركت', 25, 35),
  ('Retail', 'محلات تجارية', 20, 30),
  ('Restaurants / cafeterias', 'مطاعم / كافيتريات', 10, 25),
  ('Apartments', 'شقق سكنية', 35, 45),
  ('Kitchens', 'مطابخ', 15, 25),
  ('IT rooms', 'غرف IT', 5, 15),
];

/// The unit types offered in the summary, in the sheet's order.
const List<(String, String)> _unitTypes = <(String, String)>[
  ('AHU', 'وحدة مناولة هواء (AHU)'),
  ('Hi-wall split', 'سبليت حائطي (Hi-Wall)'),
  ('Cassette', 'كاسيت'),
  ('Floor standing', 'دولابي (Floor Standing)'),
  ('FCU', 'وحدة ملف ومروحة (FCU)'),
  ('Package unit', 'وحدة باكدج'),
];

/// The air flow per TR the range is built from (CFM).
const double _cfmPerTrLow = 300;
const double _cfmPerTrHigh = 400;

/// m²/TR for the picked application and level (0 high, 1 medium, 2 low).
double _m2PerTr(int application, int level) {
  final (String, String, double, double) a = _applications[application];
  switch (level) {
    case 0:
      return a.$3; // high load → the small value
    case 2:
      return a.$4; // low load → the big value
    default:
      return (a.$3 + a.$4) / 2; // medium → the middle
  }
}

Map<String, double> _loadEstimation(Map<String, double> v) {
  final double area = v['length']! * v['width']!; // m² (hidden)
  final double tr = area / _m2PerTr(v['application']!.round(), v['level']!.round());
  return <String, double>{
    'load': tr * K.ton, // W
    'kw': tr * K.ton, // W
    'unitType': v['unitType']!,
    'airFlow': tr,
  };
}

String _unitTypeText(double i) {
  final int index = i.round();
  if (index < 0 || index >= _unitTypes.length) return '—';
  return _unitTypes[index].$1;
}

/// "1 500 – 2 000 CFM" from the load in TR.
String _airFlowText(double tr) =>
    '${formatCalc(tr * _cfmPerTrLow)} – ${formatCalc(tr * _cfmPerTrHigh)} CFM';

const Qty _kw = Qty('power', 'kW', 'kW');

const EngCalc loadEstimation = EngCalc(
  id: 'loadEstimation',
  en: 'Load estimation',
  ar: 'تقدير الحمل',
  subtitleEn: 'Using rule of thumb method',
  subtitleAr: 'باستخدام الطريقة التقريبية (Rule of Thumb)',
  fields: <CalcField>[
    CalcField.choice('application', 'Application', 'نوع الاستخدام', <CalcChoice>[
      // Same order as [_applications].
      CalcChoice('Offices (perimeter)', 'مكاتب (محيطية)'),
      CalcChoice('Offices (interior)', 'مكاتب (داخلية)'),
      CalcChoice('Mall (public area)', 'مول (منطقة عامة)'),
      CalcChoice('Patient room', 'غرفة مريض'),
      CalcChoice('Hotel (public area)', 'فندق (منطقة عامة)'),
      CalcChoice('Supermarket', 'سوبر ماركت'),
      CalcChoice('Retail', 'محلات تجارية'),
      CalcChoice('Restaurants / cafeterias', 'مطاعم / كافيتريات'),
      CalcChoice('Apartments', 'شقق سكنية'),
      CalcChoice('Kitchens', 'مطابخ'),
      CalcChoice('IT rooms', 'غرف IT'),
    ]),
    CalcField.choice('level', 'Level', 'مستوى الحمل', <CalcChoice>[
      CalcChoice('High', 'عالي'),
      CalcChoice('Medium', 'متوسط'),
      CalcChoice('Low', 'منخفض'),
    ], defOption: 1),
    CalcField('length', 'Room length', 'طول الغرفة', qty: Q.length, def: 5),
    CalcField('width', 'Room width', 'عرض الغرفة', qty: Q.length, def: 4),
    CalcField.choice('unitType', 'Unit selection', 'نوع الوحدة', <CalcChoice>[
      // Same order as [_unitTypes].
      CalcChoice('AHU', 'وحدة مناولة هواء (AHU)'),
      CalcChoice('Hi-wall split', 'سبليت حائطي (Hi-Wall)'),
      CalcChoice('Cassette', 'كاسيت'),
      CalcChoice('Floor standing', 'دولابي (Floor Standing)'),
      CalcChoice('FCU', 'وحدة ملف ومروحة (FCU)'),
      CalcChoice('Package unit', 'وحدة باكدج'),
    ]),
  ],
  results: <CalcResult>[
    CalcResult('load', 'Total load', 'الحمل الكلي', qty: Q.tons, primary: true),
    CalcResult('kw', 'Total load (kW)', 'الحمل الكلي (كيلووات)', qty: _kw),
    CalcResult('unitType', 'Unit selection', 'نوع الوحدة', text: _unitTypeText),
    CalcResult('airFlow', 'Air flow', 'كمية الهواء', text: _airFlowText, primary: true),
  ],
  compute: _loadEstimation,
  formula: 'TR = area ÷ (m²/TR)   kW = TR × 3.517   Air flow = TR × 300 to 400 CFM',
  noteEn: 'A quick estimate for early sizing only. High load uses the smaller m²/TR '
      'of the application, low load the larger and medium the middle. Use a '
      'full cooling-load calculation for the design.',
  noteAr: 'تقدير سريع للمرحلة المبدئية فقط. الحمل العالي يأخذ القيمة الأصغر من '
      'م²/طن للاستخدام، والمنخفض القيمة الأكبر، والمتوسط القيمة الوسطى. استخدم '
      'حساب الأحمال الكامل في التصميم.',
);
