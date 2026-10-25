/// /admin/control — the control centre, on the web.
///
/// Two switchboards:
///   1. THE WEBSITE — sections and forms of this site (site_settings/main).
///   2. THE ASEC APP — exactly the switches of the app's Settings → Control
///      centre, written to the same document (`settings/app`). The app
///      listens to it live, so a switch flipped here reaches every open app
///      within a second. Super admin only (firestore.rules: settings/{doc}
///      write → isSuper()).
///
/// Keys and wording are copied from ASEC/lib/core/settings/app_features.dart
/// and the app's l10n files — keep them in step when a feature is added there.
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'package:asec/core/custom/111-app_svg_icon.dart';
import 'package:asec/features/web/admin/admin_session.dart';
import 'package:asec/features/web/admin/widgets.dart';
import 'package:asec/features/web/core/i18n.dart';
import 'package:asec/features/web/core/theme.dart';
import 'package:asec/features/web/core/widgets.dart';
import 'package:asec/features/web/data/site_repo.dart';
import 'package:asec/core/helper/main_helper/format_helper.dart';

class Switch3 {
  const Switch3(this.key, this.label, this.hint, this.icon, {this.defaultOn = true});

  final String key;
  final L label;
  final L hint;
  final IconData icon;
  final bool defaultOn;
}

class SwitchGroup {
  const SwitchGroup(this.title, this.items);

  final L title;
  final List<Switch3> items;
}

const List<SwitchGroup> kWebsiteSwitches = <SwitchGroup>[
  SwitchGroup(L('أقسام الصفحة الرئيسية', 'Home page sections'), <Switch3>[
    Switch3('show_map', L('الخريطة', 'Map'), L('صورة الدول التي عملنا بها.', 'Where we have worked.'), Icons.public_rounded),
    Switch3('show_counters', L('العدادات', 'Counters'), L('تجاري · صناعي · طبي · سكني.', 'Project counters.'), Icons.numbers_rounded),
    Switch3('show_features', L('مميزات العمل معنا', 'Why us'), L('الشريط الأسود بالأيقونات.', 'The black band with icons.'),
        Icons.star_outline_rounded),
    Switch3('show_projects', L('سابقة الأعمال', 'Projects'), L('شبكة الأعمال المميزة.', 'Featured projects grid.'), Icons.apartment_rounded),
    Switch3('show_partners', L('شركاء النجاح', 'Partners'), L('شعارات الشركاء.', 'Partner logos.'), Icons.handshake_outlined),
    Switch3('show_blog', L('من المدونة', 'From the blog'), L('آخر 6 مقالات.', 'Latest 6 articles.'), Icons.article_outlined),
    Switch3('show_ceo', L('المدير التنفيذي', 'CEO'), L('الصورة والكلمة.', 'Photo and message.'), Icons.person_outline_rounded),
    Switch3('show_testimonials', L('أراء العملاء', 'Testimonials'), L('آراء العملاء في الرئيسية والصفحات.', 'Client quotes.'),
        Icons.format_quote_rounded),
  ]),
  SwitchGroup(L('النماذج والتواصل', 'Forms and contact'), <Switch3>[
    Switch3('accept_messages', L('نموذج تواصل معنا', 'Contact form'), L('استقبال الرسائل.', 'Accept messages.'), Icons.mail_outline_rounded),
    Switch3('accept_service_requests', L('طلب خدمة', 'Service requests'), L('استقبال طلبات الخدمة.', 'Accept service requests.'),
        Icons.design_services_outlined),
    Switch3('accept_job_applications', L('طلب وظيفة', 'Job applications'), L('استقبال طلبات التوظيف.', 'Accept job applications.'),
        Icons.work_outline_rounded),
    Switch3('show_whatsapp_button', L('زر تواصل معانا', 'WhatsApp button'), L('الزر العائم أسفل الصفحة.', 'Floating button.'),
        Icons.chat_outlined),
    Switch3('show_download_button', L('زر تحميل نسخة ويندوز', 'Windows download button'),
        L('الزر المتحرك في الشريط العلوي — يحمّل آخر إصدار ويندوز.', 'The animated button in the top bar — downloads the latest Windows release.'),
        Icons.download_rounded),
  ]),
  SwitchGroup(L('الموقع كله', 'Whole site'), <Switch3>[
    Switch3('maintenance_mode', L('وضع الصيانة', 'Maintenance mode'),
        L('يخفي الموقع ويعرض رسالة الصيانة. لوحة التحكم تعمل كما هي.', 'Hides the site behind the maintenance message. The panel keeps working.'),
        Icons.construction_rounded,
        defaultOn: false),
  ]),
];

const List<SwitchGroup> kAppSwitches = <SwitchGroup>[
  SwitchGroup(L('قائمة الأعضاء', 'Member menu'), <Switch3>[
    Switch3('section_videos', L('الفيديوهات', 'Videos'), L('يرى الأعضاء صفحة الفيديوهات.', 'Members see the Videos page.'),
        Icons.video_library_rounded),
    Switch3('section_quizzes', L('الاختبارات', 'Quizzes'), L('يرى الأعضاء صفحة الاختبارات.', 'Members see the Quizzes page.'),
        Icons.quiz_outlined),
    Switch3('section_cv_directory', L('دليل السير الذاتية', 'CV directory'), L('يتصفح الأعضاء سير الجميع.', "Members can browse everyone's CVs."),
        Icons.assignment_outlined),
    Switch3('section_my_cv', L('سيرتي الذاتية', 'My CV'), L('يرى الأعضاء المسموح لهم نموذج السيرة.', 'Members allowed a CV see the CV form.'),
        Icons.person_outline_rounded),
  ]),
  SwitchGroup(L('دروس الفيديو', 'Video lessons'), <Switch3>[
    Switch3('video_sequential', L('فتح الدروس بالترتيب', 'Unlock lessons in order'),
        L('لا يُفتح الدرس إلا بعد مشاهدة السابق.', 'A lesson opens only after the previous one is watched.'), Icons.lock_rounded),
    Switch3('video_block_skip', L('منع التقديم', 'Block skipping ahead'), L('لا يمكن تجاوز ما لم يُشاهد.', "Members can't jump past what they've watched."),
        Icons.fast_forward_rounded),
    Switch3('video_autoplay', L('تشغيل الدرس التالي تلقائيًا', 'Autoplay next lesson'), L('يبدأ الدرس التالي عند انتهاء الحالي.', 'The next lesson starts when one ends.'),
        Icons.play_circle_outline_rounded),
    Switch3('video_up_next', L('قائمة التالي', 'Up next list'), L('عرض باقي الدروس بجانب المشغّل.', 'Show the other lessons beside the player.'),
        Icons.playlist_play_rounded),
    Switch3('video_options_bar', L('شريط خيارات المشغّل', 'Player options bar'),
        L('تقديم وتكرار وإعادة وصوت وسرعة تحت الفيديو.', 'Skip, loop, restart, volume and speed under the video.'), Icons.tune_rounded),
    Switch3('video_speed', L('سرعة التشغيل', 'Playback speed'), L('يمكن المشاهدة من 0.5x إلى 2x.', 'Members can watch at 0.5x – 2x.'), Icons.speed_rounded),
    Switch3('video_resume', L('استكمال من حيث توقفت', 'Resume where you stopped'),
        L('إعادة فتح الدرس تبدأ من آخر موضع.', 'Reopening a lesson jumps to the last position.'), Icons.history_rounded),
    Switch3('video_search', L('البحث والفلاتر', 'Search and filters'), L('مربع البحث والفلاتر في صفحة الفيديوهات.', 'Search box and filter chips on the Videos page.'),
        Icons.search_rounded),
    Switch3('video_course_progress', L('شريط تقدم الدورة', 'Course progress bar'), L('"شاهدت 3 من 10" في الأعلى.', '"3 of 10 lessons watched" at the top.'),
        Icons.stacked_line_chart_rounded),
  ]),
  SwitchGroup(L('التطبيق كله', 'Whole app'), <Switch3>[
    Switch3('animations', L('الحركات', 'Animations'), L('انتقالات الصفحات وحركات الظهور.', 'Page transitions and entrance animations.'),
        Icons.animation_rounded),
    Switch3('registration', L('التسجيل الجديد', 'New sign-ups'), L('إظهار "تسجيل" في شاشة الدخول.', 'Show "Register" on the sign-in screen.'),
        Icons.person_add_alt_1_rounded),
    Switch3('screen_protection', L('منع لقطات الشاشة', 'Block screenshots'),
        L('تشغيل: لقطات الشاشة وتسجيل الشاشة للتطبيق تظهر سوداء. إيقاف: مسموح.',
            'On: screenshots and screen recordings of the app come out black. Off: allowed.'),
        Icons.lock_outline_rounded),
  ]),
  SwitchGroup(L('لوحة المدير', 'Admin dashboard'), <Switch3>[
    Switch3('dashboard_charts', L('رسوم لوحة المدير', 'Dashboard charts'), L('الرسوم الأربعة تحت الأرقام.', 'The four charts under the numbers.'),
        Icons.bar_chart_rounded),
    Switch3('dashboard_table', L('جدول آخر المحاولات', 'Latest attempts table'), L('الجدول أسفل لوحة المدير.', 'The table at the bottom of the dashboard.'),
        Icons.table_rows_rounded),
  ]),
];

class ControlPage extends StatelessWidget {
  const ControlPage({super.key});

  @override
  Widget build(BuildContext context) {
    final bool isSuper = AdminSession.instance.isSuper;
    return AdminPageFrame(
      title: const L('مركز التحكم', 'Control centre').t,
      icon: Icons.toggle_on_outlined,
      subtitle: const L('شغّل أو أوقف أجزاء الموقع وتطبيق ASEC للجميع. التغيير فوري.',
              'Turn parts of the website and the ASEC app on or off for everybody. Changes apply instantly.')
          .t,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _Board(
            title: const L('الموقع', 'Website').t,
            icon: Icons.language_rounded,
            doc: SiteRepo.settingsDoc,
            groups: kWebsiteSwitches,
            canWrite: true,
          ),
          const SizedBox(height: 24),
          _Board(
            title: const L('تطبيق ASEC', 'ASEC app').t,
            icon: Icons.phone_iphone_rounded,
            doc: SiteRepo.appSettingsDoc,
            groups: kAppSwitches,
            canWrite: isSuper,
            note: isSuper
                ? const L('نفس مفاتيح الإعدادات ← مركز التحكم في التطبيق.', 'Same switches as Settings → Control centre in the app.').t
                : const L('للعرض فقط — المشرف الرئيسي وحده يغيّر إعدادات التطبيق.', 'Read only — only the super admin changes the app.').t,
            allOnButton: isSuper,
          ),
        ],
      ),
    );
  }
}

class _Board extends StatelessWidget {
  const _Board({
    required this.title,
    required this.icon,
    required this.doc,
    required this.groups,
    required this.canWrite,
    this.note,
    this.allOnButton = false,
  });

  final String title;
  final IconData icon;
  final DocumentReference<Map<String, dynamic>> doc;
  final List<SwitchGroup> groups;
  final bool canWrite;
  final String? note;
  final bool allOnButton;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: doc.snapshots(),
          builder: (BuildContext context, AsyncSnapshot<DocumentSnapshot<Map<String, dynamic>>> snap) {
            final Map<String, dynamic> data = snap.data?.data() ?? <String, dynamic>{};
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    AppIcon(icon, color: WebColors.navy),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(FormatHelper.capitalize(title), style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: WebColors.navy)),
                    ),
                    if (allOnButton)
                      TextButton.icon(
                        onPressed: () => guarded(
                          context,
                          () => doc.set(<String, dynamic>{
                            for (final SwitchGroup g in groups)
                              for (final Switch3 s in g.items) s.key: true,
                          }, SetOptions(merge: true)),
                        ),
                        icon: const AppIcon(Icons.done_all_rounded),
                        label: Text(FormatHelper.capitalize(const L('تشغيل الكل', 'Turn all on').t)),
                      ),
                  ],
                ),
                if (note != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(FormatHelper.capitalize(note!), style: TextStyle(color: WebColors.muted, fontSize: 13)),
                  ),
                if (snap.hasError) Padding(padding: const EdgeInsets.only(top: 12), child: ErrorNote(snap.error)),
                if (!snap.hasData && !snap.hasError) const Loading(height: 120),
                if (snap.hasData)
                  for (final SwitchGroup g in groups) ...<Widget>[
                    Padding(
                      padding: const EdgeInsets.only(top: 18, bottom: 4),
                      child: Text(FormatHelper.capitalize(g.title.t), style: TextStyle(fontWeight: FontWeight.w800, color: WebColors.muted)),
                    ),
                    LayoutBuilder(
                      builder: (BuildContext c, BoxConstraints bc) {
                        final int cols = bc.maxWidth > 900 ? 2 : 1;
                        final double w = (bc.maxWidth - 12 * (cols - 1)) / cols;
                        return Wrap(
                          spacing: 12,
                          children: <Widget>[
                            for (final Switch3 s in g.items)
                              SizedBox(
                                width: w,
                                child: SwitchListTile(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                                  secondary: AppIcon(s.icon, color: WebColors.navy),
                                  title: Text(FormatHelper.capitalize(s.label.t), style: const TextStyle(fontWeight: FontWeight.w700)),
                                  subtitle: Text(FormatHelper.capitalize(s.hint.t), style: const TextStyle(fontSize: 12)),
                                  value: data[s.key] is bool ? data[s.key] as bool : s.defaultOn,
                                  onChanged: !canWrite
                                      ? null
                                      : (bool v) => guarded(
                                            context,
                                            () => doc.set(<String, dynamic>{s.key: v}, SetOptions(merge: true)),
                                            done: '${s.label.t}: ${v ? const L('تشغيل', 'on').t : const L('إيقاف', 'off').t}',
                                          ),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                  ],
              ],
            );
          },
        ),
      ),
    );
  }
}
