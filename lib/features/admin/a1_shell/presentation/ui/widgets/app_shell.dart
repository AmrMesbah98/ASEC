/// Module: admin / a1_shell
///
///*************************** FILE INFO ****************************///
/// File Name: app_shell.dart
/// Purpose: Declares `AppShell` and `ShellSection` — one navigation frame that
///          is a side rail on a desktop, a narrow icon rail on a tablet and a
///          bottom bar on a phone.
/// Author: ASEC team
/// Created: 19/9/2026
/// Updated: 22/10/2026 - Phone "More" opens a full page (`_MorePage`)
///          instead of a bottom sheet, styled like the services_module
///          More list (`_MoreTile`). `ShellSection.phoneCenter`
///          makes a section the phone bar's raised centre button (its
///          tools open as a vertical speed dial above it); `phoneMore` sends one to More.
///          The rail is unchanged.
/// Updated: 29/10/2026 - Rail: a group tab (Calculations) no longer opens the
///          circular menu — tapping it expands its tools as indented
///          sub-tabs right under it; tapping again folds them away. The
///          phone bar keeps its own menu.
/// Updated: 23/10/2026 - On a phone every group tab (bar or "More") opens
///          the vertical list, so the member's Calculators match the admin's.
/// Updated: 22/10/2026 - Selected rail / bar / More items use
///          `AppTheme.accentOn(card)`, so a brand colour close to the card
///          (grey, dark purple in dark mode) still reads.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:asec/core/settings/capture_context.dart';
import 'package:asec/core/custom/110-app_widgets.dart';
import 'package:asec/core/custom/111-app_svg_icon.dart';
import 'package:asec/core/custom/57-custom_dialog_manager.dart';
import 'package:asec/core/custom/113-custom_circular_menu.dart';
import 'package:asec/core/helper/main_helper/platform_helper.dart';
import 'package:asec/core/theme/app_colors.dart';
import 'package:asec/core/theme/app_padding.dart';
import 'package:asec/core/theme/app_radius.dart';
import 'package:asec/core/theme/app_theme.dart';
import 'package:asec/core/theme/theme_controller.dart';
import 'package:asec/features/engagement/e1_engagement/presentation/ui/widgets/member_bar_actions.dart';
import 'package:asec/features/onboarding/o1_splash/presentation/ui/pages/splash_screen.dart';
import 'package:asec/features/onboarding/o2_authentication/domain/entities/app_user.dart';
import 'package:asec/features/onboarding/o2_authentication/presentation/controller/session_controller.dart';
import 'package:asec/features/onboarding/o2_authentication/presentation/ui/widgets/brand_mark.dart';
import 'package:asec/generated/l10n.dart';
import 'package:asec/core/animation/app_animations.dart';
import 'package:asec/core/helper/main_helper/format_helper.dart';
import 'package:asec/core/custom/114-app_messenger.dart';

class ShellSection {
  const ShellSection({
    required this.icon,
    required this.label,
    required this.page,
    this.shortLabel,
    this.id,
    this.phoneMore = false,
    this.phoneCenter = false,
  }) : children = const <ShellSection>[];

  /// ONE TAB, SEVERAL TOOLS. Tapping it (bar, rail or "More") opens a
  /// CustomCircularMenu with [children]; the one picked fills the page.
  /// [AppShell.open] also finds a child by its id.
  const ShellSection.group({
    required this.icon,
    required this.label,
    required this.children,
    this.shortLabel,
    this.id,
    this.phoneMore = false,
    this.phoneCenter = false,
  }) : page = const SizedBox.shrink();

  /// The tools of a group tab; empty for an ordinary section.
  final List<ShellSection> children;

  bool get isGroup => children.isNotEmpty;

  /// PHONE ONLY: never takes a bottom-bar tab — always listed under "More".
  /// The desktop / tablet rail keeps it in its place.
  final bool phoneMore;

  /// PHONE ONLY: the raised round button docked in the middle of the bottom
  /// bar (one section at most — the first marked wins). The desktop / tablet
  /// rail keeps it in its place.
  final bool phoneCenter;

  /// A name other pages can jump to with [AppShell.open] ("videos").
  final String? id;

  final IconData icon;
  final String label;
  final Widget page;

  /// The name under the icon in the PHONE bar, where a long label wraps
  /// onto two lines ("Certificate quizzes" → "Certificate").
  final String? shortLabel;

  String get barLabel => shortLabel ?? label;
}

/// ONE FRAME, THREE SHAPES — and the WIDTH picks, never the platform. A macOS
/// window dragged narrow gets the phone's bottom bar, because at 500pt a
/// 240-wide rail is half the screen.
class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.sections, required this.user});

  final List<ShellSection> sections;
  final AppUser user;

  /// From here the rail shows its labels.
  static const double railLabelWidth = PlatformHelper.desktopLayoutWidth;

  /// From here there is a rail at all; below it, a bottom bar.
  static const double railWidth = PlatformHelper.tabletBreakpoint;

  /// Switches the shell to the section whose [ShellSection.id] is [id] —
  /// how the member's home page jumps to Videos or the converter. False when
  /// there is no shell above [context] or no such section (it is hidden).
  static bool open(BuildContext context, String id) {
    final _ShellScope? scope =
        context.getInheritedWidgetOfExactType<_ShellScope>();
    return scope?.open(id) ?? false;
  }

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  /// When the system back button was last pressed on the first tab — a
  /// second press within [_exitWindow] closes the app.
  DateTime? _lastBack;
  static const Duration _exitWindow = Duration(seconds: 2);

  /// System back on the shell (Android): another tab → back to the first
  /// tab; first tab → "press again" notice; again within 2 s → exit.
  /// Pages pushed on top of the shell are not affected — they pop normally.
  void _onBack() {
    if (_index != 0) {
      _select(0);
      return;
    }
    final DateTime now = DateTime.now();
    if (_lastBack != null && now.difference(_lastBack!) < _exitWindow) {
      SystemNavigator.pop();
      return;
    }
    _lastBack = now;
    AppMessenger.of(context)
      ..hide()
      ..show(AppMessage(
        content: Text(FormatHelper.capitalize(S.of(context).pressBackAgainToExit)),
        duration: _exitWindow,
      ));
  }

  @override
  void initState() {
    super.initState();
    // The admin can switch an account off, including while its owner is
    // looking at it. The session controller notices and the shell leaves.
    SessionController.to.onDeactivated = _forceSignOut;
  }

  @override
  void dispose() {
    SessionController.to.onDeactivated = null;
    super.dispose();
  }

  Future<void> _forceSignOut() async {
    if (!mounted) return;
    await AppRouter.signOut(context);
  }

  Future<void> _confirmSignOut() async {
    final S s = S.of(context);
    final BuildContext pageContext = context;
    await CustomDialogManager.showConfirm(
      context: context,
      title: s.signOutQuestion,
      subtitle: s.signOutBody,
      confirmLabel: s.signOut,
      cancelLabel: s.cancel,
      onConfirm: () => AppRouter.signOut(pageContext),
    );
  }

  void _select(int index) => setState(() => _index = index);

  /// Rail: the group tabs whose sub-tabs are unfolded.
  final Set<int> _expanded = <int>{};

  /// Rail tap: a group folds / unfolds its sub-tabs, anything else opens.
  void _railTap(int i) {
    if (widget.sections[i].isGroup) {
      setState(() {
        if (!_expanded.remove(i)) _expanded.add(i);
      });
    } else {
      _select(i);
    }
  }

  /// Rail: open tool [child] of group [group].
  void _railPick(int group, int child) {
    setState(() {
      _picks[_groupKey(widget.sections[group])] = child;
      _index = group;
    });
  }

  /// The tool picked inside each group tab, keyed by the group's id/label.
  final Map<String, int> _picks = <String, int>{};

  String _groupKey(ShellSection s) => s.id ?? s.label;

  int _pickOf(ShellSection s) =>
      (_picks[_groupKey(s)] ?? 0).clamp(0, s.children.length - 1);

  /// A tap on section [i] from the bar, the rail or "More". A group opens
  /// the circular menu around the tapped control ([itemContext]).
  Future<void> _tap(int i, BuildContext itemContext, {bool vertical = false}) async {
    final ShellSection section = widget.sections[i];
    if (!section.isGroup) {
      _select(i);
      return;
    }
    final Rect anchor = CustomCircularMenu.rectOf(itemContext);
    final int? picked = await CustomCircularMenu.show(
      context: context,
      anchor: anchor,
      items: <CircularMenuItem>[
        for (final ShellSection c in section.children)
          // Short names (Units, Ducts, Pipes, HVAC, Plumbing, Fire) — they
          // sit under small bubbles in the arc.
          CircularMenuItem(icon: c.icon, label: c.barLabel),
      ],
      selected: _index == i ? _pickOf(section) : null,
      vertical: vertical,
    );
    if (picked == null || !mounted) return;
    setState(() {
      _picks[_groupKey(section)] = picked;
      _index = i;
    });
  }

  bool _openById(String id) {
    final int i = widget.sections.indexWhere((ShellSection s) => s.id == id);
    if (i >= 0) {
      _select(i);
      return true;
    }
    // A tool inside a group tab.
    for (int g = 0; g < widget.sections.length; g++) {
      final ShellSection group = widget.sections[g];
      final int c = group.children.indexWhere((ShellSection s) => s.id == id);
      if (c >= 0) {
        setState(() {
          _picks[_groupKey(group)] = c;
          _index = g;
        });
        return true;
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.sizeOf(context).width;
    final bool hasRail = width >= AppShell.railWidth;
    final bool showLabels = width >= AppShell.railLabelWidth;

    // THE SECTION LIST CAN SHRINK UNDER US. The member's "My CV" tab appears
    // and disappears with the admin's switch, live — and an index left
    // pointing past the end would take an IndexedStack down with it.
    final int index = _index.clamp(0, widget.sections.length - 1);
    // For screen capture alerts: the tab on screen.
    final ShellSection current = widget.sections[index];
    final ShellSection shown =
        current.isGroup ? current.children[_pickOf(current)] : current;
    CaptureContext.tabId = shown.id ?? current.id ?? '';
    CaptureContext.tabLabel = shown.label;

    final Widget body = _ShellScope(
      open: _openById,
      child: ShellSwitch(
        switchKey: index,
        child: IndexedStack(
          index: index,
          children: <Widget>[
            for (final ShellSection s in widget.sections)
              if (s.isGroup)
                // Each tool keeps what was typed while switching.
                IndexedStack(
                  index: _pickOf(s),
                  children: <Widget>[
                    for (final ShellSection c in s.children) c.page,
                  ],
                )
              else
                s.page,
          ],
        ),
      ),
    );

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? _) {
        if (!didPop) _onBack();
      },
      child: Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        // Same surface as the side rail, so bar + rail read as one frame
        // around the page. No tint or shadow when content scrolls under it.
        backgroundColor: AppColors.card,
        surfaceTintColor: AppColors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: AppColors.text),
        actionsIconTheme: IconThemeData(color: AppColors.text),
        titleSpacing: hasRail ? AppPadding.h : 16,
        // NO TITLE HERE. Every page draws its own, bigger, with the line
        // that says what the page is for — two titles on one screen is one
        // too many. The bar keeps the controls.
        // On phone there is no rail, so the bar carries the brand — the left
        // side is never an empty strip. With a rail the rail shows it.
        title: hasRail
            ? const SizedBox.shrink()
            : const BrandMark(size: 30),
        // One control only: the avatar. Dark mode and language are set once
        // and forgotten, so they live in its menu instead of the bar.
        actions: <Widget>[
          // Members: saved tips + the bell with the unread count.
          if (!widget.user.isAdmin && !widget.user.isEmpty)
            MemberBarActions(user: widget.user),
          _UserMenu(user: widget.user, onSignOut: _confirmSignOut),
          SizedBox(width: 8.w),
        ],
      ),
      body: hasRail
          ? Row(
              children: <Widget>[
                _Rail(
                  sections: widget.sections,
                  index: index,
                  showLabels: showLabels,
                  expanded: _expanded,
                  pickOf: _pickOf,
                  onSelected: _railTap,
                  onPick: _railPick,
                ),
                Expanded(child: body),
              ],
            )
          : body,
      bottomNavigationBar: hasRail ? null : _bottomBar(context, index),
      // Phone: the centre section (Calculators) is a raised round button
      // docked in the middle of the bar; its tools stack up above it.
      floatingActionButton: hasRail || _centerIndex < 0
          ? null
          : _CenterButton(
              icon: widget.sections[_centerIndex].icon,
              tooltip: widget.sections[_centerIndex].label,
              // 26/10/2026 (Eng. Ahmed Shuhayb): the calculators fan out in
              // a half circle over the button, like a protractor, instead
              // of stacking up the screen.
              // 31/10/2026: the phone row (horizontal), like the bar tabs —
              // without this the narrow phone got the rail's vertical column.
              onTap: (BuildContext c) => _tap(_centerIndex, c, vertical: true),
            ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    ),
    );
  }

  /// THE PHONE BAR: up to four tabs, two each side of the raised centre
  /// button ([ShellSection.phoneCenter]). With more sections than fit, the
  /// last slot is "More", which opens a full page with the rest. A section
  /// picked there keeps "More" highlighted, so the bar says where you are.
  /// Without a centre section the bar holds five.
  static const int _maxTabs = 5;

  /// The section drawn as the centre button, or -1.
  int get _centerIndex =>
      widget.sections.indexWhere((ShellSection s) => s.phoneCenter);

  Widget _bottomBar(BuildContext context, int index) {
    final List<ShellSection> sections = widget.sections;
    final int center = _centerIndex;
    // Who gets a tab: rail order, [ShellSection.phoneMore] last.
    final List<int> regular = <int>[
      for (int i = 0; i < sections.length; i++)
        if (i != center && !sections[i].phoneMore) i,
      for (int i = 0; i < sections.length; i++)
        if (i != center && sections[i].phoneMore) i,
    ];
    final int maxTabs = center < 0 ? _maxTabs : _maxTabs - 1;
    final bool overflow = regular.length > maxTabs;
    final int directCount = overflow ? maxTabs - 1 : regular.length;
    final List<int> direct = regular.take(directCount).toList()..sort();
    // The More page keeps the rail's order.
    final List<int> more = <int>[
      for (int i = 0; i < sections.length; i++)
        if (i != center && !direct.contains(i)) i,
    ];
    final bool inMore = overflow && more.contains(index);

    final List<Widget> tabs = <Widget>[
      for (final int i in direct)
        Expanded(
          child: _BarItem(
            icon: sections[i].icon,
            label: sections[i].barLabel,
            selected: !inMore && index == i,
            // Phone: a group tab (the member's Calculators) opens the same
            // vertical list as the admin's centre button, not the half circle.
            onTap: (BuildContext c) => _tap(i, c, vertical: true),
          ),
        ),
      if (overflow)
        Expanded(
          child: _BarItem(
            icon: inMore ? sections[index].icon : Icons.more_horiz_rounded,
            label: inMore ? sections[index].barLabel : S.of(context).moreTab,
            selected: inMore,
            onTap: (BuildContext c) => _openMore(c, more, index),
          ),
        ),
    ];
    // The gap the docked centre button sits in.
    if (center >= 0) {
      tabs.insert((tabs.length / 2).ceil(), SizedBox(width: 72.w));
    }

    return Material(
      color: AppColors.card,
      elevation: 0,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 8.h),
          child: Row(children: tabs),
        ),
      ),
    );
  }

  /// "More" opens a FULL PAGE (not a bottom sheet) with the sections that
  /// did not fit in the bar. Picking one closes the page and opens it in the
  /// shell; a group opens its circular menu over the "More" tab.
  Future<void> _openMore(
      BuildContext context, List<int> more, int current) async {
    final int? picked = await Navigator.of(context).push<int>(
      MaterialPageRoute<int>(
        builder: (_) => _MorePage(
          sections: widget.sections,
          more: more,
          current: current,
        ),
      ),
    );
    if (picked != null && context.mounted) {
      await _tap(picked, context, vertical: true);
    }
  }
}

/// The phone's "More" page: the sections at [more], as cards.
/// Pops with the picked section's index.
class _MorePage extends StatelessWidget {
  const _MorePage({
    required this.sections,
    required this.more,
    required this.current,
  });

  final List<ShellSection> sections;

  /// Indexes into [sections], in rail order.
  final List<int> more;
  final int current;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.card,
        surfaceTintColor: AppColors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: AppColors.text),
        title: Text(
          FormatHelper.capitalize(S.of(context).moreTab),
          style: StyleText.fontSize16Weight600.copyWith(color: AppColors.text),
        ),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: EdgeInsets.only(top: 16.h, bottom: 12.h),
          children: <Widget>[
            for (final int i in more)
              _MoreTile(
                section: sections[i],
                selected: i == current,
                onTap: () => Navigator.of(context).pop(i),
              ),
          ],
        ),
      ),
    );
  }
}

/// One row of the More page — the same card as the services_module More
/// list: card background, 8 radius, tinted icon box, name, chevron.
class _MoreTile extends StatelessWidget {
  const _MoreTile({
    required this.section,
    required this.selected,
    required this.onTap,
  });

  final ShellSection section;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 5.w),
      margin: EdgeInsets.symmetric(vertical: 5.h, horizontal: 10.w),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8.r),
        color: AppColors.card,
      ),
      child: InkWell(
        splashColor: AppColors.transparent,
        highlightColor: AppColors.transparent,
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        child: Row(
          children: <Widget>[
            Container(
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(.15),
                borderRadius: BorderRadius.circular(8.r),
              ),
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 10.h),
              child: AppIcon(section.icon, size: 20.sp, color: AppColors.primary),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Text(
                FormatHelper.capitalize(section.label),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: StyleText.fontSize16Weight400.copyWith(
                  color: selected ? AppTheme.accentOn(AppColors.card) : AppColors.text,
                ),
              ),
            ),
            // Mirrors itself in Arabic (matchTextDirection).
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16.sp,
              color: AppColors.text,
            ),
          ],
        ),
      ),
    );
  }
}

/// The phone bar's raised round centre button. Gets its own context, so the
/// circular menu opens around it.
class _CenterButton extends StatelessWidget {
  const _CenterButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final ValueChanged<BuildContext> onTap;

  @override
  Widget build(BuildContext context) {
    final double size = 58.r;
    return Tooltip(
      message: tooltip,
      child: Padding(
        padding: EdgeInsets.only(top: 12.h),
        // The circle's own context: the menu's ✕ is drawn exactly on it.
        child: Builder(
          builder: (BuildContext circleContext) => GestureDetector(
            onTapDown: (_) => HapticFeedback.lightImpact(),
            onTap: () => onTap(circleContext),
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary,
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.35),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: AppIcon(icon, size: 26.sp, color: AppColors.textButton),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Lets a page inside the shell switch sections (see [AppShell.open]).
class _ShellScope extends InheritedWidget {
  const _ShellScope({required this.open, required super.child});

  final bool Function(String id) open;

  @override
  bool updateShouldNotify(_ShellScope oldWidget) => false;
}

/// One phone-bar tab. The selected one sits in a soft pill that wraps the
/// icon AND its name, not just the icon.
class _BarItem extends StatelessWidget {
  const _BarItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;

  /// Gets this item's own context, so a group can anchor its menu here.
  final ValueChanged<BuildContext> onTap;

  @override
  Widget build(BuildContext context) {
    // Selected ink: primary, unless the chosen primary is too close to the
    // card to read (22/10/2026 — a grey brand colour vanished on dark mode).
    final Color color = selected
        ? AppTheme.accentOn(AppColors.card)
        : AppColors.secondaryText;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 3.w),
      child: Material(
        color: AppColors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14.r),
          onTap: () => onTap(context),
          child: AnimatedContainer(
            duration: AppMotion.fast,
            curve: AppMotion.curve,
            padding: EdgeInsets.symmetric(vertical: 7.h, horizontal: 4.w),
            decoration: BoxDecoration(
              color: selected ? AppColors.primary.withOpacity(0.22) : AppColors.transparent,
              borderRadius: BorderRadius.circular(14.r),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                AppIcon(icon, size: 21.sp, color: color),
                SizedBox(height: 3.h),
                Text(
                  FormatHelper.capitalize(label),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: (selected
                          ? StyleText.fontSize11Weight700
                          : StyleText.fontSize11Weight500)
                      .copyWith(color: color),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Rail extends StatelessWidget {
  const _Rail({
    required this.sections,
    required this.index,
    required this.showLabels,
    required this.expanded,
    required this.pickOf,
    required this.onSelected,
    required this.onPick,
  });

  final List<ShellSection> sections;
  final int index;
  final bool showLabels;

  /// Group tabs whose sub-tabs are shown.
  final Set<int> expanded;

  /// The open tool of a group tab.
  final int Function(ShellSection group) pickOf;
  final ValueChanged<int> onSelected;
  final void Function(int group, int child) onPick;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: showLabels ? 232.w : 78.w,
      color: AppColors.card,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: AppPadding.h,
              vertical: 18.h,
            ),
            child: showLabels
                ? const BrandMark(size: 40)
                : const BrandMark(size: 34, showName: false),
          ),
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.symmetric(horizontal: 8.w),
              itemCount: sections.length,
              itemBuilder: (BuildContext context, int i) {
                final ShellSection s = sections[i];
                final bool open = s.isGroup && expanded.contains(i);
                final Widget item = _RailItem(
                  section: s,
                  // A group lights up only while folded (its open tool
                  // shows the highlight when unfolded).
                  selected: i == index && !open,
                  showLabel: showLabels,
                  onTap: (_) => onSelected(i),
                );
                if (!s.isGroup) return item;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    item,
                    AnimatedSize(
                      duration: AppMotion.fast,
                      curve: AppMotion.curve,
                      alignment: Alignment.topCenter,
                      child: open
                          ? Padding(
                              padding: EdgeInsetsDirectional.only(
                                start: showLabels ? 20.w : 0,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: <Widget>[
                                  for (int c = 0; c < s.children.length; c++)
                                    _RailItem(
                                      section: s.children[c],
                                      selected: i == index && pickOf(s) == c,
                                      showLabel: showLabels,
                                      dense: true,
                                      onTap: (_) => onPick(i, c),
                                    ),
                                ],
                              ),
                            )
                          : const SizedBox(width: double.infinity),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _RailItem extends StatelessWidget {
  const _RailItem({
    required this.section,
    required this.selected,
    required this.showLabel,
    required this.onTap,
    this.dense = false,
  });

  final ShellSection section;
  final bool selected;
  final bool showLabel;

  /// Sub-tab: a little smaller and tighter, with the short name
  /// (Units, Ducts, Pipes, HVAC, Plumbing, Firefighting).
  final bool dense;

  /// Gets this item's own context, so a group can anchor its menu here.
  final ValueChanged<BuildContext> onTap;

  @override
  Widget build(BuildContext context) {
    // Selected ink: primary, unless the chosen primary is too close to the
    // card to read (22/10/2026 — a grey brand colour vanished on dark mode).
    final Color color = selected
        ? AppTheme.accentOn(AppColors.card)
        : AppColors.secondaryText;

    final Widget content = AnimatedContainer(
      duration: AppMotion.fast,
      curve: AppMotion.curve,
      margin: EdgeInsets.symmetric(vertical: dense ? 2.h : 3.h),
      padding: EdgeInsets.symmetric(
        horizontal: 12.w,
        vertical: dense ? 9.h : 12.h,
      ),
      decoration: BoxDecoration(
        color: selected
            ? AppColors.primary.withOpacity(0.22)
            : AppColors.transparent,
        borderRadius: AppRadius.containerR,
      ),
      child: Row(
        mainAxisAlignment:
            showLabel ? MainAxisAlignment.start : MainAxisAlignment.center,
        children: <Widget>[
          AppIcon(section.icon, size: dense ? 18.sp : 20.sp, color: color),
          if (showLabel) ...<Widget>[
            SizedBox(width: 12.w),
            Expanded(
              child: Text(
                FormatHelper.capitalize(dense ? section.barLabel : section.label),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: (selected
                        ? StyleText.fontSize14Weight600
                        : StyleText.fontSize14Weight400)
                    .copyWith(color: color),
              ),
            ),
          ],
        ],
      ),
    );

    return Material(
      color: AppColors.transparent,
      child: InkWell(
        borderRadius: AppRadius.containerR,
        onTap: () => onTap(context),
        child: showLabel
            ? content
            : Tooltip(message: section.label, child: content),
      ),
    );
  }
}

class _UserMenu extends StatelessWidget {
  const _UserMenu({required this.user, required this.onSignOut});

  final AppUser user;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    final S s = S.of(context);

    return PopupMenuButton<int>(
      tooltip: user.displayName,
      offset: Offset(0, 46.h),
      icon: AppAvatar(name: user.displayName, size: 32),
      onSelected: (int value) {
        final ThemeController theme = ThemeController.to;
        switch (value) {
          case 1:
            theme.toggleDarkMode();
          case 2:
            theme.toggleLanguage();
          default:
            onSignOut();
        }
      },
      itemBuilder: (BuildContext context) => <PopupMenuEntry<int>>[
        PopupMenuItem<int>(
          enabled: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(FormatHelper.capitalize(user.displayName), style: StyleText.fontSize14Weight600),
              Text(
                FormatHelper.capitalize(user.email),
                style: StyleText.fontSize12Weight400
                    .copyWith(color: AppColors.secondaryText),
              ),
              SizedBox(height: 4.h),
              Text(
                FormatHelper.capitalize(user.role.label(context)),
                style: StyleText.fontSize11Weight600
                    .copyWith(color: AppColors.primary),
              ),
            ],
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem<int>(
          value: 1,
          child: Row(
            children: <Widget>[
              AppIcon(
                ThemeController.to.isDarkMode.value
                    ? Icons.light_mode_rounded
                    : Icons.dark_mode_rounded,
                size: 18.sp,
              ),
              SizedBox(width: 10.w),
              Text(FormatHelper.capitalize(s.darkMode), style: StyleText.fontSize14Weight500),
              const Spacer(),
              AppIcon(
                ThemeController.to.isDarkMode.value
                    ? Icons.toggle_on_rounded
                    : Icons.toggle_off_rounded,
                size: 24.sp,
                color: ThemeController.to.isDarkMode.value
                    ? AppColors.primary
                    : AppColors.secondaryText,
              ),
            ],
          ),
        ),
        PopupMenuItem<int>(
          value: 2,
          child: Row(
            children: <Widget>[
              AppIcon(Icons.translate_rounded, size: 18.sp),
              SizedBox(width: 10.w),
              Text(FormatHelper.capitalize(s.language), style: StyleText.fontSize14Weight500),
            ],
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem<int>(
          value: 0,
          child: Row(
            children: <Widget>[
              AppIcon(Icons.logout_rounded, size: 18.sp, color: AppColors.red),
              SizedBox(width: 10.w),
              Text(
                FormatHelper.capitalize(s.signOut),
                style: StyleText.fontSize14Weight500
                    .copyWith(color: AppColors.red),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
