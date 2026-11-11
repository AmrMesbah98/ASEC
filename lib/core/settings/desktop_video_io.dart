import 'dart:io';

import 'package:media_kit/media_kit.dart';
import 'package:get_storage/get_storage.dart';

import 'package:asec/core/settings/app_video_player.dart';
import 'package:asec/core/settings/device_specs.dart';

export 'package:asec/core/settings/app_video_player.dart' show isVideoDecoderError;

/// Registers media_kit ([AppVideoPlayer]) as the `video_player` backend on
/// Windows and Linux.
///
/// NEVER BLOCKS STARTUP: if media_kit cannot start, the failure is swallowed
/// so the app still opens — only video playback on that desktop is lost, and
/// the player screen shows that error with a Retry button.
void registerDesktopVideo() {
  if (!Platform.isWindows && !Platform.isLinux) return;
  try {
    MediaKit.ensureInitialized();
    AppVideoPlayer.registerWith();
  } catch (_) {
    // App still opens; only desktop video playback is affected.
  }
}

/// ANDROID PHONES WHOSE VIDEO CHIP CANNOT PLAY A LESSON (06/11/2026).
/// Android's own player (ExoPlayer) uses the phone's hardware decoder; on
/// some phones it refuses certain lessons ("MediaCodecVideoRenderer error").
/// media_kit (already inside the app for Windows) decodes in software when
/// the hardware can't, so the lesson plays. Switched on only for a phone
/// that hit that error. Returns true when media_kit is now the player.
bool enableSoftwareVideoPlayer() {
  if (!Platform.isAndroid) return false;
  try {
    MediaKit.ensureInitialized();
    AppVideoPlayer.registerWith();
    return true;
  } catch (_) {
    return false;
  }
}

// ── WINDOWS / LINUX: decoding on the CPU when the graphics card can't ───────
//
// 11/11/2026 — "Could not open codec." on a PC with no graphics driver
// ("Microsoft Basic Display Adapter"): media_kit asked the graphics card to
// decode and the lesson never played. Now:
//   * a PC with no graphics driver decodes AND draws on the CPU from the
//     first lesson;
//   * any other PC whose lesson fails with a decoder error steps down one
//     level (graphics card → CPU decoding → CPU decoding and drawing), and
//     keeps that level from then on.

const String _modeKey = 'desktop_video_decode_mode';
bool _modeLoaded = false;

bool get _desktop => Platform.isWindows || Platform.isLinux;

/// Call before opening a lesson: loads the level this PC needs.
Future<void> prepareDesktopVideo() async {
  if (!_desktop || _modeLoaded) return;
  _modeLoaded = true;
  try {
    final String saved = GetStorage().read<String>(_modeKey) ?? '';
    for (final VideoDecodeMode m in VideoDecodeMode.values) {
      if (m.name == saved && m.index > AppVideoPlayer.mode.index) AppVideoPlayer.mode = m;
    }
  } catch (_) {}
  if (Platform.isWindows) {
    await DeviceSpecs.summaryWithin(const Duration(seconds: 3));
    if (DeviceSpecs.noGraphicsDriver) AppVideoPlayer.mode = VideoDecodeMode.software;
  }
}

/// A lesson failed with a decoder error: decode one level more on the CPU.
/// Returns the new level's name, or null when there is no lower level (or
/// this is not Windows / Linux).
Future<String?> softerDesktopVideo() async {
  if (!_desktop) return null;
  final VideoDecodeMode now = AppVideoPlayer.mode;
  if (now == VideoDecodeMode.software) return null;
  final VideoDecodeMode next = VideoDecodeMode.values[now.index + 1];
  AppVideoPlayer.mode = next;
  try {
    await GetStorage().write(_modeKey, next.name);
  } catch (_) {}
  return desktopVideoMode;
}

/// How lessons are decoded on this PC, for error reports.
String get desktopVideoMode => switch (AppVideoPlayer.mode) {
      VideoDecodeMode.normal => 'graphics card',
      VideoDecodeMode.softwareDecode => 'CPU decoding',
      VideoDecodeMode.software => 'CPU decoding and drawing',
    };
