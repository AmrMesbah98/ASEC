/// Module: engagement / e1_engagement
///
///*************************** FILE INFO ****************************///
/// File Name: office_previews.dart
/// Purpose: Declares the in-app previews for Office files:
///          `ExcelPreview` (the sheets as a table, one tab per sheet),
///          `WordPreview` (the document as a page) and `SlidesPreview`
///          (each slide as a card). Read by OfficeReader.
/// Author: ASEC team
/// Created: 08/11/2026

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:asec/core/custom/110-app_widgets.dart';
import 'package:asec/core/custom/9-filter_tab_with_container.dart';
import 'package:asec/core/theme/app_colors.dart';
import 'package:asec/core/theme/app_theme.dart';
import 'package:asec/features/engagement/e1_engagement/data/office/office_reader.dart';
import 'package:asec/generated/l10n.dart';

/// English or Arabic, by the app's language.
String _tr(BuildContext context, String en, String ar) =>
    Localizations.localeOf(context).languageCode == 'ar' ? ar : en;


/// Loads [load] once and draws [builder]; a retry on failure.
class _Loader<T> extends StatefulWidget {
  const _Loader({required this.load, required this.builder});

  final Future<T> Function() load;
  final Widget Function(BuildContext context, T data) builder;

  @override
  State<_Loader<T>> createState() => _LoaderState<T>();
}

class _LoaderState<T> extends State<_Loader<T>> {
  late Future<T> _future = widget.load();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<T>(
      future: _future,
      builder: (BuildContext context, AsyncSnapshot<T> snap) {
        if (snap.hasError) {
          debugPrint('🔴 [office] preview failed: ${snap.error}');
          return Center(
            child: AppErrorView(
              message: S.of(context).fvLoadFailed,
              error: snap.error,
              stackTrace: snap.stackTrace,
              onRetry: () => setState(() => _future = widget.load()),
            ),
          );
        }
        if (!snap.hasData) return const AppLoading();
        return widget.builder(context, snap.data as T);
      },
    );
  }
}

// ── Excel ───────────────────────────────────────────────────────────────────

class ExcelPreview extends StatelessWidget {
  const ExcelPreview({super.key, required this.url});

  final String url;

  @override
  Widget build(BuildContext context) => _Loader<List<OfficeSheet>>(
        load: () => OfficeReader.excel(url),
        builder: (BuildContext context, List<OfficeSheet> sheets) => _Workbook(sheets: sheets),
      );
}

class _Workbook extends StatefulWidget {
  const _Workbook({required this.sheets});

  final List<OfficeSheet> sheets;

  @override
  State<_Workbook> createState() => _WorkbookState();
}

class _WorkbookState extends State<_Workbook> {
  int _sheet = 0;

  @override
  Widget build(BuildContext context) {
    if (widget.sheets.isEmpty) return const _Empty();
    final OfficeSheet sheet = widget.sheets[_sheet];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (widget.sheets.length > 1)
          Padding(
            padding: EdgeInsets.fromLTRB(12.w, 12.h, 12.w, 4.h),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: CustomSegmentedTabs(
                tabs: <String>[for (final OfficeSheet s in widget.sheets) s.name],
                selectedIndex: _sheet,
                onTabSelected: (int i) => setState(() => _sheet = i),
              ),
            ),
          ),
        Expanded(
          child: sheet.rows.isEmpty
              ? const _Empty()
              : _SheetTable(key: ValueKey<int>(_sheet), sheet: sheet),
        ),
        if (sheet.truncated)
          Padding(
            padding: EdgeInsets.all(8.r),
            child: Text(
              'Showing the first ${OfficeReader.maxRows} rows and ${OfficeReader.maxColumns} columns',
              textAlign: TextAlign.center,
              style: StyleText.fontSize11Weight400.copyWith(color: AppColors.secondaryText),
            ),
          ),
      ],
    );
  }
}

/// The sheet as a table: column letters on top, row numbers at the side,
/// the first row bold (usually the headings). No grid lines — rows are
/// told apart by their colour.
class _SheetTable extends StatefulWidget {
  const _SheetTable({super.key, required this.sheet});

  final OfficeSheet sheet;

  @override
  State<_SheetTable> createState() => _SheetTableState();
}

class _SheetTableState extends State<_SheetTable> {
  final ScrollController _h = ScrollController();
  final ScrollController _v = ScrollController();

  static const double _cellW = 150;
  static const double _numW = 48;
  static const double _rowH = 36;

  @override
  void dispose() {
    _h.dispose();
    _v.dispose();
    super.dispose();
  }

  static String _letters(int i) {
    String s = '';
    int n = i + 1;
    while (n > 0) {
      final int r = (n - 1) % 26;
      s = String.fromCharCode(65 + r) + s;
      n = (n - 1) ~/ 26;
    }
    return s;
  }

  Widget _cell(String text, {required double width, TextStyle? style, Alignment align = Alignment.centerLeft}) {
    return SizedBox(
      width: width,
      height: _rowH,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Align(
          alignment: align,
          child: Tooltip(
            message: text.length > 18 ? text : '',
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: style ?? StyleText.fontSize13Weight400.copyWith(color: AppColors.text),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final OfficeSheet sheet = widget.sheet;
    final int cols = sheet.columnCount.clamp(1, OfficeReader.maxColumns);
    final double width = _numW + cols * _cellW;
    final TextStyle head = StyleText.fontSize12Weight600.copyWith(color: AppColors.primary);
    final TextStyle num = StyleText.fontSize11Weight500.copyWith(color: AppColors.secondaryText);

    return Scrollbar(
      controller: _h,
      thumbVisibility: true,
      notificationPredicate: (ScrollNotification n) => n.depth == 0,
      child: SingleChildScrollView(
        controller: _h,
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: width,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // A, B, C …
              Container(
                color: AppColors.primary.withOpacity(0.12),
                child: Row(
                  children: <Widget>[
                    _cell('', width: _numW),
                    for (int c = 0; c < cols; c++)
                      _cell(_letters(c), width: _cellW, style: head, align: Alignment.center),
                  ],
                ),
              ),
              Expanded(
                child: Scrollbar(
                  controller: _v,
                  thumbVisibility: true,
                  child: ListView.builder(
                    controller: _v,
                    itemCount: sheet.rows.length,
                    itemExtent: _rowH,
                    itemBuilder: (BuildContext context, int r) {
                      final List<String> row = sheet.rows[r];
                      final bool first = r == 0;
                      return ColoredBox(
                        color: first
                            ? AppColors.primary.withOpacity(0.06)
                            : r.isEven
                                ? AppColors.card
                                : AppColors.text.withOpacity(0.035),
                        child: Row(
                          children: <Widget>[
                            _cell('${r + 1}', width: _numW, style: num, align: Alignment.center),
                            for (int c = 0; c < cols; c++)
                              _cell(
                                c < row.length ? row[c] : '',
                                width: _cellW,
                                style: first
                                    ? StyleText.fontSize13Weight600.copyWith(color: AppColors.text)
                                    : null,
                                align: c < row.length && double.tryParse(row[c]) != null
                                    ? Alignment.centerRight
                                    : Alignment.centerLeft,
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Word ────────────────────────────────────────────────────────────────────

class WordPreview extends StatelessWidget {
  const WordPreview({super.key, required this.url});

  final String url;

  @override
  Widget build(BuildContext context) => _Loader<List<OfficeParagraph>>(
        load: () => OfficeReader.word(url),
        builder: (BuildContext context, List<OfficeParagraph> paras) {
          if (paras.every((OfficeParagraph p) => p.text.trim().isEmpty)) return const _Empty();
          // A white page, like the document itself.
          return Scrollbar(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(vertical: 24.h, horizontal: 16.w),
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 820),
                  padding: const EdgeInsets.symmetric(horizontal: 56, vertical: 48),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: <BoxShadow>[
                      BoxShadow(color: Colors.black.withOpacity(0.25), blurRadius: 18, offset: const Offset(0, 6)),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      for (final OfficeParagraph p in paras) _paragraph(p),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      );

  Widget _paragraph(OfficeParagraph p) {
    const Color ink = Color(0xFF1F2937);
    if (p.text.trim().isEmpty) return const SizedBox(height: 10);
    final TextStyle style = switch (p.heading) {
      1 => StyleText.fontSize19Weight600.copyWith(color: const Color(0xFF1E3A8A), fontSize: 24, height: 1.3),
      2 => StyleText.fontSize18Weight600.copyWith(color: const Color(0xFF1E40AF), height: 1.35),
      3 => StyleText.fontSize16Weight600.copyWith(color: const Color(0xFF1E40AF), height: 1.4),
      _ => StyleText.fontSize14Weight400.copyWith(color: ink, height: 1.6),
    };
    final Widget text = SelectableText(p.text, style: style);
    return Padding(
      padding: EdgeInsets.only(top: p.heading > 0 ? 14 : 2, bottom: p.heading > 0 ? 6 : 4),
      child: p.bullet && p.heading == 0
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Padding(
                  padding: EdgeInsets.only(top: 9, right: 10, left: 6),
                  child: CircleAvatar(radius: 2.5, backgroundColor: ink),
                ),
                Expanded(child: text),
              ],
            )
          : text,
    );
  }
}

// ── PowerPoint ──────────────────────────────────────────────────────────────

class SlidesPreview extends StatelessWidget {
  const SlidesPreview({super.key, required this.url});

  final String url;

  static const List<List<Color>> _themes = <List<Color>>[
    <Color>[Color(0xFFF97316), Color(0xFFC2410C)],
    <Color>[Color(0xFF334155), Color(0xFF0F172A)],
  ];

  @override
  Widget build(BuildContext context) => _Loader<List<OfficeSlide>>(
        load: () => OfficeReader.slides(url),
        builder: (BuildContext context, List<OfficeSlide> slides) {
          if (slides.isEmpty) return const _Empty();
          return Scrollbar(
            child: ListView.separated(
              padding: EdgeInsets.symmetric(vertical: 20.h, horizontal: 20.w),
              itemCount: slides.length,
              separatorBuilder: (_, __) => SizedBox(height: 18.h),
              itemBuilder: (BuildContext context, int i) {
                final OfficeSlide slide = slides[i];
                final List<Color> theme = _themes[i == 0 ? 0 : 1];
                return Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 820),
                    child: AspectRatio(
                      aspectRatio: 16 / 9,
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(36, 28, 36, 20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: theme,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: <BoxShadow>[
                            BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 6)),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              slide.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: StyleText.fontSize19Weight600.copyWith(
                                color: Colors.white,
                                fontSize: i == 0 ? 30 : 22,
                                height: 1.25,
                              ),
                            ),
                            const SizedBox(height: 14),
                            Expanded(
                              child: ClipRect(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    for (final String line in slide.lines)
                                      Padding(
                                        padding: const EdgeInsets.only(bottom: 8),
                                        child: Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: <Widget>[
                                            Padding(
                                              padding: const EdgeInsets.only(top: 7, right: 10),
                                              child: CircleAvatar(
                                                radius: 3,
                                                backgroundColor: Colors.white.withOpacity(0.8),
                                              ),
                                            ),
                                            Expanded(
                                              child: Text(
                                                line,
                                                style: StyleText.fontSize15Weight400.copyWith(
                                                  color: Colors.white.withOpacity(0.92),
                                                  height: 1.4,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                            Align(
                              alignment: Alignment.bottomRight,
                              child: Text(
                                '${i + 1} / ${slides.length}',
                                style: StyleText.fontSize12Weight600.copyWith(color: Colors.white.withOpacity(0.7)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      );
}

class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) =>
      Center(child: AppEmptyView(title: _tr(context, "This file type can't be shown inside the app", 'لا يمكن عرض هذا النوع من الملفات داخل التطبيق'), size: 100));
}
