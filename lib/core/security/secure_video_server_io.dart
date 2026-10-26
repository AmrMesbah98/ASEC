/// Module: core/security
///
///*************************** FILE INFO ****************************///
/// File Name: secure_video_server_io.dart
/// Purpose: Declares `SecureVideoServer` — the lesson gateway. The video
///          player NEVER sees a Google Drive link or a lesson file:
///
///            player ──http──▶ 127.0.0.1:<port>/v/<one-time token>.mp4
///                                   │
///                                   ├─ streamed lesson → fetched from Drive
///                                   │  by the app itself, past any system
///                                   │  proxy, and only from a server whose
///                                   │  certificate Google issued
///                                   └─ downloaded lesson → the encrypted
///                                      file, decrypted in memory
///
///          A token lives as long as the player page; closing it revokes it.
/// Author: ASEC team
/// Created: 26/10/2026
///
/// WHY. A link handed to the system player shows up in proxy / sniffer
/// tools (Fiddler, Charles, mitmproxy, HTTP Toolkit) and can be downloaded
/// outside the app forever. Here the Drive request leaves from Dart with
/// `findProxy → DIRECT`, so a system proxy is skipped, and the answer is
/// refused unless Google Trust Services signed the server's certificate —
/// which a tool that decrypts HTTPS cannot fake. That refusal is reported
/// to the super admin (SecurityMonitor) and the app locks until the tool is
/// gone.
///
/// The server only answers this device (loopback), only on tokens it gave
/// out, and refuses requests that come from download tools.

import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:asec/core/security/content_crypto.dart';
import 'package:asec/core/security/security_monitor.dart';

class _Source {
  _Source.remote(this.url, this.sizeBytes, this.label)
      : path = null,
        key = null;
  _Source.local(this.path, this.key, this.label)
      : url = null,
        sizeBytes = 0;

  final String? url;
  final String? path;
  final Uint8List? key;
  final int sizeBytes;
  final String label;
  int served = 0;
  bool flagged = false;
}

abstract final class SecureVideoServer {
  const SecureVideoServer._();

  static HttpServer? _server;
  static Future<HttpServer>? _starting;
  static final Map<String, _Source> _tokens = <String, _Source>{};
  static int _unknownHits = 0;

  /// User agents of download / scraping tools. The players (ExoPlayer,
  /// AVFoundation's AppleCoreMedia) never send these.
  static final RegExp _toolAgent = RegExp(
    r'curl|wget|python|aria2|idm|internet download|postman|insomnia|'
    r'go-http|okhttp/[0-9]|java/|libwww|httpie|powershell|mozilla|yt-dlp|ffmpeg|lavf|vlc',
    caseSensitive: false,
  );

  static Future<HttpServer> _ensure() async {
    final HttpServer? s = _server;
    if (s != null) return s;
    return _starting ??= () async {
      final HttpServer server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      server.listen(_handle, onError: (Object _) {});
      _server = server;
      return server;
    }();
  }

  static String _newToken() {
    final Random r = Random.secure();
    const String chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    return List<String>.generate(32, (_) => chars[r.nextInt(chars.length)]).join();
  }

  /// A one-time local address that plays [url] (a Drive link, already in
  /// its playable form).
  static Future<Uri> remote(String url, {int sizeBytes = 0, String label = ''}) async {
    final HttpServer s = await _ensure();
    final String t = _newToken();
    _tokens[t] = _Source.remote(url, sizeBytes, label);
    return Uri.parse('http://127.0.0.1:${s.port}/v/$t.mp4');
  }

  /// A one-time local address that plays the ENCRYPTED file at [path] with
  /// [key] (ContentCrypto.deviceKey).
  static Future<Uri> localEncrypted(String path, Uint8List key, {String label = ''}) async {
    final HttpServer s = await _ensure();
    final String t = _newToken();
    _tokens[t] = _Source.local(path, key, label);
    return Uri.parse('http://127.0.0.1:${s.port}/v/$t.mp4');
  }

  static void revoke(Uri? uri) {
    if (uri == null || uri.pathSegments.length < 2) return;
    _tokens.remove(uri.pathSegments.last.replaceAll('.mp4', ''));
  }

  static Future<void> _handle(HttpRequest req) async {
    final HttpResponse res = req.response;
    try {
      // This device only.
      if (!(req.connectionInfo?.remoteAddress.isLoopback ?? false)) {
        res.statusCode = HttpStatus.forbidden;
        await res.close();
        return;
      }
      final List<String> seg = req.uri.pathSegments;
      final String token = seg.length == 2 && seg.first == 'v' ? seg.last.replaceAll('.mp4', '') : '';
      final _Source? src = _tokens[token];
      if (src == null) {
        // Somebody is guessing addresses on the gateway.
        if (++_unknownHits == 20) {
          SecurityMonitor.alert('gateway_probe', '20 requests for unknown video addresses');
        }
        res.statusCode = HttpStatus.notFound;
        await res.close();
        return;
      }
      final String agent = req.headers.value(HttpHeaders.userAgentHeader) ?? '';
      if (_toolAgent.hasMatch(agent)) {
        SecurityMonitor.alert(
          'stream_grab',
          'A download tool asked for a lesson stream (${src.label}). User-Agent: $agent',
        );
        _tokens.remove(token);
        res.statusCode = HttpStatus.forbidden;
        await res.close();
        return;
      }
      if (req.method != 'GET' && req.method != 'HEAD') {
        res.statusCode = HttpStatus.methodNotAllowed;
        await res.close();
        return;
      }
      if (src.url != null) {
        await _serveRemote(req, src, token);
      } else {
        await _serveLocal(req, src);
      }
    } catch (_) {
      try {
        await res.close();
      } catch (_) {}
    }
  }

  /// The player asks for far more than the lesson's size → something else
  /// is reading the stream (a capture tool on the loopback address).
  static void _count(_Source src, int bytes, String token) {
    src.served += bytes;
    final int size = src.sizeBytes > 0 ? src.sizeBytes : 0;
    if (!src.flagged && size > 0 && src.served > size * 4) {
      src.flagged = true;
      SecurityMonitor.alert(
        'stream_abuse',
        'Lesson "${src.label}" streamed ${src.served ~/ (1024 * 1024)} MB '
        '(the file is ${size ~/ (1024 * 1024)} MB) — something else is reading it.',
      );
      _tokens.remove(token);
    }
  }

  // ── Streamed lessons ──────────────────────────────────────────────────────

  static Future<void> _serveRemote(HttpRequest req, _Source src, String token) async {
    final HttpResponse res = req.response;
    final HttpClientResponse up;
    try {
      up = await PinnedFetch.get(
        Uri.parse(src.url!),
        range: req.headers.value(HttpHeaders.rangeHeader),
        head: req.method == 'HEAD',
      );
    } on InterceptedException {
      _tokens.remove(token);
      res.statusCode = HttpStatus.forbidden;
      await res.close();
      return;
    }
    res.statusCode = up.statusCode;
    for (final String h in <String>[
      HttpHeaders.contentTypeHeader,
      HttpHeaders.contentLengthHeader,
      HttpHeaders.contentRangeHeader,
      HttpHeaders.acceptRangesHeader,
    ]) {
      final String? v = up.headers.value(h);
      if (v != null) res.headers.set(h, v);
    }
    // Drive sometimes labels the file octet-stream; the players want video.
    final String type = up.headers.value(HttpHeaders.contentTypeHeader) ?? '';
    if (!type.startsWith('video/')) res.headers.set(HttpHeaders.contentTypeHeader, 'video/mp4');
    res.headers.set(HttpHeaders.acceptRangesHeader, 'bytes');
    res.headers.set(HttpHeaders.cacheControlHeader, 'no-store');
    await res.addStream(up.map((List<int> c) {
      _count(src, c.length, token);
      return c;
    }));
    await res.close();
  }

  // ── Downloaded (encrypted) lessons ────────────────────────────────────────

  static Future<void> _serveLocal(HttpRequest req, _Source src) async {
    final HttpResponse res = req.response;
    final File f = File(src.path!);
    final RandomAccessFile raf = await f.open();
    try {
      final Uint8List? nonce = ContentCrypto.nonceOf(await raf.read(ContentCrypto.headerLength));
      if (nonce == null) {
        res.statusCode = HttpStatus.notFound;
        await res.close();
        return;
      }
      final int length = (await raf.length()) - ContentCrypto.headerLength;
      int start = 0;
      int end = length - 1;
      final String? range = req.headers.value(HttpHeaders.rangeHeader);
      final RegExpMatch? m =
          range == null ? null : RegExp(r'bytes=(\d*)-(\d*)').firstMatch(range);
      if (m != null) {
        final String a = m.group(1) ?? '';
        final String b = m.group(2) ?? '';
        if (a.isEmpty && b.isNotEmpty) {
          start = max(0, length - int.parse(b)); // the last N bytes
        } else {
          start = a.isEmpty ? 0 : int.parse(a);
          if (b.isNotEmpty) end = min(int.parse(b), length - 1);
        }
        if (start >= length || start > end) {
          res.statusCode = HttpStatus.requestedRangeNotSatisfiable;
          res.headers.set(HttpHeaders.contentRangeHeader, 'bytes */$length');
          await res.close();
          return;
        }
        res.statusCode = HttpStatus.partialContent;
        res.headers.set(HttpHeaders.contentRangeHeader, 'bytes $start-$end/$length');
      } else {
        res.statusCode = HttpStatus.ok;
      }
      res.headers.contentType = ContentType('video', 'mp4');
      res.headers.set(HttpHeaders.acceptRangesHeader, 'bytes');
      res.headers.set(HttpHeaders.cacheControlHeader, 'no-store');
      res.contentLength = end - start + 1;
      if (req.method == 'HEAD') {
        await res.close();
        return;
      }

      final CtrCipher cipher = CtrCipher(src.key!, nonce);
      await raf.setPosition(ContentCrypto.headerLength + start);
      int pos = start;
      const int chunk = 256 * 1024;
      while (pos <= end) {
        final Uint8List data = await raf.read(min(chunk, end - pos + 1));
        if (data.isEmpty) break;
        cipher.apply(data, pos);
        res.add(data);
        pos += data.length;
        await res.flush();
      }
      await res.close();
    } finally {
      await raf.close();
    }
  }
}

/// The Drive answer did not come from Google: something is decrypting the
/// app's HTTPS (a proxy / sniffer with its own certificate).
class InterceptedException implements Exception {
  const InterceptedException(this.issuer);
  final String issuer;
  @override
  String toString() => 'HTTPS intercepted (certificate issuer: $issuer)';
}

/// Every request for lesson bytes — the stream above and the downloads —
/// goes through here: no system proxy, and Google-issued certificates only.
abstract final class PinnedFetch {
  const PinnedFetch._();

  static final HttpClient _client = HttpClient()
    ..findProxy = ((Uri _) => 'DIRECT')
    ..autoUncompress = false
    ..connectionTimeout = const Duration(seconds: 20)
    // A certificate the device does not trust at all is refused outright.
    ..badCertificateCallback = ((X509Certificate cert, String host, int port) {
      SecurityMonitor.intercepted(host, cert.issuer);
      return false;
    });

  /// Google's own CA; Drive's certificates are issued by it.
  static bool _isGoogle(X509Certificate? c) =>
      c != null && c.issuer.contains('Google Trust Services');

  static Future<HttpClientResponse> get(
    Uri uri, {
    String? range,
    bool head = false,
  }) async {
    final HttpClientRequest rq = head ? await _client.headUrl(uri) : await _client.getUrl(uri);
    if (range != null) rq.headers.set(HttpHeaders.rangeHeader, range);
    final HttpClientResponse r = await rq.close();
    if (!_isGoogle(r.certificate)) {
      final String issuer = r.certificate?.issuer ?? 'none';
      SecurityMonitor.intercepted(uri.host, issuer);
      // Drain so the connection is freed.
      unawaited(r.drain<void>().catchError((Object _) {}));
      throw InterceptedException(issuer);
    }
    return r;
  }
}
