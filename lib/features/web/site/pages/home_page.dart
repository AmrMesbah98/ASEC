/// الرئيسية — the same sections, in the same order, as asecbim.com:
/// hero video · map · counters · خدماتنا · مميزات العمل معنا · سابقة الأعمال ·
/// شركاء النجاح · المدير التنفيذى · أراء العملاء.
///
/// Each section after the hero can be switched off in the panel
/// (site_settings/main → show_*).
library;

import 'package:flutter/material.dart';

import 'package:asec/features/web/core/doc.dart';
import 'package:asec/features/web/core/i18n.dart';
import 'package:asec/features/web/core/theme.dart';
import 'package:asec/features/web/core/widgets.dart';
import 'package:asec/features/web/data/site_repo.dart';
import 'package:asec/features/web/site/site_shell.dart';
import 'package:asec/features/web/site/widgets/cards.dart';
import 'package:asec/features/web/site/site_nav.dart';
import 'package:asec/features/engagement/e1_engagement/presentation/ui/widgets/partners_orbit.dart'
    show PartnerLogoItem;
import 'package:asec/features/engagement/e1_engagement/presentation/ui/widgets/partners_marquee.dart';
import 'package:asec/core/helper/main_helper/format_helper.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return WithSettings(
      builder: (BuildContext context, Doc s) => SitePage(
        cta: false,
        children: <Widget>[
          // The hero video that opened the page was removed (owner's request).
          if (s.b('show_map') && s.s('map_image_url').isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Contained(maxWidth: 1100, child: NetImage(s.s('map_image_url'), fit: BoxFit.contain)),
            ),
          if (s.b('show_counters') && s.maps('counters').isNotEmpty) CountersBand(counters: s.maps('counters')),
          ServicesSection(settings: s),
          if (s.b('show_features')) FeaturesSection(settings: s),
          if (s.b('show_projects')) ProjectsSection(settings: s, limit: 8),
          if (s.b('show_partners')) PartnersSection(settings: s),
          // "من المدونة" removed from the home page (25/10/2026). The
          // articles stay on the Blog page.
          if (s.b('show_ceo')) CeoSection(settings: s),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.child, this.dark = false});

  final Widget child;
  final bool dark;

  @override
  Widget build(BuildContext context) => Container(
        color: dark ? WebColors.black : null,
        padding: EdgeInsets.symmetric(vertical: context.isMobile ? 48 : 72),
        child: Contained(child: child),
      );
}

class ServicesSection extends StatelessWidget {
  const ServicesSection({super.key, required this.settings, this.showIntro = false});

  final Doc settings;
  final bool showIntro;

  @override
  Widget build(BuildContext context) => _Section(
        child: Column(
          children: <Widget>[
            SectionTitle(settings.txt('services_title', const L('خدماتنا', 'Our Services')),
                intro: showIntro ? settings.s('services_intro') : ''),
            const SizedBox(height: 36),
            StreamBuilder<List<Doc>>(
              stream: SiteRepo.published(Coll.services),
              builder: (BuildContext c, AsyncSnapshot<List<Doc>> snap) {
                if (!snap.hasData) return const Loading();
                return GridOf(
                  cols: c.cols(desktop: 3, tablet: 2, mobile: 1),
                  gap: 0,
                  children: <Widget>[for (final Doc d in snap.data!) ServiceCard(doc: d)],
                );
              },
            ),
          ],
        ),
      );
}

class FeaturesSection extends StatelessWidget {
  const FeaturesSection({super.key, required this.settings});

  final Doc settings;

  @override
  Widget build(BuildContext context) => _Section(
        dark: true,
        child: Column(
          children: <Widget>[
            SectionTitle(settings.txt('features_title', const L('مميزات العمل معنا', 'Why Work With Us')),
                intro: settings.s('features_intro'), dark: true),
            const SizedBox(height: 36),
            StreamBuilder<List<Doc>>(
              stream: SiteRepo.published(Coll.features),
              builder: (BuildContext c, AsyncSnapshot<List<Doc>> snap) {
                if (!snap.hasData) return const Loading(height: 120);
                return GridOf(
                  cols: c.cols(desktop: 4, tablet: 4, mobile: 2),
                  children: <Widget>[for (final Doc d in snap.data!) FeatureTile(doc: d)],
                );
              },
            ),
          ],
        ),
      );
}

class ProjectsSection extends StatelessWidget {
  const ProjectsSection({super.key, required this.settings, this.limit});

  final Doc settings;
  final int? limit;

  @override
  Widget build(BuildContext context) => _Section(
        child: Column(
          children: <Widget>[
            SectionTitle(settings.txt('projects_title', const L('سابقة الأعمال', 'Our Work')),
                intro: settings.s('projects_intro')),
            const SizedBox(height: 36),
            StreamBuilder<List<Doc>>(
              stream: SiteRepo.published(Coll.projects),
              builder: (BuildContext c, AsyncSnapshot<List<Doc>> snap) {
                if (!snap.hasData) return const Loading();
                List<Doc> items = snap.data!;
                if (limit != null) {
                  final List<Doc> featured = items.where((Doc d) => d.b('featured', false)).toList();
                  items = (featured.isNotEmpty ? featured : items).take(limit!).toList();
                }
                if (items.isEmpty) return EmptyNote(const L('لا توجد أعمال بعد', 'No projects yet').t);
                return GridOf(
                  cols: c.cols(desktop: 4, tablet: 2, mobile: 1),
                  gap: 14,
                  children: <Widget>[for (final Doc d in items) ProjectCard(doc: d)],
                );
              },
            ),
            if (limit != null) ...<Widget>[
              const SizedBox(height: 28),
              OutlinedButton(
                  onPressed: () => siteGo(context, '/projects'), child: Text(FormatHelper.capitalize(const L('كل الأعمال', 'All projects').t))),
            ],
          ],
        ),
      );
}

class PartnersSection extends StatelessWidget {
  const PartnersSection({super.key, required this.settings});

  final Doc settings;

  @override
  Widget build(BuildContext context) => _Section(
        child: Column(
          children: <Widget>[
            SectionTitle(settings.txt('partners_title', const L('شركاء النجاح', 'Our Partners')),
                intro: settings.s('partners_intro')),
            const SizedBox(height: 36),
            // THE SAME AS THE APP: one row of logos scrolling by itself.
            StreamBuilder<List<Doc>>(
              stream: SiteRepo.published(Coll.partners),
              builder: (BuildContext c, AsyncSnapshot<List<Doc>> snap) {
                if (!snap.hasData) return const Loading(height: 120);
                final List<PartnerLogoItem> items = <PartnerLogoItem>[
                  for (final Doc d in snap.data!)
                    if (d.raw('logo_url').trim().isNotEmpty)
                      PartnerLogoItem(name: d.s('name'), logoUrl: d.raw('logo_url')),
                ];
                if (items.isEmpty) return const SizedBox.shrink();
                return PartnersMarquee(
                  items: items,
                  accent: WebColors.red,
                  cardColor: Colors.white,
                  textColor: const Color(0xFF1F2430),
                );
              },
            ),
          ],
        ),
      );
}

class BlogSection extends StatelessWidget {
  const BlogSection({super.key, required this.settings});

  final Doc settings;

  @override
  Widget build(BuildContext context) => _Section(
        child: Column(
          children: <Widget>[
            SectionTitle(settings.txt('blog_title', const L('من المدونة', 'From the Blog')),
                intro: settings.s('blog_intro')),
            const SizedBox(height: 36),
            StreamBuilder<List<Doc>>(
              stream: SiteRepo.published(Coll.articles, by: SortBy.newest),
              builder: (BuildContext c, AsyncSnapshot<List<Doc>> snap) {
                if (!snap.hasData) return const Loading();
                final List<Doc> items = snap.data!.take(6).toList();
                if (items.isEmpty) return EmptyNote(const L('لا توجد مقالات بعد', 'No articles yet').t);
                return GridOf(
                  cols: c.cols(desktop: 3, tablet: 2, mobile: 1),
                  children: <Widget>[for (final Doc d in items) ArticleCard(doc: d)],
                );
              },
            ),
            const SizedBox(height: 28),
            OutlinedButton(
                onPressed: () => siteGo(context, '/articles'), child: Text(FormatHelper.capitalize(const L('كل المقالات', 'All articles').t))),
          ],
        ),
      );
}

class CeoSection extends StatelessWidget {
  const CeoSection({super.key, required this.settings});

  final Doc settings;

  @override
  Widget build(BuildContext context) => _Section(
        child: Column(
          children: <Widget>[
            ClipOval(child: NetImage(settings.s('ceo_photo_url'), width: 140, height: 140, placeholderIcon: Icons.person)),
            const SizedBox(height: 14),
            Text(FormatHelper.capitalize(settings.txt('ceo_label', const L('المدير التنفيذى', 'Chief Executive Officer'))),
                style: TextStyle(fontWeight: FontWeight.w700, color: WebColors.ink)),
            const SizedBox(height: 4),
            Text(FormatHelper.capitalize(settings.s('ceo_name')),
                style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: WebColors.redBright)),
            const SizedBox(height: 18),
            // 01/11/2026: ONE short line under the name — the firm's name
            // only, no long bio and no "…".
            Text(FormatHelper.capitalize('ASEC Engineering Consultants'),
                maxLines: 1,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 17, height: 1.5, fontWeight: FontWeight.w600, color: WebColors.ink)),
            const SizedBox(height: 22),
            SocialIcons(settings: settings),
          ],
        ),
      );
}

class TestimonialsSection extends StatelessWidget {
  const TestimonialsSection({super.key, required this.settings});

  final Doc settings;

  @override
  Widget build(BuildContext context) => _Section(
        child: Column(
          children: <Widget>[
            SectionTitle(settings.txt('testimonials_title', const L('أراء العملاء', 'What Our Clients Say')),
                intro: settings.s('testimonials_intro')),
            const SizedBox(height: 36),
            StreamBuilder<List<Doc>>(
              stream: SiteRepo.published(Coll.testimonials),
              builder: (BuildContext c, AsyncSnapshot<List<Doc>> snap) {
                if (!snap.hasData) return const Loading(height: 120);
                return GridOf(
                  cols: c.cols(desktop: 3, tablet: 2, mobile: 1),
                  children: <Widget>[for (final Doc d in snap.data!) TestimonialCard(doc: d)],
                );
              },
            ),
          ],
        ),
      );
}
