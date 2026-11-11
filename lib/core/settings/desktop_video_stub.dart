/// Module: core/settings
///
///*************************** FILE INFO ****************************///
/// File Name: desktop_video_stub.dart
/// Purpose: Web build of desktop_video — nothing to register in a browser.

void registerDesktopVideo() {}

/// Web build: no fallback player.
bool enableSoftwareVideoPlayer() => false;

/// Web build: nothing to prepare.
Future<void> prepareDesktopVideo() async {}

/// Web build: no lower decoding level.
Future<String?> softerDesktopVideo() async => null;

/// Web build: the browser decodes.
String get desktopVideoMode => 'browser';

/// Web build: decoder errors are the browser's.
bool isVideoDecoderError(Object e) => false;
