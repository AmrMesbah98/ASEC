/// Cards used across the site: services, projects, articles, partners,
/// testimonials, the counters band, and a simple responsive grid.
library;

import 'package:flutter/material.dart';

import 'package:asec/core/custom/111-app_svg_icon.dart';
import 'package:asec/features/web/core/doc.dart';
import 'package:asec/features/web/core/i18n.dart';
import 'package:asec/features/web/core/theme.dart';
import 'package:asec/features/web/core/widgets.dart';
import 'package:asec/features/web/site/site_nav.dart';
import 'package:asec/features/web/site/widgets/motion.dart';
import 'package:asec/core/helper/main_helper/format_helper.dart';

/// Lays children out in `cols` equal columns that wrap, heights free.
class GridOf extends StatelessWidget {
  const GridOf({super.key, required this.children, required this.cols, this.gap = 20});

  final List<Widget> children;
  final int cols;
  final double gap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints c) {
        final int n = cols < 1 ? 1 : cols;
        final double w = (c.maxWidth - gap * (n - 1)) / n;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: <Widget>[
            // Cards rise one after another across each row.
            for (int i = 0; i < children.length; i++)
              SizedBox(
                width: w,
                child: Reveal(
                  delay: Duration(milliseconds: 90 * (i % n)),
                  offset: 28,
                  child: children[i],
                ),
              ),
          ],
        );
      },
    );
  }
}

class _Hover extends StatefulWidget {
  const _Hover({required this.builder});

  final Widget Function(bool hover) builder;

  @override
  State<_Hover> createState() => _HoverState();
}

class _HoverState extends State<_Hover> {
  bool _h = false;

  @override
  Widget build(BuildContext context) => MouseRegion(
        onEnter: (_) => setState(() => _h = true),
        onExit: (_) => setState(() => _h = false),
        child: widget.builder(_h),
      );
}

// ── Services ─────────────────────────────────────────────────────────────

class ServiceCard extends StatelessWidget {
  const ServiceCard({super.key, required this.doc});

  final Doc doc;

  @override
  Widget build(BuildContext context) {
    return HoverLift(
      builder: (BuildContext context, bool h) => AnimatedContainer(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
        decoration: BoxDecoration(
          color: WebColors.white,
          border: Border.all(color: h ? WebColors.red.withValues(alpha: 0.4) : WebColors.border),
          boxShadow: h
              ? <BoxShadow>[BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 24, offset: const Offset(0, 10))]
              : const <BoxShadow>[],
        ),
        child: Column(
          children: <Widget>[
            ClipOval(
              child: AnimatedScale(
                scale: h ? 1.07 : 1,
                duration: const Duration(milliseconds: 420),
                curve: Curves.easeOutCubic,
                child: NetImage(doc.s('image_url'), width: 150, height: 150),
              ),
            ),
            const SizedBox(height: 18),
            Text(FormatHelper.capitalize(doc.s('title')),
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: WebColors.navy)),
            const SizedBox(height: 8),
            Text(FormatHelper.capitalize(doc.s('tagline')),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: WebColors.redBright)),
            const SizedBox(height: 22),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: WebColors.navy),
              onPressed: () => siteGo(context, '/services/${doc.raw('slug').isEmpty ? doc.id : doc.raw('slug')}'),
              child: Text(FormatHelper.capitalize(const L('المزيد', 'Read more').t)),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Features (مميزات العمل معنا) ─────────────────────────────────────────

class FeatureTile extends StatelessWidget {
  const FeatureTile({super.key, required this.doc});

  final Doc doc;

  @override
  Widget build(BuildContext context) => Column(
        children: <Widget>[
          NetImage(doc.s('icon_url'), width: 72, height: 72, fit: BoxFit.contain),
          const SizedBox(height: 12),
          Text(FormatHelper.capitalize(doc.s('title')),
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800)),
        ],
      );
}

// ── Counters ─────────────────────────────────────────────────────────────

class CountersBand extends StatelessWidget {
  const CountersBand({super.key, required this.counters});

  final List<Map<String, dynamic>> counters;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: WebColors.black,
      padding: const EdgeInsets.symmetric(vertical: 36),
      child: Contained(
        child: GridOf(
          cols: context.isMobile ? 2 : (counters.isEmpty ? 1 : (counters.length > 6 ? 6 : counters.length)),
          children: <Widget>[
            for (final Map<String, dynamic> c in counters)
              Column(
                children: <Widget>[
                  CountUp(
                    value: double.tryParse('${c['value']}') ?? 0,
                    builder: (_, int v) => Text(
                      FormatHelper.capitalize('+$v'),
                      textDirection: TextDirection.ltr,
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: context.isMobile ? 36 : 52,
                          fontWeight: FontWeight.w800,
                          fontFamily: 'Cairo'),
                    ),
                  ),
                  Text(FormatHelper.capitalize(counterLabel(c)),
                      style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700)),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

// ── Projects ─────────────────────────────────────────────────────────────

/// A counter's label in the current language (`label` / `label_en`).
/// 29/10/2026: in English with no `label_en` saved, a known Arabic label
/// (تجاري · صناعي · طبي · سكني) is translated instead of showing Arabic.
String counterLabel(Map<String, dynamic> c) {
  final String ar = '${c['label'] ?? ''}'.trim();
  if (AppLang.isAr) return ar;
  final String en = '${c['label_en'] ?? ''}'.trim();
  if (en.isNotEmpty) return en;
  for (final L name in _projectCategories.values) {
    if (name.ar == ar) return name.en;
  }
  return ar;
}

const Map<String, L> _projectCategories = <String, L>{
  'medical': L('طبي', 'Medical'),
  'residential': L('سكني', 'Residential'),
  'commercial': L('تجاري', 'Commercial'),
  'industrial': L('صناعي', 'Industrial'),
};

/// Project category key → its name in the current language.
Map<String, String> get kProjectCategories => <String, String>{
      for (final MapEntry<String, L> e in _projectCategories.entries) e.key: e.value.t,
    };

class ProjectCard extends StatelessWidget {
  const ProjectCard({super.key, required this.doc});

  final Doc doc;

  @override
  Widget build(BuildContext context) {
    return _Hover(
      builder: (bool h) => InkWell(
        onTap: () => siteGo(context, '/projects/${doc.id}'),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: AspectRatio(
            aspectRatio: 16 / 11,
            child: Stack(
              fit: StackFit.expand,
              children: <Widget>[
                AnimatedScale(
                  scale: h ? 1.08 : 1,
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.easeOutCubic,
                  child: NetImage(doc.s('cover')),
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: <Color>[Colors.transparent, Colors.black.withValues(alpha: h ? 0.85 : 0.7)],
                      stops: const <double>[0.4, 1],
                    ),
                  ),
                ),
                PositionedDirectional(
                  start: 16,
                  end: 16,
                  bottom: 14,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      if (kProjectCategories[doc.s('category')] != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                          margin: const EdgeInsets.only(bottom: 6),
                          decoration: BoxDecoration(color: WebColors.red, borderRadius: BorderRadius.circular(20)),
                          child: Text(FormatHelper.capitalize(kProjectCategories[doc.s('category')]!),
                              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                        ),
                      Text(FormatHelper.capitalize(doc.s('title')),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Articles ─────────────────────────────────────────────────────────────

class ArticleCard extends StatelessWidget {
  const ArticleCard({super.key, required this.doc});

  final Doc doc;

  @override
  Widget build(BuildContext context) {
    return HoverLift(
      builder: (BuildContext context, bool h) => InkWell(
        onTap: () => siteGo(context, '/articles/${doc.id}'),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            color: WebColors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: WebColors.border),
            boxShadow: h
                ? <BoxShadow>[BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 20, offset: const Offset(0, 8))]
                : const <BoxShadow>[],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              AspectRatio(
                aspectRatio: 1024 / 724,
                child: ClipRect(
                  child: AnimatedScale(
                    scale: h ? 1.06 : 1,
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.easeOutCubic,
                    child: NetImage(doc.s('cover')),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    if (doc.s('category').isNotEmpty)
                      Text(FormatHelper.capitalize(doc.s('category')),
                          style: const TextStyle(color: WebColors.blue, fontSize: 12, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text(FormatHelper.capitalize(doc.s('title')),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 17, height: 1.5, fontWeight: FontWeight.w800, color: WebColors.ink)),
                    const SizedBox(height: 8),
                    Row(
                      children: <Widget>[
                        Text(FormatHelper.capitalize(panelDate(doc.t('published_at'))),
                            style: TextStyle(color: WebColors.muted, fontSize: 12)),
                        const Spacer(),
                        Text(FormatHelper.capitalize(const L('المزيد', 'Read more').t),
                            style: const TextStyle(color: WebColors.red, fontWeight: FontWeight.w700, fontSize: 13)),
                        AppIcon(AppLang.isAr ? Icons.chevron_left_rounded : Icons.chevron_right_rounded,
                            color: WebColors.red, size: 18),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Partners & testimonials ──────────────────────────────────────────────

class PartnerLogo extends StatelessWidget {
  const PartnerLogo({super.key, required this.doc});

  final Doc doc;

  @override
  Widget build(BuildContext context) => Tooltip(
        message: doc.s('name'),
        child: SizedBox(
          height: 120,
          child: NetImage(doc.s('logo_url'), fit: BoxFit.contain),
        ),
      );
}

class TestimonialCard extends StatelessWidget {
  const TestimonialCard({super.key, required this.doc});

  final Doc doc;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: WebColors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: WebColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const AppIcon(Icons.format_quote_rounded, color: WebColors.red, size: 30),
            Text(FormatHelper.capitalize(doc.s('name')), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
            Text(FormatHelper.capitalize(doc.s('role')), style: TextStyle(color: WebColors.muted, fontSize: 12)),
            const Divider(height: 22),
            Text(FormatHelper.capitalize(doc.s('quote')), style: TextStyle(height: 1.8, fontSize: 14, color: WebColors.ink)),
          ],
        ),
      );
}

/// Opens a gallery image full screen.
void showImageViewer(BuildContext context, List<String> images, int start) {
  showDialog<void>(
    context: context,
    barrierColor: Colors.black87,
    builder: (BuildContext c) {
      final PageController pc = PageController(initialPage: start);
      return Dialog.fullscreen(
        backgroundColor: Colors.black,
        child: Stack(
          children: <Widget>[
            PageView(
              controller: pc,
              children: <Widget>[
                for (final String u in images)
                  InteractiveViewer(child: Center(child: NetImage(u, fit: BoxFit.contain))),
              ],
            ),
            Positioned(
              top: 12,
              right: 12,
              child: IconButton.filled(
                onPressed: () => Navigator.of(c).pop(),
                icon: const AppIcon(Icons.close_rounded),
              ),
            ),
            if (images.length > 1) ...<Widget>[
              Positioned(
                left: 12,
                top: 0,
                bottom: 0,
                child: Center(
                  child: IconButton.filledTonal(
                    onPressed: () => pc.nextPage(duration: const Duration(milliseconds: 250), curve: Curves.easeOut),
                    icon: const AppIcon(Icons.chevron_left_rounded),
                  ),
                ),
              ),
              Positioned(
                right: 12,
                top: 0,
                bottom: 0,
                child: Center(
                  child: IconButton.filledTonal(
                    onPressed: () => pc.previousPage(duration: const Duration(milliseconds: 250), curve: Curves.easeOut),
                    icon: const AppIcon(Icons.chevron_right_rounded),
                  ),
                ),
              ),
            ],
          ],
        ),
      );
    },
  );
}
