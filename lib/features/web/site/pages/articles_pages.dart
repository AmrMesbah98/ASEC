/// المقالات — list with category filter, search and pages of 12; one article.
library;

import 'package:asec/core/helper/main_helper/format_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';

import 'package:asec/core/custom/111-app_svg_icon.dart';
import 'package:asec/features/web/core/doc.dart';
import 'package:asec/features/web/core/i18n.dart';
import 'package:asec/features/web/core/theme.dart';
import 'package:asec/features/web/core/widgets.dart';
import 'package:asec/features/web/data/site_repo.dart';
import 'package:asec/features/web/site/pages/inner_pages.dart';
import 'package:asec/features/web/site/site_shell.dart';
import 'package:asec/features/web/site/widgets/cards.dart';
import 'package:asec/core/network/shared_stream.dart';

class ArticlesPage extends StatefulWidget {
  const ArticlesPage({super.key});

  @override
  State<ArticlesPage> createState() => _ArticlesPageState();
}

class _ArticlesPageState extends State<ArticlesPage> {
  static const int _perPage = 12;

  late final Stream<List<Doc>> _stream = shared(() => SiteRepo.published(Coll.articles, by: SortBy.newest));
  String _cat = '';
  String _q = '';
  int _page = 0;

  @override
  Widget build(BuildContext context) {
    return SitePage(
      children: <Widget>[
        PageHeader(const L('الأخبار والمقالات', 'News & Articles').t, subtitle: const L('صفحة: المقالات', 'Page: Articles').t),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 44),
          child: Contained(
            child: StreamBuilder<List<Doc>>(
              stream: _stream,
              builder: (BuildContext context, AsyncSnapshot<List<Doc>> snap) {
                if (!snap.hasData) return const Loading(height: 400);
                final List<Doc> all = snap.data!;
                final List<String> cats = <String>{
                  for (final Doc d in all)
                    if (d.s('category').isNotEmpty) d.s('category'),
                }.toList();
                final String q = _q.trim().toLowerCase();
                final List<Doc> items = all
                    .where((Doc d) => _cat.isEmpty || d.s('category') == _cat)
                    .where((Doc d) => q.isEmpty || d.s('title').toLowerCase().contains(q))
                    .toList();
                final int pages = (items.length / _perPage).ceil();
                final int page = pages == 0 ? 0 : (_page >= pages ? pages - 1 : _page);
                final List<Doc> shown = items.skip(page * _perPage).take(_perPage).toList();
                return Column(
                  children: <Widget>[
                    SizedBox(
                      width: 420,
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: const L('ابحث في المقالات', 'Search articles').t,
                          prefixIcon: const AppIcon(Icons.search_rounded),
                        ),
                        onChanged: (String v) => setState(() {
                          _q = v;
                          _page = 0;
                        }),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: <Widget>[
                        ChoiceChip(
                          label: Text(FormatHelper.capitalize(const L('الكل', 'All').t)),
                          selected: _cat.isEmpty,
                          onSelected: (_) => setState(() {
                            _cat = '';
                            _page = 0;
                          }),
                        ),
                        for (final String c in cats)
                          ChoiceChip(
                            label: Text(FormatHelper.capitalize(c)),
                            selected: _cat == c,
                            onSelected: (_) => setState(() {
                              _cat = c;
                              _page = 0;
                            }),
                          ),
                      ],
                    ),
                    const SizedBox(height: 28),
                    if (shown.isEmpty)
                      EmptyNote(const L('لا توجد مقالات', 'No articles found').t)
                    else
                      GridOf(
                        cols: context.cols(desktop: 3, tablet: 2, mobile: 1),
                        children: <Widget>[for (final Doc d in shown) ArticleCard(doc: d)],
                      ),
                    if (pages > 1) ...<Widget>[
                      const SizedBox(height: 28),
                      Wrap(
                        spacing: 6,
                        alignment: WrapAlignment.center,
                        children: <Widget>[
                          for (int i = 0; i < pages; i++)
                            SizedBox(
                              width: 42,
                              height: 42,
                              child: i == page
                                  ? FilledButton(
                                      style: FilledButton.styleFrom(padding: EdgeInsets.zero),
                                      onPressed: () {},
                                      child: Text(FormatHelper.capitalize('${i + 1}')),
                                    )
                                  : OutlinedButton(
                                      style: OutlinedButton.styleFrom(padding: EdgeInsets.zero),
                                      onPressed: () => setState(() => _page = i),
                                      child: Text(FormatHelper.capitalize('${i + 1}')),
                                    ),
                            ),
                        ],
                      ),
                    ],
                  ],
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class ArticleDetailPage extends StatelessWidget {
  const ArticleDetailPage({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Doc?>(
      stream: SiteRepo.one(Coll.articles, id),
      builder: (BuildContext context, AsyncSnapshot<Doc?> snap) {
        if (snap.hasError) return const NotFoundPage();
        if (snap.connectionState == ConnectionState.waiting && !snap.hasData) {
          return const SitePage(cta: false, children: <Widget>[Loading(height: 400)]);
        }
        final Doc? d = snap.data;
        if (d == null || !d.b('published')) return const NotFoundPage();
        return SitePage(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 44),
              child: Contained(
                maxWidth: 880,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    if (d.s('category').isNotEmpty)
                      Text(FormatHelper.capitalize(d.s('category')),
                          style: const TextStyle(color: WebColors.blue, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    Text(FormatHelper.capitalize(d.s('title')),
                        textDirection: d.dirOf('title'),
                        style: TextStyle(
                          fontSize: context.isMobile ? 26 : 36,
                          height: 1.5,
                          fontWeight: FontWeight.w800,
                          color: WebColors.navy,
                        )),
                    const SizedBox(height: 8),
                    Text(FormatHelper.capitalize(panelDate(d.t('published_at'))), style: TextStyle(color: WebColors.muted)),
                    const SizedBox(height: 22),
                    if (d.s('cover').isNotEmpty) NetImage(d.s('cover'), radius: 12, fit: BoxFit.contain),
                    const SizedBox(height: 26),
                    if (!AppLang.isAr && !d.hasEn('body_html'))
                      Container(
                        margin: const EdgeInsets.only(bottom: 20),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(color: WebColors.surface, borderRadius: BorderRadius.circular(8)),
                        child: Row(
                          children: <Widget>[
                            const AppIcon(Icons.translate_rounded, size: 18, color: WebColors.blue),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(FormatHelper.capitalize('This article is available in Arabic only.'),
                                  style: TextStyle(color: WebColors.muted, fontWeight: FontWeight.w600)),
                            ),
                          ],
                        ),
                      ),
                    SelectionArea(child: Directionality(
                      textDirection: d.dirOf('body_html'),
                      child: HtmlWidget(
                      d.s('body_html'),
                      textStyle: TextStyle(fontSize: 17, height: 2, color: WebColors.ink),
                      onTapUrl: (String url) {
                        openLink(url);
                        return true;
                      },
                      customWidgetBuilder: (element) {
                        if (element.localName == 'img') {
                          final String src = element.attributes['src'] ?? '';
                          if (src.isEmpty) return null;
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: NetImage(src, fit: BoxFit.contain, radius: 8),
                          );
                        }
                        return null;
                      },
                    ))),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
