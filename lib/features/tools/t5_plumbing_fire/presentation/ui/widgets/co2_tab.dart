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
///          the rest at 1.33 kg/m³, every value editable.
library;

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
    final Co2BandResult? r = v == null
        ? null
        : Co2Band.calculate(
            volume: v,
            firstBandM3: value('band') ?? Co2Band.firstBandM3,
            firstCoefficient: value('c1') ?? Co2Band.firstCoefficient,
            excessCoefficient: value('c2') ?? Co2Band.excessCoefficient,
            allowancePct: value('allow') ?? 0,
            cylinderKg: value('fill') ?? 0,
          );

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 16),
      children: <Widget>[
        const AgentHeading('Enclosure'),
        ResponsiveFields(children: enclosureFields()),
        const SizedBox(height: 8),
        const AgentHeading('Preliminary inputs'),
        ResponsiveFields(
          children: <Widget>[
            number('band', Co2Band.firstBandM3, 'First volume band', 'm³'),
            number('c1', Co2Band.firstCoefficient, 'First band coefficient', 'kg/m³'),
            number('c2', Co2Band.excessCoefficient, 'Excess band coefficient', 'kg/m³'),
            number('allow', Co2Band.allowancePct, 'Allowance', '%'),
            number('fill', Co2Band.cylinderKg, 'Cylinder fill', 'kg'),
          ],
        ),
        const SizedBox(height: 16),
        if (r == null)
          const Text('Enter the room length, width and height.')
        else
          ResultTable(
            items: <ResultItem>[
              ResultItem('Net protected volume', fmt(r.volume, 2), 'm³'),
              ResultItem('First-band volume', fmt(r.firstBandVolume, 2), 'm³'),
              ResultItem('Excess volume', fmt(r.excessVolume, 2), 'm³'),
              ResultItem('Total weight of CO₂', fmt(r.weight, 1), 'kg'),
              ResultItem('Indicative cylinder count', '${r.cylinders}'),
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
