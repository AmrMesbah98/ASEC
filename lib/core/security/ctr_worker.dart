/// Module: core/security
///
///*************************** FILE INFO ****************************///
/// File Name: ctr_worker.dart
/// Purpose: Declares `CtrWorker` — runs the AES-256-CTR work for downloaded
///          lessons on a BACKGROUND isolate.
///
///          `CtrCipher` is pure Dart: one AES block per 16 bytes. Run on the
///          UI isolate, decrypting the first megabytes a player asks for
///          (or encrypting a download as it arrives) froze the whole app —
///          the lag on the first offline video and while downloading. The
///          chunks now travel to one long-lived worker isolate and back as
///          TransferableTypedData, so the UI never waits on the cipher.
///          If the worker cannot start, it falls back to this isolate.
///
///          IO platforms only (imported by the *_io files, never by web).
/// Author: ASEC team
/// Created: 27/10/2026
library;

import 'dart:async';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:asec/core/security/content_crypto.dart';

abstract final class CtrWorker {
  const CtrWorker._();

  static SendPort? _port;
  static Future<SendPort>? _starting;
  static int _nextId = 0;
  static final Map<int, Completer<Uint8List>> _pending =
      <int, Completer<Uint8List>>{};

  // Kept alive for the whole run of the app.
  // ignore: unused_field
  static ReceivePort? _replies;

  static Future<SendPort> _ensure() {
    final SendPort? p = _port;
    if (p != null) return Future<SendPort>.value(p);
    return _starting ??= _spawn();
  }

  static Future<SendPort> _spawn() async {
    final ReceivePort replies = ReceivePort();
    final Completer<SendPort> ready = Completer<SendPort>();
    replies.listen((dynamic msg) {
      if (msg is SendPort) {
        if (!ready.isCompleted) ready.complete(msg);
        return;
      }
      final List<dynamic> m = msg as List<dynamic>;
      final Completer<Uint8List>? c = _pending.remove(m[0] as int);
      if (c == null) return;
      final Object result = m[1] as Object;
      if (result is TransferableTypedData) {
        c.complete(result.materialize().asUint8List());
      } else {
        c.completeError(StateError('$result'));
      }
    });
    _replies = replies;
    await Isolate.spawn(_main, replies.sendPort, debugName: 'asec-ctr-worker');
    final SendPort port = await ready.future;
    _port = port;
    return port;
  }

  /// Encrypts / decrypts [data] (CTR does both) as bytes starting at
  /// [offset] of the stream. Returns the result; [data] itself may or may
  /// not be changed, so always use the returned list.
  static Future<Uint8List> apply(
    Uint8List key,
    Uint8List nonce,
    Uint8List data,
    int offset,
  ) async {
    if (data.isEmpty) return data;
    try {
      final SendPort port = await _ensure();
      final int id = _nextId++;
      final Completer<Uint8List> done = Completer<Uint8List>();
      _pending[id] = done;
      port.send(<Object>[
        id,
        key,
        nonce,
        TransferableTypedData.fromList(<TypedData>[data]),
        offset,
      ]);
      return await done.future;
    } catch (_) {
      // No worker: do it here, slower but correct.
      CtrCipher(key, nonce).apply(data, offset);
      return data;
    }
  }

  // ── The worker isolate ──────────────────────────────────────────────────

  static void _main(SendPort replies) {
    final ReceivePort jobs = ReceivePort();
    replies.send(jobs.sendPort);

    Uint8List? lastKey;
    Uint8List? lastNonce;
    CtrCipher? cipher;

    jobs.listen((dynamic msg) {
      final List<dynamic> m = msg as List<dynamic>;
      try {
        final Uint8List key = m[1] as Uint8List;
        final Uint8List nonce = m[2] as Uint8List;
        if (cipher == null || !_same(key, lastKey) || !_same(nonce, lastNonce)) {
          cipher = CtrCipher(key, nonce);
          lastKey = key;
          lastNonce = nonce;
        }
        final Uint8List data =
            (m[3] as TransferableTypedData).materialize().asUint8List();
        cipher!.apply(data, m[4] as int);
        replies.send(<Object>[
          m[0] as int,
          TransferableTypedData.fromList(<TypedData>[data]),
        ]);
      } catch (e) {
        replies.send(<Object>[m[0] as int, '$e']);
      }
    });
  }

  static bool _same(Uint8List a, Uint8List? b) {
    if (b == null || a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
