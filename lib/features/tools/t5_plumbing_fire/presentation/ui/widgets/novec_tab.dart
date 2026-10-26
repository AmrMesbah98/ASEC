/// Module: tools / t5_plumbing_fire
///
///*************************** FILE INFO ****************************///
/// File Name: novec_tab.dart
/// Purpose: Novec (FK-5-1-12) tab — enclosure and design parameters in;
///          agent mass, cylinders, installed mass and the actual
///          concentration out. Formulas: domain/clean_agents.dart.
/// Author: ASEC team
/// Created: 25/10/2026
/// Updated: 26/10/2026 - Works like the FM-200 tab (Eng. Ahmed Shuhayb):
///          L, W, H, the fire class (4.5 % for Class A / C, 5.85 % for
///          Class B) and the minimum temperature in; S = k₁ + k₂ × T is
///          internal; only the volume, S and the agent mass are shown.
library;

import 'package:flutter/material.dart';

import 'package:asec/core/custom/1-custom_dropdown.dart';
import 'package:asec/core/theme/app_colors.dart';
import 'package:asec/features/tools/t3_duct_calc/presentation/ui/widgets/duct_fields.dart';
import 'package:asec/features/tools/t5_plumbing_fire/domain/clean_agents.dart';
import 'package:asec/features/tools/t5_plumbing_fire/presentation/ui/widgets/agent_fields.dart';

class NovecTab extends StatefulWidget {
  const NovecTab({super.key});

  @override
  State<NovecTab> createState() => _NovecTabState();
}

/// Design concentration by fire class.
enum NovecClass {
  ac('Class A / C', 4.5),
  b('Class B', 5.85);

  const NovecClass(this.label, this.concentration);
  final String label;

  /// % vol.
  final double concentration;
}

class _NovecTabState extends AgentTabState<NovecTab> {
  NovecClass _class = NovecClass.ac;

  @override
  Widget build(BuildContext context) {
    final double? v = netVolumeFromFields();
    final double? t = value('t');
    // Atmospheric factor 1, no allowance; k₁ / k₂ fixed (Novec defaults).
    final NovecResult? r = (v == null || t == null)
        ? null
        : Novec.calculate(volume: v, concentration: _class.concentration, minTempC: t);

    return ListView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.symmetric(vertical: 16),
      children: <Widget>[
        const AgentHeading('Enclosure'),
        ResponsiveFields(children: enclosureFields()),
        const SizedBox(height: 8),
        const AgentHeading('Design Parameters'),
        ResponsiveFields(
          children: <Widget>[
            SizedBox(
              width: 220,
              child: CustomDropdown<NovecClass>(
                fillColor: AppColors.card,
                label: 'Design Concentration',
                value: _class,
                items: <DropdownItem<NovecClass>>[
                  for (final NovecClass c in NovecClass.values)
                    DropdownItem<NovecClass>(value: c, label: '${fmt(c.concentration, c == NovecClass.b ? 2 : 1)} % — ${c.label}'),
                ],
                onChanged: (NovecClass? c) {
                  if (c != null) setState(() => _class = c);
                },
              ),
            ),
            number('t', Novec.minTempC, 'Min. Design Temperature', '°C'),
          ],
        ),
        const SizedBox(height: 16),
        if (r == null)
          const Text('Enter the room length, width, height and the temperature.')
        else
          ResultTable(
            items: <ResultItem>[
              ResultItem('Net Protected Volume', fmt(r.volume, 2), 'm³'),
              ResultItem('Specific Vapour Volume S', fmt(r.specificVolume, 4), 'm³/kg'),
              ResultItem('Agent Mass (Novec)', fmt(r.agentMass, 2), 'kg'),
            ],
          ),
        PreliminaryNote(
          'W = V / S × C / (100 − C),  S = ${Novec.k1} + ${Novec.k2} × T. '
          "Manufacturer's vapour data supersede the defaults.",
        ),
      ],
    );
  }
}
