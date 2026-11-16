/// Module: video / v1_videos
///
///*************************** FILE INFO ****************************///
/// File Name: cloud_lessons.dart
/// Purpose: Declares `CloudLessons` — lesson videos served from Cloudflare R2
///          (through the ASEC Worker, cloudflare/worker.js) instead of
///          Google Drive's public download address.
/// Created: 07/11/2026 (ported from ENGX)
///
/// WHY. Google Drive blocks a public file for up to 24 hours once "too many
/// users have viewed or downloaded" it — every lesson stops at once. R2 has
/// no such limit and no bandwidth charge.
///
/// HOW IT FITS. Drive stays the catalogue (sync and uploads unchanged). Each
/// lesson FILE is copied into R2 as `lessons/<drive file id>` (Settings →
/// Cloudflare lessons → Copy lessons). While Settings → Control centre →
/// "Play lessons from Cloudflare" is ON, members play ONLY from there —
/// never from Drive; OFF = Drive, as before.
///
/// SECURITY. The bucket is private. The Worker serves a lesson only on an
/// address this app signs (HMAC, minutes), signed fresh for every request
/// through the local lesson gateway, so the player never sees it. Uploads
/// need the admin's Firebase sign-in.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;

import 'package:asec/core/security/secure_video_server.dart';
import 'package:asec/core/settings/app_features.dart';
import 'package:asec/features/video/v1_videos/domain/entities/video_link.dart';

abstract final class CloudLessons {
  // The Worker's address and signing key, hidden so the app file does not
  // show them as plain text.
  static const String _hiddenBase = 'CxhEBRdcQxsTFkgPSB8WHB0cDR8eFAkUAVEBB0wEV0NBXEAEDB5bEBYVQlAXEw==';
  static const String _hiddenKey = 'AAkHTFdXW1AXBx9UU0tHCQ9KVVsHTVcFVAxFVxkKUxZGClsVUlUAEVZWX1BCBhhVXEpBXFZLVV1SEAVXDVFBUw==';
  static const List<int> _pad = <int>[99, 108, 48, 117, 100, 102, 108, 52, 114, 101, 45, 108, 101, 115, 115, 111, 110, 115];

  static String _reveal(String hidden) {
    final List<int> b = base64Url.decode(hidden);
    return utf8.decode(<int>[for (int i = 0; i < b.length; i++) b[i] ^ _pad[i % _pad.length]]);
  }

  static final String baseUrl = _reveal(_hiddenBase);
  static final String _signKey = _reveal(_hiddenKey);

  /// THE SAME WORKER ON ENGX'S DOMAIN (16/11/2026, as ENGX's lessons.engx.uk).
  /// Some providers and company networks block every `*.workers.dev`
  /// address, so lessons "could not be reached" there. This second address
  /// (a Custom Domain of the asec-lessons Worker, on the engx.uk zone in the
  /// same Cloudflare account) is tried too, and the one that answers is
  /// remembered on the device and used first from then on.
  static const String mirrorUrl = 'https://asec-lessons.engx.uk';

  static const String _goodHostKey = 'cloud_good_host';
  static bool _hostLoaded = false;

  /// Every lesson address, the one that answered last on this device first.
  static List<String> get bases {
    if (!_hostLoaded) {
      _hostLoaded = true;
      try {
        final GetStorage box = GetStorage();
        if (SecureVideoServer.goodCloudHost.isEmpty) {
          SecureVideoServer.goodCloudHost = '${box.read(_goodHostKey) ?? ''}';
        }
        SecureVideoServer.onGoodCloudHost = (String host) {
          try {
            box.write(_goodHostKey, host);
          } catch (_) {}
        };
      } catch (_) {}
    }
    final List<String> all = <String>[baseUrl, mirrorUrl];
    final String good = SecureVideoServer.goodCloudHost;
    final int i = all.indexWhere((String u) => Uri.tryParse(u)?.host == good);
    if (i > 0) all.insert(0, all.removeAt(i));
    return all;
  }

  /// R2 needs equal parts; a Worker request body must stay under 100 MB.
  static const int partBytes = 20 * 1024 * 1024;

  /// Switched on by the admin (Settings → Control centre).
  static bool get on {
    try {
      return AppFeatures.on(AppFeature.videoCloud);
    } catch (_) {
      return false;
    }
  }

  /// FILES STRAIGHT TO CLOUDFLARE (from Eduneers, 09/11/2026): course
  /// files are uploaded only to R2 and stored as `r2:<object key>`; the
  /// address is signed when the file is opened (it expires).
  static const String directPrefix = 'r2:';

  static bool isDirect(String url) => url.trim().startsWith(directPrefix);

  /// A new object key for an uploaded file: `lessons/<random>.<ext>`
  /// (the Worker only serves `lessons/…`; the key keeps the extension).
  static String newKey(String fileName) {
    final Random r = Random.secure();
    final String id = List<String>.generate(16, (_) => r.nextInt(256).toRadixString(16).padLeft(2, '0')).join();
    final int dot = fileName.lastIndexOf('.');
    final String ext = dot > 0 ? fileName.substring(dot + 1).toLowerCase() : 'bin';
    return 'lessons/$id.$ext';
  }

  /// The R2 object: its own (`r2:` link), or a Drive lesson's copy
  /// `lessons/<drive file id>`.
  static String? keyFor(String url) {
    if (isDirect(url)) return url.trim().substring(directPrefix.length);
    final String? id = VideoLink.driveId(url);
    return id == null ? null : 'lessons/$id';
  }

  static String get _device => FirebaseAuth.instance.currentUser?.uid ?? '';

  /// WRONG PC CLOCK (ported from ENGX, 10/11/2026). A signed address carries
  /// an expiry taken from this device's clock; the Worker refuses one more
  /// than an hour off ("HTTP 403 Expired"), so a PC with a wrong date or time
  /// zone could play nothing. The Worker's own time (its `Date` header) minus
  /// this device's, learnt once per run; zero until known.
  static Duration _clockOffset = Duration.zero;
  static Future<void>? _clockSync;

  /// Now, by the lesson server's clock when it is known.
  static DateTime get _now => DateTime.now().add(_clockOffset);

  /// Learns the Worker's clock once per run (call before signing). Never
  /// throws; gives up after a few seconds and keeps this device's clock.
  static Future<void> syncClock() {
    final Future<void> f = _clockSync ??= _syncClock();
    return f.timeout(const Duration(seconds: 7), onTimeout: () {});
  }

  static Future<void> _syncClock() async {
    try {
      final DateTime sent = DateTime.now();
      http.Response? r;
      for (final String b in bases) {
        try {
          r = await http.head(Uri.parse('$b/')).timeout(const Duration(seconds: 6));
          break;
        } catch (_) {}
      }
      if (r == null) throw StateError('no lesson host answered');
      final String? date = r.headers['date'];
      if (date != null) {
        final DateTime server = HttpDate.parse(date);
        // Half the round trip: when the server wrote the header.
        final DateTime local = sent.add(DateTime.now().difference(sent) ~/ 2);
        final Duration off = server.difference(local);
        // Under two minutes off is fine as it is (the header has whole seconds).
        _clockOffset = off.abs() > const Duration(minutes: 2) ? off : Duration.zero;
        return;
      }
    } catch (_) {}
    _clockSync = null; // nobody answered: try again next time
  }

  /// A fresh signed address for [key] (valid 10 minutes).
  /// [base]: which lesson address — by default the one that answered last.
  /// The signature does not include the host, so it is valid on every one.
  static String signedUrl(String key, {String? base}) {
    unawaited(syncClock());
    final int e = _now.millisecondsSinceEpoch ~/ 1000 + 600;
    final String d = _device;
    final String s = Hmac(sha256, utf8.encode(_signKey)).convert(utf8.encode('$key|$e|$d')).toString();
    return '${base ?? bases.first}/v/$key?e=$e&d=${Uri.encodeQueryComponent(d)}&s=$s';
  }

  /// For a Drive lesson [url]: signs a fresh Cloudflare address on every
  /// call — or null when Cloudflare is off / not a Drive lesson.
  static String Function()? signerFor(String url) {
    // A file that lives only in Cloudflare always comes from there; a Drive
    // lesson only while the switch is on.
    if (!isDirect(url) && !on) return null;
    final String? key = keyFor(url);
    if (key == null) return null;
    // Each call (each try) signs on the next address, the best one first:
    // where workers.dev is blocked, the second try already uses engx.uk.
    int n = 0;
    return () {
      final List<String> all = bases;
      return signedUrl(key, base: all[n++ % all.length]);
    };
  }

  // ── admin: uploads ────────────────────────────────────────────────────────

  static Future<Map<String, String>> _adminHeaders() async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) throw StateError('Sign in as the admin first.');
    final String? token = await user.getIdToken();
    return <String, String>{HttpHeaders.authorizationHeader: 'Bearer $token'};
  }

  static Uri _adminUri(String op, Map<String, String> q) => Uri.parse('${bases.first}/admin/$op').replace(queryParameters: q);

  static Map<String, dynamic> _json(http.Response r) {
    if (r.statusCode >= 300) throw HttpException('Cloudflare ${r.statusCode}: ${r.body}');
    return Map<String, dynamic>.from(jsonDecode(r.body) as Map);
  }

  /// Whether [key] is already in the bucket.
  static Future<bool> has(String key) async {
    final http.Response r = await http.get(_adminUri('has', <String, String>{'key': key}), headers: await _adminHeaders());
    return _json(r)['exists'] == true;
  }

  /// Uploads [data] (the whole file) as [key], in 20 MB parts.
  static Future<void> upload(
    String key,
    Stream<List<int>> data, {
    void Function(int bytes)? onBytes,
    bool Function()? cancelled,
  }) async {
    final String uploadId = '${_json(await http.post(_adminUri('mpu/create', <String, String>{'key': key}), headers: await _adminHeaders()))['uploadId']}';
    final List<Map<String, dynamic>> parts = <Map<String, dynamic>>[];
    final BytesBuilder buffer = BytesBuilder(copy: false);
    int n = 0;

    Future<void> send(Uint8List bytes) async {
      n++;
      Object? last;
      for (int attempt = 0; attempt < 3; attempt++) {
        try {
          final http.Response r = await http.put(
            _adminUri('mpu/part', <String, String>{'key': key, 'uploadId': uploadId, 'part': '$n'}),
            headers: await _adminHeaders(),
            body: bytes,
          );
          final Map<String, dynamic> p = _json(r);
          parts.add(<String, dynamic>{'partNumber': p['partNumber'], 'etag': p['etag']});
          onBytes?.call(bytes.length);
          return;
        } catch (e) {
          last = e;
          await Future<void>.delayed(Duration(seconds: 2 * (attempt + 1)));
        }
      }
      throw last ?? StateError('upload failed');
    }

    try {
      await for (final List<int> chunk in data) {
        if (cancelled?.call() ?? false) throw StateError('cancelled');
        buffer.add(chunk);
        while (buffer.length >= partBytes) {
          final Uint8List all = buffer.takeBytes();
          await send(Uint8List.sublistView(all, 0, partBytes));
          if (all.length > partBytes) buffer.add(Uint8List.sublistView(all, partBytes));
        }
      }
      if (buffer.length > 0 || parts.isEmpty) await send(buffer.takeBytes());
      _json(await http.post(
        _adminUri('mpu/complete', <String, String>{'key': key, 'uploadId': uploadId}),
        headers: <String, String>{...await _adminHeaders(), HttpHeaders.contentTypeHeader: 'application/json'},
        body: jsonEncode(<String, dynamic>{'parts': parts}),
      ));
    } catch (e) {
      try {
        await http.post(_adminUri('mpu/abort', <String, String>{'key': key, 'uploadId': uploadId}),
            headers: await _adminHeaders());
      } catch (_) {}
      rethrow;
    }
  }

  /// Removes a file from the bucket (the admin deleted it).
  static Future<void> delete(String key) async {
    _json(await http.post(_adminUri('delete', <String, String>{'key': key}), headers: await _adminHeaders()));
  }

  /// A copy right after a new Drive upload — never fails that upload.
  static Future<void> copyNewUpload(String driveFileId, String? path) async {
    if (path == null || path.isEmpty) return;
    try {
      await upload('lessons/$driveFileId', File(path).openRead());
    } catch (e) {
    }
  }
}
