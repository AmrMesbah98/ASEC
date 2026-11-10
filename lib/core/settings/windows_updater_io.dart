/// `WindowsUpdater` (06/11/2026) — the Windows "Update now".
///
/// Before: the button opened the browser on the installer's download link;
/// the member had to find the file in Downloads and run it — while ASEC was
/// still open, which could leave its settings half-written (white screen).
///
/// Now, inside ASEC:
///   1. the installer (ASEC-Setup.exe) downloads with a progress bar into the
///      PC's temporary folder — never into the member's Downloads;
///   2. it is checked (a real Windows program, a sensible size);
///   3. ASEC notes a normal close (no false crash report), starts the
///      installer and closes itself, so nothing is being written;
///   4. the installer opens: Next → Next → Install. It replaces the old
///      version in place and offers to start the new one.
library;

import 'dart:async';
import 'dart:io';

abstract final class WindowsUpdater {
  /// [url] is a Windows installer this updater can fetch itself.
  static bool canHandle(String url) {
    if (!Platform.isWindows) return false;
    final String u = url.toLowerCase().split('?').first;
    return u.endsWith('.exe') || u.contains('/releases/latest/download/');
  }

  /// Downloads the installer; returns its path. [onProgress] gets 0..1, or
  /// null while the size is unknown.
  static Future<String> download(
    String url, {
    required void Function(double? progress) onProgress,
    required bool Function() cancelled,
  }) async {
    final HttpClient client = HttpClient()..connectionTimeout = const Duration(seconds: 30);
    final File out = File('${Directory.systemTemp.path}\\ASEC-Setup-update.exe');
    final File part = File('${out.path}.part');
    IOSink? sink;
    try {
      final HttpClientRequest req = await client.getUrl(Uri.parse(url));
      req.followRedirects = true;
      req.maxRedirects = 10;
      final HttpClientResponse res = await req.close();
      if (res.statusCode != HttpStatus.ok) {
        await res.drain<void>();
        throw HttpException('The download answered ${res.statusCode}');
      }
      final int total = res.contentLength;
      if (part.existsSync()) part.deleteSync();
      sink = part.openWrite();
      int received = 0;
      int lastReport = 0;
      onProgress(total > 0 ? 0 : null);
      await for (final List<int> chunk in res) {
        if (cancelled()) throw const _Cancelled();
        sink.add(chunk);
        received += chunk.length;
        if (received - lastReport > 256 * 1024) {
          lastReport = received;
          onProgress(total > 0 ? received / total : null);
        }
      }
      await sink.flush();
      await sink.close();
      sink = null;
      // A real Windows program starts with "MZ"; an HTML error page does not.
      final RandomAccessFile f = await part.open();
      final List<int> head = await f.read(2);
      await f.close();
      if (received < 1024 * 1024 || head.length < 2 || head[0] != 0x4D || head[1] != 0x5A) {
        throw const FormatException('The downloaded file is not the ASEC installer.');
      }
      if (out.existsSync()) out.deleteSync();
      await part.rename(out.path);
      onProgress(1);
      return out.path;
    } catch (_) {
      try {
        await sink?.close();
      } catch (_) {}
      try {
        if (part.existsSync()) part.deleteSync();
      } catch (_) {}
      rethrow;
    } finally {
      client.close(force: true);
    }
  }

  /// Starts the installer on its own and closes ASEC.
  static Future<void> runAndExit(String path) async {
    await Process.start(path, <String>[], mode: ProcessStartMode.detached);
    await Future<void>.delayed(const Duration(milliseconds: 600));
    exit(0);
  }
}

/// The member pressed Cancel.
class _Cancelled implements Exception {
  const _Cancelled();
}
