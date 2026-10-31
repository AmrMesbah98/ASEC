/// Module: tools / t3_duct_calc
///
///*************************** FILE INFO ****************************///
/// File Name: flow_conversion_tab.dart
/// Purpose: Conversions tab — a volume flow in one unit shown in l/s,
///          m³/s, m³/min and m³/hr.
/// Author: ASEC team
/// Created: 21/10/2026
library;

import 'package:asec/core/helper/main_helper/format_helper.dart';
import 'package:flutter/material.dart';

import 'package:asec/core/custom/1-custom_dropdown.dart';
import 'package:asec/core/theme/app_colors.dart';
import 'package:asec/features/tools/t3_duct_calc/domain/duct_calculator.dart';
import 'package:asec/features/tools/t3_duct_calc/domain/duct_data.dart';
import 'package:asec/features/tools/t3_duct_calc/presentation/ui/widgets/duct_fields.dart';

class FlowConversionTab extends StatefulWidget {
  const FlowConversionTab({super.key});

  @override
  State<FlowConversionTab> createState() => _FlowConversionTabState();
}

class _FlowConversionTabState extends State<FlowConversionTab> {
  final TextEditingController _value = TextEditingController(text: '183.7');
  FlowUnit _from = FlowUnit.litresPerSecond;

  @override
  void dispose() {
    _value.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double? v = parseNumber(_value.text);
    final Map<FlowUnit, double>? out =
        v == null ? null : DuctCalculator.convertFlow(v, _from);

    return ListView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.symmetric(vertical: 16),
      children: <Widget>[
        ResponsiveFields(
          children: <Widget>[
            NumberField(
              controller: _value,
              label: 'Volume flow',
              onChanged: (_) => setState(() {}),
            ),
            SizedBox(
              width: 200,
              child: CustomDropdown<FlowUnit>(
                fillColor: AppColors.card,
                label: 'Original units',
                value: _from,
                items: <DropdownItem<FlowUnit>>[
                  for (final FlowUnit u in FlowUnit.values)
                    DropdownItem<FlowUnit>(value: u, label: u.label),
                ],
                onChanged: (FlowUnit? u) {
                  if (u != null) setState(() => _from = u);
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (out == null)
          Text(FormatHelper.capitalize('Enter a volume flow.'))
        else
          ResultTable(
            items: <ResultItem>[
              for (final FlowUnit u in FlowUnit.values)
                ResultItem(u.label, fmt(out[u], 2)),
            ],
          ),
      ],
    );
  }
}
