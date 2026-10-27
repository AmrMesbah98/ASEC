/// Module: engagement / e1_engagement
///
///*************************** FILE INFO ****************************///
/// File Name: partners_spotlight.dart
/// Purpose: Declares `PartnersSpotlight` — the partners on the member's home
///          page in the MAC and WINDOWS apps (design "B · Spotlight"): one
///          partner at a time in a big card — real logo and name — with a
///          soft pulsing glow behind it. Every 3.2 s the next one comes
///          forward (fade + rise + scale). Beside it, a row of small logos;
///          the active one is lifted and shows a progress bar that fills
///          until the switch. Click a logo to jump to it; hover the big card
///          to hold it.
///
///          Phones, tablets and the website keep the 3D ring
///          (PartnersOrbit) — see PartnersSection.
/// Author: ASEC team
/// Created: 27/10/2026

import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:asec/core/helper/main_helper/format_helper.dart';
import 'package:asec/core/theme/app_colors.dart';
import 'package:asec/core/theme/app_theme.dart';
import 'package:asec/features/engagement/e1_engagement/presentation/ui/widgets/partners_orbit.dart';
import 'package:asec/generated/l10n.dart';

class PartnersSpotlight extends StatefulWidget {
  const PartnersSpotlight({
    super.key,
    required this.items,
    this.interval = const Duration(milliseconds: 3200),
  });

  final List<PartnerLogoItem> items;

  /// How long each partner stays in front.
  final Duration interval;

  @override
  State<PartnersSpotlight> createState() => _PartnersSpotlightState();
}

class _PartnersSpotlightState extends State<PartnersSpotlight>
    with TickerProviderStateMixin {
  int _at = 0;
  bool _held = false;

  /// Fills the active thumbnail's bar; when full, the next partner comes.
  late final AnimationController _progress =
      AnimationController(vsync: this, duration: widget.interval)
        ..addStatusListener((AnimationStatus s) {
          if (s == AnimationStatus.completed && mounted) _next();
        });

  /// The glow behind the big card, breathing.
  late final AnimationController _glow = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 4),
  )..repeat(reverse: true);

  @override
  void initState() {
    super.initState();
    if (widget.items.length > 1) _progress.forward(from: 0);
  }

  @override
  void didUpdateWidget(PartnersSpotlight old) {
    super.didUpdateWidget(old);
    // The admin removed partners while this is on screen.
    if (_at >= widget.items.length) _at = 0;
    if (widget.items.length > 1 && !_progress.isAnimating && !_held) {
      _progress.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _progress.dispose();
    _glow.dispose();
    super.dispose();
  }

  void _next() => _go((_at + 1) % widget.items.length);

  void _go(int i) {
    setState(() => _at = i);
    if (widget.items.length > 1 && !_held) _progress.forward(from: 0);
  }

  void _hold(bool hold) {
    _held = hold;
    if (hold) {
      _progress.stop();
    } else if (widget.items.length > 1) {
      _progress.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<PartnerLogoItem> items = widget.items;
    if (items.isEmpty) return const SizedBox.shrink();
    final int at = _at.clamp(0, items.length - 1);

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints c) {
        // Fits the space the home page leaves (it has no page scroll).
        final double height = c.hasBoundedHeight
            ? math.min(c.maxHeight, 420)
            : 360;
        final double cardH = height * 0.94;
        final double logo = (cardH * 0.62).clamp(72.0, 260.0);

        return SizedBox(
          height: height,
          child: Row(
            children: <Widget>[
              Expanded(
                flex: 4,
                child: _Side(
                  items: items,
                  at: at,
                  progress: _progress,
                  onPick: _go,
                  compact: height < 260,
                ),
              ),
              const SizedBox(width: 32),
              Expanded(
                flex: 6,
                child: MouseRegion(
                  onEnter: (_) => _hold(true),
                  onExit: (_) => _hold(false),
                  child: Stack(
                    alignment: Alignment.center,
                    children: <Widget>[
                      // The breathing glow.
                      AnimatedBuilder(
                        animation: _glow,
                        builder: (BuildContext context, Widget? _) {
                          final double t = Curves.easeInOut.transform(_glow.value);
                          return Transform.scale(
                            scale: 1 + 0.12 * t,
                            child: Container(
                              width: cardH * 1.05,
                              height: cardH * 1.05,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: <Color>[
                                    AppColors.primary.withOpacity(0.16 + 0.12 * t),
                                    AppColors.primary.withOpacity(0),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      // The partner in front: fade + rise + scale in.
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 600),
                        switchInCurve: const Cubic(0.2, 0.8, 0.2, 1),
                        switchOutCurve: Curves.easeIn,
                        transitionBuilder: (Widget child, Animation<double> a) =>
                            FadeTransition(
                          opacity: a,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0, 0.05),
                              end: Offset.zero,
                            ).animate(a),
                            child: ScaleTransition(
                              scale: Tween<double>(begin: 0.96, end: 1).animate(a),
                              child: child,
                            ),
                          ),
                        ),
                        child: _FeatureCard(
                          key: ValueKey<int>(at),
                          item: items[at],
                          index: at,
                          total: items.length,
                          height: cardH,
                          logo: logo,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// "OUR PARTNERS", the current partner's name, and the row of small logos.
class _Side extends StatelessWidget {
  const _Side({
    required this.items,
    required this.at,
    required this.progress,
    required this.onPick,
    required this.compact,
  });

  final List<PartnerLogoItem> items;
  final int at;
  final Animation<double> progress;
  final ValueChanged<int> onPick;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final S s = S.of(context);
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          s.engPartners.toUpperCase(),
          style: StyleText.fontSize13Weight600.copyWith(
            color: AppColors.primary,
            letterSpacing: 3,
          ),
        ),
        const SizedBox(height: 8),
        if (!compact) Text(
          FormatHelper.capitalize(s.engPartnersSub),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: (compact ? StyleText.fontSize18Weight700 : StyleText.fontSize22Weight700)
              .copyWith(color: AppColors.text),
        ),
        SizedBox(height: compact ? 10 : 16),
        // 3 per row, the rows under each other; scrolls if they do not fit.
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.only(top: 4, bottom: 8),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              mainAxisExtent: 64,
            ),
            itemCount: items.length,
            itemBuilder: (BuildContext context, int i) => _Thumb(
              item: items[i],
              active: i == at,
              progress: progress,
              onTap: () => onPick(i),
            ),
          ),
        ),
      ],
    );
  }
}

class _Thumb extends StatefulWidget {
  const _Thumb({
    required this.item,
    required this.active,
    required this.progress,
    required this.onTap,
  });

  final PartnerLogoItem item;
  final bool active;
  final Animation<double> progress;
  final VoidCallback onTap;

  @override
  State<_Thumb> createState() => _ThumbState();
}

class _ThumbState extends State<_Thumb> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final bool active = widget.active;
    return Tooltip(
      message: widget.item.name,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
            transform: Matrix4.translationValues(0, active || _hover ? -3 : 0, 0),
            decoration: BoxDecoration(
              color: active ? AppColors.card : AppColors.card.withOpacity(0.55),
              borderRadius: BorderRadius.circular(14),
              boxShadow: active
                  ? <BoxShadow>[
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.22),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ]
                  : const <BoxShadow>[],
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: <Widget>[
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: _Logo(item: widget.item, size: 34),
                  ),
                ),
                if (active)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: AnimatedBuilder(
                      animation: widget.progress,
                      builder: (BuildContext context, Widget? _) => Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: FractionallySizedBox(
                          widthFactor: widget.progress.value,
                          child: Container(height: 4, color: AppColors.primary),
                        ),
                      ),
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

/// The big card: the partner's logo and name, "02 / 08".
class _FeatureCard extends StatelessWidget {
  const _FeatureCard({
    super.key,
    required this.item,
    required this.index,
    required this.total,
    required this.height,
    required this.logo,
  });

  final PartnerLogoItem item;
  final int index;
  final int total;
  final double height;
  final double logo;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: height,
      constraints: const BoxConstraints(maxWidth: 680),
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(28),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withOpacity(0.10),
            blurRadius: 50,
            offset: const Offset(0, 22),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Container(
            width: logo,
            height: logo,
            padding: EdgeInsets.all(logo * 0.08),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(logo * 0.26),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: _Logo(item: item, size: logo * 0.84),
          ),
          SizedBox(height: height * 0.05),
          Text(
            item.name.isEmpty ? '—' : item.name,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: StyleText.fontSize22Weight700.copyWith(
              color: AppColors.text,
              fontSize: (height * 0.09).clamp(18.0, 30.0),
            ),
          ),
        ],
      ),
    );
  }
}

/// The partner's logo; its first letter if the image cannot load.
class _Logo extends StatelessWidget {
  const _Logo({required this.item, required this.size});

  final PartnerLogoItem item;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Image.network(
        item.logoUrl,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => Center(
          child: Text(
            item.name.isEmpty ? '?' : item.name.characters.first.toUpperCase(),
            style: StyleText.fontSize18Weight700.copyWith(color: AppColors.primary),
          ),
        ),
      ),
    );
  }
}
