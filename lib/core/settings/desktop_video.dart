/// Module: core/settings
///
///*************************** FILE INFO ****************************///
/// File Name: desktop_video.dart
/// Purpose: `registerDesktopVideo` — gives the `video_player` package a
///          Windows / Linux backend. video_player has NO native player on
///          Windows or Linux (it throws "init() has not been implemented"),
///          so members on Windows could not watch any lesson.
///          `video_player_media_kit` plugs media_kit into video_player for
///          those two platforms only; Android, iOS, macOS and web keep their
///          own native players. The web build uses the no-op stub, so the
///          native media_kit code never reaches the website bundle.
/// Author: ASEC team
/// Created: 27/10/2026

export 'desktop_video_stub.dart'
    if (dart.library.io) 'desktop_video_io.dart';
