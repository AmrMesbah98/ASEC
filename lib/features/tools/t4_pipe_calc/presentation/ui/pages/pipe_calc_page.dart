/// Module: tools / t4_pipe_calc
///
///*************************** FILE INFO ****************************///
/// File Name: pipe_calc_page.dart
/// Purpose: Declares `PipeCalcPage` — the pipe sizer: pick units, pipe
///          type and size, type the flow (fluid: 50°F water); see the
///          pipe's outside / inside diameter, and the velocity, Reynolds number,
///          friction factor, head loss and elbow loss.
/// Author: ASEC team
/// Created: 22/10/2026
/// Updated: 22/10/2026 - Shows its title (ConsolePage header) like the
///          converter and the engineering calculators.
/// Updated: 23/10/2026 - Fluid fixed to 50°F (10°C) water: Fluid dropdown
///          and Fluid table removed; Pipe table shows only outside and
///          inside diameter.
///
/// WORKS OFFLINE — computed on the device. Built from the app's own
/// controls (CustomDropdown, CustomTextField, AppDataTable) through the
/// duct calculator's shared helpers, so both tools look and behave alike.
library;

import 'package:asec/core/helper/main_helper/format_helper.dart';
import 'package:flutter/material.dart';

import 'package:asec/core/custom/1-custom_dropdown.dart';
import 'package:asec/core/theme/app_colors.dart';
import 'package:asec/features/admin/a1_shell/presentation/ui/widgets/console_page.dart';
import 'package:asec/generated/l10n.dart';
import 'package:asec/features/tools/t3_duct_calc/presentation/ui/widgets/duct_fields.dart';
import 'package:asec/features/tools/t4_pipe_calc/domain/pipe_calculator.dart';
import 'package:asec/features/tools/t4_pipe_calc/domain/pipe_data.dart';

enum PipeUnits { ip, si }

class PipeCalcPage extends StatefulWidget {
  const PipeCalcPage({super.key});

  @override
  State<PipeCalcPage> createState() => _PipeCalcPageState();
}

class _PipeCalcPageState extends State<PipeCalcPage> {
  PipeUnits _units = PipeUnits.ip;
  PipeType _type = PipeType.sch40Steel;
  int _size = kPipeSizes.indexWhere((PipeSize s) => s.label == '½"');
  /// Fluid is fixed: 50°F (10°C) water, the first entry of [kPipeFluids].
  static final PipeFluid _fluid = kPipeFluids.first;
  late final TextEditingController _flow =
      TextEditingController(text: _flowText(kPipeSizes[_size].defaultFlowGpm));

  bool get _ip => _units == PipeUnits.ip;

  @override
  void dispose() {
    _flow.dispose();
    super.dispose();
  }

  /// A flow in gpm, written in the current units.
  String _flowText(double gpm) => _ip
      ? _trim(gpm.toStringAsFixed(2))
      : _trim((gpm * PipeSi.gpmToLs).toStringAsFixed(3));

  static String _trim(String s) =>
      s.contains('.') ? s.replaceFirst(RegExp(r'\.?0+$'), '') : s;

  /// The typed flow in gpm (0 when empty or invalid).
  double _flowGpm() {
    final double? v = parseNumber(_flow.text);
    if (v == null || v < 0) return 0;
    return _ip ? v : v / PipeSi.gpmToLs;
  }

  void _pickSize(int i) {
    setState(() {
      _size = i;
      // Like the original: a new size suggests its usual flow.
      _flow.text = _flowText(kPipeSizes[i].defaultFlowGpm);
    });
  }

  void _pickUnits(PipeUnits u) {
    if (u == _units) return;
    final double gpm = _flowGpm();
    setState(() {
      _units = u;
      _flow.text = gpm > 0 ? _flowText(gpm) : '';
    });
  }

  List<ResultItem> _pipeItems(PipeResult r) {
    if (_ip) {
      return <ResultItem>[
        ResultItem('Outside diameter', fmt(r.outsideDiameter, 3), 'in'),
        ResultItem('Inside diameter', fmt(r.insideDiameter, 3), 'in'),
      ];
    }
    return <ResultItem>[
      ResultItem('Outside diameter', fmt(r.outsideDiameter * PipeSi.inToMm, 1), 'mm'),
      ResultItem('Inside diameter', fmt(r.insideDiameter * PipeSi.inToMm, 1), 'mm'),
    ];
  }

  /// 26/10/2026: only velocity and head loss (Reynolds number, friction
  /// factor and elbow loss removed — Eng. Ahmed Shuhayb).
  List<ResultItem> _flowItems(PipeResult r, PipeFluid f) {
    if (_ip) {
      return <ResultItem>[
        ResultItem('Fluid velocity', fmt(r.velocity, 2), 'ft/s'),
        ResultItem('Head loss', fmt(r.headLoss, 3), 'ft/100 ft'),
      ];
    }
    return <ResultItem>[
      ResultItem('Fluid velocity', fmt(r.velocity * PipeSi.ftToM, 2), 'm/s'),
      ResultItem('Head loss', fmt(PipeSi.headLossPaPerM(r.headLoss, f), 1), 'Pa/m'),
      ResultItem('Head loss', fmt(r.headLoss, 3), 'm/100 m'),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final PipeSize size = kPipeSizes[_size];
    final PipeFluid fluid = _fluid;
    PipeResult? result;
    String? error;
    try {
      result = PipeCalculator.calculate(
        type: _type,
        size: size,
        fluid: fluid,
        flowGpm: _flowGpm(),
      );
      if (result == null) error = 'No data for ${size.label} ${_type.label}.';
    } on PipeCalcException catch (e) {
      error = e.message;
    }

    // Titled like the other calculators (ConsolePage header).
    return ConsolePage(
      title: S.of(context).pipeCalc,
      child: Material(
      type: MaterialType.transparency,
      child: ListView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.only(bottom: 16),
        children: <Widget>[
          ResponsiveFields(
            children: <Widget>[
              SizedBox(
                width: 180,
                child: CustomDropdown<PipeUnits>(
                  fillColor: AppColors.card,
                  label: 'Units',
                  value: _units,
                  items: const <DropdownItem<PipeUnits>>[
                    DropdownItem<PipeUnits>(value: PipeUnits.ip, label: 'Imperial'),
                    DropdownItem<PipeUnits>(value: PipeUnits.si, label: 'Metric'),
                  ],
                  onChanged: (PipeUnits? u) {
                    if (u != null) _pickUnits(u);
                  },
                ),
              ),
              SizedBox(
                width: 220,
                child: CustomDropdown<PipeType>(
                  fillColor: AppColors.card,
                  label: 'Pipe type',
                  value: _type,
                  maxOverlayHeight: 360,
                  items: <DropdownItem<PipeType>>[
                    for (final PipeType t in PipeType.values)
                      DropdownItem<PipeType>(value: t, label: t.label),
                  ],
                  onChanged: (PipeType? t) {
                    if (t != null) setState(() => _type = t);
                  },
                ),
              ),
              SizedBox(
                width: 180,
                child: CustomDropdown<int>(
                  fillColor: AppColors.card,
                  label: 'Pipe size',
                  value: _size,
                  maxOverlayHeight: 360,
                  items: <DropdownItem<int>>[
                    for (int i = 0; i < kPipeSizes.length; i++)
                      DropdownItem<int>(
                        value: i,
                        label: kPipeSizes[i].displayLabel,
                        // Sizes this pipe type is not made in are dimmed.
                        enabled: kPipeSizes[i].dimensionsFor(_type) != null,
                      ),
                  ],
                  onChanged: (int? i) {
                    if (i != null) _pickSize(i);
                  },
                ),
              ),
              NumberField(
                controller: _flow,
                label: 'Flow',
                unit: _ip ? 'US gpm' : 'L/s',
                onChanged: (_) => setState(() {}),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (error != null)
            Text(FormatHelper.capitalize(error))
          else if (result != null) ...<Widget>[
            Text(FormatHelper.capitalize('Pipe')),
            const SizedBox(height: 8),
            ResultTable(items: _pipeItems(result)),
            const SizedBox(height: 24),
            Text(FormatHelper.capitalize('Flow')),
            const SizedBox(height: 8),
            ResultTable(items: _flowItems(result, fluid)),
          ],
        ],
      ),
      ),
    );
  }
}
