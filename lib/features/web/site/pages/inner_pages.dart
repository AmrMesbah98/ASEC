/// من نحن · خدماتنا · a service · أعمالنا · a project · تقديم طلب · سياسة الخصوصية
library;

import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';

import 'package:asec/core/custom/111-app_svg_icon.dart';
import 'package:asec/features/web/core/doc.dart';
import 'package:asec/features/web/core/i18n.dart';
import 'package:asec/features/web/core/theme.dart';
import 'package:asec/features/web/core/widgets.dart';
import 'package:asec/features/web/data/site_repo.dart';
import 'package:asec/features/web/site/pages/home_page.dart';
import 'package:asec/features/web/site/site_shell.dart';
import 'package:asec/features/web/site/widgets/cards.dart';
import 'package:asec/features/web/site/site_nav.dart';
import 'package:asec/core/network/shared_stream.dart';

// ── من نحن ───────────────────────────────────────────────────────────────

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) => WithSettings(
        builder: (BuildContext context, Doc s) => SitePage(
          children: <Widget>[
            PageHeader(s.txt('about_title', const L('من نحن', 'About Us')), subtitle: s.s('about_subtitle')),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 56),
              child: Contained(
                maxWidth: 1000,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Text(const L('نبذة عن المكتب', 'About the firm').t,
                        style: const TextStyle(color: WebColors.redBright, fontWeight: FontWeight.w800, fontSize: 16)),
                    const SizedBox(height: 6),
                    Text(s.s('about_heading'),
                        style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: WebColors.navy)),
                    const SizedBox(height: 18),
                    Text(s.s('about_text'), style: const TextStyle(fontSize: 16, height: 2)),
                    if (s.l('team').isNotEmpty) ...<Widget>[
                      const SizedBox(height: 36),
                      Text(const L('يتكون فريقنا من', 'Our team').t,
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: WebColors.navy)),
                      const SizedBox(height: 16),
                      GridOf(
                        cols: context.cols(desktop: 3, tablet: 3, mobile: 2),
                        gap: 12,
                        children: <Widget>[
                          for (final String t in s.l('team'))
                            Container(
                              padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
                              decoration: BoxDecoration(
                                color: WebColors.surface,
                                border: const BorderDirectional(start: BorderSide(color: WebColors.red, width: 4)),
                              ),
                              child: Text(t,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            if (s.b('show_counters') && s.maps('counters').isNotEmpty) CountersBand(counters: s.maps('counters')),
            if (s.b('show_map') && s.s('map_image_url').isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Contained(maxWidth: 1100, child: NetImage(s.s('map_image_url'), fit: BoxFit.contain)),
              ),
          ],
        ),
      );
}

// ── خدماتنا ──────────────────────────────────────────────────────────────

class ServicesPage extends StatelessWidget {
  const ServicesPage({super.key});

  @override
  Widget build(BuildContext context) => WithSettings(
        builder: (BuildContext context, Doc s) => SitePage(
          children: <Widget>[
            PageHeader(s.txt('services_title', const L('خدماتنا', 'Our Services')), subtitle: s.s('services_intro')),
            ServicesSection(settings: s),
            if (s.b('show_features')) FeaturesSection(settings: s),
          ],
        ),
      );
}

class ServiceDetailPage extends StatelessWidget {
  const ServiceDetailPage({super.key, required this.slug});

  final String slug;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Doc>>(
      stream: SiteRepo.published(Coll.services),
      builder: (BuildContext context, AsyncSnapshot<List<Doc>> snap) {
        if (!snap.hasData) return const SitePage(cta: false, children: <Widget>[Loading(height: 400)]);
        final Doc? d = snap.data!.where((Doc x) => x.raw('slug') == slug || x.id == slug).firstOrNull;
        if (d == null) return const NotFoundPage();
        final List<String> points = d.l('points');
        return SitePage(
          children: <Widget>[
            PageHeader(d.s('title'), subtitle: d.s('tagline')),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 56),
              child: Contained(
                maxWidth: 1000,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    if (d.s('image_url').isNotEmpty)
                      AspectRatio(aspectRatio: 21 / 9, child: NetImage(d.s('image_url'), radius: 12)),
                    const SizedBox(height: 28),
                    Text(d.s('body'), style: const TextStyle(fontSize: 16, height: 2.1)),
                    if (points.isNotEmpty) ...<Widget>[
                      const SizedBox(height: 36),
                      Text(const L('اهم النقاط فى هذه الصفحة', 'Key points').t,
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: WebColors.navy)),
                      const SizedBox(height: 16),
                      for (int i = 0; i < points.length; i++)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              CircleAvatar(
                                radius: 15,
                                backgroundColor: WebColors.red,
                                child: Text('${i + 1}',
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                              ),
                              const SizedBox(width: 12),
                              Expanded(child: Text(points[i], style: const TextStyle(fontSize: 15, height: 1.9))),
                            ],
                          ),
                        ),
                    ],
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

// ── أعمالنا ──────────────────────────────────────────────────────────────

class ProjectsPage extends StatefulWidget {
  const ProjectsPage({super.key});

  @override
  State<ProjectsPage> createState() => _ProjectsPageState();
}

class _ProjectsPageState extends State<ProjectsPage> {
  String _cat = '';
  late final Stream<List<Doc>> _stream = shared(() => SiteRepo.published(Coll.projects));

  @override
  Widget build(BuildContext context) => WithSettings(
        builder: (BuildContext context, Doc s) => SitePage(
          children: <Widget>[
            PageHeader(const L('أعمالنا', 'Our Projects').t, subtitle: s.s('projects_intro')),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 48),
              child: Contained(
                child: Column(
                  children: <Widget>[
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: <Widget>[
                        ChoiceChip(
                          label: Text(const L('الكل', 'All').t),
                          selected: _cat.isEmpty,
                          onSelected: (_) => setState(() => _cat = ''),
                        ),
                        for (final MapEntry<String, String> e in kProjectCategories.entries)
                          ChoiceChip(
                            label: Text(e.value),
                            selected: _cat == e.key,
                            onSelected: (_) => setState(() => _cat = e.key),
                          ),
                      ],
                    ),
                    const SizedBox(height: 28),
                    StreamBuilder<List<Doc>>(
                      stream: _stream,
                      builder: (BuildContext c, AsyncSnapshot<List<Doc>> snap) {
                        if (!snap.hasData) return const Loading();
                        final List<Doc> items =
                            snap.data!.where((Doc d) => _cat.isEmpty || d.s('category') == _cat).toList();
                        if (items.isEmpty) return EmptyNote(const L('لا توجد أعمال في هذا القسم', 'No projects in this category').t);
                        return GridOf(
                          cols: c.cols(desktop: 3, tablet: 2, mobile: 1),
                          gap: 16,
                          children: <Widget>[for (final Doc d in items) ProjectCard(doc: d)],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
}

class ProjectDetailPage extends StatelessWidget {
  const ProjectDetailPage({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Doc?>(
      stream: SiteRepo.one(Coll.projects, id),
      builder: (BuildContext context, AsyncSnapshot<Doc?> snap) {
        if (snap.hasError) return const NotFoundPage();
        if (snap.connectionState == ConnectionState.waiting && !snap.hasData) {
          return const SitePage(cta: false, children: <Widget>[Loading(height: 400)]);
        }
        final Doc? d = snap.data;
        if (d == null || !d.b('published')) return const NotFoundPage();
        final List<String> gallery = d.l('gallery');
        final List<(String, String)> info = <(String, String)>[
          (const L('اسم العميل', 'Client').t, d.s('client')),
          (const L('الموقع', 'Location').t, d.s('location')),
          (const L('المساحة', 'Area').t, d.s('area')),
          (const L('التاريخ', 'Date').t, d.s('date')),
        ].where(((String, String) e) => e.$2.isNotEmpty).toList();
        final Widget facts = Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: WebColors.surface, borderRadius: BorderRadius.circular(12)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              for (final (String k, String v) in info) ...<Widget>[
                Text(k, style: TextStyle(color: WebColors.muted, fontSize: 13)),
                Text(v, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                const Divider(height: 22),
              ],
              if (d.l('team').isNotEmpty) ...<Widget>[
                Text(const L('فريق العمل المشارك فيه', 'Project team').t, style: TextStyle(color: WebColors.muted, fontSize: 13)),
                for (final String m in d.l('team'))
                  Text(m, style: const TextStyle(fontWeight: FontWeight.w700, height: 1.8)),
              ],
              if (d.s('download_url').isNotEmpty) ...<Widget>[
                const SizedBox(height: 18),
                ElevatedButton.icon(
                  onPressed: () => openLink(d.s('download_url')),
                  icon: const AppIcon(Icons.download_rounded),
                  label: Text(const L('تحميل ملفات المشروع', 'Download project files').t),
                ),
              ],
            ],
          ),
        );
        final Widget body = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(d.s('description'), style: const TextStyle(fontSize: 16, height: 2.1)),
            if (d.l('role').isNotEmpty) ...<Widget>[
              const SizedBox(height: 26),
              Text(const L('دورنا في المشروع:', 'Our role:').t,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: WebColors.navy)),
              const SizedBox(height: 10),
              for (final String r in d.l('role'))
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const Padding(
                        padding: EdgeInsets.only(top: 6),
                        child: AppIcon(Icons.check_circle_rounded, color: WebColors.red, size: 18),
                      ),
                      const SizedBox(width: 10),
                      Expanded(child: Text(r, style: const TextStyle(fontSize: 15, height: 1.9))),
                    ],
                  ),
                ),
            ],
          ],
        );
        return SitePage(
          children: <Widget>[
            PageHeader(d.s('title'), subtitle: kProjectCategories[d.s('category')] ?? ''),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 48),
              child: Contained(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    if (d.s('cover').isNotEmpty)
                      InkWell(
                        onTap: gallery.isEmpty ? null : () => showImageViewer(context, gallery, 0),
                        child: AspectRatio(aspectRatio: 16 / 8, child: NetImage(d.s('cover'), radius: 12)),
                      ),
                    const SizedBox(height: 32),
                    if (context.isMobile) ...<Widget>[
                      facts,
                      const SizedBox(height: 28),
                      body,
                    ] else
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          SizedBox(width: 320, child: facts),
                          const SizedBox(width: 36),
                          Expanded(child: body),
                        ],
                      ),
                    if (gallery.length > 1) ...<Widget>[
                      const SizedBox(height: 40),
                      SectionTitle(const L('صور المشروع', 'Project gallery').t),
                      const SizedBox(height: 24),
                      GridOf(
                        cols: context.cols(desktop: 4, tablet: 3, mobile: 2),
                        gap: 10,
                        children: <Widget>[
                          for (int i = 0; i < gallery.length; i++)
                            InkWell(
                              onTap: () => showImageViewer(context, gallery, i),
                              child: AspectRatio(aspectRatio: 4 / 3, child: NetImage(gallery[i], radius: 8)),
                            ),
                        ],
                      ),
                    ],
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

// ── تقديم طلب ────────────────────────────────────────────────────────────

class RequestsPage extends StatelessWidget {
  const RequestsPage({super.key});

  @override
  Widget build(BuildContext context) => WithSettings(
        builder: (BuildContext context, Doc s) => SitePage(
          children: <Widget>[
            PageHeader(const L('تقديم طلب', 'Apply').t),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 56),
              child: Contained(
                maxWidth: 900,
                child: Column(
                  children: <Widget>[
                    Text(s.s('requests_text'),
                        textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, height: 2)),
                    const SizedBox(height: 32),
                    GridOf(
                      cols: context.isMobile ? 1 : 2,
                      children: <Widget>[
                        _RequestTile(
                          icon: Icons.design_services_rounded,
                          title: const L('طلب خدمة', 'Request a Service').t,
                          text: const L('اطلب خدمة تصميم أو لوحات تنفيذية أو إشراف على التنفيذ',
                                  'Request design, shop drawings or site supervision')
                              .t,
                          onTap: () => siteGo(context, '/request-service'),
                          enabled: s.b('accept_service_requests'),
                        ),
                        _RequestTile(
                          icon: Icons.work_outline_rounded,
                          title: const L('طلب وظيفة', 'Apply for a Job').t,
                          text: const L('قدّم على وظيفة أو معايشة في أسيك', 'Apply for a job or a training placement at ASEC').t,
                          onTap: () => siteGo(context, '/request-job'),
                          enabled: s.b('accept_job_applications'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
}

class _RequestTile extends StatelessWidget {
  const _RequestTile({
    required this.icon,
    required this.title,
    required this.text,
    required this.onTap,
    required this.enabled,
  });

  final IconData icon;
  final String title;
  final String text;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) => Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: enabled ? onTap : null,
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              children: <Widget>[
                AppIcon(icon, size: 48, color: enabled ? WebColors.red : WebColors.muted),
                const SizedBox(height: 12),
                Text(title, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: WebColors.navy)),
                const SizedBox(height: 6),
                Text(enabled ? text : const L('مغلق حاليًا', 'Currently closed').t,
                    textAlign: TextAlign.center, style: TextStyle(color: WebColors.muted)),
              ],
            ),
          ),
        ),
      );
}

// ── سياسة الخصوصية ──────────────────────────────────────────────────────

class PrivacyPage extends StatelessWidget {
  const PrivacyPage({super.key});

  @override
  Widget build(BuildContext context) => WithSettings(
        builder: (BuildContext context, Doc s) => SitePage(
          cta: false,
          children: <Widget>[
            PageHeader(const L('سياسة الخصوصية', 'Privacy Policy').t),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 48),
              child: Contained(
                maxWidth: 900,
                child: s.s('privacy_html').isEmpty
                    ? EmptyNote(const L('لم تُضف سياسة الخصوصية بعد', 'No privacy policy yet').t)
                    : Directionality(
                        textDirection: s.dirOf('privacy_html'),
                        child: HtmlWidget(s.s('privacy_html'), textStyle: const TextStyle(fontSize: 16, height: 2)),
                      ),
              ),
            ),
          ],
        ),
      );
}

class NotFoundPage extends StatelessWidget {
  const NotFoundPage({super.key});

  @override
  Widget build(BuildContext context) => SitePage(
        cta: false,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 100),
            child: Column(
              children: <Widget>[
                const Text('404', style: TextStyle(fontSize: 72, fontWeight: FontWeight.w800, color: WebColors.red)),
                Text(const L('الصفحة غير موجودة', 'Page not found').t,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
                const SizedBox(height: 20),
                ElevatedButton(onPressed: () => siteGo(context, '/'), child: Text(const L('الرئيسية', 'Home').t)),
              ],
            ),
          ),
        ],
      );
}
