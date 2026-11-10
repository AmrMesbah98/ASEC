/// Module: tools / t2_engineering_calc
///
///*************************** FILE INFO ****************************///
/// File Name: calc_catalog.dart
/// Purpose: Declares `CalcCatalog` — the four tabs of the engineering
///          calculators page and the calculators in each — plus the two
///          medical-gas calculators.
/// Author: ASEC team
/// Created: 4/10/2026
///
/// To add a calculator: write it next to its siblings (calcs_hvac.dart,
/// calcs_fire.dart, calcs_plumbing.dart or below) and add it to its tab's
/// list. The page needs no change.

import 'package:flutter/material.dart';

import 'package:asec/features/tools/t2_engineering_calc/domain/calc_load_estimation.dart';
import 'package:asec/features/tools/t2_engineering_calc/domain/calc_model.dart';
import 'package:asec/features/tools/t2_engineering_calc/domain/calc_units.dart';
import 'package:asec/features/tools/t2_engineering_calc/domain/calcs_fire.dart';
import 'package:asec/features/tools/t2_engineering_calc/domain/calcs_hvac.dart';
import 'package:asec/features/tools/t2_engineering_calc/domain/calcs_plumbing.dart';

// ── Medical gas ────────────────────────────────────────────────────────────

Map<String, double> _gasDemand(Map<String, double> v) {
  final double all = v['outlets']! * v['perOutlet']!;
  return <String, double>{'all': all, 'design': all * v['diversity']! / 100};
}

const EngCalc gasDemand = EngCalc(
  id: 'gasDemand',
  en: 'Gas demand (outlets)',
  ar: 'احتياج الغاز (المخارج)',
  fields: <CalcField>[
    CalcField('outlets', 'Number of outlets', 'عدد المخارج', def: 20),
    CalcField('perOutlet', 'Design flow per outlet', 'التصرف التصميمي لكل مخرج', qty: Q.gasFlow, def: 10),
    CalcField('diversity', 'Diversity (outlets in use at once)', 'معامل التباين (المخارج العاملة معًا)', unit: '%', def: 50),
  ],
  results: <CalcResult>[
    CalcResult('all', 'Flow if every outlet runs', 'التصرف لو كل المخارج تعمل', qty: Q.gasFlow),
    CalcResult('design', 'Design flow', 'التصرف التصميمي', qty: Q.gasFlow, primary: true),
  ],
  compute: _gasDemand,
  formula: 'Q = outlets × flow per outlet × diversity',
  noteEn: 'Flow per outlet and diversity depend on the gas and the department (ward, ICU, '
      'theatre). Take them from NFPA 99 / HTM 02-01 or the hospital brief.',
  noteAr: 'التصرف لكل مخرج ومعامل التباين يختلفان حسب نوع الغاز والقسم (عنابر، رعاية '
      'مركزة، عمليات). خذهم من NFPA 99 / HTM 02-01 أو متطلبات المستشفى.',
);

Map<String, double> _cylinderBank(Map<String, double> v) {
  final double gas = v['cylinders']! * v['content']!; // m³ free gas
  return <String, double>{'bank': gas, 'duration': gas / v['demand']!};
}

const EngCalc cylinderBank = EngCalc(
  id: 'cylinderBank',
  en: 'Cylinder manifold duration',
  ar: 'مدة تشغيل مجموعة الأسطوانات',
  fields: <CalcField>[
    CalcField('cylinders', 'Cylinders per bank', 'عدد الأسطوانات في المجموعة', def: 10),
    CalcField('content', 'Gas content per cylinder (free gas)', 'محتوى الأسطوانة من الغاز (حر)', qty: Q.gasContent, def: 6800),
    CalcField('demand', 'Design flow', 'التصرف التصميمي', qty: Q.gasFlow, def: 100),
  ],
  results: <CalcResult>[
    CalcResult('bank', 'Gas in one bank', 'كمية الغاز في المجموعة', qty: Q.roomVolume),
    CalcResult('duration', 'Duration of one bank', 'مدة تشغيل المجموعة', qty: Q.hours, primary: true),
  ],
  compute: _cylinderBank,
  formula: 'Duration = cylinders × content ÷ flow',
  noteEn: 'A large oxygen cylinder (J size) holds about 6 800 L of free gas — check the '
      'supplier\'s figure.',
  noteAr: 'أسطوانة الأكسجين الكبيرة (مقاس J) تحتوي حوالي 6800 لتر غاز حر — راجع رقم '
      'المورد.',
);

const List<EngCalc> medicalGasCalcs = <EngCalc>[gasDemand, cylinderBank];

abstract final class CalcCatalog {
  /// 09/11/2026: what the HVAC menu item shows — the load estimation only.
  static const List<CalcDiscipline> hvacOnly = <CalcDiscipline>[
    CalcDiscipline(
      id: 'hvac',
      en: 'HVAC',
      ar: 'التكييف والتهوية',
      icon: Icons.ac_unit_rounded,
      calcs: <EngCalc>[loadEstimation],
    ),
  ];

  static const List<CalcDiscipline> all = <CalcDiscipline>[
    CalcDiscipline(
      id: 'hvac',
      en: 'HVAC',
      ar: 'التكييف والتهوية',
      icon: Icons.ac_unit_rounded,
      calcs: hvacCalcs,
    ),
    CalcDiscipline(
      id: 'fire',
      en: 'Fire fighting',
      ar: 'مكافحة الحريق',
      icon: Icons.local_fire_department_rounded,
      calcs: fireCalcs,
    ),
    CalcDiscipline(
      id: 'plumbing',
      en: 'Plumbing',
      ar: 'الأعمال الصحية',
      icon: Icons.plumbing_rounded,
      calcs: plumbingCalcs,
    ),
    CalcDiscipline(
      id: 'medicalGas',
      en: 'Medical gas',
      ar: 'الغازات الطبية',
      icon: Icons.medical_services_rounded,
      calcs: medicalGasCalcs,
    ),
  ];
}
