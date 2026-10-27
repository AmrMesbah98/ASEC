/// Module: core/settings
///
///*************************** FILE INFO ****************************///
/// File Name: desktop_video_io.dart
/// Purpose: Native build of desktop_video. Registers `fvp` as the
///          `video_player` backend on Windows and Linux only.

import 'dart:io';

import 'package:fvp/fvp.dart' as fvp;

void registerDesktopVideo() {
  // Only the two platforms video_player cannot play on. Android, iOS and
  // macOS keep their own native players (untouched).
  if (Platform.isWindows || Platform.isLinux) {
    fvp.registerWith(
      options: <String, dynamic>{
        'platforms': <String>['windows', 'linux'],
      },
    );
  }
}
