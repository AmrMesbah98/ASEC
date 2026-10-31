/// Module: tools / t3_duct_calc
///
///*************************** FILE INFO ****************************///
/// File Name: velocities_tab.dart
/// Purpose: Recommended Velocities tab — the recommended and maximum duct
///          velocities (m/s) by building type, as two AppDataTables.
/// Author: ASEC team
/// Created: 21/10/2026
library;

import 'package:asec/core/helper/main_helper/format_helper.dart';
import 'package:flutter/material.dart';

import 'package:asec/core/custom/100-custom_data_table.dart';
import 'package:asec/features/tools/t3_duct_calc/domain/duct_data.dart';
import 'package:asec/features/tools/t3_duct_calc/presentation/ui/widgets/duct_fields.dart';

class VelocitiesTab extends StatelessWidget {
  const VelocitiesTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.symmetric(vertical: 16),
      children: <Widget>[
        Text(FormatHelper.capitalize('Recommended Velocities (m/s)')),
        const SizedBox(height: 8),
        const _VelocityTable(rows: kRecommendedVelocities),
        const SizedBox(height: 24),
        Text(FormatHelper.capitalize('Maximum Velocities (m/s)')),
        const SizedBox(height: 8),
        const _VelocityTable(rows: kMaximumVelocities),
      ],
    );
  }
}

class _VelocityTable extends StatelessWidget {
  const _VelocityTable({required this.rows});

  final List<VelocityRow> rows;

  @override
  Widget build(BuildContext context) {
    final List<AppTableColumn<VelocityRow>> columns =
        <AppTableColumn<VelocityRow>>[
      AppTableColumn<VelocityRow>(
        label: 'Duct',
        flex: 2,
        cell: (BuildContext context, VelocityRow r) =>
            AppTableCellText('${r.ductClass} — ${r.shape}', emphasis: true),
      ),
      for (int i = 0; i < kVelocityColumns.length; i++)
        AppTableColumn<VelocityRow>(
          label: kVelocityColumns[i],
          cell: (BuildContext context, VelocityRow r) =>
              AppTableCellText(fmt(r.values[i], 1)),
        ),
    ];

    return AppDataTable<VelocityRow>(
      shrinkWrap: true,
      rows: rows,
      columns: columns,
      // Phone / tablet: one full-width card per duct type.
      cardBuilder: (BuildContext context, VelocityRow r) =>
          ductCard<VelocityRow>(context, r, columns),
    );
  }
}
