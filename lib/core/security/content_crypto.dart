/// Module: core/security
///
///*************************** FILE INFO ****************************///
/// File Name: content_crypto.dart
/// Purpose: Declares `ContentCrypto` — the small crypto toolbox that keeps
///          the lessons' Google Drive links and downloaded files out of
///          reach:
///            * [hashId]   one-way id for documents every member can read
///                         (video_catalog), so they never carry a Drive id.
///            * [reveal]   un-hides ids written into the app's code, so a
///                         `strings` dump of the app shows no Drive id.
///            * [CtrCipher] AES-256-CTR for downloaded lessons (seekable, so
///                         the player can jump anywhere without decrypting
///                         the whole file).
///            * [deviceKey] the per-device, per-account key those files use.
///                         A file copied to another computer, or out of the
///                         app, is noise.
/// Author: ASEC team
/// Created: 26/10/2026

import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:get_storage/get_storage.dart';
import 'package:pointycastle/export.dart' hide Digest;

abstract final class ContentCrypto {
  const ContentCrypto._();

  // Split so it is not one obvious string in the binary.
  static final List<int> _pepper = utf8.encode(
    <String>['a5', 'EC', '·v', 'au', 'lt', '·2', '02', '6·', 'k9', 'Qz'].join(),
  );

  // ── Ids ───────────────────────────────────────────────────────────────────

  /// One-way, stable id: the same [id] always gives the same answer, and the
  /// answer cannot be turned back into the id.
  static String hashId(String id) {
    final Digest d = Hmac(sha256, _pepper).convert(utf8.encode(id));
    return 'c_${base64Url.encode(d.bytes).replaceAll('=', '').substring(0, 22)}';
  }

  static List<int> get _pad => sha256.convert(<int>[..._pepper, ...utf8.encode('ids')]).bytes;

  /// Turns a value hidden with the same scheme back into text.
  static String reveal(String hidden) {
    final List<int> b = base64Url.decode(base64Url.normalize(hidden));
    final List<int> pad = _pad;
    return utf8.decode(<int>[for (int i = 0; i < b.length; i++) b[i] ^ pad[i % pad.length]]);
  }

  // ── Downloaded files ──────────────────────────────────────────────────────

  /// 'ASV1' — marks an encrypted lesson file.
  static const List<int> magic = <int>[0x41, 0x53, 0x56, 0x31];

  /// magic (4) + nonce (8).
  static const int headerLength = 12;

  static const String _keyName = 'asec_vk';

  /// 32 random bytes made on this device the first time, mixed with the
  /// account, so another account on the same device cannot open the files
  /// either.
  static Uint8List deviceKey(String uid) {
    final GetStorage box = GetStorage();
    String? stored = box.read<String>(_keyName);
    if (stored == null || stored.isEmpty) {
      final Random r = Random.secure();
      stored = base64Url.encode(<int>[for (int i = 0; i < 32; i++) r.nextInt(256)]);
      box.write(_keyName, stored);
    }
    final List<int> raw = base64Url.decode(stored);
    return Uint8List.fromList(
      Hmac(sha256, <int>[...raw, ..._pepper]).convert(utf8.encode('file:$uid')).bytes,
    );
  }

  static Uint8List newNonce() {
    final Random r = Random.secure();
    return Uint8List.fromList(<int>[for (int i = 0; i < 8; i++) r.nextInt(256)]);
  }

  static Uint8List header(Uint8List nonce) =>
      Uint8List.fromList(<int>[...magic, ...nonce]);

  /// The nonce of an encrypted file's first [headerLength] bytes, or null
  /// when it is not one.
  static Uint8List? nonceOf(List<int> head) {
    if (head.length < headerLength) return null;
    for (int i = 0; i < magic.length; i++) {
      if (head[i] != magic[i]) return null;
    }
    return Uint8List.fromList(head.sublist(4, headerLength));
  }
}

/// AES-256-CTR. [apply] encrypts and decrypts alike (XOR with the key
/// stream), in place, from any byte [offset] of the stream.
class CtrCipher {
  CtrCipher(Uint8List key, Uint8List nonce)
      : _nonce = nonce,
        _aes = AESEngine()..init(true, KeyParameter(key));

  final AESEngine _aes;
  final Uint8List _nonce;
  final Uint8List _ctr = Uint8List(16);
  final Uint8List _ks = Uint8List(16);

  void apply(Uint8List data, int offset) {
    int block = offset ~/ 16;
    int skip = offset % 16;
    int i = 0;
    while (i < data.length) {
      _ctr.setRange(0, 8, _nonce);
      int b = block;
      for (int k = 15; k >= 8; k--) {
        _ctr[k] = b & 0xff;
        b >>= 8;
      }
      _aes.processBlock(_ctr, 0, _ks, 0);
      for (int j = skip; j < 16 && i < data.length; j++, i++) {
        data[i] ^= _ks[j];
      }
      skip = 0;
      block++;
    }
  }
}
