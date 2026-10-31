/// Module: tools / t5_plumbing_fire
///
///*************************** FILE INFO ****************************///
/// File Name: co2_tab.dart
/// Purpose: CO₂ tab — enclosure and the band coefficients in; CO₂ weight
///          and number of cylinders out. Concept estimate only.
/// Author: ASEC team
/// Created: 22/10/2026
/// Updated: 25/10/2026 - Back in the Fire fighting calculator. Uses the
///          ASEC gas calculator workbook: the first 56.5 m³ at 1.6 kg/m³,
///          the rest at 1.33 kg/m³, in 45 kg cylinders (rounded up).
/// Updated: 26/10/2026 - Only L, W, H are entered; bands, coefficients
///          and cylinder size are fixed (Eng. Ahmed Shuhayb).
library;

import 'package:asec/core/helper/main_helper/format_helper.dart';
import 'package:flutter/material.dart';

import 'package:asec/features/tools/t3_duct_calc/presentation/ui/widgets/duct_fields.dart';
import 'package:asec/features/tools/t5_plumbing_fire/domain/clean_agents.dart';
import 'package:asec/features/tools/t5_plumbing_fire/presentation/ui/widgets/agent_fields.dart';

class Co2Tab extends StatefulWidget {
  const Co2Tab({super.key});

  @override
  State<Co2Tab> createState() => _Co2TabState();
}

class _Co2TabState extends AgentTabState<Co2Tab> {
  @override
  Widget build(BuildContext context) {
    final double? v = netVolumeFromFields();
    // 26/10/2026: the bands, coefficients and the 45 kg cylinder are fixed
    // (Co2Band defaults) and no longer shown — like the FM-200 tab.
    final Co2BandResult? r = v == null ? null : Co2Band.calculate(volume: v);

    return ListView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.symmetric(vertical: 16),
      children: <Widget>[
        const AgentHeading('Enclosure'),
        ResponsiveFields(children: enclosureFields()),
        const SizedBox(height: 16),
        if (r == null)
          Text(FormatHelper.capitalize('Enter the room length, width and height.'))
        else
          ResultTable(
            items: <ResultItem>[
              ResultItem('Net Protected Volume', fmt(r.volume, 2), 'm³'),
              ResultItem('First-Band Volume (× ${fmt(Co2Band.firstCoefficient, 1)} kg/m³)', fmt(r.firstBandVolume, 2), 'm³'),
              ResultItem('Excess Volume (× ${fmt(Co2Band.excessCoefficient, 2)} kg/m³)', fmt(r.excessVolume, 2), 'm³'),
              ResultItem('Total Weight Of CO₂', fmt(r.weight, 1), 'kg'),
              ResultItem('Number Of Cylinders', '${r.cylinders} × ${fmt(Co2Band.cylinderKg, 0)} kg'),
            ],
          ),
        const PreliminaryNote(
          'Concept estimate only, NOT an NFPA 12 design. CO₂ total flooding must be engineered for the '
          'hazard type, openings, temperature, retention, exposure and life safety.',
        ),
      ],
    );
  }
}
