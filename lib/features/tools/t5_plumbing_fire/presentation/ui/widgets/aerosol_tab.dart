/// Module: tools / t5_plumbing_fire
///
///*************************** FILE INFO ****************************///
/// File Name: aerosol_tab.dart
/// Purpose: Condensed aerosol tab (NFPA 2010) — enclosure, listed design
///          density and generator mass in; aerosol mass and generator
///          quantity out. Formulas: domain/clean_agents.dart.
/// Author: ASEC team
/// Created: 25/10/2026
library;

import 'package:flutter/material.dart';

import 'package:asec/features/tools/t3_duct_calc/presentation/ui/widgets/duct_fields.dart';
import 'package:asec/features/tools/t5_plumbing_fire/domain/clean_agents.dart';
import 'package:asec/features/tools/t5_plumbing_fire/presentation/ui/widgets/agent_fields.dart';

class AerosolTab extends StatefulWidget {
  const AerosolTab({super.key});

  @override
  State<AerosolTab> createState() => _AerosolTabState();
}

class _AerosolTabState extends AgentTabState<AerosolTab> {
  @override
  Widget build(BuildContext context) {
    final double? v = netVolumeFromFields();
    final double? d = value('density');
    final AerosolResult? r = (v == null || d == null)
        ? null
        : Aerosol.calculate(
            volume: v,
            densityGm3: d,
            allowancePct: value('allow') ?? 0,
            generatorGrams: value('gen') ?? 0,
          );

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 16),
      children: <Widget>[
        const AgentHeading('Hazard volume'),
        ResponsiveFields(children: enclosureFields()),
        const SizedBox(height: 8),
        const AgentHeading('Listed aerosol generator inputs'),
        ResponsiveFields(
          children: <Widget>[
            number('density', Aerosol.densityGm3, 'Design density', 'g/m³'),
            number('allow', Aerosol.allowancePct, 'Design allowance', '%'),
            number('gen', Aerosol.generatorGrams, 'Generator aerosol mass', 'g/unit'),
          ],
        ),
        const SizedBox(height: 16),
        if (r == null)
          const Text('Enter the room size and the listed design density.')
        else
          ResultTable(
            items: <ResultItem>[
              ResultItem('Net protected volume', fmt(r.volume, 2), 'm³'),
              ResultItem('Base aerosol requirement', fmt(r.baseMass, 0), 'g'),
              ResultItem('Adjusted aerosol mass', fmt(r.adjustedMass, 0), 'g'),
              ResultItem('Indicative generator quantity', '${r.generators}'),
              ResultItem('Nominal total aerosol mass', fmt(r.totalMass, 0), 'g'),
            ],
          ),
        const PreliminaryNote(
          "109.2 g/m³ is a sample value for comparison only — use the approved manufacturer's "
          'listed design density. Generator placement, ceiling height, obstructions and occupied-space '
          'limits need product-specific checks.',
        ),
      ],
    );
  }
}
