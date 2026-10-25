/// The public site's frame: header (logo · menu · language · "اتصل الآن"),
/// the page, the floating "تواصل معانا" button. Arabic is right-to-left,
/// English left-to-right (AppLang).
///
/// `SitePage` is what every page returns: its sections in one scroll view,
/// followed by the call-to-action band (optional) and the footer.
library;

import 'dart:async';

import 'package:flutter/material.dart';

import 'package:asec/core/custom/111-app_svg_icon.dart';
import 'package:asec/features/web/core/builtin_en.dart';
import 'package:asec/features/web/core/doc.dart';
import 'package:asec/features/web/core/i18n.dart';
import 'package:asec/features/web/core/theme.dart';
import 'package:asec/features/web/core/widgets.dart';
import 'package:asec/features/web/data/site_repo.dart';
import 'package:asec/features/web/site/site_nav.dart';
import 'package:asec/features/web/site/widgets/download_button.dart';
import 'package:asec/features/web/site/widgets/motion.dart';

class NavItem {
  const NavItem(this.label, this.path, [this.children = const <NavItem>[]]);

  final L label;
  final String path;
  final List<NavItem> children;
}

const List<NavItem> kNav = <NavItem>[
  NavItem(L('الرئيسية', 'Home'), '/'),
  NavItem(L('من نحن', 'About'), '/about'),
  NavItem(L('خدماتنا', 'Services'), '/services', <NavItem>[
    NavItem(L('تصميم متكامل', 'Integrated Design'), '/services/integrated-design'),
    NavItem(L('لوحات تنفيذية', 'Shop Drawings'), '/services/shop-drawings'),
    NavItem(L('اشراف على التنفيذ', 'Site Supervision'), '/services/supervision'),
  ]),
  NavItem(L('المقالات', 'Articles'), '/articles'),
  NavItem(L('أعمالنا', 'Projects'), '/projects'),
  NavItem(L('تواصل معنا', 'Contact'), '/contact'),
  // APPLY = the service request form, nothing else.
  NavItem(L('تقديم طلب', 'Apply'), '/request-service'),
];

/// "عربي | English" — the language as a two-option tab, floating at the
/// bottom-start corner of every page beside the back-to-top button.
class LangTab extends StatelessWidget {
  const LangTab({super.key});

  @override
  Widget build(BuildContext context) {
    Widget option(String code, String label) {
      final bool on = AppLang.code == code;
      return MouseRegion(
        cursor: on ? SystemMouseCursors.basic : SystemMouseCursors.click,
        child: GestureDetector(
          onTap: on ? null : () => AppLang.set(code),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            height: 34,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: on ? WebColors.red : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: on ? WebColors.white : WebColors.ink,
              ),
            ),
          ),
        ),
      );
    }

    return Material(
      color: WebColors.white,
      elevation: 4,
      shadowColor: Colors.black26,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(4),
        // Always Arabic first, English second — the tab does not flip with
        // the page, so the two options never swap places under the pointer.
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              option('ar', 'عربي'),
              const SizedBox(width: 2),
              option('en', 'English'),
            ],
          ),
        ),
      ),
    );
  }
}

class SiteShell extends StatelessWidget {
  const SiteShell({super.key, required this.location, required this.child});

  final String location;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: AppLang.direction,
      child: ValueListenableBuilder<Doc>(
        valueListenable: SiteSettings.instance,
        builder: (BuildContext context, Doc settings, _) {
          if (settings.b('maintenance_mode', false)) {
            return _Maintenance(
                text: settings.txt('maintenance_text',
                    const L('الموقع تحت الصيانة، نعود قريبًا.', 'The site is under maintenance. We will be back soon.')));
          }
          return Scaffold(
            backgroundColor: WebColors.white,
            endDrawer: context.isDesktop ? null : _MobileMenu(location: location),
            body: Stack(
              fit: StackFit.expand,
              children: <Widget>[
                Column(
                  children: <Widget>[
                    _Header(location: location, settings: settings),
                    Expanded(child: child),
                  ],
                ),
                if (settings.b('show_whatsapp_button') && settings.s('whatsapp').isNotEmpty)
                  PositionedDirectional(
                    end: 18,
                    bottom: 18,
                    child: _ContactBubble(phone: settings.s('whatsapp')),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ── Header ───────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header({required this.location, required this.settings});

  final String location;
  final Doc settings;

  bool _active(NavItem n) =>
      n.path == '/' ? location == '/' : location.startsWith(n.path) ||
          n.children.any((NavItem c) => location.startsWith(c.path));

  @override
  Widget build(BuildContext context) {
    final bool desktop = context.isDesktop;
    return Material(
      color: WebColors.white,
      elevation: 1,
      shadowColor: Colors.black26,
      child: SizedBox(
        height: desktop ? 96 : 76,
        child: Contained(
          child: Row(
            children: <Widget>[
              InkWell(
                onTap: () => siteGo(context, '/'),
                child: const _Logo(size: 64),
              ),
              const SizedBox(width: 24),
              if (desktop)
                Expanded(
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: <Widget>[
                      for (int i = 0; i < kNav.length; i++) ...<Widget>[
                        if (i > 0)
                          Container(width: 1, height: 16, color: WebColors.border),
                        _NavLink(item: kNav[i], active: _active(kNav[i])),
                      ],
                    ],
                  ),
                )
              else
                const Spacer(),
              // Animated "Download for Windows" (latest GitHub release).
              if (!context.isMobile && settings.b('show_download_button')) ...<Widget>[
                DownloadAppButton(
                  overrideUrl: settings.s('windows_download_url'),
                  showVersion: MediaQuery.sizeOf(context).width >= 1320,
                ),
                const SizedBox(width: 12),
              ],
              if (!context.isMobile || desktop)
                ElevatedButton(
                  onPressed: () => openLink(telLink(settings.s('phone', '+201093460618'))),
                  child: Text(const L('اتصل الآن', 'Call now').t),
                ),
              if (!desktop) ...<Widget>[
                const SizedBox(width: 12),
                Builder(
                  builder: (BuildContext c) => IconButton.filledTonal(
                    onPressed: () => Scaffold.of(c).openEndDrawer(),
                    icon: const AppIcon(Icons.menu_rounded),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  const _Logo({required this.size, this.white = false});

  final double size;

  /// All white — for the black footer, whatever the site's theme.
  final bool white;

  @override
  Widget build(BuildContext context) {
    final Widget logo = Image.asset('assets/web/images/logo.png', height: size, fit: BoxFit.contain);
    if (!white) return logo;
    return ColorFiltered(
      colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
      child: logo,
    );
  }
}

class _NavLink extends StatefulWidget {
  const _NavLink({required this.item, required this.active});

  final NavItem item;
  final bool active;

  @override
  State<_NavLink> createState() => _NavLinkState();
}

/// A menu link whose colour eases to red and whose red underline grows under
/// the pointer (and stays under the current page).
///
/// An item WITH sub-pages (خدماتنا, تقديم طلب) opens its list on HOVER — no
/// arrow, no click — like the WordPress menu. Clicking the item itself opens
/// its own page. The list stays open while the pointer travels from the item
/// down into it, and closes a moment after the pointer leaves both.
class _NavLinkState extends State<_NavLink> {
  bool _h = false;
  final LayerLink _link = LayerLink();
  final OverlayPortalController _menu = OverlayPortalController();
  Timer? _closeTimer;

  bool get _hasMenu => widget.item.children.isNotEmpty;

  @override
  void dispose() {
    _closeTimer?.cancel();
    super.dispose();
  }

  void _enter() {
    _closeTimer?.cancel();
    if (_hasMenu && !_menu.isShowing) _menu.show();
    if (!_h) setState(() => _h = true);
  }

  void _leave() {
    _closeTimer?.cancel();
    _closeTimer = Timer(const Duration(milliseconds: 180), () {
      if (!mounted) return;
      if (_menu.isShowing) _menu.hide();
      setState(() => _h = false);
    });
  }

  void _go(String path) {
    _closeTimer?.cancel();
    if (_menu.isShowing) _menu.hide();
    setState(() => _h = false);
    siteGo(context, path);
  }

  @override
  Widget build(BuildContext context) {
    final NavItem item = widget.item;
    final bool on = widget.active || _h;
    final Widget label = Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 220),
          style: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: on ? WebColors.redBright : WebColors.ink,
          ),
          child: Text(item.label.t),
        ),
        const SizedBox(height: 4),
        AnimatedContainer(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
          height: 2,
          width: on ? 26 : 0,
          decoration: BoxDecoration(color: WebColors.redBright, borderRadius: BorderRadius.circular(2)),
        ),
      ],
    );

    final Widget link = MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => _enter(),
      onExit: (_) => _leave(),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _go(item.path),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: label,
        ),
      ),
    );

    if (!_hasMenu) return link;

    return CompositedTransformTarget(
      link: _link,
      child: OverlayPortal(
        controller: _menu,
        overlayChildBuilder: (BuildContext context) => CompositedTransformFollower(
          link: _link,
          targetAnchor: Alignment.bottomCenter,
          followerAnchor: Alignment.topCenter,
          child: Align(
            alignment: Alignment.topCenter,
            child: MouseRegion(
              onEnter: (_) => _enter(),
              onExit: (_) => _leave(),
              child: _HoverMenu(items: item.children, onTap: _go),
            ),
          ),
        ),
        child: link,
      ),
    );
  }
}

/// The hover list under a menu item: white card, red bar on top, rows that
/// tint on hover. It drops in with a short fade and slide.
class _HoverMenu extends StatelessWidget {
  const _HoverMenu({required this.items, required this.onTap});

  final List<NavItem> items;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      builder: (BuildContext context, double v, Widget? child) => Opacity(
        opacity: v,
        child: Transform.translate(offset: Offset(0, (1 - v) * 10), child: child),
      ),
      child: Padding(
        // Invisible bridge between the item and the card, so the pointer
        // never "leaves" while moving down into the list.
        padding: const EdgeInsets.only(top: 6),
        child: Material(
          color: WebColors.white,
          elevation: 8,
          shadowColor: Colors.black26,
          borderRadius: BorderRadius.circular(8),
          clipBehavior: Clip.antiAlias,
          child: Directionality(
            textDirection: AppLang.direction,
            child: IntrinsicWidth(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Container(height: 3, color: WebColors.redBright),
                  const SizedBox(height: 6),
                  for (final NavItem c in items) _HoverMenuRow(item: c, onTap: onTap),
                  const SizedBox(height: 6),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HoverMenuRow extends StatefulWidget {
  const _HoverMenuRow({required this.item, required this.onTap});

  final NavItem item;
  final ValueChanged<String> onTap;

  @override
  State<_HoverMenuRow> createState() => _HoverMenuRowState();
}

class _HoverMenuRowState extends State<_HoverMenuRow> {
  bool _h = false;

  @override
  Widget build(BuildContext context) => MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _h = true),
        onExit: (_) => setState(() => _h = false),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => widget.onTap(widget.item.path),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            constraints: const BoxConstraints(minWidth: 200),
            color: _h ? WebColors.redBright.withValues(alpha: 0.07) : Colors.transparent,
            padding: EdgeInsetsDirectional.fromSTEB(_h ? 26 : 20, 11, 20, 11),
            child: Text(
              widget.item.label.t,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: _h ? WebColors.redBright : WebColors.ink,
              ),
            ),
          ),
        ),
      );
}

class _MobileMenu extends StatelessWidget {
  const _MobileMenu({required this.location});

  final String location;

  @override
  Widget build(BuildContext context) {
    void go(String p) {
      Navigator.of(context).pop();
      siteGo(context, p);
    }

    return Drawer(
      backgroundColor: WebColors.white,
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(12),
          children: <Widget>[
            const Padding(padding: EdgeInsets.all(12), child: _Logo(size: 70)),
            if (context.isMobile && SiteSettings.instance.value.b('show_download_button'))
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 0, 4, 12),
                child: DownloadAppButton(
                  overrideUrl: SiteSettings.instance.value.s('windows_download_url'),
                  fullWidth: true,
                ),
              ),
            for (final NavItem n in kNav)
              if (n.children.isEmpty)
                ListTile(
                  title: Text(n.label.t, style: const TextStyle(fontWeight: FontWeight.w700)),
                  selected: location == n.path,
                  onTap: () => go(n.path),
                )
              else
                ExpansionTile(
                  title: Text(n.label.t, style: const TextStyle(fontWeight: FontWeight.w700)),
                  trailing: const AppIcon(Icons.keyboard_arrow_down_rounded),
                  children: <Widget>[
                    ListTile(title: Text(n.label.t), onTap: () => go(n.path)),
                    for (final NavItem c in n.children)
                      ListTile(
                        contentPadding: const EdgeInsetsDirectional.only(start: 32),
                        title: Text(c.label.t),
                        onTap: () => go(c.path),
                      ),
                  ],
                ),
          ],
        ),
      ),
    );
  }
}

class _ContactBubble extends StatelessWidget {
  const _ContactBubble({required this.phone});

  final String phone;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 1400),
      curve: const Interval(0.45, 1, curve: Curves.easeOutBack),
      builder: (BuildContext context, double v, Widget? child) => Opacity(
        opacity: v.clamp(0.0, 1.0),
        child: Transform.scale(scale: 0.6 + 0.4 * v, alignment: AlignmentDirectional.bottomEnd, child: child),
      ),
      child: _bubble(),
    );
  }

  Widget _bubble() {
    return Material(
      color: WebColors.white,
      elevation: 6,
      borderRadius: BorderRadius.circular(40),
      child: InkWell(
        borderRadius: BorderRadius.circular(40),
        onTap: () => openLink(whatsappLink(phone)),
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(16, 8, 8, 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(const L('تواصل معانا', 'Chat with us').t, style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(width: 10),
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(color: Color(0xFF25D366), shape: BoxShape.circle),
                child: const AppIcon(Icons.chat_rounded, color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Maintenance extends StatelessWidget {
  const _Maintenance({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const _Logo(size: 110),
                const SizedBox(height: 24),
                Text(text,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ),
      );
}

/// Rebuilds when `site_settings/main` changes.
class WithSettings extends StatelessWidget {
  const WithSettings({super.key, required this.builder});

  final Widget Function(BuildContext context, Doc settings) builder;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<Doc>(
        valueListenable: SiteSettings.instance,
        builder: (BuildContext c, Doc s, _) => builder(c, s),
      );
}

// ── Page body ────────────────────────────────────────────────────────────

class SitePage extends StatefulWidget {
  const SitePage({super.key, required this.children, this.cta = true});

  final List<Widget> children;
  final bool cta;

  @override
  State<SitePage> createState() => _SitePageState();
}

/// PERFORMANCE: a lazy ListView (only what is near the screen is built and
/// painted, each section in its own repaint layer) instead of one giant
/// Column; no page-wide SelectionArea (it hit-tests every Text on every
/// pointer move). MOTION: sections fade up as they come into view, the mouse
/// wheel is eased, and a "back to top" button appears after a scroll.
class _SitePageState extends State<SitePage> {
  final ScrollController _scroll = ScrollController();
  final ValueNotifier<bool> _showTop = ValueNotifier<bool>(false);

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      final bool show = _scroll.hasClients && _scroll.offset > 700;
      if (show != _showTop.value) _showTop.value = show;
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    _showTop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> items = <Widget>[
      for (int i = 0; i < widget.children.length; i++)
        // The first section is on screen at once: a quicker, shorter rise.
        i == 0
            ? Reveal(offset: 16, duration: const Duration(milliseconds: 500), child: widget.children[i])
            : Reveal(child: widget.children[i]),
      if (widget.cta) const Reveal(child: CtaBand()),
      const SiteFooter(),
    ];
    return Stack(
      children: <Widget>[
        ListView.builder(
          controller: _scroll,
          padding: EdgeInsets.zero,
          cacheExtent: 600,
          itemCount: items.length,
          itemBuilder: (BuildContext context, int i) => SmoothWheel(controller: _scroll, child: items[i]),
        ),
        PositionedDirectional(
          start: 18,
          bottom: 18,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              _backToTop(),
              const LangTab(),
            ],
          ),
        ),
      ],
    );
  }

  /// Slides in after a scroll; takes no room while hidden, so the language
  /// tab sits in the corner until then.
  Widget _backToTop() {
    return ValueListenableBuilder<bool>(
      valueListenable: _showTop,
      builder: (BuildContext context, bool show, Widget? child) => AnimatedSize(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
        child: show
            ? Padding(padding: const EdgeInsetsDirectional.only(end: 10), child: child)
            : const SizedBox.shrink(),
      ),
      child: Material(
        color: WebColors.blue,
        elevation: 4,
        borderRadius: BorderRadius.circular(6),
        child: InkWell(
          borderRadius: BorderRadius.circular(6),
          onTap: () => _scroll.animateTo(0, duration: const Duration(milliseconds: 700), curve: Curves.easeInOutCubic),
          child: const SizedBox(
            width: 42,
            height: 42,
            child: Center(child: AppIcon(Icons.keyboard_arrow_up_rounded, color: WebColors.white)),
          ),
        ),
      ),
    );
  }
}

/// Dark band at the top of inner pages: "من نحن" + subtitle.
class PageHeader extends StatelessWidget {
  const PageHeader(this.title, {super.key, this.subtitle = ''});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: context.isMobile ? 40 : 64),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: <Color>[WebColors.black, WebColors.navy],
        ),
      ),
      child: Contained(
        child: Column(
          children: <Widget>[
            Text(title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: context.isMobile ? 28 : 40,
                  fontWeight: FontWeight.w800,
                  color: WebColors.white,
                )),
            if (subtitle.isNotEmpty) ...<Widget>[
              const SizedBox(height: 10),
              Text(subtitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: WebColors.white.withValues(alpha: 0.8))),
            ],
          ],
        ),
      ),
    );
  }
}

/// "ابدأ رحلتك نحو الابتكار" — as at the bottom of every inner page.
class CtaBand extends StatelessWidget {
  const CtaBand({super.key});

  @override
  Widget build(BuildContext context) => WithSettings(builder: _build);

  Widget _build(BuildContext context, Doc s) {
    return Container(
      color: WebColors.surface,
      padding: const EdgeInsets.symmetric(vertical: 56),
      child: Contained(
        child: Column(
          children: <Widget>[
            Text(s.txt('cta_title', const L('ابدأ رحلتك نحو الابتكار', 'Start your journey to innovation')),
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: WebColors.navy)),
            const SizedBox(height: 12),
            Text(
                s.txt(
                    'cta_text',
                    const L('ماذا تنتظر إذا!؟ لا تتردد في التواصل معنا والحصول على استشارة والتواصل معنا مباشرة',
                        "What are you waiting for? Don't hesitate to get in touch with us for a consultation.")),
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, height: 1.8, color: WebColors.muted)),
            const SizedBox(height: 22),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: <Widget>[
                ElevatedButton(
                    onPressed: () => siteGo(context, '/contact'), child: Text(const L('اتصل بنا', 'Contact us').t)),
                OutlinedButton(
                    onPressed: () => siteGo(context, '/request-service'),
                    child: Text(const L('طلب خدمة', 'Request a service').t)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class SocialIcons extends StatelessWidget {
  const SocialIcons({super.key, required this.settings, this.light = false});

  final Doc settings;
  final bool light;

  @override
  Widget build(BuildContext context) {
    final List<(String, IconData, Color)> items = <(String, IconData, Color)>[
      (settings.s('facebook_url'), Icons.facebook_rounded, const Color(0xFF1877F2)),
      (settings.s('linkedin_url'), Icons.business_center_rounded, const Color(0xFF0A66C2)),
      (settings.s('youtube_url'), Icons.play_arrow_rounded, const Color(0xFFFF0000)),
      (settings.s('instagram_url'), Icons.camera_alt_rounded, const Color(0xFF262626)),
      (settings.s('telegram_url'), Icons.send_rounded, const Color(0xFF229ED9)),
    ];
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      alignment: WrapAlignment.center,
      children: <Widget>[
        for (final (String url, IconData icon, Color color) in items)
          if (url.isNotEmpty)
            InkWell(
              onTap: () => openLink(url),
              customBorder: const CircleBorder(),
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                child: AppIcon(icon, size: 18, color: Colors.white),
              ),
            ),
      ],
    );
  }
}

class SiteFooter extends StatelessWidget {
  const SiteFooter({super.key});

  @override
  Widget build(BuildContext context) => WithSettings(builder: _build);

  Widget _build(BuildContext context, Doc s) {
    const TextStyle head = TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800);
    Widget link(L label, String path) => InkWell(
          onTap: () => siteGo(context, path),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Text(label.t, style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w600)),
          ),
        );
    final List<Widget> columns = <Widget>[
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
        Text(const L('خدماتنا', 'Services').t, style: head),
        const SizedBox(height: 12),
        link(const L('تصميم متكامل', 'Integrated Design'), '/services/integrated-design'),
        link(const L('لوحات تنفيذية', 'Shop Drawings'), '/services/shop-drawings'),
        link(const L('اشراف على التنفيذ', 'Site Supervision'), '/services/supervision'),
      ]),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
        Text(const L('الرئيسية', 'Home').t, style: head),
        const SizedBox(height: 12),
        link(const L('من نحن', 'About'), '/about'),
        link(const L('المقالات', 'Articles'), '/articles'),
        link(const L('أعمالنا', 'Projects'), '/projects'),
      ]),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
        Text(const L('تواصل معانا', 'Get in touch').t, style: head),
        const SizedBox(height: 12),
        link(const L('طلب خدمة', 'Request a Service'), '/request-service'),
        link(const L('تواصل معنا', 'Contact'), '/contact'),
      ]),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
        Text(const L('بيانات التواصل', 'Contact details').t, style: head),
        const SizedBox(height: 12),
        if (s.s('address').isNotEmpty)
          Text(s.s('address'), style: const TextStyle(color: Colors.white70)),
        for (final String e in s.l('emails'))
          InkWell(
            onTap: () => openLink('mailto:$e'),
            child: Text(e, style: const TextStyle(color: Colors.white70)),
          ),
        for (final String phone in sitePhones(s.raw('phone')))
          InkWell(
            onTap: () => openLink(telLink(phone)),
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: Text(phone, style: const TextStyle(color: Colors.white70)),
            ),
          ),
      ]),
    ];
    return Container(
      color: WebColors.black,
      padding: const EdgeInsets.only(top: 56, bottom: 24),
      child: Contained(
        child: Column(
          children: <Widget>[
            if (context.isMobile)
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  const Center(child: _Logo(size: 90, white: true)),
                  const SizedBox(height: 24),
                  for (final Widget c in columns) Padding(padding: const EdgeInsets.only(bottom: 22), child: c),
                ],
              )
            else
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  for (final Widget c in columns) Expanded(child: c),
                  const _Logo(size: 110, white: true),
                ],
              ),
            const SizedBox(height: 28),
            const Divider(color: Colors.white12),
            const SizedBox(height: 16),
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 16,
              runSpacing: 12,
              children: <Widget>[
                SocialIcons(settings: s),
                TextButton(
                  onPressed: () => siteGo(context, '/privacy'),
                  child: Text(const L('سياسة الخصوصية', 'Privacy policy').t, style: const TextStyle(color: Colors.white70)),
                ),
                Text(s.s('footer_text', 'Copyright © 2026. All rights reserved to ASEC'),
                    style: const TextStyle(color: Colors.white38, fontSize: 12)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
