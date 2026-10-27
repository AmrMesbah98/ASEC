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
///          package, so there is nothing to download or unzip at build time
///          (unlike fvp, which failed to unzip on the CI runner).

import 'package:video_player_media_kit/video_player_media_kit.dart';

void registerDesktopVideo() {
  // windows + linux only; every other platform stays on its native player.
  VideoPlayerMediaKit.ensureInitialized(
    windows: true,
    linux: true,
  );
}
