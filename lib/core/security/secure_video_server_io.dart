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
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show debugPrint;

import 'package:asec/core/security/content_crypto.dart';
import 'package:asec/core/security/ctr_worker.dart';
import 'package:asec/core/security/security_monitor.dart';
import 'package:asec/core/settings/error_reports.dart';

class _Source {
  _Source.remote(this.url, this.sizeBytes, this.label, {this.cloud})
      : path = null,
        key = null;
  _Source.local(this.path, this.key, this.label)
      : url = null,
        cloud = null,
        sizeBytes = 0;

  /// Signs a fresh Cloudflare address for this lesson (07/11/2026, from
  /// ENGX). Set = the lesson comes from Cloudflare ONLY, never Drive.
  final String Function()? cloud;

  final String? url;
  final String? path;
  final Uint8List? key;
  final int sizeBytes;
  final String label;
  int served = 0;
  bool flagged = false;

  /// Bytes served in the current 5-minute window ([_count]).
  int windowBytes = 0;
  DateTime windowStart = DateTime.now();

  /// Why the last request failed ('' = fine): `network:…` (no answer) or
  /// `blocked:…` (a firewall answered with its own certificate). Read by the
  /// player to tell the member what to do (ported from ENGX, 08/11/2026).
  String problem = '';

  /// Times a stalled / broken lesson stream was picked up again from where
  /// it stopped (ported from ENGX v1.0.72), for the error report.
  int resumes = 0;
}

abstract final class SecureVideoServer {
  const SecureVideoServer._();

  static HttpServer? _server;
  static Future<HttpServer>? _starting;
  static final Map<String, _Source> _tokens = <String, _Source>{};
  static int _unknownHits = 0;
  static DateTime _unknownSince = DateTime.now();

  /// Lesson addresses that were valid and then closed (player left the
  /// lesson, next lesson, revoked). The player often asks for them a few
  /// more times — that is NOT someone probing the gateway (12/11/2026).
  static final Set<String> _retired = <String>{};

  static void _retire(String token) {
    _retire(token);
    _retired.add(token);
    if (_retired.length > 200) _retired.remove(_retired.first);
  }

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
  static Future<Uri> remote(String url, {int sizeBytes = 0, String label = '', String Function()? cloud}) async {
    final HttpServer s = await _ensure();
    final String t = _newToken();
    _tokens[t] = _Source.remote(url, sizeBytes, label, cloud: cloud);
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
    _retire(uri.pathSegments.last.replaceAll('.mp4', ''));
  }

  /// NO INTERNET AT ALL (11/11/2026, from ENGX): the lesson host's name was
  /// not found AND not even Google's / Cloudflare's DNS answered by IP
  /// address (network unreachable, sending not allowed, no route). The
  /// device was offline at that moment — not a blocked DNS.
  static bool looksOffline(String t) => t
      .split(' | ')
      .every((String h) => h.contains('DNS over HTTPS failed too') && _offlineSign.hasMatch(h));

  static final RegExp _offlineSign = RegExp(
    r'Network is unreachable|was disallowed because|No route to host|errno = (101|113|10050|10051|10057|10065)\b',
  );

  /// Why the lesson at [stream] could not be fetched ('' = no problem):
  /// `blocked:…` or `network:…`.
  static String problemOf(Uri? stream) => _sourceOf(stream)?.problem ?? '';

  /// Bytes already handed to the player for [stream].
  static int servedOf(Uri? stream) => _sourceOf(stream)?.served ?? 0;

  static _Source? _sourceOf(Uri? stream) {
    if (stream == null) return null;
    final List<String> seg = stream.pathSegments;
    return seg.isEmpty ? null : _tokens[seg.last.replaceAll('.mp4', '')];
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
        // FIX (12/11/2026): addresses of lessons that were open a moment ago
        // don't count, and the count starts again every 10 minutes — before,
        // 20 harmless misses over a whole day raised "gateway probed".
        if (!_retired.contains(token)) {
          final DateTime now = DateTime.now();
          if (now.difference(_unknownSince) > const Duration(minutes: 10)) {
            _unknownSince = now;
            _unknownHits = 0;
          }
          if (++_unknownHits == 20) {
            SecurityMonitor.alert('gateway_probe', '20 requests for unknown video addresses in 10 minutes');
          }
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
        _retire(token);
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
  ///
  /// FIX (12/11/2026): MORE THAN 3× THE LESSON IN 5 MINUTES. It used to be 4×
  /// over the WHOLE time a lesson was open — a student who re-watched or kept
  /// seeking back went past it, got a false "stream copied", and the lesson
  /// STOPPED mid-watch. Watching never pulls a whole lesson three times in 5
  /// minutes; a second program copying it alongside the player does.
  static const Duration _abuseWindow = Duration(minutes: 5);

  static void _count(_Source src, int bytes, String token) {
    src.served += bytes;
    final DateTime now = DateTime.now();
    if (now.difference(src.windowStart) > _abuseWindow) {
      src.windowStart = now;
      src.windowBytes = 0;
    }
    src.windowBytes += bytes;
    final int size = src.sizeBytes > 0 ? src.sizeBytes : 0;
    if (!src.flagged && size > 0 && src.windowBytes > size * 3) {
      src.flagged = true;
      SecurityMonitor.alert(
        'stream_abuse',
        'Lesson "${src.label}" streamed ${src.windowBytes ~/ (1024 * 1024)} MB in 5 minutes '
        '(the file is ${size ~/ (1024 * 1024)} MB) — something else is reading it.',
      );
      _retire(token);
    }
  }

  // ── Streamed lessons ──────────────────────────────────────────────────────

  static Future<void> _serveRemote(HttpRequest req, _Source src, String token) async {
    final HttpResponse res = req.response;
    HttpClientResponse up;
    final String? range = req.headers.value(HttpHeaders.rangeHeader);
    final bool head = req.method == 'HEAD';
    try {
      if (src.cloud != null) {
        // CLOUDFLARE ONLY (07/11/2026, from ENGX): never Google Drive while
        // it is on — Drive's daily download limit stopped every lesson.
        final HttpClientResponse? fromCloud = await _fetchCloud(src, range, head);
        if (fromCloud == null) {
          res.statusCode = HttpStatus.badGateway;
          await res.close();
          return;
        }
        if (fromCloud.statusCode >= 400) {
          final int code = fromCloud.statusCode;
          unawaited(fromCloud.drain<void>().catchError((Object _) {}));
          ErrorReports.report(
            code == HttpStatus.notFound
                ? 'Lesson "${src.label}" is not in Cloudflare yet — Settings → Cloudflare lessons → Copy lessons.'
                : 'Lesson "${src.label}" could not play: the lesson server answered $code.',
            StackTrace.empty,
            source: 'video',
          );
          res.statusCode = HttpStatus.badGateway;
          await res.close();
          return;
        }
        up = fromCloud;
      } else {
        up = await PinnedFetch.get(Uri.parse(src.url!), range: range, head: head);
      }
    } on InterceptedException {
      _retire(token);
      res.statusCode = HttpStatus.forbidden;
      await res.close();
      return;
    } on DriveUnavailableException catch (e) {
      // Drive would not return the video (quota / private / removed). Report
      // the lesson so the super admin sees WHICH lesson is broken and why,
      // instead of a vague player "Source error".
      ErrorReports.report(
        'Lesson "${src.label}" could not play: $e',
        StackTrace.empty,
        source: 'video',
      );
      res.statusCode = HttpStatus.badGateway;
      await res.close();
      return;
    } catch (e) {
      // No internet, DNS, a firewall, a timeout … — answered at once so the
      // player is not left waiting (ported from ENGX).
      final String t = '$e';
      src.problem = t.contains('CERTIFICATE_VERIFY_FAILED')
          ? 'blocked:$t'
          : looksOffline(t)
              ? 'offline:$t'
              : 'network:$t';
      res.statusCode = HttpStatus.badGateway;
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
    if (src.cloud != null && !head) {
      await _pipeResuming(res, up, src, token);
    } else {
      await res.addStream(up.map((List<int> c) {
        _count(src, c.length, token);
        return c;
      }));
    }
    await res.close();
  }

  /// One lesson request to Cloudflare: 3 tries (15 s each). Null = no
  /// answer (reported, and [_Source.problem] says why).
  static Future<HttpClientResponse?> _fetchCloud(_Source src, String? range, bool head,
      {bool report = true}) async {
    final String Function() cloud = src.cloud!;
    Object? lastError;
    for (int attempt = 0; attempt < 3; attempt++) {
      try {
        final Uri at = Uri.parse(cloud());
        try {
          final HttpClientResponse r =
              await PinnedFetch.get(at, range: range, head: head).timeout(const Duration(seconds: 15));
          src.problem = '';
          return r;
        } on TimeoutException {
          // NO ANSWER (07/11/2026, from ENGX): some providers send
          // *.workers.dev to an address that never answers instead of
          // failing the name lookup. The next try connects to the address
          // Google's DNS gives instead.
          PinnedFetch.suspect(at);
          rethrow;
        } on SocketException {
          PinnedFetch.suspect(at);
          rethrow;
        }
      } on InterceptedException {
        rethrow;
      } catch (e) {
        lastError = e;
        if (attempt < 2) await Future<void>.delayed(Duration(milliseconds: 600 * (attempt + 1)));
      }
    }
    // BLOCKED NETWORK (ported from ENGX, 08/11/2026): a certificate the
    // device does not trust ("self signed", "Hostname mismatch") is a
    // company / provider firewall's block page — the member is told to try
    // another connection, not to "check the internet".
    final String t = '$lastError'.replaceAll(RegExp(r'\s+'), ' ');
    src.problem = t.contains('CERTIFICATE_VERIFY_FAILED') || t.contains('HandshakeException')
        ? 'blocked:$t'
        : looksOffline(t)
            ? 'offline:$t'
            : 'network:$t';
    if (report) {
      ErrorReports.report(
        'Lesson "${src.label}" could not play: the lesson server did not answer '
        '(${t.length > 900 ? t.substring(0, 900) : t})'
        '${src.resumes > 0 ? ' · stream picked up again ${src.resumes} time${src.resumes == 1 ? '' : 's'}' : ''}',
        StackTrace.empty,
        source: 'video',
      );
    }
    return null;
  }

  // ── Stalled streams (ported from ENGX v1.0.72) ────────────────────────────
  // The lesson host answered, sent a few KB, then the connection went
  // silent (a lossy line / a provider dropping long transfers). Nothing
  // watched the body, so the player waited on a dead socket. Now: no byte
  // for [_stallAfter] while the player is reading → that connection is
  // dropped and the SAME response continues from the exact byte it stopped
  // at, with a fresh signed address.

  static const Duration _stallAfter = Duration(seconds: 12);
  static const int _maxResumes = 6;
  static final RegExp _contentRange = RegExp(r'bytes\s+(\d+)-(\d+)/');

  /// Pipes [first] to [res]; a stalled or broken upstream is picked up
  /// again with a Range request from the next missing byte.
  static Future<void> _pipeResuming(HttpResponse res, HttpClientResponse first, _Source src, String token) async {
    int start = 0;
    int? end;
    final RegExpMatch? cr = _contentRange.firstMatch(first.headers.value(HttpHeaders.contentRangeHeader) ?? '');
    if (first.statusCode == HttpStatus.partialContent && cr != null) {
      start = int.parse(cr.group(1)!);
      end = int.parse(cr.group(2)!);
    } else if (first.statusCode == HttpStatus.ok && first.contentLength > 0) {
      end = first.contentLength - 1;
    } else if (first.statusCode != HttpStatus.ok) {
      await res.addStream(first.map((List<int> c) {
        _count(src, c.length, token);
        return c;
      }));
      return;
    }
    int sent = 0;
    HttpClientResponse up = first;
    for (int resume = 0;; resume++) {
      final _PipeEnd how = await _pipe(res, up, src, token, (int n) => sent += n);
      if (how == _PipeEnd.playerGone) return;
      final int from = start + sent;
      if (how == _PipeEnd.done && (end == null || from > end)) return;
      if (resume >= _maxResumes || !_tokens.containsKey(token) || (end != null && from > end)) return;
      HttpClientResponse? next;
      try {
        next = await _fetchCloud(src, 'bytes=$from-${end ?? ''}', false, report: false);
      } catch (_) {
        next = null;
      }
      if (next == null) return; // closing the response lets the player ask again
      final RegExpMatch? nr = _contentRange.firstMatch(next.headers.value(HttpHeaders.contentRangeHeader) ?? '');
      if (next.statusCode != HttpStatus.partialContent || nr == null || int.parse(nr.group(1)!) != from) {
        unawaited(next.drain<void>().catchError((Object _) {}));
        return;
      }
      src.resumes++;
      debugPrint('🟡 [Lesson] stream stalled — picked up again at byte $from (${src.resumes})');
      up = next;
    }
  }

  /// Copies [up] into [res] until it ends, stalls, breaks, or the player
  /// hangs up. Waits for each chunk to be written before reading the next,
  /// so a paused player never piles the lesson up in memory — and only the
  /// time spent waiting on the lesson host counts as a stall.
  static Future<_PipeEnd> _pipe(
    HttpResponse res,
    HttpClientResponse up,
    _Source src,
    String token,
    void Function(int bytes) onBytes,
  ) async {
    final StreamIterator<List<int>> it = StreamIterator<List<int>>(up);
    try {
      while (true) {
        bool more;
        try {
          more = await it.moveNext().timeout(_stallAfter);
        } on TimeoutException {
          return _PipeEnd.broken;
        } catch (_) {
          return _PipeEnd.broken; // connection dropped mid-lesson
        }
        if (!more) return _PipeEnd.done;
        final List<int> chunk = it.current;
        try {
          res.add(chunk);
          await res.flush();
        } catch (_) {
          return _PipeEnd.playerGone; // seek / closed lesson
        }
        onBytes(chunk.length);
        _count(src, chunk.length, token);
        if (!_tokens.containsKey(token)) return _PipeEnd.playerGone;
      }
    } finally {
      unawaited(it.cancel().catchError((Object _) {}));
    }
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

      // Decrypted on the background worker — on the UI isolate this froze
      // the app while the player buffered (see CtrWorker).
      await raf.setPosition(ContentCrypto.headerLength + start);
      int pos = start;
      const int chunk = 256 * 1024;
      while (pos <= end) {
        final Uint8List read = await raf.read(min(chunk, end - pos + 1));
        if (read.isEmpty) break;
        final Uint8List data = await CtrWorker.apply(src.key!, nonce, read, pos);
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
/// How one upstream connection of a lesson stream ended.
enum _PipeEnd { done, broken, playerGone }

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
    ..badCertificateCallback = PinnedFetch.outdatedRoot;

  /// Google's own CA; Drive's certificates are issued by it.
  static bool _isGoogle(X509Certificate? c) =>
      c != null && c.issuer.contains('Google Trust Services');

  /// The public authorities Cloudflare's certificates come from (07/11/2026,
  /// lessons on Cloudflare R2). A sniffer's own certificate is none of these.
  static const List<String> _cloudflareIssuers = <String>[
    'Google Trust Services',
    "Let's Encrypt",
    'SSL.com',
    'SSL Corporation',
    'Sectigo',
    'DigiCert',
  ];

  /// FIX (12/11/2026) — FALSE "HTTPS sniffer" alerts. Cloudflare's lesson
  /// server uses an SSL.com certificate; PCs whose root certificates were
  /// never updated don't know SSL.com's newer ECC root, so the connection was
  /// refused, reported as a sniffer, and the lesson did not play.
  /// Now, for the lesson server only (never Google), a certificate from a
  /// known public CA, inside its validity dates, is accepted quietly. A
  /// sniffer's certificate carries its own name and is still refused.
  static bool outdatedRoot(X509Certificate cert, String host, int port) {
    final DateTime now = DateTime.now();
    final bool known = !host.contains('google') &&
        _cloudflareIssuers.any(cert.issuer.contains) &&
        now.isAfter(cert.startValidity) &&
        now.isBefore(cert.endValidity);
    if (!known) SecurityMonitor.intercepted(host, cert.issuer);
    return known;
  }

  static bool _trusted(X509Certificate? c, Uri uri) {
    if (c == null) return false;
    if (uri.host.contains('google')) return _isGoogle(c);
    return _cloudflareIssuers.any(c.issuer.contains);
  }

  // Some internet providers' DNS does not answer for *.workers.dev ("Failed
  // host lookup") although the server is reachable. Then the address is
  // asked from Google's DNS over HTTPS and the app connects to it directly,
  // with full HTTPS checks for the real name. Google hosts never take this
  // path. (07/11/2026, from ENGX)
  static final Map<String, HttpClient> _viaDoh = <String, HttpClient>{};

  /// Hosts that did not answer (time-out / connection error) through the
  /// device's own DNS: their next request goes through DNS over HTTPS.
  static final Set<String> _suspect = <String>{};

  static void suspect(Uri uri) {
    if (!uri.host.contains('google')) _suspect.add(uri.host);
  }

  static Future<HttpClientRequest> _open(Uri uri, bool head) async {
    final HttpClient? doh = _viaDoh[uri.host];
    if (doh != null) return head ? doh.headUrl(uri) : doh.getUrl(uri);
    if (_suspect.remove(uri.host)) {
      final HttpClient? client = await _clientByDoh(uri.host);
      if (client != null) {
        _viaDoh[uri.host] = client;
        return head ? client.headUrl(uri) : client.getUrl(uri);
      }
    }
    try {
      return head ? await _client.headUrl(uri) : await _client.getUrl(uri);
    } on SocketException catch (e) {
      if (uri.host.contains('google') || !'$e'.contains('host lookup')) rethrow;
      final HttpClient? client = await _clientByDoh(uri.host);
      if (client == null) {
        throw SocketException('${e.message} — and DNS over HTTPS failed too ($lastDohError)',
            osError: e.osError, address: e.address, port: e.port);
      }
      _viaDoh[uri.host] = client;
      return head ? client.headUrl(uri) : client.getUrl(uri);
    }
  }

  static Future<HttpClient?> _clientByDoh(String host) async {
    final List<InternetAddress> ips = await _dohLookup(host);
    if (ips.isEmpty) return null;
    final HttpClient c = HttpClient()
      ..findProxy = ((Uri _) => 'DIRECT')
      ..autoUncompress = false
      ..connectionTimeout = const Duration(seconds: 20)
      ..badCertificateCallback = PinnedFetch.outdatedRoot;
    int next = 0;
    c.connectionFactory = (Uri url, String? proxyHost, int? proxyPort) async {
      final InternetAddress ip = ips[next++ % ips.length];
      final int port = url.hasPort ? url.port : 443;
      final Future<SecureSocket> socket = Socket.connect(ip, port, timeout: const Duration(seconds: 15))
          .then((Socket raw) => SecureSocket.secure(raw, host: url.host));
      return ConnectionTask.fromSocket(socket, () {});
    };
    return c;
  }

  /// Why the last DNS-over-HTTPS lookup failed (for the error report).
  static String lastDohError = '';

  /// A host's IPv4 addresses from DNS over HTTPS ([] when none). Asked by IP
  /// address first (8.8.8.8, 1.1.1.1), so a network whose own DNS does not
  /// answer — even for dns.google — still gets an answer (07/11/2026).
  static Future<List<InternetAddress>> _dohLookup(String host) async {
    final List<Uri> servers = <Uri>[
      Uri.https('8.8.8.8', '/resolve', <String, String>{'name': host, 'type': 'A'}),
      Uri.https('1.1.1.1', '/dns-query', <String, String>{'name': host, 'type': 'A'}),
      Uri.https('8.8.4.4', '/resolve', <String, String>{'name': host, 'type': 'A'}),
      Uri.https('1.0.0.1', '/dns-query', <String, String>{'name': host, 'type': 'A'}),
      Uri.https('dns.google', '/resolve', <String, String>{'name': host, 'type': 'A'}),
    ];
    final List<String> why = <String>[];
    for (final Uri server in servers) {
      try {
        final HttpClientRequest rq = await _client.getUrl(server).timeout(const Duration(seconds: 6));
        rq.headers.set(HttpHeaders.acceptHeader, 'application/dns-json');
        final HttpClientResponse r = await rq.close().timeout(const Duration(seconds: 6));
        final String body = await r.transform(const Utf8Decoder(allowMalformed: true)).join();
        final Object? data = jsonDecode(body);
        final Object? answers = data is Map ? data['Answer'] : null;
        final List<InternetAddress> ips = <InternetAddress>[
          if (answers is List)
            for (final Object? a in answers)
              if (a is Map && a['type'] == 1 && InternetAddress.tryParse('${a['data']}') != null)
                InternetAddress('${a['data']}'),
        ];
        if (ips.isNotEmpty) {
          lastDohError = '';
          return ips;
        }
        why.add('${server.host}: no address');
      } catch (e) {
        final String t = '$e';
        why.add('${server.host}: ${t.length > 80 ? t.substring(0, 80) : t}');
      }
    }
    lastDohError = why.join('; ');
    return <InternetAddress>[];
  }

  static Future<HttpClientResponse> _send(Uri uri, String? range, bool head) async {
    final HttpClientRequest rq = await _open(uri, head);
    if (range != null) rq.headers.set(HttpHeaders.rangeHeader, range);
    final HttpClientResponse r = await rq.close();
    if (!_trusted(r.certificate, uri)) {
      final String issuer = r.certificate?.issuer ?? 'none';
      SecurityMonitor.intercepted(uri.host, issuer);
      unawaited(r.drain<void>().catchError((Object _) {}));
      throw InterceptedException(issuer);
    }
    return r;
  }

  static final RegExp _driveUuid = RegExp('name="uuid" value="([^"]+)"');
  static final RegExp _driveConfirm = RegExp('name="confirm" value="([^"]+)"');

  /// Fetches lesson bytes. Handles Google Drive's "confirm" page: a LARGE
  /// Drive file does not download straight away — Drive first answers with an
  /// HTML page (the "we can't scan this file for viruses" / quota warning),
  /// and the real file needs a second request carrying a token from that
  /// page. The old code handed the first link straight to the player, so the
  /// player got HTML and failed with "Source error". Here the app resolves
  /// that page itself and returns the real video stream — the player only
  /// ever sees clean bytes.
  static Future<HttpClientResponse> get(
    Uri uri, {
    String? range,
    bool head = false,
  }) async {
    HttpClientResponse r = await _send(uri, range, head);
    final String type = r.headers.contentType?.mimeType ?? '';
    final bool isDrive = uri.host.contains('google');
    if (!head && isDrive && type == 'text/html') {
      // Read the warning page (small) and build the confirm link.
      final String body =
          await r.transform(const Utf8Decoder(allowMalformed: true)).join();
      final String? uuid = _driveUuid.firstMatch(body)?.group(1);
      final String? confirm = _driveConfirm.firstMatch(body)?.group(1);
      if (uuid != null) {
        final Uri confirmUri = uri.replace(queryParameters: <String, String>{
          ...uri.queryParameters,
          'confirm': confirm ?? 't',
          'uuid': uuid,
        });
        r = await _send(confirmUri, range, head);
        final String type2 = r.headers.contentType?.mimeType ?? '';
        if (type2 == 'text/html') {
          unawaited(r.drain<void>().catchError((Object _) {}));
          throw const DriveUnavailableException();
        }
      } else {
        // No token on the page: the file is private, over quota, or removed.
        throw const DriveUnavailableException();
      }
    }
    return r;
  }
}

/// Google Drive answered with a web page, not the video — the file is over
/// its daily download quota, has been made private, or was removed. Reported
/// to the super admin so a broken lesson is visible.
class DriveUnavailableException implements Exception {
  const DriveUnavailableException();
  @override
  String toString() =>
      'Google Drive did not return the video (quota exceeded, private, or removed).';
}
