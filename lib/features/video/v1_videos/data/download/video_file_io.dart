/// Module: video / v1_videos
///
///*************************** FILE INFO ****************************///
/// File Name: video_file_io.dart
/// Purpose: The phone / desktop build of video_file.dart.
/// Author: ASEC team
/// Created: 1/10/2026
///
/// WHERE THE FILES GO
/// ------------------
/// The app's private "Application Support" folder (path_provider), inside
/// `asec_videos/<uid>/`. It is NOT the phone's Downloads, Gallery or Files:
/// the student cannot open, share or copy the video outside ASEC, other apps
/// cannot see it, and deleting the app deletes it. Unlike the cache folder,
/// the system does not empty it by itself when space runs low, so a lesson
/// the student downloaded is still there on the bus.
///
/// A download is written to `<id>.asv.part` and renamed only when complete,
/// so a cut connection never leaves a half video that looks finished.
///
/// ENCRYPTED (26/10/2026). The file is AES-256-CTR with a key made on this
/// device for this account (ContentCrypto.deviceKey). Copied out of the
/// folder — or to another computer — it is noise. It plays only through
/// SecureVideoServer, which decrypts it in memory.

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:asec/core/security/content_crypto.dart';
import 'package:asec/core/security/ctr_worker.dart';
import 'package:asec/core/security/secure_video_server_io.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';

const bool videoDownloadsSupported = true;

Future<String> videoDownloadsDir(String uid) async {
  final Directory base = await getApplicationSupportDirectory();
  final Directory dir = Directory('${base.path}/asec_videos/$uid');
  if (!dir.existsSync()) await dir.create(recursive: true);
  return dir.path;
}

bool videoFileExists(String path) => File(path).existsSync();

/// Where the same lesson was saved before downloads were encrypted.
String legacyVideoPath(String encryptedPath) =>
    encryptedPath.replaceAll(RegExp(r'\.asv$'), '.mp4');

Future<void> deleteVideoFile(String path) async {
  for (final String p in <String>[path, '$path.part', legacyVideoPath(path)]) {
    final File f = File(p);
    if (f.existsSync()) await f.delete();
  }
}

Future<void> deleteVideoDir(String dir) async {
  final Directory d = Directory(dir);
  if (d.existsSync()) await d.delete(recursive: true);
}

Future<void> downloadVideoFile({
  required String url,
  required String path,
  required int expectedBytes,
  required Uint8List key,
  required void Function(int received, int total) onProgress,
  required bool Function() cancelled,
}) async {
  final File part = File('$path.part');
  IOSink? sink;
  try {
    // Past any system proxy, Google-issued certificates only — a sniffer
    // that decrypts HTTPS gets nothing and is reported (PinnedFetch).
    final HttpClientResponse res = await PinnedFetch.get(Uri.parse(url));
    final String type = res.headers.value(HttpHeaders.contentTypeHeader) ?? '';
    // A private Drive file, or Drive's "quota exceeded" page, answers 200
    // with an HTML page instead of the video.
    if (res.statusCode != 200 || type.startsWith('text/html')) {
      unawaited(res.drain<void>().catchError((Object _) {}));
      throw HttpException('HTTP ${res.statusCode} ($type)');
    }
    final int total = res.contentLength > 0 ? res.contentLength : expectedBytes;
    // ENCRYPTED ON THE WAY IN: the plain video never touches the disk.
    final Uint8List nonce = ContentCrypto.newNonce();
    sink = part.openWrite();
    sink.add(ContentCrypto.header(nonce));
    int received = 0;
    int lastReport = 0;
    await for (final List<int> chunk in res) {
      if (cancelled()) throw const _Cancelled();
      // Encrypted on the background worker, so the app does not lag while
      // a lesson downloads (see CtrWorker).
      final Uint8List data = await CtrWorker.apply(
          key, nonce, Uint8List.fromList(chunk), received);
      sink.add(data);
      received += data.length;
      // ~ every 256 KB, so the progress ring does not rebuild per packet.
      if (received - lastReport > 256 * 1024) {
        lastReport = received;
        onProgress(received, total);
      }
    }
    await sink.flush();
    await sink.close();
    sink = null;
    if (received == 0) throw const HttpException('Empty file');
    onProgress(received, total > 0 ? total : received);
    await part.rename(path);
  } on _Cancelled {
    await sink?.close();
    sink = null;
    if (part.existsSync()) await part.delete();
    rethrow;
  } catch (_) {
    await sink?.close();
    sink = null;
    if (part.existsSync()) await part.delete();
    rethrow;
  }
}

/// Lessons downloaded before 26/10/2026 were plain `.mp4` files anybody
/// could copy out of the app's folder. Encrypts [plainPath] into
/// [encryptedPath] and deletes the plain file.
Future<void> encryptLegacyVideo(String plainPath, String encryptedPath, Uint8List key) async {
  final File plain = File(plainPath);
  if (!plain.existsSync()) return;
  final File part = File('$encryptedPath.part');
  final Uint8List nonce = ContentCrypto.newNonce();
  final IOSink sink = part.openWrite();
  try {
    sink.add(ContentCrypto.header(nonce));
    int pos = 0;
    await for (final List<int> chunk in plain.openRead()) {
      final Uint8List data =
          await CtrWorker.apply(key, nonce, Uint8List.fromList(chunk), pos);
      sink.add(data);
      pos += data.length;
    }
    await sink.flush();
    await sink.close();
    await part.rename(encryptedPath);
    await plain.delete();
  } catch (_) {
    try {
      await sink.close();
    } catch (_) {}
    if (part.existsSync()) await part.delete();
  }
}

/// Thrown out of [downloadVideoFile] when the student cancels.
class _Cancelled implements Exception {
  const _Cancelled();
}

VideoPlayerController localVideoController(String path) =>
    VideoPlayerController.file(File(path));
