/// Module: video / v1_videos
///
/// File Name: video_watermark.dart
/// Purpose: Declares `VideoWatermark` — the viewer's name, phone / email
///          and account code drifting over the lesson (like a TV channel's
///          moving tag), so a screen recording that leaks out shows whose
///          account it came from. Shown over the picture in the page and in
///          full screen (Chewie's `overlay`); it never takes a tap.
/// Created: 07/11/2026
library;

import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import 'package:asec/features/onboarding/o2_authentication/domain/entities/app_user.dart';
import 'package:asec/features/onboarding/o2_authentication/presentation/controller/session_controller.dart';

class VideoWatermark extends StatefulWidget {
  const VideoWatermark({super.key});

  @override
  State<VideoWatermark> createState() => _VideoWatermarkState();
}

class _VideoWatermarkState extends State<VideoWatermark> {
  final Random _random = Random();
  Alignment _at = const Alignment(-0.7, -0.6);
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // A new spot every few seconds — never long enough in one place to be
    // cropped or blurred out of a recording.
    _timer = Timer.periodic(const Duration(seconds: 6), (_) {
      if (!mounted) return;
      setState(() => _at = Alignment(
            _random.nextDouble() * 1.7 - 0.85,
            _random.nextDouble() * 1.7 - 0.85,
          ));
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  static String _text() {
    try {
      final AppUser me = SessionController.to.current;
      final String contact = me.phone.trim().isNotEmpty ? me.phone.trim() : me.email.trim();
      final String code = me.uid.length > 8 ? me.uid.substring(0, 8) : me.uid;
      return <String>[
        if (me.displayName.trim().isNotEmpty) me.displayName.trim(),
        <String>[if (contact.isNotEmpty) contact, if (code.isNotEmpty) 'ID $code'].join('  ·  '),
      ].where((String l) => l.isNotEmpty).join('\n');
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final String text = _text();
    if (text.isEmpty) return const SizedBox.shrink();
    return IgnorePointer(
      child: AnimatedAlign(
        alignment: _at,
        duration: const Duration(milliseconds: 1800),
        curve: Curves.easeInOut,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.38),
              fontSize: 13,
              fontWeight: FontWeight.w600,
              height: 1.3,
              decoration: TextDecoration.none,
              shadows: const <Shadow>[Shadow(blurRadius: 3, color: Colors.black54)],
            ),
          ),
        ),
      ),
    );
  }
}
