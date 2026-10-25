/// Module: tools / t5_plumbing_fire
///
///*************************** FILE INFO ****************************///
/// File Name: fm200_tab.dart
/// Purpose: FM-200 tab — room area, height and ambient temperature in;
///          room volume, agent weight, Kidde cylinder part number, nozzle
///          size and the pipe limits for 1, 2 or 4 nozzles out.
/// Author: ASEC team
/// Created: 22/10/2026
library;

import 'package:flutter/material.dart';

import 'package:asec/core/custom/10-custom_tabs.dart';
import 'package:asec/core/custom/100-custom_data_table.dart';
import 'package:asec/features/tools/t3_duct_calc/presentation/ui/widgets/duct_fields.dart';
import 'package:asec/features/tools/t5_plumbing_fire/domain/fire_gas.dart';

class Fm200Tab extends StatefulWidget {
  const Fm200Tab({super.key});

  @override
  State<Fm200Tab> createState() => _Fm200TabState();
}

class _Fm200TabState extends State<Fm200Tab> {
  final TextEditingController _area = TextEditingController(text: '50');
  final TextEditingController _height = TextEditingController(text: '3');
  final TextEditingController _ambient = TextEditingController(text: '21');
  Fm200Nozzles _nozzles = Fm200Nozzles.one;

  @override
  void dispose() {
    _area.dispose();
    _height.dispose();
    _ambient.dispose();
    super.dispose();
  }

  static String _in(double v) =>
      '${v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toString()}"';

  @override
  Widget build(BuildContext context) {
    final double? a = parseNumber(_area.text);
    final double? h = parseNumber(_height.text);
    final double? t = parseNumber(_ambient.text);
    final Fm200Result? r = (a == null || h == null || t == null || a <= 0 || h <= 0)
        ? null
        : Fm200.calculate(areaM2: a, heightM: h, ambientC: t);
    final Fm200Cylinder? cyl = r?.cylinder;
    final Fm200Layout? layout = cyl?.layout(_nozzles);
    void changed(String _) => setState(() {});

    final List<AppTableColumn<Fm200Section>> columns = <AppTableColumn<Fm200Section>>[
      AppTableColumn<Fm200Section>(
        label: 'Section',
        cell: (BuildContext c, Fm200Section s) => AppTableCellText('Section ${s.name}', emphasis: true),
      ),
      AppTableColumn<Fm200Section>(
        label: 'Pipe size',
        cell: (BuildContext c, Fm200Section s) => AppTableCellText(_in(s.pipeSize)),
      ),
      AppTableColumn<Fm200Section>(
        label: 'Max. length (ft)',
        cell: (BuildContext c, Fm200Section s) => AppTableCellText(fmt(s.maxLengthFt, 0)),
      ),
      AppTableColumn<Fm200Section>(
        label: 'Max. elbows',
        cell: (BuildContext c, Fm200Section s) => AppTableCellText('${s.maxElbows}'),
      ),
      AppTableColumn<Fm200Section>(
        label: 'Max. height (ft)',
        cell: (BuildContext c, Fm200Section s) => AppTableCellText(fmt(s.maxHeightFt, 0)),
      ),
    ];

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 16),
      children: <Widget>[
        ResponsiveFields(
          children: <Widget>[
            NumberField(controller: _area, label: 'Area', unit: 'm²', onChanged: changed),
            NumberField(controller: _height, label: 'Height', unit: 'm', onChanged: changed),
            NumberField(controller: _ambient, label: 'Ambient', unit: '°C', onChanged: changed),
          ],
        ),
        const SizedBox(height: 16),
        if (r == null)
          const Text('Enter the room area, height and ambient temperature.')
        else ...<Widget>[
          ResultTable(
            items: <ResultItem>[
              ResultItem('Room volume', fmt(r.volume, 2), 'm³'),
              ResultItem('Total weight of FM-200', fmt(r.agentWeight, 2), 'kg'),
              ResultItem('Take weight of FM-200 cylinder', fmt(r.takeWeight, 0), 'kg'),
            ],
          ),
          const SizedBox(height: 16),
          if (cyl == null)
            Text(
              'Weight of FM-200 = ${fmt(r.takeWeight, 0)} kg > 227 kg — '
              'too much for one cylinder. Please try another value.',
            )
          else ...<Widget>[
            const Text('As per KIDDE FM-200 catalogue'),
            const SizedBox(height: 8),
            CustomTabs(
              tabs: <String>[for (final Fm200Nozzles n in Fm200Nozzles.values) n.label],
              selectedValue: _nozzles.index,
              onChanged: (int i) => setState(() => _nozzles = Fm200Nozzles.values[i]),
            ),
            const SizedBox(height: 12),
            if (layout == null)
              Text('${_nozzles.label}: not available for the ${cyl.sizeLb} lb cylinder.')
            else ...<Widget>[
              ResultTable(
                items: <ResultItem>[
                  ResultItem('Use part no.', cyl.partNumber),
                  ResultItem('Cylinder', '${cyl.sizeLb}', 'lb'),
                  ResultItem('Nozzle size', _in(layout.nozzleSize)),
                  ResultItem('Page no.', '${_nozzles.page}'),
                  ResultItem('Table no.', _nozzles.table),
                  ResultItem('Figure', _nozzles.figure),
                ],
              ),
              const SizedBox(height: 16),
              // The catalogue figure for this layout — what A, B, C mean.
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: ColoredBox(
                      // White even in dark mode: the drawing is on white.
                      color: Colors.white,
                      child: Image.asset(
                        _nozzles.figureAsset,
                        fit: BoxFit.contain,
                        filterQuality: FilterQuality.high,
                        semanticLabel: _nozzles.figure,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _nozzles.figure,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
              AppDataTable<Fm200Section>(
                shrinkWrap: true,
                rows: layout.sections,
                columns: columns,
                cardBuilder: (BuildContext c, Fm200Section s) =>
                    ductCard<Fm200Section>(c, s, columns),
              ),
            ],
          ],
        ],
      ],
    );
  }
}
