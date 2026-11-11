/// Module: web / site
///
///*************************** FILE INFO ****************************///
/// File Name: download_button.dart
/// Purpose: "Download for Windows" — the animated button in the site's top
///          bar (and the mobile menu) that downloads the latest ASEC
///          Windows build.
/// Author: ASEC team
/// Created: 25/10/2026
///
/// WHERE THE FILE COMES FROM (25/10/2026): the WEBSITE serves it. The
/// release workflow copies the installer to Firebase Storage
/// (downloads/ASEC-Setup-<tag>.exe + downloads/latest.json) and the button
/// downloads it from there, so visitors never land on GitHub. Until that
/// copy exists the GitHub release file is used, as before:
///
/// every `v*` tag builds the Windows app on
/// GitHub Actions (.github/workflows/windows-release.yml) and attaches
/// `ASEC-Setup.exe` (the installer) and `ASEC-windows.zip` (portable) to
/// that tag's release; the button offers the installer, else the zip. [WindowsRelease] asks the
/// GitHub API for the LATEST release once per visit, so the button always
/// offers the newest version and shows its tag ("v1.0.3"). The panel can
/// override the link (Site settings → Downloads) and hide the button
/// (Control → "Windows download button").
///
/// The button is hidden until there is something to download: no release
/// yet and no link in the panel = no button.
///
/// ANIMATION
///   idle        — a light sweep across the button every few seconds, a
///                 soft pulsing glow and a bobbing arrow; grows on hover.
///   downloading — the arrow drops into the button again and again while a
///                 progress fill crosses it (the browser's own download
///                 starts at the same moment).
///   done        — turns green with a popping ✓ "Download started", then
///                 back to idle.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import 'package:asec/core/custom/111-app_svg_icon.dart';
import 'package:asec/features/web/core/i18n.dart';
import 'package:asec/features/web/core/theme.dart';
import 'package:asec/core/helper/main_helper/format_helper.dart';

/// The GitHub repository the Windows build is released from.
const String kReleaseRepo = 'AmrMesbah98/asec-app';

/// The installer the workflow attaches to every release (preferred).
const String kWindowsSetupName = 'ASEC-Setup.exe';

/// The portable zip attached beside it (fallback).
const String kWindowsAssetName = 'ASEC-windows.zip';

/// Where the release workflow publishes the installer for the website:
/// Firebase Storage, `downloads/` (public read — storage.rules).
const String kStorageBucket = 'asec-a811b.firebasestorage.app';
const String kStorageFolder = 'downloads';
const String _storageBase = 'https://firebasestorage.googleapis.com/v0/b/$kStorageBucket/o';

class WindowsReleaseInfo {
  const WindowsReleaseInfo({required this.version, required this.url});

  /// The release tag, e.g. "v1.0.3".
  final String version;

  /// Direct download link of the installer (or the zip).
  final String url;
}

/// The latest GitHub release with a Windows zip — fetched once per visit.
abstract final class WindowsRelease {
  static final ValueNotifier<WindowsReleaseInfo?> latest = ValueNotifier<WindowsReleaseInfo?>(null);
  static bool _started = false;

  static void load() {
    if (_started) return;
    _started = true;
    unawaited(_fetch());
  }

  static Future<void> _fetch() async {
    // 1. The website's own copy (Firebase Storage). The visitor downloads
    //    from the site and never sees GitHub.
    if (await _fromWebsite()) return;
    // 2. Until the first release has been published there: GitHub's file.
    await _fromGitHub();
  }

  /// `downloads/latest.json` → {"version": "v1.0.6", "file": "ASEC-Setup-v1.0.6.exe"}
  static Future<bool> _fromWebsite() async {
    try {
      final http.Response res = await http.get(Uri.parse(
        '$_storageBase/${Uri.encodeComponent('$kStorageFolder/latest.json')}?alt=media',
      ));
      if (res.statusCode != 200) return false;
      final Object? json = jsonDecode(utf8.decode(res.bodyBytes));
      if (json is! Map) return false;
      final String file = '${json['file'] ?? ''}';
      if (file.isEmpty) return false;
      latest.value = WindowsReleaseInfo(
        version: '${json['version'] ?? ''}',
        url: '$_storageBase/${Uri.encodeComponent('$kStorageFolder/$file')}?alt=media',
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<void> _fromGitHub() async {
    try {
      final http.Response res = await http.get(
        Uri.parse('https://api.github.com/repos/$kReleaseRepo/releases/latest'),
        headers: const <String, String>{'Accept': 'application/vnd.github+json'},
      );
      if (res.statusCode != 200) return; // 404 = no release yet
      final Map<String, dynamic> json = jsonDecode(res.body) as Map<String, dynamic>;
      String? setup;
      String? exact;
      String? anyZip;
      for (final Object? a in (json['assets'] as List<dynamic>?) ?? const <dynamic>[]) {
        if (a is! Map) continue;
        final String name = '${a['name'] ?? ''}';
        final String link = '${a['browser_download_url'] ?? ''}';
        if (link.isEmpty) continue;
        if (name == kWindowsSetupName) setup = link;
        if (name == kWindowsAssetName) exact = link;
        if (name.toLowerCase().endsWith('.zip')) anyZip ??= link;
      }
      final String? url = setup ?? exact ?? anyZip;
      if (url == null) return;
      latest.value = WindowsReleaseInfo(version: '${json['tag_name'] ?? ''}', url: url);
    } catch (_) {
      // Offline / rate-limited: the button simply stays hidden.
    }
  }
}

/// A panel link that only opens a GitHub PAGE (the releases list, the repo)
/// sends the visitor to GitHub instead of downloading — ignored, so the
/// button downloads the file itself. A direct file link is still honoured.
bool _isGitHubPage(String url) {
  final Uri? u = Uri.tryParse(url);
  if (u == null || !u.host.endsWith('github.com')) return false;
  return !u.path.contains('/releases/download/') && !u.path.contains('/releases/latest/download/');
}

enum _Phase { idle, downloading, done }

class DownloadAppButton extends StatefulWidget {
  const DownloadAppButton({
    super.key,
    this.overrideUrl = '',
    this.showVersion = true,
    this.fullWidth = false,
  });

  /// A link typed in the panel; wins over the GitHub release when filled.
  final String overrideUrl;

  /// Show the release tag beside the label.
  final bool showVersion;

  /// Stretch to the available width (mobile menu).
  final bool fullWidth;

  @override
  State<DownloadAppButton> createState() => _DownloadAppButtonState();
}

class _DownloadAppButtonState extends State<DownloadAppButton> with TickerProviderStateMixin {
  static const Color _navy = Color(0xFF102D5E);
  static const Color _greenDark = Color(0xFF137A43);

  late final AnimationController _idle =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 2600))..repeat();
  late final AnimationController _progress =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1700));

  _Phase _phase = _Phase.idle;
  bool _hover = false;
  Timer? _reset;

  @override
  void initState() {
    super.initState();
    WindowsRelease.load();
  }

  @override
  void dispose() {
    _reset?.cancel();
    _idle.dispose();
    _progress.dispose();
    super.dispose();
  }

  Future<void> _start(String url) async {
    if (_phase != _Phase.idle) return;
    setState(() => _phase = _Phase.downloading);
    // '_self': the zip is served as an attachment, so the browser downloads
    // it and the visitor stays on the page (no empty tab).
    unawaited(launchUrl(Uri.parse(url), webOnlyWindowName: '_self'));
    await _progress.forward(from: 0);
    if (!mounted) return;
    setState(() => _phase = _Phase.done);
    _reset?.cancel();
    _reset = Timer(const Duration(milliseconds: 2800), () {
      if (!mounted) return;
      _progress.value = 0;
      setState(() => _phase = _Phase.idle);
    });
  }

  String get _label => switch (_phase) {
        _Phase.idle => const L('تحميل نسخة ويندوز', 'Download for Windows').t,
        _Phase.downloading => const L('جاري التحميل…', 'Downloading…').t,
        _Phase.done => const L('بدأ التحميل', 'Download started').t,
      };

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<WindowsReleaseInfo?>(
      valueListenable: WindowsRelease.latest,
      builder: (BuildContext context, WindowsReleaseInfo? info, _) {
        String override = widget.overrideUrl.trim();
        if (_isGitHubPage(override)) override = '';
        final String url = override.isNotEmpty ? override : (info?.url ?? '');
        if (url.isEmpty) return const SizedBox.shrink();
        final String version = override.isNotEmpty ? '' : (info?.version ?? '');

        return Semantics(
          button: true,
          label: const L('تحميل نسخة ويندوز من التطبيق', 'Download the ASEC app for Windows').t,
          child: MouseRegion(
            cursor: _phase == _Phase.idle ? SystemMouseCursors.click : SystemMouseCursors.basic,
            onEnter: (_) => setState(() => _hover = true),
            onExit: (_) => setState(() => _hover = false),
            child: GestureDetector(
              onTap: () => _start(url),
              child: AnimatedBuilder(
                animation: Listenable.merge(<Listenable>[_idle, _progress]),
                builder: (BuildContext context, _) => _body(version),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _icon() {
    switch (_phase) {
      case _Phase.idle:
        final double bob = (_hover ? 3.5 : 2.5) * math.sin(_idle.value * 2 * math.pi);
        return Transform.translate(
          offset: Offset(0, bob),
          child: const AppIcon(Icons.download_rounded, size: 20, color: WebColors.white),
        );
      case _Phase.downloading:
        // The arrow falls through the icon box three times.
        final double y = ((_progress.value * 3) % 1) * 24 - 12;
        return ClipRect(
          child: SizedBox(
            width: 20,
            height: 20,
            child: Transform.translate(
              offset: Offset(0, y),
              child: const AppIcon(Icons.download_rounded, size: 20, color: WebColors.white),
            ),
          ),
        );
      case _Phase.done:
        return TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0.3, end: 1),
          duration: const Duration(milliseconds: 520),
          curve: Curves.elasticOut,
          builder: (BuildContext context, double s, Widget? child) => Transform.scale(scale: s, child: child),
          child: const AppIcon(Icons.check_rounded, size: 20, color: WebColors.white),
        );
    }
  }

  Widget _body(String version) {
    final double t = _idle.value;
    final bool idle = _phase == _Phase.idle;
    final bool done = _phase == _Phase.done;
    final double pulse = (math.sin(t * 2 * math.pi) + 1) / 2; // 0..1
    final double glow = idle ? 0.22 + 0.18 * pulse : 0.3;
    final Color glowColor = done ? WebColors.success : WebColors.blue;

    final Widget content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          _icon(),
          const SizedBox(width: 10),
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            child: Text(
              FormatHelper.capitalize(_label),
              maxLines: 1,
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: WebColors.white,
              ),
            ),
          ),
          if (idle && widget.showVersion && version.isNotEmpty) ...<Widget>[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: WebColors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                version,
                textDirection: TextDirection.ltr,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: WebColors.white),
              ),
            ),
          ],
        ],
      ),
    );

    return AnimatedScale(
      scale: _hover && idle ? 1.05 : 1,
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        height: 44,
        width: widget.fullWidth ? double.infinity : null,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          gradient: LinearGradient(
            colors: done ? const <Color>[WebColors.success, _greenDark] : const <Color>[_navy, WebColors.blue],
          ),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: glowColor.withValues(alpha: glow),
              blurRadius: 10 + 10 * glow,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          alignment: AlignmentDirectional.center,
          children: <Widget>[
            // Downloading: a light fill crossing the button.
            if (_phase == _Phase.downloading)
              Positioned.fill(
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: FractionallySizedBox(
                    widthFactor: Curves.easeInOut.transform(_progress.value),
                    heightFactor: 1,
                    child: ColoredBox(color: WebColors.white.withValues(alpha: 0.2)),
                  ),
                ),
              ),
            // Idle: a light sweep in the first part of every cycle.
            if (idle && t < 0.4)
              Positioned.fill(
                child: Align(
                  alignment: Alignment(-1.8 + (t / 0.4) * 3.6, 0),
                  child: FractionallySizedBox(
                    widthFactor: 0.32,
                    heightFactor: 1,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: <Color>[
                            WebColors.white.withValues(alpha: 0),
                            WebColors.white.withValues(alpha: 0.32),
                            WebColors.white.withValues(alpha: 0),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            content,
          ],
        ),
      ),
    );
  }
}
