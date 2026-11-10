/// Web build of WindowsUpdater — never used there.
library;

abstract final class WindowsUpdater {
  static bool canHandle(String url) => false;

  static Future<String> download(
    String url, {
    required void Function(double? progress) onProgress,
    required bool Function() cancelled,
  }) async =>
      throw UnsupportedError('Windows only');

  static Future<void> runAndExit(String path) async {}
}
