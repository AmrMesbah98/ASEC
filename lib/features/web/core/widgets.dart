/// Small building blocks shared by the site and the panel.
library;

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:asec/core/custom/111-app_svg_icon.dart';
import 'package:asec/features/web/core/i18n.dart';
import 'package:asec/features/web/core/theme.dart';
import 'package:asec/core/helper/main_helper/format_helper.dart';

extension Responsive on BuildContext {
  double get width => MediaQuery.sizeOf(this).width;
  bool get isMobile => width < 720;
  bool get isTablet => width >= 720 && width < 1100;
  bool get isDesktop => width >= 1100;

  /// Columns for a card grid at this width.
  int cols({int mobile = 1, int tablet = 2, int desktop = 3}) =>
      isMobile ? mobile : (isTablet ? tablet : desktop);
}

/// Centres content at the site's 1200px column with side gutters.
class Contained extends StatelessWidget {
  const Contained({
    super.key,
    required this.child,
    this.maxWidth = 1200,
    this.vertical = 0,
  });

  final Widget child;
  final double maxWidth;
  final double vertical;

  @override
  Widget build(BuildContext context) {
    final double side = context.isMobile ? 16 : 32;
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: side, vertical: vertical),
          child: child,
        ),
      ),
    );
  }
}

/// An image from a URL that never breaks the layout.
///
/// Images still live on the WordPress host (asecbim.com/wp-content/…), which
/// sends no CORS headers. Flutter's CanvasKit renderer needs CORS to draw an
/// image into the canvas, so `WebHtmlElementStrategy.fallback` lets it fall
/// back to a plain <img> element when CORS is missing.
class NetImage extends StatelessWidget {
  const NetImage(
    this.url, {
    super.key,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.radius = 0,
    this.placeholderIcon = Icons.image_outlined,
  });

  final String url;
  final BoxFit fit;
  final double? width;
  final double? height;
  final double radius;
  final IconData placeholderIcon;

  @override
  Widget build(BuildContext context) {
    final Widget placeholder = Container(
      width: width,
      height: height,
      color: WebColors.surface,
      alignment: Alignment.center,
      child: AppIcon(placeholderIcon, color: WebColors.muted.withValues(alpha: 0.5)),
    );
    if (url.trim().isEmpty) {
      return radius <= 0 ? placeholder : ClipRRect(borderRadius: BorderRadius.circular(radius), child: placeholder);
    }
    // PERFORMANCE: decode at the size it is shown (x screen density), not at
    // the file's full size — a 4000px photo in a 380px card is ~100x the
    // pixels to decode, upload and scale every frame.
    // MOTION: fade in once decoded instead of popping in.
    final Widget img = LayoutBuilder(
      builder: (BuildContext context, BoxConstraints c) {
        final double dpr = MediaQuery.devicePixelRatioOf(context);
        final double w = width ?? (c.hasBoundedWidth ? c.maxWidth : 0);
        final double h = height ?? (c.hasBoundedHeight ? c.maxHeight : 0);
        // `cover` may be height-bound: allow for a wide photo in a tall box.
        final double target = fit == BoxFit.cover ? (w > h * 1.78 ? w : h * 1.78) : w;
        final int? decodeWidth = target <= 0 || target.isInfinite ? null : (target * dpr).round().clamp(64, 2600);
        return Image.network(
          url,
          fit: fit,
          width: width,
          height: height,
          cacheWidth: decodeWidth,
          filterQuality: FilterQuality.medium,
          webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
          errorBuilder: (_, _, _) => placeholder,
          frameBuilder: (BuildContext context, Widget child, int? frame, bool sync) {
            if (sync) return child;
            return AnimatedOpacity(
              opacity: frame == null ? 0 : 1,
              duration: const Duration(milliseconds: 450),
              curve: Curves.easeOut,
              child: child,
            );
          },
        );
      },
    );
    if (radius <= 0) return img;
    return ClipRRect(borderRadius: BorderRadius.circular(radius), child: img);
  }
}

/// "خدماتنا" — red heading, short blue bar, muted intro. As on asecbim.com.
class SectionTitle extends StatelessWidget {
  const SectionTitle(this.title, {super.key, this.intro = '', this.dark = false});

  final String title;
  final String intro;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Text(
          FormatHelper.capitalize(title),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: context.isMobile ? 26 : 34,
            fontWeight: FontWeight.w800,
            color: WebColors.redBright,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: 46,
          height: 3,
          decoration: BoxDecoration(color: WebColors.blue, borderRadius: BorderRadius.circular(2)),
        ),
        if (intro.isNotEmpty) ...<Widget>[
          const SizedBox(height: 14),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 820),
            child: Text(
              FormatHelper.capitalize(intro),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                height: 1.8,
                fontWeight: FontWeight.w600,
                color: dark ? WebColors.white.withValues(alpha: 0.8) : WebColors.ink,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class Loading extends StatelessWidget {
  const Loading({super.key, this.height = 240});

  final double height;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: height,
        child: const Center(
          child: SizedBox(width: 28, height: 28, child: CircularProgressIndicator(strokeWidth: 2.4)),
        ),
      );
}

class EmptyNote extends StatelessWidget {
  const EmptyNote(this.text, {super.key, this.icon = Icons.inbox_outlined});

  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Column(
          children: <Widget>[
            AppIcon(icon, size: 42, color: WebColors.muted.withValues(alpha: 0.5)),
            const SizedBox(height: 10),
            Text(FormatHelper.capitalize(text), textAlign: TextAlign.center, style: TextStyle(color: WebColors.muted)),
          ],
        ),
      );
}

/// Opens a link, a phone number or an email in a new tab / the right app.
Future<void> openLink(String url) async {
  final String u = url.trim();
  if (u.isEmpty) return;
  final Uri? uri = Uri.tryParse(u);
  if (uri == null) return;
  await launchUrl(uri, webOnlyWindowName: u.startsWith('http') ? '_blank' : '_self');
}

String telLink(String phone) => 'tel:${phone.replaceAll(RegExp(r'[^0-9+]'), '')}';

String whatsappLink(String phone) => 'https://wa.me/${phone.replaceAll(RegExp(r'[^0-9]'), '')}';

/// Arabic month names, as the WordPress site prints dates ("أبريل 12, 2025").
String arabicDate(DateTime? d) {
  if (d == null) return '';
  const List<String> months = <String>[
    'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
    'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر',
  ];
  return '${d.day} ${months[d.month - 1]} ${d.year}';
}

/// A date in the current language: "12 أبريل 2025" / "12 April 2025".
/// Used by the panel and the public site.
String panelDate(DateTime? d) {
  if (d == null) return '';
  if (AppLang.isAr) return arabicDate(d);
  const List<String> months = <String>[
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];
  return '${d.day} ${months[d.month - 1]} ${d.year}';
}
