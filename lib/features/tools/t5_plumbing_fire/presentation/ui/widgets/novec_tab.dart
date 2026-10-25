/// Module: tools / t5_plumbing_fire
///
///*************************** FILE INFO ****************************///
/// File Name: novec_tab.dart
/// Purpose: Novec (FK-5-1-12) tab — enclosure and design parameters in;
///          agent mass, cylinders, installed mass and the actual
///          concentration out. Formulas: domain/clean_agents.dart.
/// Author: ASEC team
/// Created: 25/10/2026
library;

import 'package:flutter/material.dart';

import 'package:asec/features/tools/t3_duct_calc/presentation/ui/widgets/duct_fields.dart';
import 'package:asec/features/tools/t5_plumbing_fire/domain/clean_agents.dart';
import 'package:asec/features/tools/t5_plumbing_fire/presentation/ui/widgets/agent_fields.dart';

class NovecTab extends StatefulWidget {
  const NovecTab({super.key});

  @override
  State<NovecTab> createState() => _NovecTabState();
}

class _NovecTabState extends AgentTabState<NovecTab> {
  @override
  Widget build(BuildContext context) {
    final double? v = netVolumeFromFields();
    final double? c = value('c');
    final double? t = value('t');
    final NovecResult? r = (v == null || c == null || t == null)
        ? null
        : Novec.calculate(
            volume: v,
            concentration: c,
            minTempC: t,
            atmFactor: value('atm') ?? Novec.atmFactor,
            allowancePct: value('allow') ?? 0,
            cylinderFillKg: value('fill') ?? 0,
            k1: value('k1') ?? Novec.k1,
            k2: value('k2') ?? Novec.k2,
          );

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 16),
      children: <Widget>[
        const AgentHeading('Enclosure'),
        ResponsiveFields(children: enclosureFields()),
        const SizedBox(height: 8),
        const AgentHeading('Design parameters — verify the selected system listing'),
        ResponsiveFields(
          children: <Widget>[
            number('c', Novec.concentration, 'Design concentration', '%'),
            number('t', Novec.minTempC, 'Min. design temperature', '°C'),
            number('atm', Novec.atmFactor, 'Atmospheric factor', '×'),
            number('allow', Novec.allowancePct, 'Design allowance', '%'),
            number('fill', Novec.cylinderFillKg, 'Cylinder fill', 'kg'),
            number('k1', Novec.k1, 'Vapour volume k₁', 'm³/kg'),
            number('k2', Novec.k2, 'Vapour coefficient k₂', 'm³/kg·°C'),
          ],
        ),
        const SizedBox(height: 16),
        if (r == null)
          const Text('Enter the room size, a concentration between 0 and 100 % and the temperature.')
        else
          ResultTable(
            items: <ResultItem>[
              ResultItem('Net protected volume', fmt(r.volume, 2), 'm³'),
              ResultItem('Specific vapour volume S', fmt(r.specificVolume, 4), 'm³/kg'),
              ResultItem('Agent mass at design conditions', fmt(r.agentMass, 2), 'kg'),
              ResultItem('Adjusted agent requirement', fmt(r.adjustedMass, 2), 'kg'),
              ResultItem('Indicative cylinder count', '${r.cylinders}'),
              ResultItem('Installed agent mass', fmt(r.installedMass, 0), 'kg'),
              ResultItem('Actual concentration', fmt(r.actualConcentration, 2), '%'),
            ],
          ),
        const PreliminaryNote(
          'Check material compatibility, occupancy limits, nozzle and piping hydraulics, '
          'discharge and hold time, enclosure integrity and relief venting. '
          "Manufacturer's vapour data supersede the defaults.",
        ),
      ],
    );
  }
}
