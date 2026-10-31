/// Module: tools / t5_plumbing_fire
///
///*************************** FILE INFO ****************************///
/// File Name: aerosol_tab.dart
/// Purpose: Condensed aerosol tab (NFPA 2010) — enclosure, listed design
///          density and generator mass in; aerosol mass and generator
///          quantity out. Formulas: domain/clean_agents.dart.
/// Author: ASEC team
/// Created: 25/10/2026
/// Updated: 26/10/2026 - Eng. Ahmed Shuhayb: only L, W, H and the fire
///          class (design density A 49.32, B 72.02, C 81.79 g/m³) are
///          entered; the result is the volume and the aerosol mass.
library;

import 'package:asec/core/helper/main_helper/format_helper.dart';
import 'package:flutter/material.dart';

import 'package:asec/core/custom/1-custom_dropdown.dart';
import 'package:asec/core/theme/app_colors.dart';
import 'package:asec/features/tools/t3_duct_calc/presentation/ui/widgets/duct_fields.dart';
import 'package:asec/features/tools/t5_plumbing_fire/domain/clean_agents.dart';
import 'package:asec/features/tools/t5_plumbing_fire/presentation/ui/widgets/agent_fields.dart';

class AerosolTab extends StatefulWidget {
  const AerosolTab({super.key});

  @override
  State<AerosolTab> createState() => _AerosolTabState();
}

/// Listed design density by fire class (g/m³).
enum AerosolClass {
  a('Class A', 49.32),
  b('Class B', 72.02),
  c('Class C', 81.79);

  const AerosolClass(this.label, this.density);
  final String label;
  final double density;
}

class _AerosolTabState extends AgentTabState<AerosolTab> {
  AerosolClass _class = AerosolClass.a;

  @override
  Widget build(BuildContext context) {
    final double? v = netVolumeFromFields();
    final AerosolResult? r =
        v == null ? null : Aerosol.calculate(volume: v, densityGm3: _class.density);

    return ListView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.symmetric(vertical: 16),
      children: <Widget>[
        const AgentHeading('Hazard Volume'),
        ResponsiveFields(children: enclosureFields()),
        const SizedBox(height: 8),
        const AgentHeading('Design Density'),
        ResponsiveFields(
          children: <Widget>[
            SizedBox(
              width: 220,
              child: CustomDropdown<AerosolClass>(
                fillColor: AppColors.card,
                label: 'Fire Class',
                value: _class,
                items: <DropdownItem<AerosolClass>>[
                  for (final AerosolClass c in AerosolClass.values)
                    DropdownItem<AerosolClass>(value: c, label: '${c.label} — ${fmt(c.density, 2)} g/m³'),
                ],
                onChanged: (AerosolClass? c) {
                  if (c != null) setState(() => _class = c);
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (r == null)
          Text(FormatHelper.capitalize('Enter the room length, width and height.'))
        else
          ResultTable(
            items: <ResultItem>[
              ResultItem('Net Protected Volume', fmt(r.volume, 2), 'm³'),
              ResultItem('Aerosol Mass Required', fmt(r.baseMass, 0), 'g'),
            ],
          ),
        const PreliminaryNote(
          'M = V × design density. Generator placement, ceiling height, obstructions and occupied-space '
          'limits need product-specific checks.',
        ),
      ],
    );
  }
}
