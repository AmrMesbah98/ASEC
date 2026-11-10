/// Module: user / u2_home
///
///*************************** FILE INFO ****************************///
/// File Name: engineering_services.dart
/// Purpose: Declares the member home's ENGINEERING SERVICES — the
///          `ServicesSection` shown right above the Library on every
///          platform (phone, tablet, desktop, web), and the
///          `ServiceDetailsPage` a service opens.
///
///          The four services, in this order:
///            1. Design Review           — charged per hour
///            2. Engineering Design      — charged per hour
///            3. Engineering Calculations — charged per hour
///            4. Site Supervision        — charged per visit
///
///          No price is shown in the app. "Book this service" opens a
///          WhatsApp chat with ASEC (01080601010) with the service's name
///          already written in the message.
/// Author: ASEC team
/// Created: 06/11/2026

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:asec/core/animation/app_animations.dart';
import 'package:asec/core/custom/111-app_svg_icon.dart';
import 'package:asec/core/theme/app_colors.dart';
import 'package:asec/core/theme/app_padding.dart';
import 'package:asec/core/theme/app_theme.dart';
import 'package:asec/features/user/u1_shell/presentation/ui/widgets/member_links.dart';

// ── Data ────────────────────────────────────────────────────────────────────

/// A text in both languages.
class _Bi {
  const _Bi(this.ar, this.en);

  final String ar;
  final String en;

  /// The text in the app's language — Arabic in Arabic mode, English in
  /// English mode, never both (09/11/2026).
  String main(BuildContext context) => _isArabic(context) ? ar : en;
}

bool _isArabic(BuildContext context) =>
    Localizations.localeOf(context).languageCode == 'ar';

/// How a service is charged. The amount itself is never shown.
enum ServiceBilling { perHour, perVisit }

class EngineeringService {
  const EngineeringService({
    required this.id,
    required this.icon,
    required this.name,
    required this.intro,
    required this.includes,
    required this.billing,
  });

  final String id;
  final IconData icon;
  final _Bi name;
  final _Bi intro;
  final List<_Bi> includes;
  final ServiceBilling billing;
}

abstract final class EngineeringServices {
  const EngineeringServices._();

  /// ASEC's WhatsApp, international form of 01080601010 (Egypt, +20).
  static const String whatsappNumber = '201080601010';

  /// The services, in the order they are shown.
  static const List<EngineeringService> all = <EngineeringService>[
    EngineeringService(
      id: 'design_review',
      icon: Icons.manage_search_rounded,
      name: _Bi('مراجعة التصميم', 'Design Review'),
      intro: _Bi(
        'مراجعة رسومات ومستندات تصميم أنظمة MEP وتشمل:',
        'A review of MEP drawings and design documents, including:',
      ),
      includes: <_Bi>[
        _Bi('مراجعة المطابقة للأكواد والمواصفات', 'Code & Specification Compliance Review'),
        _Bi('التنسيق بين الأنظمة واكتشاف التعارضات', 'Coordination & Clash Check Between Systems'),
        _Bi('تقرير ملاحظات مفصل بالتوصيات', 'Detailed Comments Report With Recommendations'),
      ],
      billing: ServiceBilling.perHour,
    ),
    EngineeringService(
      id: 'engineering_design',
      icon: Icons.design_services_rounded,
      name: _Bi('إعداد التصميمات', 'Engineering Design'),
      intro: _Bi(
        'إعداد التصميم الكامل لأنظمة MEP ويشمل:',
        'Complete design of MEP systems, including:',
      ),
      includes: <_Bi>[
        _Bi('تصميم أنظمة التكييف والتهوية', 'HVAC & Ventilation Design'),
        _Bi('تصميم أنظمة الصحي ومكافحة الحريق', 'Plumbing & Fire Fighting Design'),
        _Bi('الرسومات التنفيذية وجداول الكميات', 'Shop Drawings & Bill of Quantities'),
      ],
      billing: ServiceBilling.perHour,
    ),
    EngineeringService(
      id: 'engineering_calculations',
      icon: Icons.calculate_rounded,
      name: _Bi('الحسابات الهندسية', 'Engineering Calculations'),
      intro: _Bi(
        'إعداد ومراجعة الحسابات الهندسية وتشمل:',
        'Preparing and checking engineering calculations, including:',
      ),
      includes: <_Bi>[
        _Bi('الحسابات الهيدروليكية', 'Hydraulic Calculations'),
        _Bi('حسابات الأحمال الحرارية (تبريد وتدفئة)', 'Cooling & Heating Load Calculations'),
        _Bi('تحديد واختيار المعدات المناسبة', 'Equipment Sizing & Selection'),
      ],
      billing: ServiceBilling.perHour,
    ),
    EngineeringService(
      id: 'site_supervision',
      icon: Icons.engineering_rounded,
      name: _Bi('الإشراف على التنفيذ', 'Site Supervision'),
      intro: _Bi(
        'زيارات ميدانية لمتابعة تنفيذ الأعمال وتشمل:',
        'Site visits to follow the works on site, including:',
      ),
      includes: <_Bi>[
        _Bi('متابعة التنفيذ مطابقًا للرسومات المعتمدة', 'Follow-Up Against the Approved Drawings'),
        _Bi('الاختبارات والتشغيل والاستلام', 'Testing, Commissioning & Handover'),
        _Bi('تقرير بعد كل زيارة', 'A Report After Every Visit'),
      ],
      billing: ServiceBilling.perVisit,
    ),
  ];

  /// Opens a WhatsApp chat with ASEC, the service's name already written.
  static Future<void> book(BuildContext context, EngineeringService service) async {
    final bool ar = _isArabic(context);
    final String message = ar
        ? 'مرحبًا ASEC، أريد حجز خدمة: ${service.name.ar}'
        : 'Hello ASEC, I would like to book: ${service.name.en}';
    final Uri url = Uri.parse(
      'https://wa.me/$whatsappNumber?text=${Uri.encodeComponent(message)}',
    );
    bool opened = false;
    try {
      opened = await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (_) {}
    if (!opened) {
      try {
        opened = await launchUrl(url);
      } catch (_) {}
    }
    if (!opened && context.mounted) {
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(
          content: Text(
            ar
                ? 'تعذر فتح واتساب. تواصل معنا على 01080601010'
                : 'Could not open WhatsApp. Contact us on 01080601010',
          ),
        ),
      );
    }
  }
}

// ── Home section (the list) ─────────────────────────────────────────────────

/// "Engineering Services" — the title and the four services as colourful
/// cards in ONE HORIZONTAL ROW (06/11/2026): on a phone the row scrolls
/// sideways; on a wide screen the four cards share the width. A tap opens
/// the service's details.
class ServicesSection extends StatelessWidget {
  const ServicesSection({super.key});

  @override
  Widget build(BuildContext context) {
    final bool ar = _isArabic(context);
    const List<EngineeringService> services = EngineeringServices.all;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                ar ? 'الخدمات الهندسية' : 'Engineering Services',
                style: StyleText.fontSize18Weight600.copyWith(color: AppColors.text),
              ),
            ),
            // Phones only: the row scrolls sideways there.
            if (MediaQuery.sizeOf(context).width < 700)
              Text(
              ar ? 'اسحب لرؤية المزيد' : 'Swipe for more',
              style: StyleText.fontSize12Weight500.copyWith(color: AppColors.secondaryText),
            ),
          ],
        ),
        SizedBox(height: 10.h),
        LayoutBuilder(
          builder: (BuildContext context, BoxConstraints c) {
            final bool wide = c.maxWidth >= 640;
            if (wide) {
              // 09/11/2026: shorter cards (was 158 / 168.h).
              return SizedBox(
                height: 132,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    for (int i = 0; i < services.length; i++) ...<Widget>[
                      if (i > 0) const SizedBox(width: 12),
                      Expanded(child: _ServiceCard(service: services[i], index: i)),
                    ],
                  ],
                ),
              );
            }
            return SizedBox(
              height: 136.h,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                clipBehavior: Clip.none,
                physics: const BouncingScrollPhysics(),
                itemCount: services.length,
                separatorBuilder: (_, __) => SizedBox(width: 12.w),
                itemBuilder: (BuildContext context, int i) => SizedBox(
                  width: 156.w,
                  child: _ServiceCard(service: services[i], index: i),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

/// One service as a gradient card: a glass icon badge, the name in the
/// app's language only, and "Per hour / Per
/// visit" with an arrow at the bottom. Each service has its own colour.
class _ServiceCard extends StatefulWidget {
  const _ServiceCard({required this.service, required this.index});

  final EngineeringService service;
  final int index;

  @override
  State<_ServiceCard> createState() => _ServiceCardState();
}

class _ServiceCardState extends State<_ServiceCard> {
  bool _down = false;
  bool _hover = false;

  /// OFFICIAL LOOK (06/11/2026): every card in ASEC's own colour — a deep
  /// gradient of the brand primary (same hue, darker at the bottom), no
  /// rainbow. Follows the theme (light / dark) like the rest of the app.
  static List<Color> _gradient(int i) => _brandGradient();

  @override
  Widget build(BuildContext context) {
    final EngineeringService s = widget.service;
    final bool ar = _isArabic(context);
    final List<Color> colors = _gradient(widget.index);
    final String billing = s.billing == ServiceBilling.perHour
        ? (ar ? 'بالساعة' : 'Per hour')
        : (ar ? 'بالزيارة' : 'Per visit');
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _down = true),
      onTapCancel: () => setState(() => _down = false),
      onTapUp: (_) => setState(() => _down = false),
      onTap: () => PushedSectionPage.open(
        context,
        ServiceDetailsPage(service: s),
        title: s.name.main(context),
      ),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: AnimatedScale(
          scale: _down ? 0.96 : (_hover ? 1.02 : 1),
          duration: const Duration(milliseconds: 140),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20.r),
              gradient: LinearGradient(
                begin: AlignmentDirectional.topStart,
                end: AlignmentDirectional.bottomEnd,
                colors: colors,
              ),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: Colors.black.withOpacity(_hover ? 0.22 : 0.14),
                  blurRadius: _hover ? 18 : 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20.r),
              child: Stack(
                children: <Widget>[
                  // Soft circles for depth.
                  PositionedDirectional(
                    top: -28,
                    end: -24,
                    child: _Bubble(size: 92, opacity: 0.08),
                  ),
                  PositionedDirectional(
                    bottom: -36,
                    start: -20,
                    child: _Bubble(size: 80, opacity: 0.06),
                  ),
                  // The service's drawing, large and faint.
                  PositionedDirectional(
                    bottom: 8,
                    end: 6,
                    child: Icon(s.icon, size: 52, color: Colors.white.withOpacity(0.10)),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.22),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white.withOpacity(0.35)),
                          ),
                          child: Center(child: AppIcon(s.icon, size: 19, color: Colors.white)),
                        ),
                        const Spacer(),
                        Text(
                          s.name.main(context),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: StyleText.fontSize15Weight600.copyWith(color: Colors.white, height: 1.25),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: <Widget>[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.20),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                billing,
                                style: StyleText.fontSize11Weight400
                                    .copyWith(color: Colors.white, fontWeight: FontWeight.w600),
                              ),
                            ),
                            const Spacer(),
                            Container(
                              width: 26,
                              height: 26,
                              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                              child: Icon(
                                ar ? Icons.arrow_back_rounded : Icons.arrow_forward_rounded,
                                size: 16,
                                color: colors.last,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.size, required this.opacity});

  final double size;
  final double opacity;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(opacity)),
      );
}

// ── Details page ────────────────────────────────────────────────────────────

/// The official ASEC look shared by the cards and the details page — the SAME
/// gradient as the home "Welcome back" card (09/11/2026): brand primary →
/// secondary primary.
List<Color> _brandGradient() => <Color>[AppColors.primary, AppColors.secondaryPrimary];

/// SERVICE DETAILS (06/11/2026 redesign): a brand header with the service,
/// what it includes as numbered steps, and "Book this service" → WhatsApp.
/// 09/11/2026: only the app's language is shown, and the "How it works"
/// and "How it is charged" blocks are gone.
class ServiceDetailsPage extends StatelessWidget {
  const ServiceDetailsPage({super.key, required this.service});

  final EngineeringService service;

  @override
  Widget build(BuildContext context) {
    final bool ar = _isArabic(context);
    final bool perHour = service.billing == ServiceBilling.perHour;
    final List<Color> brand = _brandGradient();

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(AppPadding.h, 12.h, AppPadding.h, 28.h),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: FadeSlideIn(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                // ── Header ──
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24.r),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: brand,
                    ),
                    boxShadow: <BoxShadow>[
                      BoxShadow(color: Colors.black.withOpacity(0.16), blurRadius: 18, offset: const Offset(0, 8)),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24.r),
                    child: Stack(
                      children: <Widget>[
                        const PositionedDirectional(top: -40, end: -30, child: _Bubble(size: 150, opacity: 0.07)),
                        const PositionedDirectional(bottom: -50, start: -30, child: _Bubble(size: 120, opacity: 0.05)),
                        PositionedDirectional(
                          bottom: -6,
                          end: 10,
                          child: Icon(service.icon, size: 110, color: Colors.white.withOpacity(0.07)),
                        ),
                        Padding(
                          padding: EdgeInsets.all(20.r),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.18),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Colors.white.withOpacity(0.30)),
                                ),
                                child: Center(child: AppIcon(service.icon, size: 30, color: Colors.white)),
                              ),
                              SizedBox(height: 16.h),
                              Text(
                                ar ? 'خدمة هندسية' : 'ENGINEERING SERVICE',
                                style: StyleText.fontSize11Weight400.copyWith(
                                  color: Colors.white.withOpacity(0.75),
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: ar ? 0 : 1.4,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                service.name.main(context),
                                style: StyleText.fontSize20Weight600.copyWith(color: Colors.white, fontSize: 24),
                              ),
                              SizedBox(height: 14.h),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: <Widget>[
                                  _HeaderChip(
                                    icon: perHour ? Icons.schedule_rounded : Icons.location_on_outlined,
                                    text: perHour ? (ar ? 'بالساعة' : 'Per hour') : (ar ? 'بالزيارة' : 'Per visit'),
                                  ),
                                  _HeaderChip(
                                    icon: Icons.verified_outlined,
                                    text: ar ? 'مهندسون معتمدون' : 'Certified engineers',
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 18.h),

                // ── What it includes ──
                _SectionLabel(icon: Icons.fact_check_outlined, text: ar ? 'تشمل الخدمة' : 'What It Includes'),
                SizedBox(height: 4.h),
                Padding(
                  padding: EdgeInsets.only(bottom: 10.h),
                  child: Text(
                    service.intro.main(context),
                    style: StyleText.fontSize13Weight500.copyWith(color: AppColors.secondaryText),
                  ),
                ),
                _Panel(
                  child: Column(
                    children: <Widget>[
                      for (int i = 0; i < service.includes.length; i++) ...<Widget>[
                        if (i > 0)
                          Divider(height: 22.h, thickness: 1, color: AppColors.secondaryText.withOpacity(0.08)),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Container(
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(colors: brand),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  '${i + 1}',
                                  style: StyleText.fontSize13Weight500
                                      .copyWith(color: Colors.white, fontWeight: FontWeight.w700),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(top: 5),
                                child: Text(
                                  service.includes[i].main(context),
                                  style: StyleText.fontSize14Weight600.copyWith(color: AppColors.text),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                SizedBox(height: 18.h),

                // 09/11/2026: "How it works" and "How it is charged" removed.
                _BookButton(
                  label: ar ? 'احجز هذه الخدمة' : 'Book This Service',
                  sub: ar ? 'يفتح واتساب برسالة جاهزة' : 'Opens WhatsApp with the message ready',
                  colors: brand,
                  onTap: () => EngineeringServices.book(context, service),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HeaderChip extends StatelessWidget {
  const _HeaderChip({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.16),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.22)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, size: 14, color: Colors.white),
            const SizedBox(width: 6),
            Text(text,
                style: StyleText.fontSize12Weight500.copyWith(color: Colors.white, fontWeight: FontWeight.w600)),
          ],
        ),
      );
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Row(
        children: <Widget>[
          AppIcon(icon, size: 20, color: AppTheme.accentOn(AppColors.background)),
          const SizedBox(width: 8),
          Text(text, style: StyleText.fontSize16Weight600.copyWith(color: AppColors.text)),
        ],
      );
}

class _Panel extends StatelessWidget {
  const _Panel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
        padding: EdgeInsets.all(16.r),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(18.r),
          border: Border.all(color: AppColors.secondaryText.withOpacity(0.08)),
          boxShadow: <BoxShadow>[
            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4)),
          ],
        ),
        child: child,
      );
}

/// The full-width brand button (WhatsApp chat bubble), with a line under it.
class _BookButton extends StatelessWidget {
  const _BookButton({required this.label, required this.sub, required this.colors, required this.onTap});

  final String label;
  final String sub;
  final List<Color> colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18.r),
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: colors),
        boxShadow: <BoxShadow>[
          BoxShadow(color: colors.last.withOpacity(0.35), blurRadius: 16, offset: const Offset(0, 6)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18.r),
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 16.w),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.18), shape: BoxShape.circle),
                  child: const Center(child: AppIcon(Icons.chat_rounded, size: 19, color: Colors.white)),
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(label, style: StyleText.fontSize16Weight600.copyWith(color: Colors.white)),
                      Text(sub,
                          style: StyleText.fontSize11Weight400.copyWith(color: Colors.white.withOpacity(0.8))),
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
