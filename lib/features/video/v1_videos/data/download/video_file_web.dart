/// Module: video / v1_videos
///
///*************************** FILE INFO ****************************///
/// File Name: video_file_web.dart
/// Purpose: The web build of video_file.dart — no offline lessons in a
///          browser.
/// Author: ASEC team
/// Created: 1/10/2026

import 'dart:typed_data';

import 'package:video_player/video_player.dart';

const bool videoDownloadsSupported = false;

Future<String> videoDownloadsDir(String uid) async =>
    throw UnsupportedError('Downloads are not available on the web');

bool videoFileExists(String path) => false;

String legacyVideoPath(String encryptedPath) => encryptedPath;

Future<void> encryptLegacyVideo(String plainPath, String encryptedPath, Uint8List key) async {}

Future<void> deleteVideoFile(String path) async {}

Future<void> deleteVideoDir(String dir) async {}

Future<void> deleteAllVideoDirs() async {}

Future<void> downloadVideoFile({
  required String url,
  required String path,
  required int expectedBytes,
  required Uint8List key,
  required void Function(int received, int total) onProgress,
  required bool Function() cancelled,
  String Function()? cloud,
}) async =>
    throw UnsupportedError('Downloads are not available on the web');

VideoPlayerController localVideoController(String path) =>
    throw UnsupportedError('Downloads are not available on the web');
