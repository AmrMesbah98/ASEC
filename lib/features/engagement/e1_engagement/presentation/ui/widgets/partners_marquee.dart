/// Module: engagement / e1_engagement
///
///*************************** FILE INFO ****************************///
/// File Name: partners_marquee.dart
/// Purpose: Declares `PartnersMarquee` — the partners in ONE ROW that
///          scrolls by itself, without end, on EVERY platform (phones,
///          tablets, Mac, Windows and the website).
/// Author: ASEC team
/// Created: 29/10/2026
///
/// THE ANIMATION
///  • The row glides on its own and loops forever (the logos are repeated,
///    so the end never shows). Follows the reading direction (RTL too).
///  • Each card bobs up and down gently, a little out of step with its
///    neighbours, like a wave running along the row.
///  • Cards rise and fade in one after another when the row first shows.
///  • A light sheen sweeps across each card now and then.
///  • The edges fade out, so logos slide in and out softly.
///  • Hover (mouse) — the row pauses and the card lifts, grows and glows.
///    Touch / drag — the member can scroll it by hand; it carries on by
///    itself a moment after they let go.
///  • "Reduce motion" (system setting) — the row stands still, no bobbing.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'package:asec/core/theme/app_colors.dart';
import 'package:asec/features/engagement/e1_engagement/presentation/ui/widgets/partners_orbit.dart'
    show PartnerLogoItem;

class PartnersMarquee extends StatefulWidget {
  const PartnersMarquee({
    super.key,
    required this.items,
    this.speed = 38,
    this.accent,
    this.cardColor,
    this.textColor,
    this.showNames = true,
  });

  final List<PartnerLogoItem> items;

  /// Logical pixels per second.
  final double speed;

  /// FOR THE WEBSITE, which has its own colours and no app theme. Left
  /// null, the app's theme is used.
  final Color? accent;
  final Color? cardColor;
  final Color? textColor;

  /// The partner's name under its logo.
  final bool showNames;

  @override
  State<PartnersMarquee> createState() => _PartnersMarqueeState();
}

class _PartnersMarqueeState extends State<PartnersMarquee>
    with TickerProviderStateMixin {
  final ScrollController _scroll = ScrollController();

  /// Seconds since the row appeared — drives the bob, sheen and entrance.
  final ValueNotifier<double> _time = ValueNotifier<double>(0);

  late final Ticker _ticker = createTicker(_tick);
  Duration _last = Duration.zero;

  /// Slows to a stop on hover and speeds back up after (0 … 1).
  double _pace = 1;
  bool _hovered = false;
  bool _touching = false;
  DateTime _resumeAt = DateTime.fromMillisecondsSinceEpoch(0);

  /// Width of one card + the gap after it (set by build).
  double _extent = 150;

  /// Repeats of the partner list each way — the row never reaches an end.
  static const int _loops = 2000;

  @override
  void initState() {
    super.initState();
    _ticker.start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _scroll.dispose();
    _time.dispose();
    super.dispose();
  }

  /// The system's "reduce motion" — read in build.
  bool _still = false;

  void _tick(Duration now) {
    final double dt =
        ((now - _last).inMicroseconds / 1e6).clamp(0.0, 0.05).toDouble();
    _last = now;
    if (!mounted) return;
    final bool still = _still;
    if (!still) _time.value += dt;

    final bool held = _hovered ||
        _touching ||
        DateTime.now().isBefore(_resumeAt) ||
        still;
    // Ease the speed up / down instead of stopping dead.
    final double target = held ? 0 : 1;
    _pace += (target - _pace) * math.min(1, dt * 5);

    if (!_scroll.hasClients || widget.items.isEmpty) return;
    final ScrollPosition p = _scroll.position;
    if (_pace > 0.001 && !_touching) {
      final double set = _extent * widget.items.length;
      double next = p.pixels + widget.speed * _pace * dt;
      // Keep well inside the list: jump back one full set (looks the same).
      if (next > p.maxScrollExtent - set * 2) next -= set * (_loops ~/ 2);
      _scroll.jumpTo(next);
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<PartnerLogoItem> items = widget.items;
    if (items.isEmpty) return const SizedBox.shrink();
    _still = MediaQuery.maybeDisableAnimationsOf(context) ?? false;

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints c) {
        final double width = c.maxWidth.isFinite ? c.maxWidth : 400;
        // Phone ~ 108, tablet ~ 132, desktop / site ~ 156.
        double card = width < 500 ? 108 : (width < 1000 ? 132 : 156);
        // Given a height (desktop home, no page scroll): fit inside it.
        if (c.hasBoundedHeight) {
          final double fit = (c.maxHeight - 34) / (widget.showNames ? 1.05 : 0.8);
          card = math.max(72.0, math.min(card, fit));
        }
        final double gap = card * 0.16;
        _extent = card + gap;
        final double cardH = card * (widget.showNames ? 1.05 : 0.8);
        // Room for the bob and the hover lift + glow.
        final double height = cardH + 34;

        // Start in the middle so dragging back works too.
        final double startAt = _extent * items.length * (_loops ~/ 2);

        return SizedBox(
          height: height,
          child: MouseRegion(
            onEnter: (_) => _hovered = true,
            onExit: (_) => _hovered = false,
            child: Listener(
              onPointerDown: (_) => _touching = true,
              onPointerUp: (_) => _release(),
              onPointerCancel: (_) => _release(),
              child: ShaderMask(
                // Soft fade at both ends.
                shaderCallback: (Rect r) => const LinearGradient(
                  colors: <Color>[
                    Colors.transparent,
                    Colors.black,
                    Colors.black,
                    Colors.transparent,
                  ],
                  stops: <double>[0, 0.08, 0.92, 1],
                ).createShader(r),
                blendMode: BlendMode.dstIn,
                child: ListView.builder(
                  controller: _jumpOnce(startAt),
                  scrollDirection: Axis.horizontal,
                  itemExtent: _extent,
                  itemCount: items.length * _loops,
                  physics: const BouncingScrollPhysics(),
                  itemBuilder: (BuildContext context, int i) {
                    final int n = i % items.length;
                    return Padding(
                      padding: EdgeInsetsDirectional.only(end: gap),
                      child: Center(
                        child: _PartnerCard(
                          item: items[n],
                          // Same phase after the loop-back jump (a whole
                          // number of these blocks), so nothing twitches.
                          index: i % (items.length * 8),
                          width: card,
                          height: cardH,
                          time: _time,
                          accent: widget.accent ?? AppColors.primary,
                          cardColor: widget.cardColor ?? AppColors.card,
                          textColor: widget.textColor ?? AppColors.text,
                          showName: widget.showNames,
                          // Cards on the first screen come in one by one.
                          // Later ones (scrolling in) appear at once.
                          entranceDelay: math.min(n * 0.09, 0.9),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  bool _placed = false;

  /// Puts the row in the middle of its long list the first time it lays out.
  ScrollController _jumpOnce(double to) {
    if (!_placed) {
      _placed = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scroll.hasClients) _scroll.jumpTo(to);
      });
    }
    return _scroll;
  }

  void _release() {
    _touching = false;
    // Let a fling settle, then carry on by itself.
    _resumeAt = DateTime.now().add(const Duration(milliseconds: 1400));
  }
}

class _PartnerCard extends StatefulWidget {
  const _PartnerCard({
    required this.item,
    required this.index,
    required this.width,
    required this.height,
    required this.time,
    required this.accent,
    required this.cardColor,
    required this.textColor,
    required this.showName,
    required this.entranceDelay,
  });

  final PartnerLogoItem item;
  final int index;
  final double width;
  final double height;
  final ValueNotifier<double> time;
  final Color accent;
  final Color cardColor;
  final Color textColor;
  final bool showName;
  final double entranceDelay;

  @override
  State<_PartnerCard> createState() => _PartnerCardState();
}

class _PartnerCardState extends State<_PartnerCard>
    with SingleTickerProviderStateMixin {
  bool _hover = false;

  /// Rise + fade in, once.
  late final AnimationController _enter = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  );

  @override
  void initState() {
    super.initState();
    if (widget.time.value > 1.5) {
      _enter.value = 1;
      return;
    }
    Future<void>.delayed(
      Duration(milliseconds: (widget.entranceDelay * 1000).round()),
      () {
        if (mounted) _enter.forward();
      },
    );
  }

  @override
  void dispose() {
    _enter.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double w = widget.width;
    final double logo = w * (widget.showName ? 0.5 : 0.56);
    final Color accent = widget.accent;

    final Widget body = MouseRegion(
      cursor: SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: Tooltip(
        message: widget.item.name,
        child: AnimatedScale(
          scale: _hover ? 1.08 : 1,
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutBack,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOut,
            width: w,
            height: widget.height,
            transform: Matrix4.translationValues(0, _hover ? -6 : 0, 0),
            decoration: BoxDecoration(
              color: widget.cardColor,
              borderRadius: BorderRadius.circular(w * 0.16),
              border: Border.all(
                color: _hover ? accent.withOpacity(0.55) : accent.withOpacity(0.10),
                width: 1.2,
              ),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: _hover
                      ? accent.withOpacity(0.28)
                      : Colors.black.withOpacity(0.07),
                  blurRadius: _hover ? 22 : 12,
                  offset: Offset(0, _hover ? 10 : 5),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: <Widget>[
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Container(
                        width: logo,
                        height: logo,
                        padding: EdgeInsets.all(logo * 0.1),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(logo * 0.24),
                        ),
                        child: Image.network(
                          widget.item.logoUrl,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => Center(
                            child: Text(
                              widget.item.name.isEmpty
                                  ? '?'
                                  : widget.item.name.characters.first.toUpperCase(),
                              style: TextStyle(
                                color: accent,
                                fontWeight: FontWeight.w700,
                                fontSize: logo * 0.4,
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (widget.showName) ...<Widget>[
                        SizedBox(height: w * 0.07),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: w * 0.08),
                          child: Text(
                            widget.item.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: DefaultTextStyle.of(context).style.copyWith(
                                  color: widget.textColor,
                                  fontWeight: FontWeight.w600,
                                  fontSize: (w * 0.1).clamp(11.0, 15.0),
                                  decoration: TextDecoration.none,
                                ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                // The sheen: a soft light band crossing the card every few
                // seconds, each card at its own moment.
                Positioned.fill(
                  child: IgnorePointer(
                    child: ValueListenableBuilder<double>(
                      valueListenable: widget.time,
                      builder: (BuildContext context, double t, Widget? _) {
                        const double every = 5.5;
                        final double phase =
                            ((t + widget.index * 0.7) % every) / 1.1; // 0…1 sweeps
                        if (phase > 1) return const SizedBox.shrink();
                        final double x = -1.6 + 3.2 * phase;
                        return DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment(x - 0.6, -1),
                              end: Alignment(x + 0.6, 1),
                              colors: <Color>[
                                Colors.white.withOpacity(0),
                                Colors.white.withOpacity(0.22),
                                Colors.white.withOpacity(0),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    // The gentle wave (bob) + the entrance.
    return AnimatedBuilder(
      animation: Listenable.merge(<Listenable>[widget.time, _enter]),
      builder: (BuildContext context, Widget? child) {
        final double e = Curves.easeOutCubic.transform(_enter.value);
        final double bob = math.sin(widget.time.value * 1.6 + widget.index * 0.8) * 4;
        return Opacity(
          opacity: e,
          child: Transform.translate(
            offset: Offset(0, bob + (1 - e) * 24),
            child: child,
          ),
        );
      },
      child: body,
    );
  }
}
