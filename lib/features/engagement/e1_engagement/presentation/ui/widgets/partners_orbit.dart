/// Module: engagement / e1_engagement
///
///*************************** FILE INFO ****************************///
/// File Name: partners_orbit.dart
/// Purpose: Declares `PartnersSection` / `PartnersOrbit` — the partners'
///          logos turning in a 3D ring around the ASEC logo, over a slowly
///          turning gear, on the member's home page.
/// Author: ASEC team
/// Created: 16/10/2026
/// Updated: 24/10/2026 - In the app the ASEC logo in the centre has no disc
///          behind it.
///
/// THE SAME PARTNERS AS THE WEBSITE: `site_partners` (name, logo_url,
/// order, published). The admin adds them in Engagement → Partners (or
/// Website → Partners); only published ones show.
///
/// THE 3D RING. Every logo sits on a tilted ellipse at its own angle; the
/// whole ring turns. A logo's depth (sin of its angle) sets its size, its
/// opacity and its paint order — the ones at the back are smaller, fainter
/// and drawn first, so the front ones pass over them. No 3D engine.

import 'dart:math' as math;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:asec/core/custom/110-app_widgets.dart';
import 'package:asec/core/custom/57-custom_dialog_manager.dart';
import 'package:asec/core/custom/58-default_switch_button.dart';
import 'package:asec/features/engagement/e1_engagement/presentation/ui/widgets/engagement_widgets.dart';
import 'package:asec/core/helper/main_helper/format_helper.dart';
import 'package:asec/core/theme/app_colors.dart';
import 'package:asec/core/theme/app_theme.dart';
import 'package:asec/features/onboarding/o2_authentication/presentation/ui/widgets/brand_mark.dart';
import 'package:asec/features/web/core/doc.dart';
import 'package:asec/features/web/data/site_repo.dart';
import 'package:asec/generated/l10n.dart';

class PartnerLogoItem {
  const PartnerLogoItem({required this.name, required this.logoUrl});

  final String name;
  final String logoUrl;
}

/// "Our partners" + the orbit. Shows nothing while there are no partners.
class PartnersSection extends StatelessWidget {
  const PartnersSection({super.key, this.fill = false});

  /// Fill the height it is given (desktop / tablet home, no page scroll).
  final bool fill;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Doc>>(
      stream: SiteRepo.published(Coll.partners),
      builder: (BuildContext context, AsyncSnapshot<List<Doc>> snap) {
        final List<PartnerLogoItem> items = <PartnerLogoItem>[
          for (final Doc d in snap.data ?? const <Doc>[])
            if (d.raw('logo_url').trim().isNotEmpty)
              PartnerLogoItem(name: d.s('name'), logoUrl: d.raw('logo_url')),
        ];
        if (items.isEmpty) return const SizedBox.shrink();
        if (fill) return PartnersOrbit(items: items);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            // No title — the ring speaks for itself.
            PartnersOrbit(items: items),
          ],
        );
      },
    );
  }
}

class PartnersOrbit extends StatefulWidget {
  const PartnersOrbit({
    super.key,
    required this.items,
    this.period = const Duration(seconds: 26),
    this.accent,
    this.centerColor,
    this.center,
  });

  final List<PartnerLogoItem> items;

  /// FOR THE WEBSITE, which has its own colours and no app theme: the gear
  /// and glow colour, the middle disc's colour and what sits on it. Left
  /// null, the app's theme and the ASEC mark are used.
  final Color? accent;
  final Color? centerColor;
  final Widget? center;

  bool get _site => accent != null;

  /// One full turn of the ring.
  final Duration period;

  @override
  State<PartnersOrbit> createState() => _PartnersOrbitState();
}

class _PartnersOrbitState extends State<PartnersOrbit>
    with SingleTickerProviderStateMixin {
  late final AnimationController _spin =
      AnimationController(vsync: this, duration: widget.period)..repeat();

  /// Dragging sideways turns the ring by hand; letting go, it carries on.
  double _dragOffset = 0;

  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints c) {
        final double width = c.maxWidth;
        // Given a height (home page without scrolling): fit inside it.
        final double height = c.hasBoundedHeight
            ? math.min(c.maxHeight, (width * 0.75).clamp(160.0, 380.0))
            : (width * 0.55).clamp(240.0, 380.0);
        final double rx = math.max(60.0, width / 2 - (widget._site ? 56.0 : 56.r)); // ring radius, sideways
        final double ry = height * 0.22; // the tilt: a flat ellipse
        final double logo = (height * 0.26).clamp(c.hasBoundedHeight ? 40.0 : 58.0, 92.0);

        return GestureDetector(
          onHorizontalDragUpdate: (DragUpdateDetails d) =>
              setState(() => _dragOffset += d.delta.dx / (rx == 0 ? 1 : rx)),
          child: SizedBox(
            height: height,
            child: AnimatedBuilder(
              animation: _spin,
              builder: (BuildContext context, _) {
                final double turn = _spin.value * 2 * math.pi + _dragOffset;
                final int n = widget.items.length;

                // Each logo: its angle, then depth -1 (back) … 1 (front).
                final List<(int, double)> placed = <(int, double)>[
                  for (int i = 0; i < n; i++) (i, turn + i * 2 * math.pi / n),
                ]..sort(((int, double) a, (int, double) b) =>
                    math.sin(a.$2).compareTo(math.sin(b.$2)));

                Widget logoAt((int, double) p) {
                  final double depth = math.sin(p.$2); // -1 back … 1 front
                  final double k = (depth + 1) / 2; // 0 … 1
                  final double scale = 0.55 + 0.5 * k;
                  final double size = logo * scale;
                  final double x = width / 2 + rx * math.cos(p.$2) - size / 2;
                  final double y = height / 2 + ry * depth - size / 2;
                  return Positioned(
                    left: x,
                    top: y,
                    child: Opacity(
                      opacity: 0.4 + 0.6 * k,
                      child: _LogoChip(
                        item: widget.items[p.$1],
                        size: size,
                        depth: k,
                        accent: widget.accent,
                      ),
                    ),
                  );
                }

                return Stack(
                  clipBehavior: Clip.none,
                  children: <Widget>[
                    // The gear, turning the other way, behind everything.
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _GearPainter(
                          angle: -turn * 0.6,
                          color: widget.accent ?? AppColors.primary,
                          rx: rx,
                          ry: ry,
                        ),
                      ),
                    ),
                    // The logos behind the centre…
                    for (final p in placed)
                      if (math.sin(p.$2) < 0) logoAt(p),
                    // …ASEC in the middle ("around us")…
                    Center(
                      child: Container(
                        // App: no disc, so the logo gets more room.
                        width: logo * (widget._site ? 1.25 : 1.6),
                        height: logo * (widget._site ? 1.25 : 1.6),
                        // App: the ASEC logo alone, no disc behind it. The
                        // website keeps its disc.
                        decoration: !widget._site
                            ? null
                            : BoxDecoration(
                                color: widget.centerColor ?? AppColors.card,
                                shape: BoxShape.circle,
                                boxShadow: <BoxShadow>[
                                  BoxShadow(
                                    color: (widget.accent ?? AppColors.primary).withOpacity(0.35),
                                    blurRadius: 30,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                        alignment: Alignment.center,
                        child: widget.center ??
                            BrandMark(size: logo * (widget._site ? 0.7 : 1.1), showName: false),
                      ),
                    ),
                    // …and the ones in front pass over it.
                    for (final p in placed)
                      if (math.sin(p.$2) >= 0) logoAt(p),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class _LogoChip extends StatelessWidget {
  const _LogoChip({required this.item, required this.size, required this.depth, this.accent});

  final PartnerLogoItem item;
  final double size;

  /// Set on the website: no app theme there.
  final Color? accent;

  /// 0 (back) … 1 (front) — the shadow grows as it comes forward.
  final double depth;

  @override
  Widget build(BuildContext context) {
    // No hover name — just the logo.
    return Container(
        width: size,
        height: size,
        padding: EdgeInsets.all(size * 0.16),
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Colors.black.withOpacity(0.10 + 0.18 * depth),
              blurRadius: 6 + 14 * depth,
              offset: Offset(0, 3 + 6 * depth),
            ),
          ],
        ),
        child: ClipOval(
          child: Image.network(
            item.logoUrl,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => Center(
              child: Text(
                FormatHelper.capitalize(
                    item.name.isEmpty ? '?' : item.name.characters.first),
                style: accent != null
                    ? TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: accent)
                    : StyleText.fontSize18Weight700.copyWith(color: AppColors.primary),
              ),
            ),
          ),
        ),
    );
  }
}

/// A gear wheel lying on the same tilted plane as the ring: teeth around a
/// rim, a hub, spokes — drawn flat, then squashed to the ellipse.
class _GearPainter extends CustomPainter {
  _GearPainter({
    required this.angle,
    required this.color,
    required this.rx,
    required this.ry,
  });

  final double angle;
  final Color color;
  final double rx;
  final double ry;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset c = size.center(Offset.zero);
    final double r = rx * 0.78;
    if (r <= 0) return;

    canvas.save();
    canvas.translate(c.dx, c.dy);
    // The tilt: squash the circle into the ring's ellipse.
    canvas.scale(1, ry / rx);
    canvas.rotate(angle);

    const int teeth = 28;
    final Path gear = Path();
    for (int i = 0; i < teeth; i++) {
      final double a0 = i * 2 * math.pi / teeth;
      final double a1 = a0 + math.pi / teeth * 0.45;
      final double a2 = a0 + math.pi / teeth * 1.0;
      final double a3 = a0 + math.pi / teeth * 1.45;
      final double outer = r * 1.08;
      final List<Offset> pts = <Offset>[
        Offset(math.cos(a0) * r, math.sin(a0) * r),
        Offset(math.cos(a1) * outer, math.sin(a1) * outer),
        Offset(math.cos(a2) * outer, math.sin(a2) * outer),
        Offset(math.cos(a3) * r, math.sin(a3) * r),
      ];
      if (i == 0) {
        gear.moveTo(pts[0].dx, pts[0].dy);
      } else {
        gear.lineTo(pts[0].dx, pts[0].dy);
      }
      for (final Offset p in pts.skip(1)) {
        gear.lineTo(p.dx, p.dy);
      }
    }
    gear.close();

    canvas.drawPath(gear, Paint()..color = color.withOpacity(0.07));
    canvas.drawPath(
      gear,
      Paint()
        ..color = color.withOpacity(0.28)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6,
    );

    final Paint line = Paint()
      ..color = color.withOpacity(0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    canvas.drawCircle(Offset.zero, r * 0.72, line);
    canvas.drawCircle(Offset.zero, r * 0.30, line);
    for (int i = 0; i < 6; i++) {
      final double a = i * math.pi / 3;
      canvas.drawLine(
        Offset(math.cos(a) * r * 0.30, math.sin(a) * r * 0.30),
        Offset(math.cos(a) * r * 0.72, math.sin(a) * r * 0.72),
        line,
      );
    }
    canvas.restore();

    // The orbit the logos travel on.
    canvas.drawOval(
      Rect.fromCenter(center: c, width: rx * 2, height: ry * 2),
      Paint()
        ..color = color.withOpacity(0.22)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
  }

  @override
  bool shouldRepaint(covariant _GearPainter old) =>
      old.angle != angle || old.color != color || old.rx != rx || old.ry != ry;
}

// ── Admin: Engagement → Partners ────────────────────────────────────────────

/// The admin's partners: a live preview of the ring, then every partner
/// with its "shown" switch and a delete menu. Add = pick the logo, name it.
class PartnersAdminTab extends StatefulWidget {
  const PartnersAdminTab({super.key});

  /// The tab's top-right button.
  static Future<void> add(BuildContext context) async {
    final S s = S.of(context);
    final FilePickerResult? picked = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true, // a logo is small; the bytes work on every platform
    );
    final PlatformFile? file =
        picked == null || picked.files.isEmpty ? null : picked.files.first;
    if (file == null || file.bytes == null || !context.mounted) return;

    final int dot = file.name.lastIndexOf('.');
    final String? name = await CustomDialogManager.showInput(
      context: context,
      title: s.engPartnerAdd,
      subtitle: file.name,
      fieldLabel: s.engPartnerName,
      hint: dot > 0 ? file.name.substring(0, dot) : file.name,
      submitLabel: s.add,
      cancelLabel: s.cancel,
    );
    if (name == null || name.trim().isEmpty || !context.mounted) return;

    try {
      final String url = await SiteRepo.uploadImage(
        folder: 'partners',
        fileName: file.name,
        bytes: file.bytes!,
      );
      await SiteRepo.save(Coll.partners, null, <String, dynamic>{
        'name': name.trim(),
        'logo_url': url,
        'order': DateTime.now().millisecondsSinceEpoch ~/ 1000,
        'published': true,
      });
      if (context.mounted) showEngagementToast(context, s.engPartnerAdded);
    } catch (e) {
      if (context.mounted) showEngagementToast(context, engErrorText(context, e));
    }
  }

  @override
  State<PartnersAdminTab> createState() => _PartnersAdminTabState();
}

class _PartnersAdminTabState extends State<PartnersAdminTab> {
  late final Stream<List<Doc>> _all = SiteRepo.all(Coll.partners);

  @override
  Widget build(BuildContext context) {
    final S s = S.of(context);
    return StreamBuilder<List<Doc>>(
      stream: _all,
      builder: (BuildContext context, AsyncSnapshot<List<Doc>> snap) {
        if (snap.hasError) {
          return AppErrorView(message: engErrorText(context, snap.error), error: snap.error, stackTrace: snap.stackTrace);
        }
        if (!snap.hasData) return const AppLoading();
        final List<Doc> docs = snap.data!;
        if (docs.isEmpty) return AppEmptyView(title: s.engPartnersEmpty);

        final List<PartnerLogoItem> shown = <PartnerLogoItem>[
          for (final Doc d in docs)
            if (d.data['published'] == true && d.raw('logo_url').isNotEmpty)
              PartnerLogoItem(name: d.s('name'), logoUrl: d.raw('logo_url')),
        ];

        return ListView(
          padding: EdgeInsets.only(bottom: 24.h),
          children: <Widget>[
            if (shown.isNotEmpty) ...<Widget>[
              PartnersOrbit(items: shown),
              SizedBox(height: 16.h),
            ],
            for (final Doc d in docs) ...<Widget>[
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(14.r),
                ),
                child: Row(
                  children: <Widget>[
                    Container(
                      width: 46.r,
                      height: 46.r,
                      padding: EdgeInsets.all(6.r),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: ClipOval(
                        child: Image.network(
                          d.raw('logo_url'),
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                        ),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Text(
                        FormatHelper.capitalize(d.s('name')),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: StyleText.fontSize15Weight600
                            .copyWith(color: AppColors.text),
                      ),
                    ),
                    Text(
                      FormatHelper.capitalize(s.engTipActive),
                      style: StyleText.fontSize12Weight500
                          .copyWith(color: AppColors.secondaryText),
                    ),
                    SizedBox(width: 6.w),
                    DefaultSwitchButton(
                      value: d.data['published'] == true,
                      onChanged: (bool v) => SiteRepo.patch(
                        Coll.partners,
                        d.id,
                        <String, dynamic>{'published': v},
                      ),
                    ),
                    DeleteMenu(
                      onDelete: () => confirmDelete(
                        context,
                        name: d.s('name'),
                        action: () => SiteRepo.remove(Coll.partners, d.id),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 10.h),
            ],
          ],
        );
      },
    );
  }
}
