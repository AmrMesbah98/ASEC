/// Module: tools / t5_plumbing_fire
///
///*************************** FILE INFO ****************************///
/// File Name: fm200_tab.dart
/// Purpose: FM-200 tab — room area, height and ambient temperature in;
///          room volume, agent weight, Kidde cylinder part number, nozzle
///          size and the pipe limits for 1, 2 or 4 nozzles out.
/// Author: ASEC team
/// Created: 22/10/2026
/// Updated: 31/10/2026 - Pipe limits in one table (row per limit, column
///          per section) on every screen, phones included.
/// Updated: 26/10/2026 - Length × width instead of area, like the other
///          fire tabs (Eng. Ahmed Shuhayb).
library;

import 'package:asec/core/helper/main_helper/format_helper.dart';
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
  final TextEditingController _length = TextEditingController(text: '10');
  final TextEditingController _width = TextEditingController(text: '5');
  final TextEditingController _height = TextEditingController(text: '3');
  final TextEditingController _ambient = TextEditingController(text: '21');
  Fm200Nozzles _nozzles = Fm200Nozzles.one;

  @override
  void dispose() {
    _length.dispose();
    _width.dispose();
    _height.dispose();
    _ambient.dispose();
    super.dispose();
  }

  static String _in(double v) =>
      '${v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toString()}"';

  @override
  Widget build(BuildContext context) {
    final double? l = parseNumber(_length.text);
    final double? w = parseNumber(_width.text);
    final double? a = (l == null || w == null || l <= 0 || w <= 0) ? null : l * w;
    final double? h = parseNumber(_height.text);
    final double? t = parseNumber(_ambient.text);
    final Fm200Result? r = (a == null || h == null || t == null || a <= 0 || h <= 0)
        ? null
        : Fm200.calculate(areaM2: a, heightM: h, ambientC: t);
    final Fm200Cylinder? cyl = r?.cylinder;
    final Fm200Layout? layout = cyl?.layout(_nozzles);
    void changed(String _) => setState(() {});

    return ListView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.symmetric(vertical: 16),
      children: <Widget>[
        ResponsiveFields(
          children: <Widget>[
            NumberField(controller: _length, label: 'Length', unit: 'm', onChanged: changed),
            NumberField(controller: _width, label: 'Width', unit: 'm', onChanged: changed),
            NumberField(controller: _height, label: 'Height', unit: 'm', onChanged: changed),
            NumberField(controller: _ambient, label: 'Ambient', unit: '°C', onChanged: changed),
          ],
        ),
        const SizedBox(height: 16),
        if (r == null)
          Text(FormatHelper.capitalize('Enter the room length, width, height and ambient temperature.'))
        else ...<Widget>[
          ResultTable(
            exportTitle: 'FM-200',
            discipline: 'Fire fighting',
            items: <ResultItem>[
              ResultItem('Room Volume', fmt(r.volume, 2), 'm³'),
              ResultItem('Total Weight Of FM-200', fmt(r.agentWeight, 2), 'kg'),
              ResultItem('Take Weight Of FM-200 Cylinder', fmt(r.takeWeight, 0), 'kg'),
            ],
            // 09/11/2026: the files carry the inputs, the cylinder and
            // nozzle layout picked, the pipe-limits table, the catalogue
            // figure and the method.
            inputs: <ResultItem>[
              ResultItem('Length', _length.text.trim(), 'm'),
              ResultItem('Width', _width.text.trim(), 'm'),
              ResultItem('Height', _height.text.trim(), 'm'),
              ResultItem('Ambient', _ambient.text.trim(), '°C'),
              if (cyl != null) ResultItem('Nozzles', _nozzles.label),
            ],
            exportResults: <ResultItem>[
              ResultItem('Room Volume', fmt(r.volume, 2), 'm³'),
              ResultItem('Total Weight Of FM-200', fmt(r.agentWeight, 2), 'kg'),
              ResultItem('Take Weight Of FM-200 Cylinder', fmt(r.takeWeight, 0), 'kg'),
              if (cyl != null && layout != null) ...<ResultItem>[
                ResultItem('Use part no.', cyl.partNumber),
                ResultItem('Cylinder', '${cyl.sizeLb}', 'lb'),
                ResultItem('Nozzle size', _in(layout.nozzleSize)),
                ResultItem('Page no.', '${_nozzles.page}'),
                ResultItem('Table no.', _nozzles.table),
                ResultItem('Figure', _nozzles.figure),
              ],
            ],
            extraTitle: 'Pipe limits',
            extraHeaders: layout == null
                ? const <String>[]
                : <String>['Item', for (final Fm200Section sec in layout.sections) 'Section ${sec.name}'],
            extraRows: layout == null
                ? const <List<String>>[]
                : <List<String>>[
                    for (final _Limit l in _Limit.all)
                      <String>[l.label, for (final Fm200Section sec in layout.sections) l.value(sec)],
                  ],
            imageAsset: layout == null ? null : _nozzles.figureAsset,
            imageCaption: layout == null ? '' : _nozzles.figure,
            method: 'V = L × W × H\n'
                'S = 0.1269 + 0.0005 × T\n'
                'W = V ÷ S × C ÷ (100 − C),  C = ${fmt(Fm200.concentration, 0)} %\n'
                'Cylinder: the smallest KIDDE cylinder that holds W (rounded up)',
          ),
          const SizedBox(height: 16),
          if (cyl == null)
            Text(
              'Weight of FM-200 = ${fmt(r.takeWeight, 0)} kg > 227 kg — '
              'too much for one cylinder. Please try another value.',
            )
          else ...<Widget>[
            Text(FormatHelper.capitalize('As per KIDDE FM-200 catalogue')),
            const SizedBox(height: 8),
            CustomTabs(
              tabs: <String>[for (final Fm200Nozzles n in Fm200Nozzles.values) n.label],
              selectedValue: _nozzles.index,
              onChanged: (int i) => setState(() => _nozzles = Fm200Nozzles.values[i]),
            ),
            const SizedBox(height: 12),
            if (layout == null)
              Text(FormatHelper.capitalize('${_nozzles.label}: not available for the ${cyl.sizeLb} lb cylinder.'))
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
              // 31/10/2026 (Eng. Ahmed Shuhayb): the pipe limits in ONE
              // TABLE on every screen, phones too (no cards) — a row per
              // limit, a column per section.
              AppDataTable<_Limit>(
                shrinkWrap: true,
                cardsOnTablet: false,
                rows: _Limit.all,
                columns: <AppTableColumn<_Limit>>[
                  AppTableColumn<_Limit>(
                    label: 'Item',
                    flex: 3,
                    cell: (BuildContext c, _Limit l) => AppTableCellText(l.label, emphasis: true),
                  ),
                  for (final Fm200Section s in layout.sections)
                    AppTableColumn<_Limit>(
                      label: 'Section ${s.name}',
                      flex: 2,
                      cell: (BuildContext c, _Limit l) => AppTableCellText(l.value(s)),
                    ),
                ],
              ),
            ],
          ],
        ],
      ],
    );
  }
}

/// One row of the FM-200 pipe-limits table.
class _Limit {
  const _Limit(this.label, this.value);

  final String label;
  final String Function(Fm200Section s) value;

  static final List<_Limit> all = <_Limit>[
    _Limit('Pipe size', (Fm200Section s) => _Fm200TabState._in(s.pipeSize)),
    _Limit('Max. length (ft)', (Fm200Section s) => fmt(s.maxLengthFt, 0)),
    _Limit('Max. elbows', (Fm200Section s) => '${s.maxElbows}'),
    _Limit('Max. height (ft)', (Fm200Section s) => fmt(s.maxHeightFt, 0)),
  ];
}
