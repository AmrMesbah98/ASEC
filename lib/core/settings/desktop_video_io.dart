/// Module: core/settings
///
///*************************** FILE INFO ****************************///
/// File Name: desktop_video_io.dart
/// Purpose: Native build of desktop_video. Registers `media_kit` (through
///          `video_player_media_kit`) as the `video_player` backend on
///          Windows and Linux only — the two platforms where `video_player`
///          itself has no player and throws "init() has not been
///          implemented". Android, iOS and macOS keep their own native
///          players, untouched. media_kit's libraries ship PREBUILT in the
///          package (`media_kit_libs_video`), so there is nothing to download
///          or unzip at build time.
///
/// NEVER BLOCKS STARTUP. If media_kit cannot start (a library missing, an old
/// build), the failure is swallowed so the APP STILL OPENS — the window must
/// never stay hidden because of the video backend. Only video playback is
/// lost, and that failure is already shown on the player screen.

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:video_player_media_kit/video_player_media_kit.dart';

void registerDesktopVideo() {
  try {
    // windows + linux only; every other platform stays on its native player.
    VideoPlayerMediaKit.ensureInitialized(
      windows: true,
      linux: true,
    );
  } catch (error, stack) {
    // The app opens anyway; only video on this desktop is affected.
    debugPrint('media_kit init failed (video may not play on desktop): $error');
    debugPrintStack(stackTrace: stack);
  }
}

/// ANDROID PHONES WHOSE VIDEO CHIP CANNOT PLAY A LESSON (06/11/2026, from
/// ENGX). Android's own player (ExoPlayer) uses the phone's hardware decoder;
/// on some phones it refuses certain lessons ("MediaCodecVideoRenderer
/// error"). media_kit (already inside the app for Windows) decodes in
/// software when the hardware can't. Switched on only for a phone that hit
/// that error. Returns true when media_kit is now the player.
bool enableSoftwareVideoPlayer() {
  if (!Platform.isAndroid) return false;
  try {
    VideoPlayerMediaKit.ensureInitialized(android: true);
    return true;
  } catch (_) {
    return false;
  }
}
