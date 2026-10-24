/// Module: tools / t2_engineering_calc
///
///*************************** FILE INFO ****************************///
/// File Name: engineering_calc_page.dart
/// Purpose: Declares `EngineeringCalcPage` — the engineering calculators
///          (HVAC, fire fighting, plumbing, medical gas), in the same design
///          as the unit converter: discipline tabs on top, the inputs card on
///          the left, results and the method on the right (stacked on phones).
/// Author: ASEC team
/// Created: 4/10/2026
///
/// ONLINE AND OFFLINE. The maths runs on the device, so the page also sits on
/// the offline screen (AppConnectivity). Admins get it as a menu tab; a
/// member gets it in Settings → "My space" once the admin has unlocked it
/// (a paid extra — CalcAccess remembers the unlock for offline use).
///
/// Every calculator is data (domain/calc_catalog.dart). This page only
/// draws fields, converts units, calls the calculator's compute function
/// and shows the results — it knows nothing about any one calculator.
///
/// Built only from the app's own controls: CustomTabs, CustomTextField,
/// CustomDropdown and customButton.
///
/// EXPORT: the results card has "Export PDF" and "Export Excel" — the open
/// calculator with its inputs, results and method (data/calc_export.dart),
/// saved through the system "Save as" dialog (data/file_saver.dart).

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:asec/core/custom/1-custom_dropdown.dart';
import 'package:asec/core/custom/10-custom_tabs.dart';
import 'package:asec/core/custom/2-custom_textfield.dart';
import 'package:asec/core/custom/5-custom_button.dart';
import 'package:asec/core/theme/app_colors.dart';
import 'package:asec/core/theme/app_theme.dart';
import 'package:asec/features/admin/a1_shell/presentation/ui/widgets/console_page.dart';
import 'package:asec/features/tools/t1_unit_converter/domain/unit_catalog.dart';
import 'package:asec/features/tools/t2_engineering_calc/data/calc_export.dart';
import 'package:asec/features/tools/t2_engineering_calc/domain/calc_catalog.dart';
import 'package:asec/features/tools/t2_engineering_calc/domain/calc_model.dart';
import 'package:asec/generated/l10n.dart';
import 'package:asec/core/helper/main_helper/format_helper.dart';
import 'package:asec/core/custom/114-app_messenger.dart';

class EngineeringCalcPage extends StatefulWidget {
  const EngineeringCalcPage({super.key});

  @override
  State<EngineeringCalcPage> createState() => _EngineeringCalcPageState();
}

class _EngineeringCalcPageState extends State<EngineeringCalcPage> {
  int _discipline = 0;

  /// The open calculator of each tab, so switching tabs comes back to it.
  final Map<String, int> _picked = <String, int>{};

  /// SI (false) or IP (true) — the units every field starts in.
  bool _imperial = false;

  /// One session per calculator: what the user typed survives switching.
  final Map<String, _CalcSession> _sessions = <String, _CalcSession>{};

  /// True while a PDF / Excel file is being made.
  bool _exporting = false;

  CalcDiscipline get _disc => CalcCatalog.all[_discipline];
  int get _calcIndex => _picked[_disc.id] ?? 0;
  EngCalc get _calc => _disc.calcs[_calcIndex];

  _CalcSession get _session => _sessions.putIfAbsent(
        // The same calculator can sit in two tabs (pipe friction): one session.
        _calc.id,
        () => _CalcSession(_calc, _imperial),
      );

  @override
  void dispose() {
    for (final _CalcSession s in _sessions.values) {
      s.dispose();
    }
    super.dispose();
  }

  void _setSystem(bool imperial) {
    if (imperial == _imperial) return;
    setState(() {
      _imperial = imperial;
      for (final _CalcSession s in _sessions.values) {
        s.setSystem(imperial);
      }
    });
  }

  void _copy(String text) {
    Clipboard.setData(ClipboardData(text: text));
    AppMessenger.of(context)
      ..hide()
      ..show(AppMessage(
        content: Text(FormatHelper.capitalize(S.of(context).copiedValue(text))),
        duration: const Duration(seconds: 2),
      ));
  }

  /// Makes the file and opens the system "Save as" dialog (name + folder,
  /// starting in Downloads). iOS's Files sheet has no name field, so on
  /// iOS the name is asked first.
  Future<void> _export({required bool excel}) async {
    if (_exporting) return;
    final S s = S.of(context);
    final bool ar = Localizations.localeOf(context).languageCode == 'ar';
    final AppMessenger messenger = AppMessenger.of(context);
    final CalcReport report = _session.report(s, ar, _disc);
    final String ext = excel ? 'xlsx' : 'pdf';
    String fileName = '${report.fileBase}.$ext';

    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
      final String? typed = await _askFileName(s, report.fileBase);
      if (typed == null) return;
      fileName = '$typed.$ext';
    }

    setState(() => _exporting = true);
    try {
      final String? saved = excel
          ? await CalcExport.saveExcel(report, fileName: fileName, dialogTitle: s.calcExportExcel)
          : await CalcExport.savePdf(report, fileName: fileName, dialogTitle: s.calcExportPdf);
      if (saved != null) {
        messenger
          ..hide()
          ..show(AppMessage(content: Text(FormatHelper.capitalize(s.calcSaved(saved)))));
      }
    } catch (e) {
      messenger.show(AppMessage(
        content: Text(FormatHelper.capitalize(kDebugMode ? '${s.errUnknown}\n$e' : s.errUnknown)),
        duration: const Duration(seconds: 6),
      ));
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  /// The file-name box (iOS only). Returns the name without extension, or
  /// null on Cancel.
  Future<String?> _askFileName(S s, String suggested) async {
    final TextEditingController name = TextEditingController(text: suggested);
    final String? result = await showDialog<String>(
      context: context,
      builder: (BuildContext d) {
        void submit() {
          final String v = name.text.trim().replaceAll(RegExp(r'[\\/:*?"<>|]'), '-');
          Navigator.of(d).pop(v.isEmpty ? suggested : v);
        }

        return AlertDialog(
          backgroundColor: AppColors.card,
          title: Text(FormatHelper.capitalize(s.calcFileName), style: StyleText.fontSize16Weight500),
          content: CustomTextField(
            controller: name,
            label: s.calcFileName,
            textDirection: TextDirection.ltr,
            onSubmitted: (_) => submit(),
          ),
          actions: <Widget>[
            customButton(
              title: s.cancel,
              function: () => Navigator.of(d).pop(),
              wrapContent: true,
              color: AppColors.card,
              textColor: AppColors.text,
            ),
            customButton(title: s.save, function: submit, wrapContent: true),
          ],
        );
      },
    );
    name.dispose();
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final S s = S.of(context);
    final bool ar = Localizations.localeOf(context).languageCode == 'ar';
    final _CalcSession session = _session;

    final Widget body = LayoutBuilder(
      builder: (BuildContext context, BoxConstraints c) {
        final bool wide = c.maxWidth >= 900;
        final Widget inputs = _inputsCard(s, ar, session);
        final Widget output = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            _resultsCard(s, ar, session),
            SizedBox(height: 16.h),
            _methodCard(s, ar, session.calc),
          ],
        );

        return SingleChildScrollView(
          padding: EdgeInsets.only(bottom: 24.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              CustomTabs(
                tabs: <String>[for (final CalcDiscipline d in CalcCatalog.all) d.name(ar)],
                selectedValue: _discipline,
                onChanged: (int i) => setState(() => _discipline = i),
                spacing: 24.sp,
                textStyle: StyleText.fontSize16Weight500,
              ),
              SizedBox(height: 14.h),
              Wrap(
                spacing: 8.w,
                runSpacing: 8.h,
                children: <Widget>[
                  for (int i = 0; i < _disc.calcs.length; i++)
                    _chip(
                      _disc.calcs[i].name(ar),
                      selected: i == _calcIndex,
                      onTap: () => setState(() => _picked[_disc.id] = i),
                    ),
                ],
              ),
              SizedBox(height: 16.h),
              if (wide)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(flex: 5, child: inputs),
                    SizedBox(width: 16.w),
                    Expanded(flex: 4, child: output),
                  ],
                )
              else ...<Widget>[
                inputs,
                SizedBox(height: 16.h),
                output,
              ],
            ],
          ),
        );
      },
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      body: ConsolePage(
        title: s.engineeringCalc,
        subtitle: s.engineeringCalcSub,
        child: body,
      ),
    );
  }

  // ── Pieces ───────────────────────────────────────────────────────────────

  Widget _chip(String label, {required bool selected, required VoidCallback onTap}) {
    return customButton(
      title: label,
      function: onTap,
      wrapContent: true,
      color: selected ? AppColors.primary : AppColors.card,
      textColor: selected ? AppColors.textButton : AppColors.text,
    );
  }

  BoxDecoration get _cardDecoration => BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16.r),
      );

  Widget _inputsCard(S s, bool ar, _CalcSession session) {
    final EngCalc calc = session.calc;
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: _cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(_disc.icon, color: AppColors.primary, size: 22),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  FormatHelper.capitalize(calc.name(ar)),
                  style: StyleText.fontSize18Weight600.copyWith(color: AppColors.text),
                ),
              ),
              SizedBox(width: 8.w),
              _chip('SI', selected: !_imperial, onTap: () => _setSystem(false)),
              SizedBox(width: 6.w),
              _chip('IP', selected: _imperial, onTap: () => _setSystem(true)),
            ],
          ),
          SizedBox(height: 6.h),
          Text(
            FormatHelper.capitalize(s.calcInputs),
            style: StyleText.fontSize13Weight500.copyWith(color: AppColors.secondaryText),
          ),
          SizedBox(height: 12.h),
          for (final CalcField f in calc.fields)
            if (session.visible(f)) ...<Widget>[
              f.isChoice ? _choiceField(ar, session, f) : _numberField(ar, session, f),
              SizedBox(height: 12.h),
            ],
          SizedBox(height: 4.h),
          Center(
            child: customButton(
              title: s.calcReset,
              function: () => setState(() => session.reset(_imperial)),
              wrapContent: true,
              color: AppColors.card,
              textColor: AppColors.text,
            ),
          ),
        ],
      ),
    );
  }

  Widget _choiceField(bool ar, _CalcSession session, CalcField f) {
    return CustomDropdown<int>(
      label: f.name(ar),
      value: session.choices[f.id],
      maxOverlayHeight: 360,
      items: <DropdownItem<int>>[
        for (int i = 0; i < f.options.length; i++)
          DropdownItem<int>(value: i, label: f.options[i].name(ar)),
      ],
      onChanged: (int? i) {
        if (i != null) setState(() => session.choose(f, i));
      },
    );
  }

  Widget _numberField(bool ar, _CalcSession session, CalcField f) {
    final Qty? qty = f.qty;
    final Widget field = CustomTextField(
      controller: session.controllers[f.id],
      label: f.name(ar),
      keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
      textDirection: TextDirection.ltr,
      onChanged: (_) => setState(session.recompute),
    );

    final Widget? trailing;
    if (qty != null) {
      final List<UnitDef> units = qty.category.units;
      trailing = SizedBox(
        width: 150,
        child: CustomDropdown<int>(
          value: session.units[f.id],
          maxOverlayHeight: 320,
          items: <DropdownItem<int>>[
            for (int i = 0; i < units.length; i++)
              DropdownItem<int>(value: i, label: units[i].symbol),
          ],
          onChanged: (int? i) {
            if (i != null) setState(() => session.changeUnit(f, i));
          },
        ),
      );
    } else if (f.unit.isNotEmpty) {
      trailing = SizedBox(
        width: 56,
        child: Padding(
          padding: EdgeInsets.only(bottom: 14.h),
          child: Text(
            FormatHelper.capitalize(f.unit),
            textAlign: TextAlign.center,
            style: StyleText.fontSize13Weight600.copyWith(color: AppColors.secondaryText),
          ),
        ),
      );
    } else {
      trailing = null;
    }

    if (trailing == null) return field;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: <Widget>[
        Expanded(child: field),
        SizedBox(width: 8.w),
        trailing,
      ],
    );
  }

  Widget _resultsCard(S s, bool ar, _CalcSession session) {
    final Map<String, double>? results = session.results;
    return Container(
      padding: EdgeInsets.all(12.r),
      decoration: _cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Padding(
            padding: EdgeInsets.fromLTRB(4.w, 4.h, 4.w, 8.h),
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8.w,
              runSpacing: 8.h,
              children: <Widget>[
                Text(
                  FormatHelper.capitalize(s.calcResults),
                  style: StyleText.fontSize15Weight600.copyWith(color: AppColors.text),
                ),
                if (_exporting)
                  const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.2),
                  )
                else if (results != null)
                  Wrap(
                    spacing: 8.w,
                    runSpacing: 8.h,
                    children: <Widget>[
                      for (final (bool excel, String label) in <(bool, String)>[
                        (false, s.calcExportPdf),
                        (true, s.calcExportExcel),
                      ])
                        customButton(
                          title: label,
                          function: () => _export(excel: excel),
                          wrapContent: true,
                        ),
                    ],
                  ),
              ],
            ),
          ),
          if (results == null)
            Padding(
              padding: EdgeInsets.all(8.r),
              child: Text(
                FormatHelper.capitalize(s.calcFillAll),
                style: StyleText.fontSize13Weight500.copyWith(color: AppColors.secondaryText),
              ),
            )
          else
            for (final CalcResult r in session.calc.results)
              _resultRow(ar, session, r, results[r.id]),
          Padding(
            padding: EdgeInsets.fromLTRB(4.w, 8.h, 4.w, 0),
            child: Text(
              FormatHelper.capitalize(s.calcTapHint),
              style: StyleText.fontSize12Weight400.copyWith(color: AppColors.secondaryText),
            ),
          ),
        ],
      ),
    );
  }

  Widget _resultRow(bool ar, _CalcSession session, CalcResult r, double? value) {
    final String text = session.display(r, value);
    final bool canCycle = r.qty != null && value != null && value.isFinite;

    return Material(
      color: r.primary ? AppColors.primary.withOpacity(0.08) : Colors.transparent,
      borderRadius: BorderRadius.circular(10.r),
      child: InkWell(
        borderRadius: BorderRadius.circular(10.r),
        onTap: canCycle ? () => setState(() => session.cycleResultUnit(r)) : null,
        onLongPress: text == '—' ? null : () => _copy(text),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 10.h),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  FormatHelper.capitalize(r.name(ar)),
                  style: StyleText.fontSize13Weight500.copyWith(color: AppColors.text),
                ),
              ),
              SizedBox(width: 8.w),
              Text(
                FormatHelper.capitalize(text),
                textDirection: TextDirection.ltr,
                style: (r.primary ? StyleText.fontSize15Weight600 : StyleText.fontSize13Weight600)
                    .copyWith(color: r.primary ? AppColors.primary : AppColors.text),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _methodCard(S s, bool ar, EngCalc calc) {
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: _cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            FormatHelper.capitalize(s.calcFormula),
            style: StyleText.fontSize15Weight600.copyWith(color: AppColors.text),
          ),
          SizedBox(height: 10.h),
          Directionality(
            textDirection: TextDirection.ltr,
            child: Text(
              FormatHelper.capitalize(calc.formula),
              style: StyleText.fontSize13Weight500.copyWith(color: AppColors.primary, height: 1.6),
            ),
          ),
          if (calc.note(ar).isNotEmpty) ...<Widget>[
            SizedBox(height: 12.h),
            Text(
              FormatHelper.capitalize(calc.note(ar)),
              style: StyleText.fontSize13Weight500.copyWith(color: AppColors.text, height: 1.5),
            ),
          ],
          SizedBox(height: 12.h),
          Text(
            FormatHelper.capitalize(s.calcDisclaimer),
            style: StyleText.fontSize12Weight400.copyWith(color: AppColors.secondaryText),
          ),
        ],
      ),
    );
  }
}

/// What the user typed and picked in one calculator.
class _CalcSession {
  _CalcSession(this.calc, bool imperial) {
    for (final CalcField f in calc.fields) {
      if (f.isChoice) {
        choices[f.id] = f.defOption;
      } else {
        controllers[f.id] = TextEditingController();
      }
    }
    reset(imperial);
  }

  final EngCalc calc;
  final Map<String, TextEditingController> controllers = <String, TextEditingController>{};
  final Map<String, int> units = <String, int>{};
  final Map<String, int> choices = <String, int>{};
  final Map<String, int> resultUnits = <String, int>{};

  /// null while a shown field is empty or not a number.
  Map<String, double>? results;

  void dispose() {
    for (final TextEditingController c in controllers.values) {
      c.dispose();
    }
  }

  bool visible(CalcField f) {
    final (String, int)? rule = f.showIf;
    return rule == null || choices[rule.$1] == rule.$2;
  }

  /// Accepts Arabic-Indic digits and a comma or Arabic decimal separator.
  double? _parsed(String id) {
    const String arabic = '٠١٢٣٤٥٦٧٨٩';
    final StringBuffer b = StringBuffer();
    for (final String ch in controllers[id]!.text.trim().split('')) {
      final int i = arabic.indexOf(ch);
      if (i >= 0) {
        b.write(i);
      } else if (ch == '٫' || ch == ',') {
        b.write('.');
      } else if (ch != ' ' && ch != '٬') {
        b.write(ch);
      }
    }
    return double.tryParse(b.toString());
  }

  double? _base(CalcField f) {
    final double? v = _parsed(f.id);
    if (v == null) return null;
    final Qty? q = f.qty;
    return q == null ? v : q.toBase(v, units[f.id]!);
  }

  void _setBase(CalcField f, double base) {
    final Qty? q = f.qty;
    final double shown = q == null ? base : q.fromBase(base, units[f.id]!);
    controllers[f.id]!.text = formatCalc(shown, digits: 6);
  }

  CalcField? _field(String id) {
    for (final CalcField f in calc.fields) {
      if (f.id == id) return f;
    }
    return null;
  }

  void recompute() {
    final Map<String, double> v = <String, double>{};
    for (final CalcField f in calc.fields) {
      if (f.isChoice) {
        v[f.id] = choices[f.id]!.toDouble();
        continue;
      }
      final double? b = _base(f);
      if (b == null) {
        if (visible(f)) {
          results = null;
          return;
        }
        v[f.id] = double.nan;
      } else {
        v[f.id] = b;
      }
    }
    try {
      results = calc.compute(v);
    } catch (_) {
      results = null;
    }
  }

  void changeUnit(CalcField f, int to) {
    final double? b = _base(f);
    units[f.id] = to;
    if (b != null) _setBase(f, b);
    recompute();
  }

  void choose(CalcField f, int option) {
    choices[f.id] = option;
    f.options[option].presets.forEach((String id, double siValue) {
      final CalcField? target = _field(id);
      if (target != null) _setBase(target, target.siToBase(siValue));
    });
    recompute();
  }

  void setSystem(bool imperial) {
    for (final CalcField f in calc.fields) {
      final Qty? q = f.qty;
      if (f.isChoice || q == null) continue;
      final double? b = _base(f);
      units[f.id] = q.defaultIndex(imperial);
      if (b != null) _setBase(f, b);
    }
    for (final CalcResult r in calc.results) {
      final Qty? q = r.qty;
      if (q != null) resultUnits[r.id] = q.defaultIndex(imperial);
    }
    recompute();
  }

  void reset(bool imperial) {
    for (final CalcField f in calc.fields) {
      if (f.isChoice) {
        choices[f.id] = f.defOption;
        continue;
      }
      final Qty? q = f.qty;
      if (q != null) units[f.id] = q.defaultIndex(imperial);
      _setBase(f, f.siToBase(f.def));
    }
    for (final CalcResult r in calc.results) {
      final Qty? q = r.qty;
      if (q != null) resultUnits[r.id] = q.defaultIndex(imperial);
    }
    recompute();
  }

  void cycleResultUnit(CalcResult r) {
    final Qty? q = r.qty;
    if (q == null) return;
    resultUnits[r.id] = (resultUnits[r.id]! + 1) % q.category.units.length;
  }

  /// The open calculator as a printable report (only the fields on screen).
  CalcReport report(S s, bool ar, CalcDiscipline discipline) {
    final List<CalcRow> inputs = <CalcRow>[];
    for (final CalcField f in calc.fields) {
      if (!visible(f)) continue;
      if (f.isChoice) {
        inputs.add(CalcRow(label: f.name(ar), text: f.options[choices[f.id]!].name(ar)));
        continue;
      }
      final double? v = _parsed(f.id);
      final Qty? q = f.qty;
      final String unit = q == null ? f.unit : q.category.units[units[f.id]!].symbol;
      final String n = v == null ? '—' : formatCalc(v, digits: 6);
      inputs.add(CalcRow(
        label: f.name(ar),
        text: unit.isEmpty ? n : '$n $unit',
        number: v,
        unit: unit,
      ));
    }

    final List<CalcRow> out = <CalcRow>[];
    for (final CalcResult r in calc.results) {
      final double? value = results?[r.id];
      final Qty? q = r.qty;
      double? number;
      String unit = r.unit;
      if (r.text == null && value != null && value.isFinite) {
        final double shown = q == null ? value : q.fromBase(value, resultUnits[r.id]!);
        number = double.tryParse(formatCalc(shown, digits: 6));
        if (q != null) unit = q.category.units[resultUnits[r.id]!].symbol;
      }
      out.add(CalcRow(
        label: r.name(ar),
        text: display(r, value),
        number: number,
        unit: unit,
        primary: r.primary,
      ));
    }

    return CalcReport(
      id: calc.id,
      title: calc.name(ar),
      discipline: discipline.name(ar),
      arabic: ar,
      inputs: inputs,
      results: out,
      formula: calc.formula,
      note: calc.note(ar),
      labels: CalcReportLabels(
        inputs: s.calcInputs,
        results: s.calcResults,
        method: s.calcFormula,
        item: s.calcItem,
        value: s.calcValue,
        unit: s.calcUnit,
        date: s.calcDate,
        disclaimer: s.calcDisclaimer,
      ),
    );
  }

  String display(CalcResult r, double? value) {
    if (value == null || value.isNaN || value.isInfinite) return '—';
    final String Function(double)? text = r.text;
    if (text != null) return text(value);
    final Qty? q = r.qty;
    if (q == null) {
      final String n = formatCalc(value);
      return r.unit.isEmpty ? n : '$n ${r.unit}';
    }
    final int u = resultUnits[r.id]!;
    return '${formatCalc(q.fromBase(value, u))} ${q.category.units[u].symbol}';
  }
}
