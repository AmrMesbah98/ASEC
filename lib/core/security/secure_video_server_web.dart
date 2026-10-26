/// Module: core/security
///
///*************************** FILE INFO ****************************///
/// File Name: secure_video_server_web.dart
/// Purpose: Web build of SecureVideoServer — no local server in a browser.

import 'dart:typed_data';

abstract final class SecureVideoServer {
  const SecureVideoServer._();

  static Future<Uri> remote(String url, {int sizeBytes = 0, String label = ''}) async =>
      Uri.parse(url);

  static Future<Uri> localEncrypted(String path, Uint8List key, {String label = ''}) async =>
      Uri.parse(path);

  static void revoke(Uri? uri) {}
}
