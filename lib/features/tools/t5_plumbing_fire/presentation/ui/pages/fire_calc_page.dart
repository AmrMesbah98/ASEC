/// Module: tools / t5_plumbing_fire
///
///*************************** FILE INFO ****************************///
/// File Name: fire_calc_page.dart
/// Purpose: Declares `FireCalcPage` — the Fire fighting calculator, its own
///          entry in the calculators list.
/// Author: ASEC team
/// Created: 23/10/2026
/// Updated: 25/10/2026 - Tabs: FM-200, CO₂, Novec (FK-5-1-12) and
///          Condensed aerosol, switched with the app's CustomTabs.
///
/// WORKS OFFLINE — computed on the device. Titled with the ConsolePage
/// header like the other calculators.
library;

import 'package:flutter/material.dart';

import 'package:asec/core/custom/10-custom_tabs.dart';
import 'package:asec/features/admin/a1_shell/presentation/ui/widgets/console_page.dart';
import 'package:asec/generated/l10n.dart';
import 'package:asec/features/tools/t5_plumbing_fire/presentation/ui/widgets/aerosol_tab.dart';
import 'package:asec/features/tools/t5_plumbing_fire/presentation/ui/widgets/co2_tab.dart';
import 'package:asec/features/tools/t5_plumbing_fire/presentation/ui/widgets/fm200_tab.dart';
import 'package:asec/features/tools/t5_plumbing_fire/presentation/ui/widgets/novec_tab.dart';

class FireCalcPage extends StatefulWidget {
  const FireCalcPage({super.key});

  @override
  State<FireCalcPage> createState() => _FireCalcPageState();
}

class _FireCalcPageState extends State<FireCalcPage> {
  int _tab = 0;

  static const List<String> _titles = <String>[
    'FM-200',
    'CO₂',
    'Novec',
    'Aerosol',
  ];

  @override
  Widget build(BuildContext context) {
    return ConsolePage(
      title: S.of(context).fireCalc,
      child: Material(
        type: MaterialType.transparency,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            CustomTabs(
              tabs: _titles,
              selectedValue: _tab,
              onChanged: (int i) => setState(() => _tab = i),
            ),
            // IndexedStack keeps every tab's inputs while switching.
            Expanded(
              child: IndexedStack(
                index: _tab,
                children: const <Widget>[
                  Fm200Tab(),
                  Co2Tab(),
                  NovecTab(),
                  AerosolTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
