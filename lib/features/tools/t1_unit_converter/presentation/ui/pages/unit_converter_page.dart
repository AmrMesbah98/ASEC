/// Module: tools / t1_unit_converter
///
///*************************** FILE INFO ****************************///
/// File Name: unit_converter_page.dart
/// Purpose: Declares `UnitConverterPage` — a unit converter in the spirit of
///          unitconverters.net, limited to the main engineering units
///          (length, area, volume, mass, temperature, pressure, flow, speed,
///          cooling load, density, time) — UnitCatalog.converter.
/// Author: ASEC team
/// Created: 1/10/2026
///
/// WORKS OFFLINE. Everything is computed on the device from UnitCatalog —
/// no Firestore, no network. It is a drawer tab for members and admins, and
/// the sign-in screen opens it too ([standalone] = true), so it is there
/// even when the app cannot sign in for lack of internet.
///
/// Built only from the app's own controls: CustomTabs (categories),
/// CustomTextField (value and result), CustomDropdown (units) and
/// customButton (swap).

import 'dart:math' as math;

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
import 'package:asec/generated/l10n.dart';
import 'package:asec/core/helper/main_helper/format_helper.dart';
import 'package:asec/core/custom/114-app_messenger.dart';

class UnitConverterPage extends StatefulWidget {
  const UnitConverterPage({super.key, this.standalone = false});

  /// Opened on its own (from the sign-in screen): gets its own app bar.
  final bool standalone;

  @override
  State<UnitConverterPage> createState() => _UnitConverterPageState();
}

class _UnitConverterPageState extends State<UnitConverterPage> {
  final TextEditingController _input = TextEditingController(text: '1');

  /// The answer, shown in a read-only CustomTextField. Updated by
  /// [_recompute] after every change — never during build.
  final TextEditingController _result = TextEditingController();

  int _category = 0;
  late int _from = UnitCatalog.converter[0].defaultFrom;
  late int _to = UnitCatalog.converter[0].defaultTo;

  UnitCategory get _cat => UnitCatalog.converter[_category];

  @override
  void initState() {
    super.initState();
    _recompute();
  }

  @override
  void dispose() {
    _input.dispose();
    _result.dispose();
    super.dispose();
  }

  void _recompute() {
    final double? v = _value;
    _result.text = v == null
        ? ''
        : format(UnitCategory.convert(v, _cat.units[_from], _cat.units[_to]));
  }

  void _update(VoidCallback change) {
    setState(change);
    _recompute();
  }

  void _pickCategory(int index) {
    if (index == _category) return;
    _update(() {
      _category = index;
      _from = _cat.defaultFrom;
      _to = _cat.defaultTo;
    });
  }

  void _swap() => _update(() {
        final int t = _from;
        _from = _to;
        _to = t;
      });

  /// Accepts Arabic-Indic digits and a comma or Arabic decimal separator.
  double? get _value {
    const String arabic = '٠١٢٣٤٥٦٧٨٩';
    final StringBuffer b = StringBuffer();
    for (final String ch in _input.text.trim().split('')) {
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

  /// ROUNDED FOR READING, not for a lab: everything shows at most 2 decimals
  /// (03/11/2026). A value so small it would round to 0 keeps 3
  /// significant digits instead (1 W = 0.000284 TR, not 0), and huge ones go
  /// to scientific notation. Trailing zeros are dropped (2.50 → 2.5).
  static String format(double v, {int decimals = 2}) {
    if (v.isNaN || v.isInfinite) return '—';
    if (v == 0) return '0';
    final double a = v.abs();
    if (a >= 1e12) return _trimExp(v.toStringAsExponential(decimals));
    final double smallest = 0.5 / math.pow(10, decimals);
    if (a < smallest) {
      final String p = v.toStringAsPrecision(3);
      return p.contains('e') ? _trimExp(p) : _trimZeros(p);
    }
    return _trimZeros(v.toStringAsFixed(decimals));
  }

  static String _trimZeros(String s) => s.contains('.')
      ? s.replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '')
      : s;

  static String _trimExp(String s) => s.replaceFirst(RegExp(r'\.?0+e'), 'e');

  /// "≈" when either unit is a rounded convention (electric hp), else "=".
  static String relation(UnitDef a, UnitDef b) =>
      a.approx || b.approx ? '≈' : '=';

  void _copy(String text) {
    Clipboard.setData(ClipboardData(text: text));
    AppMessenger.of(context)
      ..hide()
      ..show(AppMessage(
        content: Text(FormatHelper.capitalize(S.of(context).copiedValue(text))),
        duration: const Duration(seconds: 2),
      ));
  }

  @override
  Widget build(BuildContext context) {
    final S s = S.of(context);
    final bool ar = Localizations.localeOf(context).languageCode == 'ar';

    final Widget body = LayoutBuilder(
      builder: (BuildContext context, BoxConstraints c) {
        final bool wide = c.maxWidth >= 900;
        final Widget converter = _ConverterCard(
          category: _cat,
          arabic: ar,
          input: _input,
          result: _result,
          from: _from,
          to: _to,
          onInput: () => _update(() {}),
          onFrom: (int i) => _update(() => _from = i),
          onTo: (int i) => _update(() => _to = i),
          onSwap: _swap,
          onCopy: _copy,
        );
        final Widget table = _AllConversions(
          category: _cat,
          arabic: ar,
          value: _value,
          from: _from,
          to: _to,
          onPick: (int i) => _update(() => _to = i),
          onCopy: _copy,
        );

        return SingleChildScrollView(
          padding: EdgeInsets.only(bottom: 24.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              CustomTabs(
                tabs: <String>[for (final UnitCategory cat in UnitCatalog.converter) cat.name(ar)],
                selectedValue: _category,
                onChanged: _pickCategory,
                spacing: 24.sp,
                textStyle: StyleText.fontSize16Weight500,
              ),
              SizedBox(height: 16.h),
              if (wide)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(flex: 5, child: converter),
                    SizedBox(width: 16.w),
                    Expanded(flex: 4, child: table),
                  ],
                )
              else ...<Widget>[
                converter,
                SizedBox(height: 16.h),
                table,
              ],
            ],
          ),
        );
      },
    );

    if (!widget.standalone) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: ConsolePage(
          title: s.unitConverter,
          subtitle: s.unitConverterSub,
          child: body,
        ),
      );
    }
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(FormatHelper.capitalize(s.unitConverter), style: StyleText.fontSize18Weight600),
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          child: body,
        ),
      ),
    );
  }
}

class _ConverterCard extends StatelessWidget {
  const _ConverterCard({
    required this.category,
    required this.arabic,
    required this.input,
    required this.result,
    required this.from,
    required this.to,
    required this.onInput,
    required this.onFrom,
    required this.onTo,
    required this.onSwap,
    required this.onCopy,
  });

  final UnitCategory category;
  final bool arabic;
  final TextEditingController input;
  final TextEditingController result;
  final int from;
  final int to;
  final VoidCallback onInput;
  final ValueChanged<int> onFrom;
  final ValueChanged<int> onTo;
  final VoidCallback onSwap;
  final ValueChanged<String> onCopy;

  @override
  Widget build(BuildContext context) {
    final S s = S.of(context);
    final UnitDef f = category.units[from];
    final UnitDef t = category.units[to];
    final String oneText =
        _UnitConverterPageState.format(UnitCategory.convert(1, f, t), decimals: 2);

    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(category.icon, color: AppColors.primary, size: 22),
              SizedBox(width: 8.w),
              Text(FormatHelper.capitalize(category.name(arabic)),
                  style: StyleText.fontSize18Weight600.copyWith(color: AppColors.text)),
            ],
          ),
          SizedBox(height: 16.h),
          CustomTextField(
            controller: input,
            label: s.unitFrom,
            hint: s.unitValue,
            keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
            textDirection: TextDirection.ltr,
            onChanged: (_) => onInput(),
          ),
          SizedBox(height: 8.h),
          _UnitDropdown(units: category.units, arabic: arabic, value: from, onChanged: onFrom),
          SizedBox(height: 12.h),
          Center(
            child: customButton(
              title: '⇅  ${s.swapUnits}',
              function: onSwap,
              wrapContent: true,
            ),
          ),
          SizedBox(height: 12.h),
          CustomTextField(
            controller: result,
            label: s.unitTo,
            readOnly: true,
            textDirection: TextDirection.ltr,
            valueStyle: StyleText.fontSize18Weight600.copyWith(color: AppColors.primary),
            onTap: () {
              if (result.text.isNotEmpty) onCopy(result.text);
            },
            suffixIcon: IconButton(
              onPressed: () {
                if (result.text.isNotEmpty) onCopy(result.text);
              },
              icon: Icon(Icons.copy_rounded, size: 18, color: AppColors.primary),
            ),
          ),
          SizedBox(height: 8.h),
          _UnitDropdown(units: category.units, arabic: arabic, value: to, onChanged: onTo),
          SizedBox(height: 14.h),
          Text(
            FormatHelper.capitalize('1 ${f.shown} ${_UnitConverterPageState.relation(f, t)} $oneText ${t.shown}'),
            textDirection: TextDirection.ltr,
            textAlign: TextAlign.center,
            style: StyleText.fontSize13Weight500.copyWith(color: AppColors.secondaryText),
          ),
        ],
      ),
    );
  }
}

class _UnitDropdown extends StatelessWidget {
  const _UnitDropdown({
    required this.units,
    required this.arabic,
    required this.value,
    required this.onChanged,
  });

  final List<UnitDef> units;
  final bool arabic;
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return CustomDropdown<int>(
      value: value,
      maxOverlayHeight: 360,
      items: <DropdownItem<int>>[
        for (int i = 0; i < units.length; i++)
          DropdownItem<int>(
            value: i,
            label: '${units[i].name(arabic)}  (${units[i].shown})',
          ),
      ],
      onChanged: onChanged,
    );
  }
}

/// The entered value in every unit of the category — tap a row to make it
/// the "to" unit, long-press to copy.
class _AllConversions extends StatelessWidget {
  const _AllConversions({
    required this.category,
    required this.arabic,
    required this.value,
    required this.from,
    required this.to,
    required this.onPick,
    required this.onCopy,
  });

  final UnitCategory category;
  final bool arabic;
  final double? value;
  final int from;
  final int to;
  final ValueChanged<int> onPick;
  final ValueChanged<String> onCopy;

  @override
  Widget build(BuildContext context) {
    final S s = S.of(context);
    final UnitDef f = category.units[from];
    final double? v = value;

    return Container(
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Padding(
            padding: EdgeInsets.fromLTRB(4.w, 4.h, 4.w, 8.h),
            child: Text(
              FormatHelper.capitalize('${s.allConversions} · ${v == null ? '—' : _UnitConverterPageState.format(v, decimals: 2)} ${f.shown}'),
              style: StyleText.fontSize15Weight600.copyWith(color: AppColors.text),
            ),
          ),
          for (int i = 0; i < category.units.length; i++) _row(i, v),
        ],
      ),
    );
  }

  Widget _row(int i, double? v) {
    final UnitDef u = category.units[i];
    final String text = v == null
        ? '—'
        : _UnitConverterPageState.format(
            UnitCategory.convert(v, category.units[from], u),
            decimals: 2,
          );
    final bool isTo = i == to;
    final bool isFrom = i == from;

    return Material(
      color: isTo ? AppColors.primary.withOpacity(0.08) : Colors.transparent,
      borderRadius: BorderRadius.circular(10.r),
      child: InkWell(
        borderRadius: BorderRadius.circular(10.r),
        onTap: () => onPick(i),
        onLongPress: v == null ? null : () => onCopy(text),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 9.h),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  FormatHelper.capitalize(u.name(arabic)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: StyleText.fontSize13Weight500.copyWith(
                    color: isFrom ? AppColors.secondaryText : AppColors.text,
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              Text(
                FormatHelper.capitalize('${i != from && (u.approx || category.units[from].approx) ? '≈ ' : ''}$text ${u.shown}'),
                textDirection: TextDirection.ltr,
                style: StyleText.fontSize13Weight600.copyWith(
                  color: isTo ? AppColors.primary : AppColors.text,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
